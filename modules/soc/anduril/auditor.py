#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════════════════╗
║  ANDURIL STIG AUDITOR - NixOS Hardening Compliance Scanner                 ║
║  Based on: Anduril NixOS STIG (DOD Release 2024-10-25)                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

import json
import subprocess
import re
import sys
import os
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field
from typing import Dict, List, Optional
from enum import Enum

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

STIG_DB_PATH = Path(__file__).parent / "stig-database.json"
NIXOS_CONFIG_PATH = Path("/etc/nixos")

# ANSI Colors
class Colors:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    BLUE = "\033[0;34m"
    CYAN = "\033[0;36m"
    MAGENTA = "\033[0;35m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

# Severity weights for scoring
SEVERITY_WEIGHT = {
    "high": 10,
    "medium": 5,
    "low": 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# DATA STRUCTURES
# ═══════════════════════════════════════════════════════════════════════════════

class CheckResult(Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    SKIP = "SKIP"
    ERROR = "ERROR"

@dataclass
class Finding:
    rule_id: str
    title: str
    severity: str
    category: str
    result: CheckResult
    details: str = ""
    fix_hint: str = ""

@dataclass
class AuditReport:
    timestamp: str = ""
    total_rules: int = 0
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    errors: int = 0
    score: float = 0.0
    max_score: float = 0.0
    findings: List[Finding] = field(default_factory=list)
    by_category: Dict[str, Dict] = field(default_factory=dict)
    by_severity: Dict[str, Dict] = field(default_factory=dict)

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK ENGINES
# ═══════════════════════════════════════════════════════════════════════════════

def run_command(cmd: str, timeout: int = 10) -> tuple[int, str, str]:
    """Execute shell command and return (returncode, stdout, stderr)"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "timeout"
    except Exception as e:
        return -1, "", str(e)

def check_nix_grep(rule: dict) -> tuple[CheckResult, str]:
    """Check NixOS configuration using grep pattern matching"""
    pattern = rule.get("checkPattern", "")
    cmd = rule.get("checkCommand", "")
    
    if not cmd:
        return CheckResult.SKIP, "No check command defined"
    
    code, stdout, stderr = run_command(cmd)
    
    if code == 0 and stdout:
        # Pattern found, now verify it matches expected
        if pattern and re.search(pattern, stdout):
            return CheckResult.PASS, f"Found: {stdout[:100]}..."
        elif not pattern:
            return CheckResult.PASS, f"Found: {stdout[:100]}..."
        else:
            return CheckResult.FAIL, f"Pattern mismatch. Found: {stdout[:100]}"
    else:
        return CheckResult.FAIL, "Configuration not found"

def check_sysctl(rule: dict) -> tuple[CheckResult, str]:
    """Check kernel sysctl parameter"""
    cmd = rule.get("checkCommand", "")
    pattern = rule.get("checkPattern", "")
    
    if not cmd:
        return CheckResult.SKIP, "No check command"
    
    code, stdout, stderr = run_command(cmd)
    
    if code != 0:
        return CheckResult.ERROR, f"Command failed: {stderr}"
    
    if pattern and re.search(pattern, stdout):
        return CheckResult.PASS, stdout
    else:
        return CheckResult.FAIL, f"Expected pattern '{pattern}', got: {stdout}"

def check_auditctl(rule: dict) -> tuple[CheckResult, str]:
    """Check audit rules using auditctl"""
    cmd = rule.get("checkCommand", "")
    pattern = rule.get("checkPattern", "")
    
    code, stdout, stderr = run_command(cmd)
    
    if code != 0 or not stdout:
        return CheckResult.FAIL, "Audit rule not found"
    
    if pattern:
        # Check if all required syscalls are present
        required = pattern.split(".*")
        missing = [r for r in required if r and r not in stdout]
        if missing:
            return CheckResult.FAIL, f"Missing syscalls: {missing}"
    
    return CheckResult.PASS, stdout[:100]

def check_stat(rule: dict) -> tuple[CheckResult, str]:
    """Check file permissions/ownership using stat"""
    cmd = rule.get("checkCommand", "")
    pattern = rule.get("checkPattern", "")
    
    code, stdout, stderr = run_command(cmd)
    
    if code != 0:
        return CheckResult.SKIP, f"Path not found: {stderr}"
    
    if pattern and re.search(pattern, stdout):
        return CheckResult.PASS, stdout
    else:
        return CheckResult.FAIL, f"Expected '{pattern}', got: {stdout}"

# Check type dispatcher
CHECK_ENGINES = {
    "nix-grep": check_nix_grep,
    "sysctl": check_sysctl,
    "auditctl": check_auditctl,
    "stat": check_stat,
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUDITOR CORE
# ═══════════════════════════════════════════════════════════════════════════════

class AndurilAuditor:
    def __init__(self, db_path: Path = STIG_DB_PATH, verbose: bool = False):
        self.db_path = db_path
        self.verbose = verbose
        self.rules = []
        self.meta = {}
        self._load_database()
    
    def _load_database(self):
        """Load STIG rules from JSON database"""
        if not self.db_path.exists():
            print(f"{Colors.RED}ERROR: STIG database not found: {self.db_path}{Colors.RESET}")
            sys.exit(1)
        
        with open(self.db_path) as f:
            data = json.load(f)
            self.meta = data.get("meta", {})
            self.rules = data.get("rules", [])
    
    def _log(self, msg: str, level: str = "INFO"):
        """Log message with color"""
        if not self.verbose and level == "DEBUG":
            return
        colors = {
            "INFO": Colors.CYAN,
            "WARN": Colors.YELLOW,
            "ERROR": Colors.RED,
            "SUCCESS": Colors.GREEN,
            "DEBUG": Colors.MAGENTA
        }
        print(f"{colors.get(level, '')}{msg}{Colors.RESET}")
    
    def run_audit(self) -> AuditReport:
        """Execute full audit and return report"""
        report = AuditReport(
            timestamp=datetime.now().isoformat(),
            total_rules=len(self.rules)
        )
        
        # Initialize category/severity tracking
        for rule in self.rules:
            cat = rule.get("category", "unknown")
            sev = rule.get("severity", "medium")
            if cat not in report.by_category:
                report.by_category[cat] = {"passed": 0, "failed": 0, "total": 0}
            if sev not in report.by_severity:
                report.by_severity[sev] = {"passed": 0, "failed": 0, "total": 0}
        
        # Run each check
        for rule in self.rules:
            check_type = rule.get("checkType", "nix-grep")
            engine = CHECK_ENGINES.get(check_type, check_nix_grep)
            
            try:
                result, details = engine(rule)
            except Exception as e:
                result = CheckResult.ERROR
                details = str(e)
            
            finding = Finding(
                rule_id=rule.get("id", ""),
                title=rule.get("title", ""),
                severity=rule.get("severity", "medium"),
                category=rule.get("category", "unknown"),
                result=result,
                details=details,
                fix_hint=rule.get("nixFix", "")
            )
            report.findings.append(finding)
            
            # Update counters
            cat = finding.category
            sev = finding.severity
            weight = SEVERITY_WEIGHT.get(sev, 5)
            
            report.max_score += weight
            report.by_category[cat]["total"] += 1
            report.by_severity[sev]["total"] += 1
            
            if result == CheckResult.PASS:
                report.passed += 1
                report.score += weight
                report.by_category[cat]["passed"] += 1
                report.by_severity[sev]["passed"] += 1
            elif result == CheckResult.FAIL:
                report.failed += 1
                report.by_category[cat]["failed"] += 1
                report.by_severity[sev]["failed"] += 1
            elif result == CheckResult.SKIP:
                report.skipped += 1
            else:
                report.errors += 1
        
        return report
    
    def print_banner(self):
        """Print audit banner"""
        print(f"""
{Colors.BLUE}╔══════════════════════════════════════════════════════════════════════════════╗
║  {Colors.BOLD}ANDURIL STIG AUDITOR{Colors.RESET}{Colors.BLUE} - NixOS Hardening Compliance Scanner                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Benchmark: {self.meta.get('benchmarkId', 'N/A'):<52} ║
║  Version:   {self.meta.get('version', 'N/A'):<52} ║
║  Release:   {self.meta.get('releaseDate', 'N/A'):<52} ║
║  Rules:     {str(len(self.rules)):<52} ║
╚══════════════════════════════════════════════════════════════════════════════╝{Colors.RESET}
""")
    
    def print_report(self, report: AuditReport, show_all: bool = False):
        """Print formatted audit report"""
        # Summary
        pct = (report.score / report.max_score * 100) if report.max_score > 0 else 0
        
        if pct >= 90:
            score_color = Colors.GREEN
        elif pct >= 70:
            score_color = Colors.YELLOW
        else:
            score_color = Colors.RED
        
        print(f"\n{Colors.BOLD}═══ AUDIT SUMMARY ═══{Colors.RESET}")
        print(f"  Timestamp:  {report.timestamp}")
        print(f"  Score:      {score_color}{pct:.1f}%{Colors.RESET} ({report.score:.0f}/{report.max_score:.0f} points)")
        print(f"  Passed:     {Colors.GREEN}{report.passed}{Colors.RESET}")
        print(f"  Failed:     {Colors.RED}{report.failed}{Colors.RESET}")
        print(f"  Skipped:    {Colors.YELLOW}{report.skipped}{Colors.RESET}")
        print(f"  Errors:     {report.errors}")
        
        # By severity
        print(f"\n{Colors.BOLD}═══ BY SEVERITY ═══{Colors.RESET}")
        for sev in ["high", "medium", "low"]:
            if sev in report.by_severity:
                data = report.by_severity[sev]
                passed = data["passed"]
                total = data["total"]
                pct = (passed / total * 100) if total > 0 else 0
                color = Colors.RED if sev == "high" else (Colors.YELLOW if sev == "medium" else Colors.CYAN)
                print(f"  {color}{sev.upper():8}{Colors.RESET}: {passed}/{total} ({pct:.0f}%)")
        
        # By category
        print(f"\n{Colors.BOLD}═══ BY CATEGORY ═══{Colors.RESET}")
        for cat, data in sorted(report.by_category.items()):
            passed = data["passed"]
            total = data["total"]
            pct = (passed / total * 100) if total > 0 else 0
            bar = "█" * int(pct / 10) + "░" * (10 - int(pct / 10))
            color = Colors.GREEN if pct >= 80 else (Colors.YELLOW if pct >= 50 else Colors.RED)
            print(f"  {cat:12}: {color}{bar}{Colors.RESET} {passed}/{total} ({pct:.0f}%)")
        
        # Failed findings
        failed = [f for f in report.findings if f.result == CheckResult.FAIL]
        if failed:
            print(f"\n{Colors.BOLD}{Colors.RED}═══ FAILED CHECKS ═══{Colors.RESET}")
            for f in failed:
                sev_color = Colors.RED if f.severity == "high" else Colors.YELLOW
                print(f"  [{sev_color}{f.severity.upper()}{Colors.RESET}] {f.rule_id}: {f.title}")
                if self.verbose:
                    print(f"       Details: {f.details}")
                    print(f"       Fix: {f.fix_hint}")
        
        # Passed findings (if show_all)
        if show_all:
            passed = [f for f in report.findings if f.result == CheckResult.PASS]
            print(f"\n{Colors.BOLD}{Colors.GREEN}═══ PASSED CHECKS ═══{Colors.RESET}")
            for f in passed:
                print(f"  [PASS] {f.rule_id}: {f.title}")
        
        # Final verdict
        print(f"\n{'═' * 80}")
        if pct >= 90:
            print(f"{Colors.GREEN}{Colors.BOLD}✓ SYSTEM READY FOR PRODUCTION{Colors.RESET}")
        elif pct >= 70:
            print(f"{Colors.YELLOW}{Colors.BOLD}⚠ SYSTEM NEEDS HARDENING{Colors.RESET}")
        else:
            print(f"{Colors.RED}{Colors.BOLD}✗ CRITICAL HARDENING REQUIRED{Colors.RESET}")
        print()
    
    def export_json(self, report: AuditReport, path: str):
        """Export report as JSON"""
        data = {
            "meta": self.meta,
            "audit": {
                "timestamp": report.timestamp,
                "score_percent": (report.score / report.max_score * 100) if report.max_score > 0 else 0,
                "score_points": report.score,
                "max_points": report.max_score,
                "passed": report.passed,
                "failed": report.failed,
                "skipped": report.skipped,
                "errors": report.errors,
            },
            "by_category": report.by_category,
            "by_severity": report.by_severity,
            "findings": [
                {
                    "id": f.rule_id,
                    "title": f.title,
                    "severity": f.severity,
                    "category": f.category,
                    "result": f.result.value,
                    "details": f.details,
                    "fix": f.fix_hint
                }
                for f in report.findings
            ]
        }
        
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"{Colors.CYAN}Report exported to: {path}{Colors.RESET}")

# ═══════════════════════════════════════════════════════════════════════════════
# CLI INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Anduril STIG Auditor - NixOS Hardening Compliance Scanner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  anduril-audit              # Run audit with summary
  anduril-audit -v           # Verbose output with fix hints
  anduril-audit --all        # Show all findings including passed
  anduril-audit --json out.json  # Export to JSON
        """
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--all", action="store_true", help="Show all findings including passed")
    parser.add_argument("--json", metavar="FILE", help="Export report to JSON file")
    parser.add_argument("--db", metavar="PATH", help="Custom STIG database path")
    
    args = parser.parse_args()
    
    db_path = Path(args.db) if args.db else STIG_DB_PATH
    
    auditor = AndurilAuditor(db_path=db_path, verbose=args.verbose)
    auditor.print_banner()
    
    print(f"{Colors.CYAN}Running audit...{Colors.RESET}\n")
    report = auditor.run_audit()
    
    auditor.print_report(report, show_all=args.all)
    
    if args.json:
        auditor.export_json(report, args.json)
    
    # Exit code based on result
    pct = (report.score / report.max_score * 100) if report.max_score > 0 else 0
    sys.exit(0 if pct >= 70 else 1)

if __name__ == "__main__":
    main()
