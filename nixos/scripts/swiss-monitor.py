#!/usr/bin/env python3
"""
Swiss Monitor - Real-time Log Monitoring with Semantic ML Analysis

A unified monitoring tool for NixOS SOC infrastructure that:
- Streams logs from multiple sources (journald, Suricata, FIM)
- Classifies events using local Ollama LLM
- Provides colorized terminal output with Rich
- Supports JSON output for pipeline integration

Usage:
    swiss-monitor [--source SOURCE] [--ml] [--json] [--filter SEVERITY]

Examples:
    swiss-monitor                        # Monitor all sources
    swiss-monitor --source journald      # Only journald
    swiss-monitor --ml                   # Enable ML classification
    swiss-monitor --json                 # JSON output for pipelines
"""

import argparse
import asyncio
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import AsyncIterator, Optional

try:
    import aiohttp
    from rich.console import Console
    from rich.live import Live
    from rich.panel import Panel
    from rich.table import Table
    from rich.text import Text
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    print("Warning: Rich not available, using plain output", file=sys.stderr)


class Severity(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


@dataclass
class LogEvent:
    """Represents a parsed log event"""
    timestamp: str
    source: str
    message: str
    severity: Severity = Severity.INFO
    category: str = ""
    raw: str = ""
    ml_classification: Optional[str] = None


class OllamaClassifier:
    """Classify log events using Ollama local LLM"""
    
    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3.2:1b"):
        self.base_url = base_url
        self.model = model
        self.session: Optional[aiohttp.ClientSession] = None
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, *args):
        if self.session:
            await self.session.close()
    
    async def classify(self, log_message: str) -> tuple[Severity, str]:
        """
        Classify a log message using Ollama.
        Returns (severity, category) tuple.
        """
        if not self.session:
            return Severity.INFO, "unclassified"
            
        prompt = f"""Analyze this log message and classify it:

Log: {log_message[:500]}

Respond with ONLY a JSON object (no markdown):
{{"severity": "critical|high|medium|low|info", "category": "short category name"}}"""

        try:
            async with self.session.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.1, "num_predict": 50}
                },
                timeout=aiohttp.ClientTimeout(total=5)
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    response_text = data.get("response", "").strip()
                    
                    # Parse JSON response
                    try:
                        # Clean up potential markdown
                        if response_text.startswith("```"):
                            response_text = response_text.split("\n", 1)[1].rsplit("```", 1)[0]
                        
                        result = json.loads(response_text)
                        severity = Severity(result.get("severity", "info").lower())
                        category = result.get("category", "general")[:30]
                        return severity, category
                    except (json.JSONDecodeError, ValueError):
                        pass
        except Exception:
            pass
            
        return Severity.INFO, "unclassified"


class LogSource:
    """Base class for log sources"""
    
    async def stream(self) -> AsyncIterator[LogEvent]:
        """Stream log events from source"""
        raise NotImplementedError


class JournaldSource(LogSource):
    """Stream logs from systemd journal"""
    
    def __init__(self, units: list[str] = None, priority: str = "warning"):
        self.units = units or []
        self.priority = priority
        
    async def stream(self) -> AsyncIterator[LogEvent]:
        cmd = ["journalctl", "-f", "-o", "json", "-p", self.priority]
        for unit in self.units:
            cmd.extend(["-u", unit])
            
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL
        )
        
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
                
            try:
                data = json.loads(line.decode())
                yield LogEvent(
                    timestamp=datetime.fromtimestamp(
                        int(data.get("__REALTIME_TIMESTAMP", 0)) / 1_000_000
                    ).isoformat(),
                    source=f"journald:{data.get('_SYSTEMD_UNIT', 'system')}",
                    message=data.get("MESSAGE", ""),
                    severity=self._parse_priority(data.get("PRIORITY", 6)),
                    raw=line.decode()
                )
            except (json.JSONDecodeError, ValueError):
                continue
    
    @staticmethod
    def _parse_priority(priority: int) -> Severity:
        """Convert journald priority to Severity"""
        if priority <= 2:
            return Severity.CRITICAL
        elif priority == 3:
            return Severity.HIGH
        elif priority == 4:
            return Severity.MEDIUM
        elif priority == 5:
            return Severity.LOW
        return Severity.INFO


