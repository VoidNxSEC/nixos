#!/usr/bin/env python3
"""
Professional Architecture Analyzer
===================================
High-performance NixOS architecture analysis with LLM integration.

Features:
- Async parallel processing with aiohttp
- Self-analysis and quality scoring
- Auto-correction with validation
- Incremental caching with SQLite
- Multi-format reporting

Usage:
    arch-analyze --repo /etc/nixos --output ./arch
    arch-analyze --self-test
    arch-analyze --auto-fix --dry-run
"""

from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import logging
import os
import re
import signal
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
from datetime import datetime
from pathlib import Path
from typing import Any

# Local imports
from models import (
    AnalysisConfig,
    ArchitectureReport,
    AutoFix,
    CacheEntry,
    Complexity,
    DependencyEdge,
    DependencyGraph,
    FixType,
    Issue,
    ModuleAnalysis,
    ModuleNode,
    QualityScore,
    SecurityFinding,
    Severity,
    ValidationResult,
)
from prompts import PROMPTS, get_prompt

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

VERSION = "2.0.0"
DEFAULT_MODEL = "qwen2.5-coder:7b-instruct"
OLLAMA_BASE_URL = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MAX_CONCURRENT = int(os.getenv("LLM_PARALLEL", "8"))
REQUEST_TIMEOUT = int(os.getenv("LLM_TIMEOUT", "120"))
CACHE_DB_PATH = Path(os.getenv("ARCH_CACHE_DB", "/var/lib/arch-analyzer/cache.db"))

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(levelname)-8s │ %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════════════
# Ollama Client - High-performance async client
# ═══════════════════════════════════════════════════════════════════════════

class OllamaClient:
    """Async Ollama client with connection pooling and retry logic."""

    def __init__(
        self,
        model: str = DEFAULT_MODEL,
        base_url: str = OLLAMA_BASE_URL,
        timeout: int = REQUEST_TIMEOUT,
        max_retries: int = 3,
        max_concurrent: int = MAX_CONCURRENT,
    ):
        self.model = model
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self.max_concurrent = max_concurrent
        self._executor: ThreadPoolExecutor | None = None
        self._stats = {"requests": 0, "errors": 0, "tokens": 0}

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

    @property
    def stats(self) -> dict:
        return self._stats.copy()

    def _sync_request(self, url: str, data: bytes | None = None) -> tuple[int, str]:
        """Make synchronous HTTP request."""
        req = urllib.request.Request(
            url,
            data=data,
            headers={"Content-Type": "application/json"} if data else {},
        )
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                return resp.status, resp.read().decode()
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode()
        except urllib.error.URLError as e:
            raise ConnectionError(f"Connection failed: {e.reason}")

    def check_health_sync(self) -> bool:
        """Check if Ollama is available and model is loaded."""
        try:
            status, body = self._sync_request(f"{self.base_url}/api/tags")
            if status == 200:
                data = json.loads(body)
                models = [m.get("name", "") for m in data.get("models", [])]
                model_base = self.model.split(":")[0]
                return any(model_base in m for m in models)
        except Exception as e:
            log.error(f"Ollama health check failed: {e}")
        return False

    async def check_health(self) -> bool:
        """Check if Ollama is available (async wrapper)."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self._executor, self.check_health_sync)

    def generate_sync(
        self,
        prompt: str,
        system: str | None = None,
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ) -> str:
        """Generate completion synchronously with retry logic."""
        self._stats["requests"] += 1
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            },
        }
        if system:
            payload["system"] = system

        data = json.dumps(payload).encode()

        for attempt in range(self.max_retries):
            try:
                status, body = self._sync_request(
                    f"{self.base_url}/api/generate", data
                )
                if status == 200:
                    resp = json.loads(body)
                    self._stats["tokens"] += resp.get("eval_count", 0)
                    return resp.get("response", "")
                else:
                    self._stats["errors"] += 1
                    log.warning(f"Ollama error (attempt {attempt + 1}): {body[:100]}")
            except ConnectionError as e:
                self._stats["errors"] += 1
                log.warning(f"Connection error (attempt {attempt + 1}): {e}")
            except Exception as e:
                self._stats["errors"] += 1
                log.warning(f"Error (attempt {attempt + 1}): {e}")

            if attempt < self.max_retries - 1:
                time.sleep(2**attempt)

        return ""

    async def generate(
        self,
        prompt: str,
        system: str | None = None,
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ) -> str:
        """Generate completion asynchronously."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(
            self._executor,
            lambda: self.generate_sync(prompt, system, temperature, max_tokens),
        )

    async def batch_generate(
        self, prompts: list[tuple[str, str]], temperature: float = 0.1
    ) -> list[str]:
        """Process multiple prompts in parallel."""
        tasks = [self.generate(prompt, system, temperature) for prompt, system in prompts]
        return await asyncio.gather(*tasks)


