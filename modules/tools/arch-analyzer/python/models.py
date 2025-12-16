#!/usr/bin/env python3
"""
Pydantic Models for Architecture Analyzer
==========================================
Structured data models for analysis results, reports, and auto-fixes.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any


class Complexity(str, Enum):
    """Module complexity levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Severity(str, Enum):
    """Issue severity levels."""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class FixType(str, Enum):
    """Types of auto-fixes available."""
    ADD_IMPORT = "add_import"
    REMOVE_UNUSED = "remove_unused"
    FIX_SYNTAX = "fix_syntax"
    ADD_DOCUMENTATION = "add_documentation"
    SECURITY_PATCH = "security_patch"
    REFACTOR = "refactor"
    DEPENDENCY_FIX = "dependency_fix"


@dataclass
class ModuleAnalysis:
    """Analysis result for a single Nix module."""
    path: str
    name: str
    category: str
    
    # LLM-generated
    purpose: str = ""
    complexity: Complexity = Complexity.MEDIUM
    
    # Dependencies
    dependencies: list[str] = field(default_factory=list)
    imports: list[str] = field(default_factory=list)
    imported_by: list[str] = field(default_factory=list)
    
    # Code info
    options_defined: list[str] = field(default_factory=list)
    lines_of_code: int = 0
    has_documentation: bool = False
    documentation_coverage: float = 0.0
    
    # Issues
    security_concerns: list[str] = field(default_factory=list)
    issues: list[Issue] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    
    # Metadata
    analysis_time_ms: int = 0
    content_hash: str = ""
    last_modified: str = ""
    error: str | None = None


@dataclass
class Issue:
    """A detected issue or problem in a module."""
    id: str
    severity: Severity
    category: str
    message: str
    line: int | None = None
    column: int | None = None
    suggestion: str | None = None
    fixable: bool = False


@dataclass
class SecurityFinding:
    """Security vulnerability or concern."""
    id: str
    severity: Severity
    module: str
    title: str
    description: str
    cwe: str | None = None
    remediation: str | None = None
    line: int | None = None


@dataclass
class AutoFix:
    """A proposed automatic fix."""
    id: str
    fix_type: FixType
    module: str
    description: str
    original_content: str
    fixed_content: str
    line_start: int
    line_end: int
    confidence: float = 0.0
    risk: str = "low"
    applied: bool = False
    validated: bool = False


@dataclass
class ValidationResult:
    """Result of validating an applied fix."""
    fix_id: str
    success: bool
    message: str
    build_passed: bool = False
    syntax_valid: bool = False
    tests_passed: bool = False
    rollback_required: bool = False


@dataclass
class QualityScore:
    """Overall quality scoring for the repository."""
    overall: int = 0  # 0-100
    
    # Component scores
    documentation: int = 0
    security: int = 0
    organization: int = 0
    complexity: int = 0
    testing: int = 0
    
    # Issues count
    critical_issues: int = 0
    warnings: int = 0
    orphan_modules: int = 0
    
    # Trends
    trend: str = "stable"  # improving, stable, degrading
    previous_score: int | None = None


@dataclass
class DependencyGraph:
    """Dependency graph between modules."""
    nodes: dict[str, ModuleNode] = field(default_factory=dict)
    edges: list[DependencyEdge] = field(default_factory=list)
    
    # Graph metrics
    strongly_connected: list[list[str]] = field(default_factory=list)
    orphans: list[str] = field(default_factory=list)
    entry_points: list[str] = field(default_factory=list)


@dataclass
class ModuleNode:
    """A node in the dependency graph."""
    name: str
    category: str
    path: str
    in_degree: int = 0
    out_degree: int = 0


@dataclass
class DependencyEdge:
    """An edge in the dependency graph."""
    source: str
    target: str
    edge_type: str = "import"  # import, option, service


@dataclass
class ArchitectureReport:
    """Complete architecture analysis report."""
    # Metadata
    timestamp: str
    repository: str
    model_used: str
    analysis_duration_seconds: float = 0.0
    
    # Summary stats
    total_modules: int = 0
    total_lines: int = 0
    category_summary: dict[str, int] = field(default_factory=dict)
    
    # Core data
    modules: list[ModuleAnalysis] = field(default_factory=list)
    dependency_graph: DependencyGraph = field(default_factory=DependencyGraph)
    quality_score: QualityScore = field(default_factory=QualityScore)
    
    # Findings
    security_findings: list[SecurityFinding] = field(default_factory=list)
    auto_fixes: list[AutoFix] = field(default_factory=list)
    
    # AI summary
    executive_summary: str = ""
    architecture_patterns: list[str] = field(default_factory=list)
    technical_debt: list[str] = field(default_factory=list)
    priority_actions: list[str] = field(default_factory=list)


@dataclass
class CacheEntry:
    """Cache entry for incremental analysis."""
    path: str
    content_hash: str
    last_analyzed: str
    analysis: ModuleAnalysis


@dataclass
class AnalysisConfig:
    """Configuration for analysis run."""
    repo_root: Path
    output_dir: Path
    model: str = "qwen2.5-coder:7b-instruct"
    max_concurrent: int = 8
    timeout: int = 120
    use_cache: bool = True
    cache_db: Path = Path("/var/lib/arch-analyzer/cache.db")
    self_analyze: bool = True
    auto_fix: bool = False
    dry_run: bool = True
    verbose: bool = False
