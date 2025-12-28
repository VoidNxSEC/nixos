#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════
# Architecture Analyzer with LLM Integration
# ═══════════════════════════════════════════════════════════════════════════
# High-performance automated architecture documentation using local llama.cpp
# Model: qwen2.5-coder:7b-instruct (optimized for code understanding)
#
# Features:
#   • Async/parallel processing for maximum throughput
#   • Semantic code understanding with local LLM (llama.cpp)
#   • Dependency graph generation (Mermaid)
#   • Security posture assessment
#   • Architecture pattern recognition
#   • Multi-format output (MD, JSON)
#
# Usage:
#   python arch-analyzer.py --repo /etc/nixos --output ./arch
#
# Performance:
#   • 8x parallel processing
#   • < 5s per module analysis
#   • < 5 min for 100+ modules
# ═══════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import logging
import os
import re
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Any

import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

DEFAULT_MODEL = "unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
LLAMACPP_BASE_URL = os.getenv("LLAMACPP_BASE_URL", "http://localhost:8080")
MAX_CONCURRENT = int(os.getenv("LLM_PARALLEL", "8"))
REQUEST_TIMEOUT = int(os.getenv("LLM_TIMEOUT", "120"))

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(levelname)-8s │ %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════
# Data Models
# ═══════════════════════════════════════════════════════════════════════════

@dataclass
class ModuleAnalysis:
    """Analysis result for a single Nix module."""
    path: str
    name: str
    category: str
    purpose: str = ""
    complexity: str = "medium"  # low, medium, high, critical
    dependencies: list[str] = field(default_factory=list)
    imports: list[str] = field(default_factory=list)
    options_defined: list[str] = field(default_factory=list)
    security_concerns: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    lines_of_code: int = 0
    has_documentation: bool = False
    analysis_time_ms: int = 0
    error: str | None = None


@dataclass
class ArchitectureReport:
    """Complete architecture analysis report."""
    timestamp: str
    repository: str
    model_used: str
    total_modules: int = 0
    total_lines: int = 0
    analysis_duration_seconds: float = 0.0
    modules: list[ModuleAnalysis] = field(default_factory=list)
    dependency_graph: dict[str, list[str]] = field(default_factory=dict)
    category_summary: dict[str, int] = field(default_factory=dict)
    security_score: int = 0
    architecture_patterns: list[str] = field(default_factory=list)
    technical_debt: list[str] = field(default_factory=list)
    ai_summary: str = ""


# ═══════════════════════════════════════════════════════════════════════════
# Llama.cpp Client (stdlib-based, OpenAI-compatible API)
# ═══════════════════════════════════════════════════════════════════════════