class SuricataSource(LogSource):
    """Stream Suricata EVE JSON logs"""
    
    def __init__(self, eve_path: str = "/var/log/suricata/eve.json"):
        self.eve_path = Path(eve_path)
        
    async def stream(self) -> AsyncIterator[LogEvent]:
        if not self.eve_path.exists():
            return
            
        proc = await asyncio.create_subprocess_exec(
            "tail", "-f", "-n", "0", str(self.eve_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL
        )
        
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
                
            try:
                data = json.loads(line.decode())
                event_type = data.get("event_type", "unknown")
                
                # Skip non-alert events for now
                if event_type != "alert":
                    continue
                    
                alert = data.get("alert", {})
                yield LogEvent(
                    timestamp=data.get("timestamp", datetime.now().isoformat()),
                    source=f"suricata:{event_type}",
                    message=alert.get("signature", data.get("event_type", "")),
                    severity=self._parse_severity(alert.get("severity", 3)),
                    category=alert.get("category", ""),
                    raw=line.decode()
                )
            except (json.JSONDecodeError, ValueError):
                continue
    
    @staticmethod
    def _parse_severity(sev: int) -> Severity:
        """Convert Suricata severity to Severity enum"""
        if sev == 1:
            return Severity.CRITICAL
        elif sev == 2:
            return Severity.HIGH
        elif sev == 3:
            return Severity.MEDIUM
        return Severity.LOW


class FIMSource(LogSource):
    """Stream FIM (File Integrity Monitor) alerts"""
    
    def __init__(self, fim_path: str = "/var/log/soc/fim-alerts.json"):
        self.fim_path = Path(fim_path)
        
    async def stream(self) -> AsyncIterator[LogEvent]:
        if not self.fim_path.exists():
            return
            
        proc = await asyncio.create_subprocess_exec(
            "tail", "-f", "-n", "0", str(self.fim_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL
        )
        
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
                
            try:
                data = json.loads(line.decode())
                yield LogEvent(
                    timestamp=data.get("timestamp", datetime.now().isoformat()),
                    source="fim",
                    message=f"{data.get('action', 'unknown')}: {data.get('path', '')}",
                    severity=Severity(data.get("severity", "medium")),
                    category="file_integrity",
                    raw=line.decode()
                )
            except (json.JSONDecodeError, ValueError):
                continue


class SwissMonitor:
    """Main monitoring orchestrator"""
    
    SEVERITY_COLORS = {
        Severity.CRITICAL: "bold red",
        Severity.HIGH: "red",
        Severity.MEDIUM: "yellow",
        Severity.LOW: "cyan",
        Severity.INFO: "white",
    }
    
    SEVERITY_ICONS = {
        Severity.CRITICAL: "🔴",
        Severity.HIGH: "🟠",
        Severity.MEDIUM: "🟡",
        Severity.LOW: "🔵",
        Severity.INFO: "⚪",
    }
    
    def __init__(
        self,
        sources: list[str] = None,
        enable_ml: bool = False,
        json_output: bool = False,
        filter_severity: str = None,
        ollama_model: str = "llama3.2:1b"
    ):
        self.source_names = sources or ["journald", "suricata", "fim"]
        self.enable_ml = enable_ml
        self.json_output = json_output
        self.filter_severity = Severity(filter_severity) if filter_severity else None
        self.ollama_model = ollama_model
        
        self.console = Console() if RICH_AVAILABLE else None
        self.event_count = 0
        self.ml_count = 0
        
    def _create_sources(self) -> list[LogSource]:
        """Create log source instances"""
        sources = []
        for name in self.source_names:
            if name == "journald":
                sources.append(JournaldSource(
                    units=["suricata", "docker", "sshd"],
                    priority="notice"
                ))
            elif name == "suricata":
                sources.append(SuricataSource())
            elif name == "fim":
                sources.append(FIMSource())
        return sources
    
    async def _process_event(
        self,
        event: LogEvent,
        classifier: Optional[OllamaClassifier]
    ) -> Optional[LogEvent]:
        """Process and optionally classify event"""
        
        # ML classification
        if classifier and self.enable_ml and event.message:
            severity, category = await classifier.classify(event.message)
            # Only upgrade severity, never downgrade
            if severity.value < event.severity.value:
                event.severity = severity
            if category and category != "unclassified":
                event.ml_classification = category
                self.ml_count += 1
        
        # Filter by severity
        if self.filter_severity:
            severity_order = [Severity.CRITICAL, Severity.HIGH, Severity.MEDIUM, Severity.LOW, Severity.INFO]
            if severity_order.index(event.severity) > severity_order.index(self.filter_severity):
                return None
                
        return event
    
    def _output_event(self, event: LogEvent):
        """Output event to console or JSON"""
        self.event_count += 1
        
        if self.json_output:
            output = {
                "timestamp": event.timestamp,
                "source": event.source,
                "severity": event.severity.value,
                "message": event.message,
                "category": event.category,
            }
            if event.ml_classification:
                output["ml_classification"] = event.ml_classification
            print(json.dumps(output))
            sys.stdout.flush()
            return
        
        if self.console:
            icon = self.SEVERITY_ICONS[event.severity]
            color = self.SEVERITY_COLORS[event.severity]
            
            text = Text()
            text.append(f"{icon} ", style=color)
            text.append(f"[{event.timestamp[11:19]}] ", style="dim")
            text.append(f"[{event.source}] ", style="blue")
            text.append(event.message[:100], style=color)
            
            if event.ml_classification:
                text.append(f" 🤖{event.ml_classification}", style="magenta")
            
            self.console.print(text)
        else:
            # Plain output
            icon = {"critical": "!", "high": "*", "medium": "+", "low": "-", "info": " "}
            print(f"[{icon[event.severity.value]}] [{event.timestamp}] [{event.source}] {event.message}")
    
    async def _stream_source(
        self,
        source: LogSource,
        classifier: Optional[OllamaClassifier],
        queue: asyncio.Queue
    ):
        """Stream events from a source to the queue"""
        try:
            async for event in source.stream():
                await queue.put((source, event))
        except asyncio.CancelledError:
            pass
        except Exception as e:
            if not self.json_output and self.console:
                self.console.print(f"[red]Source error: {e}[/red]")
    
    async def run(self):
        """Main run loop"""
        sources = self._create_sources()
        
        if not sources:
            print("No log sources available", file=sys.stderr)
            return
        
        # Show header
        if not self.json_output and self.console:
            self.console.print(Panel.fit(
                f"[bold green]Swiss Monitor[/bold green] - Real-time Log Analysis\n"
                f"Sources: {', '.join(self.source_names)} | ML: {'✅' if self.enable_ml else '❌'}",
                border_style="green"
            ))
        
        # Create event queue
        queue: asyncio.Queue = asyncio.Queue()
        
        # Setup ML classifier
        classifier = None
        if self.enable_ml:
            classifier = OllamaClassifier(model=self.ollama_model)
            await classifier.__aenter__()
        
        try:
            # Start source streaming tasks
            tasks = [
                asyncio.create_task(self._stream_source(source, classifier, queue))
                for source in sources
            ]
            
            # Process events from queue
            while True:
                try:
                    _, event = await asyncio.wait_for(queue.get(), timeout=30)
                    processed = await self._process_event(event, classifier)
                    if processed:
                        self._output_event(processed)
                except asyncio.TimeoutError:
                    if not self.json_output and self.console:
                        self.console.print("[dim]Waiting for events...[/dim]")
                        
        except KeyboardInterrupt:
            if not self.json_output and self.console:
                self.console.print(f"\n[yellow]Stopped. Processed {self.event_count} events ({self.ml_count} ML classified)[/yellow]")
        finally:
            for task in tasks:
                task.cancel()
            if classifier:
                await classifier.__aexit__()


def main():
    parser = argparse.ArgumentParser(
        description="Swiss Monitor - Real-time Log Monitoring with ML",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  swiss-monitor                        Monitor all sources
  swiss-monitor --source journald      Only journald logs
  swiss-monitor --ml                   Enable ML classification
  swiss-monitor --json                 JSON output for pipelines
  swiss-monitor --filter high          Show only high/critical
        """
    )
    
    parser.add_argument(
        "--source", "-s",
        action="append",
        dest="sources",
        choices=["journald", "suricata", "fim"],
        help="Log source(s) to monitor (can specify multiple)"
    )
    
    parser.add_argument(
        "--ml", "-m",
        action="store_true",
        help="Enable ML classification via Ollama"
    )
    
    parser.add_argument(
        "--model",
        default="llama3.2:1b",
        help="Ollama model for classification (default: llama3.2:1b)"
    )
    
    parser.add_argument(
        "--json", "-j",
        action="store_true",
        help="Output as JSON (one event per line)"
    )
    
    parser.add_argument(
        "--filter", "-f",
        choices=["critical", "high", "medium", "low", "info"],
        help="Filter by minimum severity"
    )
    
    args = parser.parse_args()
    
    monitor = SwissMonitor(
        sources=args.sources,
        enable_ml=args.ml,
        json_output=args.json,
        filter_severity=args.filter,
        ollama_model=args.model
    )
    
    asyncio.run(monitor.run())


if __name__ == "__main__":
    main()
