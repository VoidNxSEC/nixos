#!/usr/bin/env python3
"""
VRAM Intelligence Monitor

Real-time GPU memory monitoring with intelligent scheduling and auto-scaling.

Features:
- Continuous nvidia-smi polling (sub-5s latency)
- VRAM budget calculator with predictions
- Priority-based scheduler with queue management
- Auto-scaling (evict low-priority models when threshold exceeded)
- Alert system (systemd notifications + webhooks)

Usage:
    python vram_monitor.py monitor --interval 5 --db-path /var/lib/ml-offload/registry.db
    python vram_monitor.py status --state-file /var/lib/ml-offload/vram-state.json
    python vram_monitor.py budget --model-id 5 --db-path /var/lib/ml-offload/registry.db
"""

import argparse
import json
import os
import subprocess
import sys
import time
import requests
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional


@dataclass
class GPUMemoryInfo:
    """GPU memory snapshot"""
    timestamp: str
    gpu_id: int
    total_mb: int
    used_mb: int
    free_mb: int
    utilization_percent: float
    temperature_c: int
    processes: List[Dict[str, any]]


@dataclass
class VRAMState:
    """Current VRAM state"""
    last_update: str
    gpus: List[GPUMemoryInfo]
    total_vram_gb: float
    used_vram_gb: float
    free_vram_gb: float
    utilization_percent: float
    loaded_models: List[Dict[str, any]]  # From registry + backends
    pending_queue: List[Dict[str, any]]
    alerts: List[str]