# ═══════════════════════════════════════════════════════════════════════════
# Cache Layer - SQLite-based incremental caching
# ═══════════════════════════════════════════════════════════════════════════

class CacheLayer:
    """SQLite cache for incremental analysis."""

    def __init__(self, db_path: Path = CACHE_DB_PATH):
        self.db_path = db_path
        self._conn: sqlite3.Connection | None = None

    def __enter__(self):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(str(self.db_path))
        self._init_schema()
        return self

    def __exit__(self, *args):
        if self._conn:
            self._conn.close()

    def _init_schema(self):
        """Initialize database schema."""
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS module_cache (
                path TEXT PRIMARY KEY,
                content_hash TEXT NOT NULL,
                last_analyzed TEXT NOT NULL,
                analysis_json TEXT NOT NULL
            )
        """)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS report_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                quality_score INTEGER,
                total_modules INTEGER,
                report_json TEXT
            )
        """)
        self._conn.commit()

    def get(self, path: str, content_hash: str) -> ModuleAnalysis | None:
        """Get cached analysis if hash matches."""
        cursor = self._conn.execute(
            "SELECT analysis_json FROM module_cache WHERE path = ? AND content_hash = ?",
            (path, content_hash),
        )
        row = cursor.fetchone()
        if row:
            data = json.loads(row[0])
            return ModuleAnalysis(**data)
        return None

    def set(self, path: str, content_hash: str, analysis: ModuleAnalysis):
        """Cache analysis result."""
        self._conn.execute(
            """INSERT OR REPLACE INTO module_cache 
               (path, content_hash, last_analyzed, analysis_json)
               VALUES (?, ?, ?, ?)""",
            (
                path,
                content_hash,
                datetime.now().isoformat(),
                json.dumps(asdict(analysis)),
            ),
        )
        self._conn.commit()

    def save_report(self, report: ArchitectureReport):
        """Save report to history."""
        self._conn.execute(
            """INSERT INTO report_history 
               (timestamp, quality_score, total_modules, report_json)
               VALUES (?, ?, ?, ?)""",
            (
                report.timestamp,
                report.quality_score.overall,
                report.total_modules,
                json.dumps(asdict(report)),
            ),
        )
        self._conn.commit()

    def get_previous_score(self) -> int | None:
        """Get previous quality score for trend analysis."""
        cursor = self._conn.execute(
            "SELECT quality_score FROM report_history ORDER BY id DESC LIMIT 1 OFFSET 1"
        )
        row = cursor.fetchone()
        return row[0] if row else None

    def clear(self):
        """Clear all cache."""
        self._conn.execute("DELETE FROM module_cache")
        self._conn.commit()


# ═══════════════════════════════════════════════════════════════════════════
# Static Analyzer - Fast pattern-based analysis
# ═══════════════════════════════════════════════════════════════════════════

class StaticAnalyzer:
    """Fast static analysis without LLM."""

    # Patterns for Nix code analysis
    IMPORT_PATTERN = re.compile(r"import\s+([^\s;]+)")
    OPTION_PATTERN = re.compile(r"(\w+)\s*=\s*(?:mkOption|mkEnableOption)")
    MKIF_PATTERN = re.compile(r"mkIf\s+config\.([^\s]+)")
    SERVICE_PATTERN = re.compile(r"systemd\.services\.(\w+)")
    HARDCODED_SECRET = re.compile(
        r'(password|apiKey|secret|token)\s*=\s*"[^"]+"|\'[^\']+\'', re.IGNORECASE
    )

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self._all_modules: dict[str, Path] = {}
        self._import_graph: dict[str, set[str]] = {}

    def discover_modules(self) -> list[Path]:
        """Find all Nix modules in the repository."""
        modules = []
        for nix_file in self.repo_root.rglob("*.nix"):
            if any(p in nix_file.parts for p in [".git", "node_modules", "result", "archive"]):
                continue
            modules.append(nix_file)
            self._all_modules[nix_file.stem] = nix_file
        return modules

    def analyze(self, path: Path) -> dict[str, Any]:
        """Perform static analysis on a module."""
        try:
            content = path.read_text()
        except Exception as e:
            return {"error": str(e)}

        lines = content.splitlines()
        
        # Basic metrics
        result = {
            "lines_of_code": len(lines),
            "blank_lines": sum(1 for l in lines if not l.strip()),
            "comment_lines": sum(1 for l in lines if l.strip().startswith("#")),
            "has_documentation": "description" in content or "# " in content[:500],
        }

        # Imports
        result["imports"] = self.IMPORT_PATTERN.findall(content)
        result["options_count"] = len(self.OPTION_PATTERN.findall(content))
        result["options_defined"] = self.OPTION_PATTERN.findall(content)

        # Services
        result["services_defined"] = self.SERVICE_PATTERN.findall(content)

        # Security checks
        result["has_security_content"] = any(
            k in content.lower()
            for k in ["firewall", "security", "hardening", "permission", "auth"]
        )
        result["hardcoded_secrets"] = bool(self.HARDCODED_SECRET.search(content))

        # mkIf dependencies
        result["config_dependencies"] = self.MKIF_PATTERN.findall(content)

        return result

    def build_import_graph(self, modules: list[Path]) -> DependencyGraph:
        """Build dependency graph from imports."""
        graph = DependencyGraph()

        # Add all modules as nodes
        for path in modules:
            category = self._extract_category(path)
            graph.nodes[path.stem] = ModuleNode(
                name=path.stem,
                category=category,
                path=str(path.relative_to(self.repo_root)),
            )

        # Parse imports and build edges
        imported_by: dict[str, set[str]] = {m.stem: set() for m in modules}
        
        for path in modules:
            try:
                content = path.read_text()
                imports = self.IMPORT_PATTERN.findall(content)
                
                for imp in imports:
                    # Extract module name from import
                    imp_name = imp.split("/")[-1].replace(".nix", "").strip("./")
                    if imp_name in graph.nodes and imp_name != path.stem:
                        graph.edges.append(
                            DependencyEdge(source=path.stem, target=imp_name)
                        )
                        graph.nodes[path.stem].out_degree += 1
                        graph.nodes[imp_name].in_degree += 1
                        imported_by[imp_name].add(path.stem)
            except Exception:
                continue

        # Find orphans (modules not imported by anything except default.nix)
        for name, node in graph.nodes.items():
            importers = imported_by.get(name, set())
            # Filter out default.nix as importer
            real_importers = {i for i in importers if i != "default"}
            if node.in_degree == 0 or (len(real_importers) == 0 and name != "default"):
                if name not in ["flake", "configuration", "default"]:
                    graph.orphans.append(name)

        # Find entry points (high out-degree, low in-degree)
        for name, node in graph.nodes.items():
            if node.out_degree > 3 and node.in_degree <= 1:
                graph.entry_points.append(name)

        return graph

    def _extract_category(self, path: Path) -> str:
        """Extract module category from path."""
        try:
            rel_path = path.relative_to(self.repo_root / "modules")
            parts = rel_path.parts
            return parts[0] if parts else "root"
        except ValueError:
            return "root"