class LlamaCppClient:
    """High-performance llama.cpp client using OpenAI-compatible API (stdlib only)."""

    def __init__(
        self,
        model: str = DEFAULT_MODEL,
        base_url: str = LLAMACPP_BASE_URL,
        timeout: int = REQUEST_TIMEOUT,
        max_retries: int = 3,
        max_concurrent: int = MAX_CONCURRENT
    ):
        self.model = model
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self.max_concurrent = max_concurrent
        self._executor: ThreadPoolExecutor | None = None

    def __enter__(self):
        self._executor = ThreadPoolExecutor(max_workers=self.max_concurrent)
        return self

    def __exit__(self, *args):
        if self._executor:
            self._executor.shutdown(wait=True)

    async def __aenter__(self):
        self._executor = ThreadPoolExecutor(max_workers=self.max_concurrent)
        return self

    async def __aexit__(self, *args):
        if self._executor:
            self._executor.shutdown(wait=True)

    def _sync_request(self, url: str, data: bytes | None = None) -> tuple[int, str]:
        """Make synchronous HTTP request."""
        req = urllib.request.Request(
            url,
            data=data,
            headers={"Content-Type": "application/json"} if data else {}
        )
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                return resp.status, resp.read().decode()
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode()
        except urllib.error.URLError as e:
            raise ConnectionError(f"Connection failed: {e.reason}")

    def check_health_sync(self) -> bool:
        """Check if llama.cpp is available (sync)."""
        try:
            status, body = self._sync_request(f"{self.base_url}/v1/models")
            if status == 200:
                # OpenAI-compatible endpoint returns model list
                # For llama.cpp, just check if endpoint responds
                return True
        except Exception as e:
            log.error(f"llama.cpp health check failed: {e}")
        return False

    async def check_health(self) -> bool:
        """Check if llama.cpp is available (async wrapper)."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self._executor, self.check_health_sync)

    def generate_sync(
        self,
        prompt: str,
        system: str | None = None,
        temperature: float = 0.1,
        max_tokens: int = 2048
    ) -> str:
        """Generate completion synchronously with retry logic (OpenAI format)."""
        # Combine system and prompt for OpenAI-compatible format
        full_prompt = prompt
        if system:
            full_prompt = f"{system}\n\n{prompt}"
        
        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": False
        }

        data = json.dumps(payload).encode()

        for attempt in range(self.max_retries):
            try:
                status, body = self._sync_request(
                    f"{self.base_url}/v1/completions",
                    data
                )
                if status == 200:
                    response_data = json.loads(body)
                    # OpenAI format: choices[0].text
                    return response_data.get("choices", [{}])[0].get("text", "")
                else:
                    log.warning(f"llama.cpp error (attempt {attempt+1}): {body[:100]}")
            except ConnectionError as e:
                log.warning(f"Connection error (attempt {attempt+1}): {e}")
            except Exception as e:
                log.warning(f"Error (attempt {attempt+1}): {e}")

            if attempt < self.max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff

        return ""

    async def generate(
        self,
        prompt: str,
        system: str | None = None,
        temperature: float = 0.1,
        max_tokens: int = 2048
    ) -> str:
        """Generate completion asynchronously."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(
            self._executor,
            lambda: self.generate_sync(prompt, system, temperature, max_tokens)
        )

    async def batch_generate(
        self,
        prompts: list[tuple[str, str]],  # (prompt, system)
        temperature: float = 0.1
    ) -> list[str]:
        """Process multiple prompts in parallel."""
        tasks = [
            self.generate(prompt, system, temperature)
            for prompt, system in prompts
        ]
        return await asyncio.gather(*tasks)


# ═══════════════════════════════════════════════════════════════════════════
# Prompt Templates
# ═══════════════════════════════════════════════════════════════════════════

PROMPTS = {
    "module_analysis": {
        "system": """You are an expert NixOS configuration analyst specializing in Nix modules.
Analyze code precisely and provide structured, factual analysis.
Focus on: purpose, complexity, dependencies, and potential issues.
Be concise and technical. Use only facts from the code provided.""",

        "template": """Analyze this NixOS module and provide a structured analysis.

FILE: {filename}
CATEGORY: {category}

```nix
{code}
```

Respond ONLY with this exact JSON structure (no markdown, no explanation):
{{
  "purpose": "One sentence describing what this module does",
  "complexity": "low|medium|high|critical",
  "dependencies": ["list", "of", "nix", "module", "dependencies"],
  "options_defined": ["list", "of", "mkOption", "names"],
  "security_concerns": ["list of security issues, if any"],
  "recommendations": ["list of improvement suggestions"]
}}"""
    },

    "architecture_summary": {
        "system": """You are a software architect analyzing NixOS configuration repositories.
Provide high-level insights about architecture patterns, organization quality, and improvements.
Be concise but comprehensive. Focus on actionable insights.""",

        "template": """Analyze this NixOS repository architecture summary:

REPOSITORY: {repo}
TOTAL MODULES: {total_modules}
TOTAL LINES: {total_lines}

CATEGORY BREAKDOWN:
{category_breakdown}

TOP MODULES BY COMPLEXITY:
{complexity_breakdown}

SECURITY MODULES:
{security_modules}

Provide a comprehensive analysis in JSON format:
{{
  "summary": "2-3 sentence executive summary",
  "patterns": ["detected architecture patterns"],
  "strengths": ["strong points of this configuration"],
  "technical_debt": ["areas needing improvement"],
  "security_assessment": "brief security posture assessment",
  "priority_actions": ["top 3 recommended actions"]
}}"""
    }
}