class NvidiaSMIMonitor:
    """Wrapper around nvidia-smi for GPU monitoring"""

    @staticmethod
    def query_gpu() -> List[GPUMemoryInfo]:
        """Query nvidia-smi for GPU memory info"""
        try:
            # Query nvidia-smi for memory and utilization
            cmd = [
                "nvidia-smi",
                "--query-gpu=index,memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu",
                "--format=csv,noheader,nounits"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            gpus = []
            for line in result.stdout.strip().split("\n"):
                parts = [p.strip() for p in line.split(",")]
                if len(parts) == 6:
                    gpu_id, total, used, free, util, temp = parts
                    gpus.append(GPUMemoryInfo(
                        timestamp=datetime.now().isoformat(),
                        gpu_id=int(gpu_id),
                        total_mb=int(total),
                        used_mb=int(used),
                        free_mb=int(free),
                        utilization_percent=float(util),
                        temperature_c=int(temp),
                        processes=NvidiaSMIMonitor.query_processes(int(gpu_id))
                    ))

            return gpus

        except subprocess.CalledProcessError as e:
            print(f"Error querying nvidia-smi: {e}", file=sys.stderr)
            return []
        except Exception as e:
            print(f"Unexpected error in nvidia-smi query: {e}", file=sys.stderr)
            return []

    @staticmethod
    def query_processes(gpu_id: int) -> List[Dict[str, any]]:
        """Query processes using GPU"""
        try:
            cmd = [
                "nvidia-smi",
                "--query-compute-apps=pid,used_memory,process_name",
                "--format=csv,noheader,nounits",
                f"--id={gpu_id}"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            processes = []
            for line in result.stdout.strip().split("\n"):
                if line:
                    parts = [p.strip() for p in line.split(",")]
                    if len(parts) == 3:
                        pid, mem, name = parts
                        processes.append({
                            "pid": int(pid),
                            "memory_mb": int(mem),
                            "name": name
                        })

            return processes

        except subprocess.CalledProcessError:
            return []
        except Exception:
            return []


class VRAMBudgetCalculator:
    """Calculate VRAM requirements for models"""

    @staticmethod
    def estimate_vram(model_metadata: Dict[str, any], layers: Optional[int] = None) -> float:
        """
        Estimate VRAM usage in GB for a model

        Args:
            model_metadata: Model metadata from registry
            layers: Number of GPU layers (for GGUF models)

        Returns:
            Estimated VRAM usage in GB
        """
        # Base estimate from registry
        base_estimate = model_metadata.get("vram_estimate_gb", 0.0)

        # Adjust for layers (GGUF models)
        if model_metadata.get("format") == "GGUF" and layers is not None:
            # Rough estimate: each layer uses size_gb / 32 (assuming ~32 layers typical)
            size_gb = model_metadata.get("size_gb", 0.0)
            per_layer = size_gb / 32.0
            layer_estimate = (per_layer * layers) + 0.5  # +500MB overhead
            return round(layer_estimate, 2)

        return base_estimate

    @staticmethod
    def can_fit(required_gb: float, available_gb: float, safety_margin: float = 0.1) -> bool:
        """
        Check if model can fit in available VRAM with safety margin

        Args:
            required_gb: Required VRAM in GB
            available_gb: Available VRAM in GB
            safety_margin: Safety margin (0.1 = 10%)

        Returns:
            True if model can safely fit
        """
        margin_gb = required_gb * safety_margin
        return (required_gb + margin_gb) <= available_gb

    @staticmethod
    def recommend_layers(model_size_gb: float, available_gb: float) -> int:
        """
        Recommend optimal number of GPU layers for GGUF model

        Args:
            model_size_gb: Model file size in GB
            available_gb: Available VRAM in GB

        Returns:
            Recommended number of GPU layers
        """
        # Assume 32 layers typical, each using model_size / 32
        per_layer = model_size_gb / 32.0
        overhead = 0.5  # 500MB overhead

        # Calculate max layers that fit
        max_layers = int((available_gb - overhead) / per_layer)
        return max(0, min(max_layers, 32))  # Clamp to 0-32


class VRAMScheduler:
    """Intelligent scheduling queue for model loading"""

    def __init__(self, max_queue_size: int = 10, timeout_seconds: int = 300):
        self.max_queue_size = max_queue_size
        self.timeout_seconds = timeout_seconds
        self.queue: List[Dict[str, any]] = []

    def add_request(self, model_id: int, backend: str, priority: str = "medium") -> bool:
        """Add model load request to queue"""
        if len(self.queue) >= self.max_queue_size:
            return False

        request = {
            "model_id": model_id,
            "backend": backend,
            "priority": priority,
            "timestamp": datetime.now().isoformat(),
            "status": "pending"
        }
        self.queue.append(request)

        # Sort by priority (high > medium > low) and timestamp
        priority_order = {"high": 3, "medium": 2, "low": 1}
        self.queue.sort(
            key=lambda r: (priority_order.get(r["priority"], 0), r["timestamp"]),
            reverse=True
        )

        return True

    def get_next(self) -> Optional[Dict[str, any]]:
        """Get next request from queue"""
        # Remove expired requests
        now = datetime.now()
        self.queue = [
            r for r in self.queue
            if (now - datetime.fromisoformat(r["timestamp"])).total_seconds() < self.timeout_seconds
        ]

        if self.queue:
            return self.queue.pop(0)
        return None

    def clear(self):
        """Clear all pending requests"""
        self.queue.clear()


class VRAMMonitor:
    """Main VRAM monitoring and management system"""

    def __init__(self, db_path: str, state_file: str, log_file: str):
        self.db_path = db_path
        self.state_file = state_file
        self.log_file = log_file
        self.scheduler = VRAMScheduler()
        self.alerts = []

    def log(self, message: str):
        """Log message to file"""
        timestamp = datetime.now().isoformat()
        log_line = f"[{timestamp}] {message}\n"
        with open(self.log_file, "a") as f:
            f.write(log_line)
        print(log_line.strip())

    def monitor_loop(self, interval: int, auto_scale: bool, threshold: int):
        """Main monitoring loop"""
        self.log(f"Starting VRAM monitor (interval={interval}s, auto_scale={auto_scale}, threshold={threshold}%)")

        while True:
            try:
                # Query GPU state
                gpus = NvidiaSMIMonitor.query_gpu()
                if not gpus:
                    self.log("Warning: No GPU data available")
                    time.sleep(interval)
                    continue

                # Calculate aggregated stats
                total_vram_gb = sum(gpu.total_mb for gpu in gpus) / 1024.0
                used_vram_gb = sum(gpu.used_mb for gpu in gpus) / 1024.0
                free_vram_gb = total_vram_gb - used_vram_gb
                util_percent = (used_vram_gb / total_vram_gb * 100) if total_vram_gb > 0 else 0.0

                # Create state snapshot
                state = VRAMState(
                    last_update=datetime.now().isoformat(),
                    gpus=[asdict(gpu) for gpu in gpus],
                    total_vram_gb=round(total_vram_gb, 2),
                    used_vram_gb=round(used_vram_gb, 2),
                    free_vram_gb=round(free_vram_gb, 2),
                    utilization_percent=round(util_percent, 1),
                    loaded_models=[],  # TODO: Query from backends
                    pending_queue=[],  # TODO: Get from scheduler
                    alerts=self.alerts.copy()
                )

                # Save state to file
                with open(self.state_file, "w") as f:
                    json.dump(asdict(state), f, indent=2)

                # Check thresholds and trigger alerts
                if util_percent >= threshold and auto_scale:
                    self.log(f"ALERT: VRAM usage {util_percent:.1f}% exceeds threshold {threshold}%")
                    self.alerts.append(f"High VRAM usage: {util_percent:.1f}%")
                    # TODO: Trigger auto-scaling (evict low-priority models)

                # Log current state
                if int(time.time()) % 60 == 0:  # Log every minute
                    self.log(f"VRAM: {used_vram_gb:.2f}GB / {total_vram_gb:.2f}GB ({util_percent:.1f}%)")

                time.sleep(interval)

            except KeyboardInterrupt:
                self.log("Monitor stopped by user")
                break
            except Exception as e:
                self.log(f"ERROR: {e}")
                time.sleep(interval)


def cmd_monitor(args):
    """Run continuous VRAM monitoring"""
    monitor = VRAMMonitor(args.db_path, args.state_file, args.log_file)
    monitor.monitor_loop(
        interval=args.interval,
        auto_scale=args.auto_scale == "true",
        threshold=args.threshold
    )
    return 0


def cmd_status(args):
    """Display current VRAM status"""
    if not os.path.exists(args.state_file):
        print("No state file found (monitor not running?)", file=sys.stderr)
        return 1

    with open(args.state_file, "r") as f:
        state = json.load(f)

    print("=== VRAM Status ===")
    print(f"Last Update: {state['last_update']}")
    print(f"Total VRAM: {state['total_vram_gb']:.2f} GB")
    print(f"Used VRAM: {state['used_vram_gb']:.2f} GB")
    print(f"Free VRAM: {state['free_vram_gb']:.2f} GB")
    print(f"Utilization: {state['utilization_percent']:.1f}%")
    print()

    print("=== GPU Details ===")
    for gpu in state['gpus']:
        print(f"GPU {gpu['gpu_id']}:")
        print(f"  Memory: {gpu['used_mb']}MB / {gpu['total_mb']}MB ({gpu['utilization_percent']:.1f}%)")
        print(f"  Temperature: {gpu['temperature_c']}°C")
        if gpu['processes']:
            print(f"  Processes:")
            for proc in gpu['processes']:
                print(f"    - PID {proc['pid']}: {proc['name']} ({proc['memory_mb']}MB)")
        print()

    if state['alerts']:
        print("=== Alerts ===")
        for alert in state['alerts']:
            print(f"  ⚠️  {alert}")

    return 0


def cmd_budget(args):
    """Calculate VRAM budget for model"""
    # This would integrate with registry.py to get model metadata
    print("Budget calculation not yet implemented")
    return 1


def main():
    parser = argparse.ArgumentParser(description="VRAM Intelligence Monitor")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Monitor command
    monitor_parser = subparsers.add_parser("monitor", help="Run continuous VRAM monitoring")
    monitor_parser.add_argument("--interval", type=int, default=5, help="Monitoring interval (seconds)")
    monitor_parser.add_argument("--db-path", required=True, help="Path to registry database")
    monitor_parser.add_argument("--state-file", required=True, help="Path to VRAM state file")
    monitor_parser.add_argument("--auto-scale", choices=["true", "false"], default="false")
    monitor_parser.add_argument("--threshold", type=int, default=85, help="Auto-scale threshold (%)")
    monitor_parser.add_argument("--log-file", required=True, help="Path to log file")

    # Status command
    status_parser = subparsers.add_parser("status", help="Display current VRAM status")
    status_parser.add_argument("--state-file", required=True, help="Path to VRAM state file")

    # Budget command
    budget_parser = subparsers.add_parser("budget", help="Calculate VRAM budget for model")
    budget_parser.add_argument("--model-id", type=int, required=True, help="Model ID from registry")
    budget_parser.add_argument("--db-path", required=True, help="Path to registry database")
    budget_parser.add_argument("--layers", type=int, help="Number of GPU layers (for GGUF)")

    args = parser.parse_args()

    if args.command == "monitor":
        return cmd_monitor(args)
    elif args.command == "status":
        return cmd_status(args)
    elif args.command == "budget":
        return cmd_budget(args)


if __name__ == "__main__":
    sys.exit(main())