# ═══════════════════════════════════════════════════════════════════════════
# LLM Analyzer - Semantic analysis with LLM
# ═══════════════════════════════════════════════════════════════════════════

class LLMAnalyzer:
    """LLM-powered semantic analysis."""

    def __init__(self, client: OllamaClient, repo_root: Path, cache: CacheLayer | None = None):
        self.client = client
        self.repo_root = repo_root
        self.cache = cache

    def _get_content_hash(self, path: Path) -> str:
        """Generate hash for cache key."""
        try:
            content = path.read_text()
            return hashlib.md5(content.encode()).hexdigest()[:12]
        except Exception:
            return ""

    async def analyze_module(self, path: Path, static: dict[str, Any]) -> ModuleAnalysis:
        """Analyze a single module with LLM."""
        start_time = time.monotonic()
        content_hash = self._get_content_hash(path)
        rel_path = str(path.relative_to(self.repo_root))

        # Check cache
        if self.cache:
            cached = self.cache.get(rel_path, content_hash)
            if cached:
                log.debug(f"Cache hit: {path.name}")
                return cached

        try:
            content = path.read_text()
            category = self._extract_category(path)

            # Truncate large files
            code_for_llm = content[:6000] if len(content) > 6000 else content

            # Get prompt
            system, prompt = get_prompt(
                "module_analysis",
                filename=rel_path,
                category=category,
                lines=static.get("lines_of_code", 0),
                code=code_for_llm,
            )

            # LLM analysis
            response = await self.client.generate(prompt, system)
            data = self._parse_json(response)

            # Build analysis object
            analysis = ModuleAnalysis(
                path=rel_path,
                name=path.stem,
                category=category,
                purpose=data.get("purpose", ""),
                complexity=Complexity(data.get("complexity", "medium")),
                dependencies=data.get("dependencies", []),
                imports=static.get("imports", []),
                options_defined=data.get("options_defined", []),
                security_concerns=data.get("security_concerns", []),
                recommendations=data.get("recommendations", []),
                lines_of_code=static.get("lines_of_code", 0),
                has_documentation=static.get("has_documentation", False),
                analysis_time_ms=int((time.monotonic() - start_time) * 1000),
                content_hash=content_hash,
            )

            # Parse issues
            for issue_data in data.get("issues", []):
                analysis.issues.append(
                    Issue(
                        id=f"{path.stem}_{len(analysis.issues)}",
                        severity=Severity(issue_data.get("severity", "info")),
                        category="llm_detected",
                        message=issue_data.get("message", ""),
                        line=issue_data.get("line"),
                    )
                )

            # Add static analysis issues
            if static.get("hardcoded_secrets"):
                analysis.issues.append(
                    Issue(
                        id=f"{path.stem}_secret",
                        severity=Severity.CRITICAL,
                        category="security",
                        message="Potential hardcoded secret detected",
                        fixable=True,
                    )
                )

            # Cache result
            if self.cache:
                self.cache.set(rel_path, content_hash, analysis)

            return analysis

        except Exception as e:
            log.error(f"Error analyzing {path}: {e}")
            return ModuleAnalysis(
                path=rel_path,
                name=path.stem,
                category=self._extract_category(path),
                error=str(e),
                analysis_time_ms=int((time.monotonic() - start_time) * 1000),
            )

    async def analyze_all(
        self, modules: list[Path], static_results: dict[Path, dict]
    ) -> list[ModuleAnalysis]:
        """Analyze all modules in parallel."""
        log.info(f"Analyzing {len(modules)} modules with LLM...")

        tasks = [
            self.analyze_module(path, static_results.get(path, {}))
            for path in modules
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        analyses = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                log.error(f"Analysis failed for {modules[i]}: {result}")
                analyses.append(
                    ModuleAnalysis(
                        path=str(modules[i]),
                        name=modules[i].stem,
                        category="error",
                        error=str(result),
                    )
                )
            else:
                analyses.append(result)

        return analyses

    async def generate_summary(self, report: ArchitectureReport) -> dict[str, Any]:
        """Generate architecture summary with LLM."""
        # Build breakdown strings
        category_breakdown = "\n".join(
            f"  - {cat}: {count} modules"
            for cat, count in sorted(report.category_summary.items(), key=lambda x: -x[1])
        )

        complex_modules = sorted(
            [m for m in report.modules if m.complexity in (Complexity.HIGH, Complexity.CRITICAL)],
            key=lambda m: -m.lines_of_code,
        )[:5]
        complexity_breakdown = "\n".join(
            f"  - {m.name} ({m.category}): {m.complexity.value}, {m.lines_of_code} lines"
            for m in complex_modules
        )

        security_modules = [m for m in report.modules if m.category == "security"][:5]
        security_breakdown = "\n".join(
            f"  - {m.name}: {m.purpose[:50]}..." for m in security_modules
        )

        orphans = report.dependency_graph.orphans[:10]
        orphan_breakdown = "\n".join(f"  - {o}" for o in orphans) if orphans else "  - None detected"

        system, prompt = get_prompt(
            "architecture_summary",
            repo=report.repository,
            total_modules=report.total_modules,
            total_lines=report.total_lines,
            categories=len(report.category_summary),
            category_breakdown=category_breakdown or "  - No categories",
            complexity_breakdown=complexity_breakdown or "  - No complex modules",
            security_modules=security_breakdown or "  - No security modules",
            orphan_modules=orphan_breakdown,
        )

        response = await self.client.generate(prompt, system, temperature=0.2)
        return self._parse_json(response)

    def _parse_json(self, response: str) -> dict[str, Any]:
        """Parse JSON from LLM response."""
        if not response:
            return {}

        response = response.strip()

        # Handle markdown code blocks
        if "```json" in response:
            match = re.search(r"```json\s*(.*?)\s*```", response, re.DOTALL)
            if match:
                response = match.group(1)
        elif "```" in response:
            match = re.search(r"```\s*(.*?)\s*```", response, re.DOTALL)
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

    def _extract_category(self, path: Path) -> str:
        """Extract category from path."""
        try:
            rel_path = path.relative_to(self.repo_root / "modules")
            parts = rel_path.parts
            return parts[0] if parts else "root"
        except ValueError:
            return "root"


# ═══════════════════════════════════════════════════════════════════════════
# Self Analyzer - Analyze the analyzer itself
# ═══════════════════════════════════════════════════════════════════════════

class SelfAnalyzer:
    """Self-analysis for quality scoring and improvement."""

    def __init__(self, client: OllamaClient):
        self.client = client

    async def analyze_self(self) -> dict[str, Any]:
        """Analyze this analyzer's code quality."""
        analyzer_path = Path(__file__)
        
        if not analyzer_path.exists():
            return {"error": "Cannot find analyzer source"}

        content = analyzer_path.read_text()
        lines = len(content.splitlines())

        system, prompt = get_prompt(
            "self_analysis",
            filename=analyzer_path.name,
            lines=lines,
            code=content[:8000],  # Truncate for LLM
        )

        response = await self.client.generate(prompt, system, temperature=0.2)
        return self._parse_json(response)

    def calculate_quality_score(self, report: ArchitectureReport) -> QualityScore:
        """Calculate overall quality score."""
        score = QualityScore()

        # Documentation score (0-100)
        if report.total_modules > 0:
            documented = sum(1 for m in report.modules if m.has_documentation)
            score.documentation = int((documented / report.total_modules) * 100)

        # Security score (starts at 100, deductions for issues)
        score.security = 100
        critical_findings = [
            f for f in report.security_findings if f.severity == Severity.CRITICAL
        ]
        score.security -= len(critical_findings) * 20
        score.security = max(0, score.security)

        # Organization score
        orphan_ratio = len(report.dependency_graph.orphans) / max(report.total_modules, 1)
        score.organization = int((1 - orphan_ratio) * 100)
        score.orphan_modules = len(report.dependency_graph.orphans)

        # Complexity score (lower is better for avg complexity)
        high_complex = sum(
            1 for m in report.modules
            if m.complexity in (Complexity.HIGH, Complexity.CRITICAL)
        )
        complex_ratio = high_complex / max(report.total_modules, 1)
        score.complexity = int((1 - complex_ratio) * 100)

        # Count issues
        for m in report.modules:
            for issue in m.issues:
                if issue.severity == Severity.CRITICAL:
                    score.critical_issues += 1
                elif issue.severity in (Severity.WARNING, Severity.ERROR):
                    score.warnings += 1

        # Overall score (weighted average)
        score.overall = int(
            score.documentation * 0.2
            + score.security * 0.3
            + score.organization * 0.2
            + score.complexity * 0.2
            + (100 - min(score.critical_issues * 10, 100)) * 0.1
        )

        return score

    def _parse_json(self, response: str) -> dict[str, Any]:
        """Parse JSON response."""
        try:
            start = response.find("{")
            end = response.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except json.JSONDecodeError:
            pass
        return {}


# ═══════════════════════════════════════════════════════════════════════════
# Auto Corrector - Generate and apply fixes
# ═══════════════════════════════════════════════════════════════════════════

class AutoCorrector:
    """Generate and apply automatic fixes."""

    def __init__(self, client: OllamaClient, repo_root: Path):
        self.client = client
        self.repo_root = repo_root
        self._backups: dict[str, str] = {}

    async def generate_fix(self, module: ModuleAnalysis, issue: Issue) -> AutoFix | None:
        """Generate fix for an issue."""
        if not issue.fixable:
            return None

        path = self.repo_root / module.path
        if not path.exists():
            return None

        try:
            content = path.read_text()
            lines = content.splitlines()
            
            # Context around issue
            line = issue.line or 1
            start = max(0, line - 5)
            end = min(len(lines), line + 5)
            context = "\n".join(lines[start:end])

            system, prompt = get_prompt(
                "generate_fix",
                filename=module.path,
                issue_message=issue.message,
                severity=issue.severity.value,
                line=line,
                start_line=start + 1,
                end_line=end,
                code_context=context,
                full_code=content[:4000],
            )

            response = await self.client.generate(prompt, system)
            data = self._parse_json(response)

            if not data.get("can_fix", False):
                return None

            return AutoFix(
                id=f"fix_{module.name}_{issue.id}",
                fix_type=FixType.SECURITY_PATCH if "secret" in issue.message.lower() else FixType.FIX_SYNTAX,
                module=module.path,
                description=data.get("description", ""),
                original_content=context,
                fixed_content=data.get("fixed_code", ""),
                line_start=start + 1,
                line_end=end,
                confidence=data.get("confidence", 0.5),
                risk=data.get("risk", "medium"),
            )

        except Exception as e:
            log.error(f"Failed to generate fix for {module.path}: {e}")
            return None

    async def generate_all_fixes(self, report: ArchitectureReport) -> list[AutoFix]:
        """Generate fixes for all fixable issues."""
        fixes = []
        
        for module in report.modules:
            for issue in module.issues:
                if issue.fixable:
                    fix = await self.generate_fix(module, issue)
                    if fix:
                        fixes.append(fix)

        return fixes

    def apply_fix(self, fix: AutoFix, dry_run: bool = True) -> bool:
        """Apply a fix to the codebase."""
        path = self.repo_root / fix.module
        
        if not path.exists():
            log.error(f"File not found: {path}")
            return False

        try:
            content = path.read_text()
            lines = content.splitlines()

            # Backup before modification
            if not dry_run:
                self._backups[str(path)] = content

            # Apply fix
            new_lines = (
                lines[: fix.line_start - 1]
                + fix.fixed_content.splitlines()
                + lines[fix.line_end:]
            )
            new_content = "\n".join(new_lines)

            if dry_run:
                log.info(f"[DRY-RUN] Would apply fix to {fix.module}")
                log.info(f"  Lines {fix.line_start}-{fix.line_end}")
                log.info(f"  Change: {fix.description}")
                return True
            else:
                path.write_text(new_content)
                fix.applied = True
                log.info(f"Applied fix to {fix.module}")
                return True

        except Exception as e:
            log.error(f"Failed to apply fix: {e}")
            return False

    def rollback(self, path: str) -> bool:
        """Rollback a fix using backup."""
        if path not in self._backups:
            log.error(f"No backup found for {path}")
            return False

        try:
            Path(path).write_text(self._backups[path])
            log.info(f"Rolled back changes to {path}")
            return True
        except Exception as e:
            log.error(f"Rollback failed: {e}")
            return False

    def _parse_json(self, response: str) -> dict[str, Any]:
        """Parse JSON response."""
        try:
            start = response.find("{")
            end = response.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except json.JSONDecodeError:
            pass
        return {}


# ═══════════════════════════════════════════════════════════════════════════
# Report Generator - Multi-format output
# ═══════════════════════════════════════════════════════════════════════════

class ReportGenerator:
    """Generate reports in multiple formats."""

    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_markdown(self, report: ArchitectureReport) -> str:
        """Generate comprehensive Markdown report."""
        lines = [
            "# 🤖 AI Architecture Analysis Report",
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
            report.executive_summary or "_Analysis complete._",
            "",
            "### Quality Score",
            "",
            f"**Overall: {report.quality_score.overall}/100**",
            "",
            "| Component | Score |",
            "|-----------|-------|",
            f"| Documentation | {report.quality_score.documentation}/100 |",
            f"| Security | {report.quality_score.security}/100 |",
            f"| Organization | {report.quality_score.organization}/100 |",
            f"| Complexity | {report.quality_score.complexity}/100 |",
            "",
        ]

        # Trend indicator
        if report.quality_score.previous_score is not None:
            diff = report.quality_score.overall - report.quality_score.previous_score
            trend = "📈" if diff > 0 else "📉" if diff < 0 else "➡️"
            lines.append(f"**Trend**: {trend} {diff:+d} from previous ({report.quality_score.previous_score})")
            lines.append("")

        # Stats
        lines.extend([
            "### Quick Stats",
            "",
            "| Metric | Value |",
            "|--------|-------|",
            f"| **Total Modules** | {report.total_modules} |",
            f"| **Total Lines** | {report.total_lines:,} |",
            f"| **Categories** | {len(report.category_summary)} |",
            f"| **Orphan Modules** | {len(report.dependency_graph.orphans)} |",
            f"| **Critical Issues** | {report.quality_score.critical_issues} |",
            "",
            "---",
            "",
        ])

        # Category breakdown
        lines.extend([
            "## 📊 Category Breakdown",
            "",
            "| Category | Modules |",
            "|----------|---------|",
        ])
        for cat, count in sorted(report.category_summary.items(), key=lambda x: -x[1]):
            lines.append(f"| **{cat}** | {count} |")

        # Dependency graph as Mermaid
        lines.extend([
            "",
            "---",
            "",
            "## 🔗 Dependency Graph",
            "",
            "```mermaid",
            self._generate_mermaid(report),
            "```",
            "",
        ])

        # Orphan modules
        if report.dependency_graph.orphans:
            lines.extend([
                "---",
                "",
                "## ⚠️ Orphan Modules",
                "",
                "These modules are not imported anywhere:",
                "",
            ])
            for orphan in report.dependency_graph.orphans[:20]:
                lines.append(f"- `{orphan}`")
            lines.append("")

        # Module analysis by category
        lines.extend([
            "---",
            "",
            "## 📦 Module Analysis",
            "",
        ])

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
            for m in sorted(mods, key=lambda x: -x.lines_of_code)[:15]:
                purpose = (m.purpose[:55] + "...") if len(m.purpose) > 55 else m.purpose
                icon = {"low": "🟢", "medium": "🟡", "high": "🟠", "critical": "🔴"}.get(
                    m.complexity.value, "⚪"
                )
                lines.append(f"| `{m.name}` | {purpose} | {icon} {m.complexity.value} | {m.lines_of_code} |")
            lines.append("")

        # Security findings
        if report.security_findings:
            lines.extend([
                "---",
                "",
                "## 🔒 Security Findings",
                "",
            ])
            for finding in report.security_findings[:20]:
                icon = {"critical": "🔴", "error": "🟠", "warning": "🟡"}.get(
                    finding.severity.value, "ℹ️"
                )
                lines.append(f"- {icon} **{finding.module}**: {finding.title}")
                lines.append(f"  - {finding.description}")
            lines.append("")

        # Auto-fixes
        if report.auto_fixes:
            lines.extend([
                "---",
                "",
                "## 🔧 Suggested Fixes",
                "",
            ])
            for fix in report.auto_fixes[:15]:
                status = "✅ Applied" if fix.applied else "⏸️ Pending"
                lines.append(f"- **{fix.module}** ({status})")
                lines.append(f"  - {fix.description}")
                lines.append(f"  - Confidence: {fix.confidence:.0%}, Risk: {fix.risk}")
            lines.append("")

        # Technical debt
        if report.technical_debt:
            lines.extend([
                "---",
                "",
                "## 📋 Technical Debt",
                "",
            ])
            for debt in report.technical_debt:
                lines.append(f"- {debt}")
            lines.append("")

        # Priority actions
        if report.priority_actions:
            lines.extend([
                "---",
                "",
                "## 🎯 Priority Actions",
                "",
            ])
            for i, action in enumerate(report.priority_actions, 1):
                lines.append(f"{i}. {action}")
            lines.append("")

        # Footer
        lines.extend([
            "---",
            "",
            f"*Generated with arch-analyzer v{VERSION}*",
            f"*Model: {report.model_used}*",
        ])

        return "\n".join(lines)

    def _generate_mermaid(self, report: ArchitectureReport) -> str:
        """Generate Mermaid diagram."""
        lines = ["graph TD"]

        # Group by category
        categories: dict[str, list[str]] = {}
        for node in report.dependency_graph.nodes.values():
            if node.category not in categories:
                categories[node.category] = []
            categories[node.category].append(node.name)

        # Add subgraphs
        for cat, nodes in sorted(categories.items()):
            lines.append(f"    subgraph {cat}")
            for node in sorted(set(nodes))[:10]:
                module = next((m for m in report.modules if m.name == node), None)
                if module and module.complexity == Complexity.CRITICAL:
                    lines.append(f"        {node}[{node}]:::critical")
                elif module and module.complexity == Complexity.HIGH:
                    lines.append(f"        {node}[{node}]:::high")
                else:
                    lines.append(f"        {node}[{node}]")
            lines.append("    end")

        # Add edges (limited to avoid clutter)
        edge_count = 0
        for edge in report.dependency_graph.edges[:50]:
            if edge.target in report.dependency_graph.nodes and edge_count < 50:
                lines.append(f"    {edge.source} --> {edge.target}")
                edge_count += 1

        # Styles
        lines.extend([
            "",
            "    classDef critical fill:#ff6b6b,stroke:#c92a2a",
            "    classDef high fill:#ffd43b,stroke:#f59f00",
        ])

        return "\n".join(lines)

    def generate_json(self, report: ArchitectureReport) -> str:
        """Generate JSON report."""
        # Convert dataclasses to dict, handling enums
        def convert(obj):
            if hasattr(obj, "value"):  # Enum
                return obj.value
            if hasattr(obj, "__dict__"):
                return {k: convert(v) for k, v in asdict(obj).items()}
            if isinstance(obj, list):
                return [convert(i) for i in obj]
            if isinstance(obj, dict):
                return {k: convert(v) for k, v in obj.items()}
            return obj

        data = convert(report)
        return json.dumps(data, indent=2, ensure_ascii=False, default=str)

    def save_all(self, report: ArchitectureReport) -> dict[str, Path]:
        """Save all report formats."""
        outputs = {}

        # Markdown
        md_path = self.output_dir / "AI-ARCHITECTURE-REPORT.md"
        md_path.write_text(self.generate_markdown(report))
        outputs["markdown"] = md_path
        log.info(f"✓ Markdown: {md_path}")

        # JSON
        json_path = self.output_dir / "AI-ARCHITECTURE-REPORT.json"
        json_path.write_text(self.generate_json(report))
        outputs["json"] = json_path
        log.info(f"✓ JSON: {json_path}")

        # Mermaid diagram
        mmd_path = self.output_dir / "dependency-graph.mmd"
        mmd_path.write_text(self._generate_mermaid(report))
        outputs["mermaid"] = mmd_path
        log.info(f"✓ Mermaid: {mmd_path}")

        return outputs


# ═══════════════════════════════════════════════════════════════════════════
# Main Pipeline
# ═══════════════════════════════════════════════════════════════════════════

async def run_analysis(config: AnalysisConfig) -> ArchitectureReport:
    """Run complete architecture analysis pipeline."""
    start_time = time.monotonic()

    log.info("=" * 70)
    log.info(f"🚀 Architecture Analyzer v{VERSION}")
    log.info(f"   Repository: {config.repo_root}")
    log.info(f"   Model: {config.model}")
    log.info(f"   Parallelism: {config.max_concurrent}x")
    log.info("=" * 70)

    # Initialize components
    cache = CacheLayer(config.cache_db) if config.use_cache else None
    if cache:
        cache.__enter__()

    async with OllamaClient(
        model=config.model,
        timeout=config.timeout,
        max_concurrent=config.max_concurrent,
    ) as client:
        # Verify Ollama
        if not await client.check_health():
            log.error("❌ Ollama not available or model not loaded")
            raise RuntimeError("Ollama connection failed")
        log.info("✓ Ollama connection verified")

        # Static analysis
        static_analyzer = StaticAnalyzer(config.repo_root)
        modules = static_analyzer.discover_modules()
        log.info(f"📁 Found {len(modules)} Nix modules")

        static_results = {}
        for path in modules:
            static_results[path] = static_analyzer.analyze(path)

        # Build dependency graph
        dep_graph = static_analyzer.build_import_graph(modules)
        log.info(f"🔗 Built dependency graph: {len(dep_graph.edges)} edges, {len(dep_graph.orphans)} orphans")

        # LLM analysis
        llm_analyzer = LLMAnalyzer(client, config.repo_root, cache)
        analyses = await llm_analyzer.analyze_all(modules, static_results)

        # Build initial report
        report = ArchitectureReport(
            timestamp=datetime.now().isoformat(),
            repository=str(config.repo_root),
            model_used=config.model,
            total_modules=len(modules),
            total_lines=sum(m.lines_of_code for m in analyses),
            modules=analyses,
            dependency_graph=dep_graph,
        )

        # Category summary
        for m in analyses:
            report.category_summary[m.category] = report.category_summary.get(m.category, 0) + 1

        # Security findings from analysis
        for m in analyses:
            for concern in m.security_concerns:
                report.security_findings.append(
                    SecurityFinding(
                        id=f"sec_{m.name}_{len(report.security_findings)}",
                        severity=Severity.WARNING,
                        module=m.path,
                        title="Security Concern",
                        description=concern,
                    )
                )

        # Generate AI summary
        log.info("🧠 Generating architecture summary...")
        summary = await llm_analyzer.generate_summary(report)
        report.executive_summary = summary.get("executive_summary", "")
        report.architecture_patterns = summary.get("architecture_patterns", [])
        report.technical_debt = summary.get("technical_debt", [])
        report.priority_actions = summary.get("priority_actions", [])

        # Calculate quality score
        self_analyzer = SelfAnalyzer(client)
        report.quality_score = self_analyzer.calculate_quality_score(report)
        
        # Get previous score for trend
        if cache:
            report.quality_score.previous_score = cache.get_previous_score()
            if report.quality_score.previous_score is not None:
                diff = report.quality_score.overall - report.quality_score.previous_score
                if diff > 2:
                    report.quality_score.trend = "improving"
                elif diff < -2:
                    report.quality_score.trend = "degrading"

        # Auto-fix generation
        if config.auto_fix:
            log.info("🔧 Generating auto-fixes...")
            corrector = AutoCorrector(client, config.repo_root)
            report.auto_fixes = await corrector.generate_all_fixes(report)
            log.info(f"   Generated {len(report.auto_fixes)} fixes")

            if not config.dry_run:
                for fix in report.auto_fixes:
                    if fix.confidence > 0.8 and fix.risk == "low":
                        corrector.apply_fix(fix, dry_run=False)

        # Self-analysis
        if config.self_analyze:
            log.info("🔍 Running self-analysis...")
            self_report = await self_analyzer.analyze_self()
            if self_report.get("quality_score"):
                log.info(f"   Analyzer self-score: {self_report['quality_score']}/100")

        report.analysis_duration_seconds = time.monotonic() - start_time

        # Save to cache
        if cache:
            cache.save_report(report)
            cache.__exit__(None, None, None)

        # Generate reports
        generator = ReportGenerator(config.output_dir)
        generator.save_all(report)

        # Final summary
        log.info("=" * 70)
        log.info("✅ Analysis Complete!")
        log.info(f"   Quality Score: {report.quality_score.overall}/100 ({report.quality_score.trend})")
        log.info(f"   Modules analyzed: {report.total_modules}")
        log.info(f"   Total lines: {report.total_lines:,}")
        log.info(f"   Security findings: {len(report.security_findings)}")
        log.info(f"   Duration: {report.analysis_duration_seconds:.1f}s")
        log.info("=" * 70)

        return report


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description=f"Architecture Analyzer v{VERSION} - AI-powered NixOS analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--repo", "-r",
        type=Path,
        default=Path("/etc/nixos"),
        help="Repository root (default: /etc/nixos)",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("/etc/nixos/arch"),
        help="Output directory (default: /etc/nixos/arch)",
    )
    parser.add_argument(
        "--model", "-m",
        default=DEFAULT_MODEL,
        help=f"Ollama model (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--parallel", "-p",
        type=int,
        default=MAX_CONCURRENT,
        help=f"Max concurrent requests (default: {MAX_CONCURRENT})",
    )
    parser.add_argument(
        "--timeout", "-t",
        type=int,
        default=REQUEST_TIMEOUT,
        help=f"Request timeout in seconds (default: {REQUEST_TIMEOUT})",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Disable caching",
    )
    parser.add_argument(
        "--auto-fix",
        action="store_true",
        help="Generate auto-fix suggestions",
    )
    parser.add_argument(
        "--apply-fixes",
        action="store_true",
        help="Apply auto-fixes (requires --auto-fix)",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run self-analysis only",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Verbose logging",
    )

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    config = AnalysisConfig(
        repo_root=args.repo,
        output_dir=args.output,
        model=args.model,
        max_concurrent=args.parallel,
        timeout=args.timeout,
        use_cache=not args.no_cache,
        auto_fix=args.auto_fix,
        dry_run=not args.apply_fixes,
    )

    # Handle signals
    def signal_handler(sig, frame):
        log.info("\n⚠️ Analysis interrupted")
        sys.exit(1)

    signal.signal(signal.SIGINT, signal_handler)

    try:
        asyncio.run(run_analysis(config))
    except Exception as e:
        log.error(f"❌ Fatal error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