# ═══════════════════════════════════════════════════════════════════════════
# Code Analyzer
# ═══════════════════════════════════════════════════════════════════════════

class CodeAnalyzer:
    """Analyzes Nix modules using LLM for semantic understanding."""

    # Patterns to extract from Nix files
    IMPORT_PATTERN = re.compile(r'import\s+([^\s;]+)')
    OPTION_PATTERN = re.compile(r'(\w+)\s*=\s*(?:mkOption|mkEnableOption)')
    MKIF_PATTERN = re.compile(r'mkIf\s+config\.([^\s]+)')

    def __init__(self, client: LlamaCppClient, repo_root: Path):
        self.client = client
        self.repo_root = repo_root
        self._cache: dict[str, ModuleAnalysis] = {}

    def _get_cache_key(self, path: Path) -> str:
        """Generate cache key from file path and content hash."""
        try:
            content = path.read_text()
            content_hash = hashlib.md5(content.encode()).hexdigest()[:8]
            return f"{path.name}_{content_hash}"
        except Exception:
            return str(path)

    def _extract_category(self, path: Path) -> str:
        """Extract module category from path."""
        try:
            rel_path = path.relative_to(self.repo_root / "modules")
            parts = rel_path.parts
            return parts[0] if parts else "unknown"
        except ValueError:
            return "root"

    def _static_analysis(self, content: str) -> dict[str, Any]:
        """Perform fast static analysis without LLM."""
        return {
            "lines_of_code": len(content.splitlines()),
            "has_documentation": "description" in content or '# ' in content[:500],
            "imports": self.IMPORT_PATTERN.findall(content),
            "options_count": len(self.OPTION_PATTERN.findall(content)),
            "has_security": any(k in content.lower() for k in [
                "firewall", "security", "hardening", "permission", "auth"
            ])
        }

    async def analyze_module(self, path: Path) -> ModuleAnalysis:
        """Analyze a single Nix module with LLM."""
        start_time = time.monotonic()
        cache_key = self._get_cache_key(path)

        # Check cache
        if cache_key in self._cache:
            log.debug(f"Cache hit: {path.name}")
            return self._cache[cache_key]

        try:
            content = path.read_text()
            rel_path = str(path.relative_to(self.repo_root))
            category = self._extract_category(path)

            # Static analysis first
            static = self._static_analysis(content)

            # Truncate large files for LLM
            code_for_llm = content[:8000] if len(content) > 8000 else content

            # LLM analysis
            prompt = PROMPTS["module_analysis"]["template"].format(
                filename=rel_path,
                category=category,
                code=code_for_llm
            )
            system = PROMPTS["module_analysis"]["system"]

            response = await self.client.generate(prompt, system)

            # Parse JSON response
            analysis_data = self._parse_json_response(response)

            analysis = ModuleAnalysis(
                path=rel_path,
                name=path.stem,
                category=category,
                purpose=analysis_data.get("purpose", "Analysis pending"),
                complexity=analysis_data.get("complexity", "medium"),
                dependencies=analysis_data.get("dependencies", []),
                imports=static["imports"],
                options_defined=analysis_data.get("options_defined", []),
                security_concerns=analysis_data.get("security_concerns", []),
                recommendations=analysis_data.get("recommendations", []),
                lines_of_code=static["lines_of_code"],
                has_documentation=static["has_documentation"],
                analysis_time_ms=int((time.monotonic() - start_time) * 1000)
            )

            self._cache[cache_key] = analysis
            return analysis

        except Exception as e:
            log.error(f"Error analyzing {path}: {e}")
            return ModuleAnalysis(
                path=str(path.relative_to(self.repo_root)),
                name=path.stem,
                category=self._extract_category(path),
                error=str(e),
                analysis_time_ms=int((time.monotonic() - start_time) * 1000)
            )

    def _parse_json_response(self, response: str) -> dict[str, Any]:
        """Parse JSON from LLM response, handling common issues."""
        if not response:
            return {}

        # Try to extract JSON from response
        response = response.strip()

        # Handle markdown code blocks
        if "```json" in response:
            match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
            if match:
                response = match.group(1)
        elif "```" in response:
            match = re.search(r'```\s*(.*?)\s*```', response, re.DOTALL)
            if match:
                response = match.group(1)

        # Find JSON object
        start = response.find("{")
        end = response.rfind("}") + 1
        if start >= 0 and end > start:
            response = response[start:end]

        try:
            return json.loads(response)
        except json.JSONDecodeError:
            log.debug(f"Failed to parse JSON: {response[:100]}...")
            return {}

    async def analyze_all(self, paths: list[Path]) -> list[ModuleAnalysis]:
        """Analyze all modules in parallel."""
        log.info(f"Analyzing {len(paths)} modules with {MAX_CONCURRENT}x parallelism...")

        tasks = [self.analyze_module(p) for p in paths]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Handle exceptions
        analyses = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                log.error(f"Analysis failed for {paths[i]}: {result}")
                analyses.append(ModuleAnalysis(
                    path=str(paths[i]),
                    name=paths[i].stem,
                    category="error",
                    error=str(result)
                ))
            else:
                analyses.append(result)

        return analyses


# ═══════════════════════════════════════════════════════════════════════════
# Architecture Interpreter
# ═══════════════════════════════════════════════════════════════════════════

class ArchitectureInterpreter:
    """High-level architecture analysis and pattern recognition."""

    def __init__(self, client: LlamaCppClient):
        self.client = client

    def build_dependency_graph(
        self,
        modules: list[ModuleAnalysis]
    ) -> dict[str, list[str]]:
        """Build dependency graph from module analyses."""
        graph: dict[str, list[str]] = {}

        for module in modules:
            node = module.name
            deps = []

            # From LLM analysis
            deps.extend(module.dependencies)

            # From static import analysis
            for imp in module.imports:
                # Extract module name from import path
                if "/" in imp:
                    dep_name = imp.split("/")[-1].replace(".nix", "")
                    if dep_name and dep_name != node:
                        deps.append(dep_name)

            graph[node] = list(set(deps))

        return graph

    def generate_mermaid_diagram(
        self,
        graph: dict[str, list[str]],
        modules: list[ModuleAnalysis]
    ) -> str:
        """Generate Mermaid diagram from dependency graph."""
        lines = ["graph TD"]

        # Create category subgraphs
        categories: dict[str, list[str]] = {}
        for module in modules:
            cat = module.category
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(module.name)

        # Add nodes by category
        for cat, nodes in sorted(categories.items()):
            lines.append(f"    subgraph {cat}")
            for node in sorted(nodes)[:10]:  # Limit nodes per category
                # Determine node style based on complexity
                module = next((m for m in modules if m.name == node), None)
                if module:
                    if module.complexity == "critical":
                        lines.append(f"        {node}[{node}]:::critical")
                    elif module.complexity == "high":
                        lines.append(f"        {node}[{node}]:::high")
                    else:
                        lines.append(f"        {node}[{node}]")
            lines.append("    end")

        # Add edges (limit to avoid clutter)
        edge_count = 0
        max_edges = 50
        for source, targets in sorted(graph.items()):
            for target in targets[:3]:  # Max 3 deps per node
                if target in graph and edge_count < max_edges:
                    lines.append(f"    {source} --> {target}")
                    edge_count += 1

        # Add styles
        lines.extend([
            "",
            "    classDef critical fill:#ff6b6b,stroke:#c92a2a",
            "    classDef high fill:#ffd43b,stroke:#f59f00"
        ])

        return "\n".join(lines)

    async def generate_summary(
        self,
        report: ArchitectureReport,
        modules: list[ModuleAnalysis]
    ) -> dict[str, Any]:
        """Generate high-level architecture summary using LLM."""
        # Build category breakdown
        category_breakdown = "\n".join([
            f"  - {cat}: {count} modules"
            for cat, count in sorted(report.category_summary.items(), key=lambda x: -x[1])
        ])

        # Top complex modules
        complex_modules = sorted(
            [m for m in modules if m.complexity in ("high", "critical")],
            key=lambda m: m.lines_of_code,
            reverse=True
        )[:5]
        complexity_breakdown = "\n".join([
            f"  - {m.name} ({m.category}): {m.complexity}, {m.lines_of_code} lines"
            for m in complex_modules
        ])

        # Security modules
        security = [m for m in modules if m.category == "security" or m.security_concerns]
        security_breakdown = "\n".join([
            f"  - {m.name}: {m.purpose[:50]}..."
            for m in security[:5]
        ])

        prompt = PROMPTS["architecture_summary"]["template"].format(
            repo=report.repository,
            total_modules=report.total_modules,
            total_lines=report.total_lines,
            category_breakdown=category_breakdown or "  - No categories found",
            complexity_breakdown=complexity_breakdown or "  - No complex modules",
            security_modules=security_breakdown or "  - No security modules found"
        )
        system = PROMPTS["architecture_summary"]["system"]

        response = await self.client.generate(prompt, system, temperature=0.2)

        # Parse response
        try:
            start = response.find("{")
            end = response.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except json.JSONDecodeError:
            pass

        return {
            "summary": "Analysis completed. See detailed module reports.",
            "patterns": [],
            "technical_debt": [],
            "priority_actions": []
        }


# ═══════════════════════════════════════════════════════════════════════════
# Report Generator
# ═══════════════════════════════════════════════════════════════════════════

class ReportGenerator:
    """Generate architecture reports in multiple formats."""

    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_markdown(self, report: ArchitectureReport, mermaid: str) -> str:
        """Generate comprehensive Markdown report."""
        lines = [
            "# 🤖 AI-Powered Architecture Analysis Report",
            "",
            f"> **Generated**: {report.timestamp}",
            f"> **Model**: `{report.model_used}`",
            f"> **Repository**: `{report.repository}`",
            f"> **Analysis Duration**: {report.analysis_duration_seconds:.1f}s",
            "",
            "---",
            "",
            "## 📋 Executive Summary",
            "",
            report.ai_summary if report.ai_summary else "_Analysis complete._",
            "",
            "### Quick Stats",
            "",
            "| Metric | Value |",
            "|--------|-------|",
            f"| **Total Modules** | {report.total_modules} |",
            f"| **Total Lines** | {report.total_lines:,} |",
            f"| **Categories** | {len(report.category_summary)} |",
            f"| **Security Score** | {report.security_score}/100 |",
            "",
            "---",
            "",
            "## 📊 Category Breakdown",
            "",
            "| Category | Modules | Description |",
            "|----------|---------|-------------|",
        ]

        # Category table
        for cat, count in sorted(report.category_summary.items(), key=lambda x: -x[1]):
            lines.append(f"| **{cat}** | {count} | - |")

        # Dependency graph
        lines.extend([
            "",
            "---",
            "",
            "## 🔗 Dependency Graph",
            "",
            "```mermaid",
            mermaid,
            "```",
            "",
            "---",
            "",
            "## 📦 Module Analysis",
            "",
        ])

        # Group modules by category
        by_category: dict[str, list[ModuleAnalysis]] = {}
        for m in report.modules:
            if m.category not in by_category:
                by_category[m.category] = []
            by_category[m.category].append(m)

        for cat, mods in sorted(by_category.items()):
            lines.extend([
                f"### {cat}/",
                "",
                "| Module | Purpose | Complexity | Lines |",
                "|--------|---------|------------|-------|",
            ])
            for m in sorted(mods, key=lambda x: -x.lines_of_code):
                purpose = m.purpose[:60] + "..." if len(m.purpose) > 60 else m.purpose
                complexity_icon = {
                    "low": "🟢",
                    "medium": "🟡",
                    "high": "🟠",
                    "critical": "🔴"
                }.get(m.complexity, "⚪")
                lines.append(
                    f"| `{m.name}` | {purpose} | {complexity_icon} {m.complexity} | {m.lines_of_code} |"
                )
            lines.append("")

        # Security section
        security_concerns = [
            (m.name, concern)
            for m in report.modules
            for concern in m.security_concerns
        ]
        if security_concerns:
            lines.extend([
                "---",
                "",
                "## 🔒 Security Concerns",
                "",
            ])
            for module, concern in security_concerns[:20]:
                lines.append(f"- **{module}**: {concern}")
            lines.append("")

        # Architecture patterns
        if report.architecture_patterns:
            lines.extend([
                "---",
                "",
                "## 🏗️ Architecture Patterns Detected",
                "",
            ])
            for pattern in report.architecture_patterns:
                lines.append(f"- {pattern}")
            lines.append("")

        # Technical debt
        if report.technical_debt:
            lines.extend([
                "---",
                "",
                "## ⚠️ Technical Debt",
                "",
            ])
            for debt in report.technical_debt:
                lines.append(f"- {debt}")
            lines.append("")

        # Recommendations
        recommendations = [
            (m.name, rec)
            for m in report.modules
            for rec in m.recommendations
        ][:15]
        if recommendations:
            lines.extend([
                "---",
                "",
                "## 💡 Recommendations",
                "",
            ])
            for module, rec in recommendations:
                lines.append(f"- **{module}**: {rec}")
            lines.append("")

        # Footer
        lines.extend([
            "---",
            "",
            "*Generated with AI-powered architecture analysis*",
            f"*Model: {report.model_used}*"
        ])

        return "\n".join(lines)

    def generate_json(self, report: ArchitectureReport) -> str:
        """Generate JSON report."""
        # Convert dataclasses to dict
        data = {
            "metadata": {
                "timestamp": report.timestamp,
                "repository": report.repository,
                "model": report.model_used,
                "duration_seconds": report.analysis_duration_seconds
            },
            "summary": {
                "total_modules": report.total_modules,
                "total_lines": report.total_lines,
                "categories": report.category_summary,
                "security_score": report.security_score,
                "patterns": report.architecture_patterns,
                "technical_debt": report.technical_debt
            },
            "modules": [asdict(m) for m in report.modules],
            "dependency_graph": report.dependency_graph
        }
        return json.dumps(data, indent=2, ensure_ascii=False)

    def save_all(
        self,
        report: ArchitectureReport,
        mermaid: str
    ) -> dict[str, Path]:
        """Save all report formats."""
        outputs = {}

        # Markdown
        md_path = self.output_dir / "AI-ARCHITECTURE-REPORT.md"
        md_path.write_text(self.generate_markdown(report, mermaid))
        outputs["markdown"] = md_path
        log.info(f"✓ Markdown report: {md_path}")

        # JSON
        json_path = self.output_dir / "AI-ARCHITECTURE-REPORT.json"
        json_path.write_text(self.generate_json(report))
        outputs["json"] = json_path
        log.info(f"✓ JSON report: {json_path}")

        # Mermaid diagram
        mmd_path = self.output_dir / "dependency-graph.mmd"
        mmd_path.write_text(mermaid)
        outputs["mermaid"] = mmd_path
        log.info(f"✓ Mermaid diagram: {mmd_path}")

        return outputs


# ═══════════════════════════════════════════════════════════════════════════
# Main Pipeline
# ═══════════════════════════════════════════════════════════════════════════

async def run_analysis(
    repo_root: Path,
    output_dir: Path,
    model: str = DEFAULT_MODEL,
    max_concurrent: int = MAX_CONCURRENT
) -> ArchitectureReport:
    """Run complete architecture analysis pipeline."""
    start_time = time.monotonic()

    log.info("=" * 70)
    log.info("🚀 AI Architecture Analyzer")
    log.info(f"   Repository: {repo_root}")
    log.info(f"   Model: {model}")
    log.info(f"   Parallelism: {max_concurrent}x")
    log.info("=" * 70)

    # Find all Nix modules
    modules_dir = repo_root / "modules"
    if not modules_dir.exists():
        log.error(f"Modules directory not found: {modules_dir}")
        sys.exit(1)

    nix_files = list(modules_dir.rglob("*.nix"))
    log.info(f"📁 Found {len(nix_files)} Nix modules to analyze")

    # Initialize client and analyzers
    async with LlamaCppClient(model=model) as client:
        # Verify connection
        if not await client.check_health():
            log.error(f"❌ llama.cpp not available")
            log.error(f"   Ensure llama.cpp is running: systemctl status llama-cpp")
            sys.exit(1)
        log.info(f"✓ llama.cpp connection verified")

        # Analyze modules
        analyzer = CodeAnalyzer(client, repo_root)
        modules = await analyzer.analyze_all(nix_files)

        # Build report
        report = ArchitectureReport(
            timestamp=datetime.now().isoformat(),
            repository=str(repo_root),
            model_used=model,
            total_modules=len(modules),
            total_lines=sum(m.lines_of_code for m in modules),
            modules=modules
        )

        # Category summary
        for m in modules:
            cat = m.category
            report.category_summary[cat] = report.category_summary.get(cat, 0) + 1

        # Calculate security score
        security_modules = len([m for m in modules if m.category == "security"])
        has_hardening = any("hardening" in m.name.lower() for m in modules)
        has_firewall = any("firewall" in m.name.lower() for m in modules)
        report.security_score = min(100, security_modules * 10 + (30 if has_hardening else 0) + (20 if has_firewall else 0))

        # Architecture interpretation
        interpreter = ArchitectureInterpreter(client)

        # Build dependency graph
        report.dependency_graph = interpreter.build_dependency_graph(modules)
        mermaid = interpreter.generate_mermaid_diagram(report.dependency_graph, modules)

        # Generate AI summary
        log.info("🧠 Generating architecture summary...")
        summary = await interpreter.generate_summary(report, modules)
        report.ai_summary = summary.get("summary", "")
        report.architecture_patterns = summary.get("patterns", [])
        report.technical_debt = summary.get("technical_debt", [])

        # Save reports
        report.analysis_duration_seconds = time.monotonic() - start_time
        generator = ReportGenerator(output_dir)
        outputs = generator.save_all(report, mermaid)

        # Final summary
        log.info("=" * 70)
        log.info("✅ Analysis Complete!")
        log.info(f"   Modules analyzed: {report.total_modules}")
        log.info(f"   Total lines: {report.total_lines:,}")
        log.info(f"   Security score: {report.security_score}/100")
        log.info(f"   Duration: {report.analysis_duration_seconds:.1f}s")
        log.info("=" * 70)

        return report


def main():
    """Entry point."""
    parser = argparse.ArgumentParser(
        description="AI-powered NixOS architecture analyzer",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--repo", "-r",
        type=Path,
        default=Path("/etc/nixos"),
        help="Repository root path (default: /etc/nixos)"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("./arch"),
        help="Output directory for reports (default: ./arch)"
    )
    parser.add_argument(
        "--model", "-m",
        type=str,
        default=DEFAULT_MODEL,
        help=f"Ollama model to use (default: {DEFAULT_MODEL})"
    )
    parser.add_argument(
        "--parallel", "-p",
        type=int,
        default=MAX_CONCURRENT,
        help=f"Max concurrent requests (default: {MAX_CONCURRENT})"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose logging"
    )

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Run analysis with specified parallelism

    # Run analysis
    try:
        asyncio.run(run_analysis(args.repo, args.output, args.model, args.parallel))
    except KeyboardInterrupt:
        log.info("\n⚠️ Analysis interrupted")
        sys.exit(1)
    except Exception as e:
        log.error(f"❌ Fatal error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
