#!/usr/bin/env python3
"""
Intelligent Environment Setup & Validator
Automatically configures the dev environment, validates dependencies,
troubleshoots issues, and provides intelligent recommendations
"""

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.tree import Tree
import platform

console = Console()


class Status(Enum):
    """Check status enum"""
    PASS = "✓"
    FAIL = "✗"
    WARN = "⚠"
    INFO = "ℹ"


@dataclass
class Check:
    """Validation check result"""
    name: str
    status: Status
    message: str
    fix: Optional[str] = None


class EnvironmentValidator:
    """Intelligent environment validator with auto-fix capabilities"""

    def __init__(self):
        self.checks: List[Check] = []
        self.system_info = self._gather_system_info()

    def _gather_system_info(self) -> Dict:
        """Gather comprehensive system information"""
        return {
            'os': platform.system(),
            'os_version': platform.version(),
            'arch': platform.machine(),
            'python_version': platform.python_version(),
            'cpu_count': os.cpu_count(),
            'user': os.getenv('USER', 'unknown'),
            'home': str(Path.home()),
            'cwd': str(Path.cwd())
        }

    def _run_command(self, cmd: List[str], capture: bool = True) -> Tuple[bool, str]:
        """Run command and return success status and output"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=capture,
                text=True,
                timeout=30
            )
            return result.returncode == 0, result.stdout if capture else ""
        except Exception as e:
            return False, str(e)

    def check_nix(self) -> Check:
        """Validate Nix installation"""
        success, output = self._run_command(['nix', '--version'])

        if success:
            version = output.strip().split()[-1] if output else "unknown"
            return Check(
                "Nix",
                Status.PASS,
                f"Installed (version {version})"
            )
        else:
            return Check(
                "Nix",
                Status.FAIL,
                "Not installed or not in PATH",
                "Install: curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
            )

    def check_flakes(self) -> Check:
        """Check if Nix flakes are enabled"""
        success, _ = self._run_command(['nix', 'flake', '--help'])

        if success:
            return Check("Nix Flakes", Status.PASS, "Enabled")
        else:
            return Check(
                "Nix Flakes",
                Status.FAIL,
                "Not enabled",
                "Enable in ~/.config/nix/nix.conf:\nexperimental-features = nix-command flakes"
            )

    def check_direnv(self) -> Check:
        """Check direnv installation"""
        success, _ = self._run_command(['direnv', '--version'])

        if success:
            # Check if direnv hook is in shell rc
            shell = os.getenv('SHELL', '').split('/')[-1]
            rc_file = Path.home() / f'.{shell}rc'

            if rc_file.exists() and 'direnv' in rc_file.read_text():
                return Check("direnv", Status.PASS, "Installed and hooked")
            else:
                return Check(
                    "direnv",
                    Status.WARN,
                    "Installed but not hooked to shell",
                    f"Add to ~/{rc_file.name}: eval \"$(direnv hook {shell})\""
                )
        else:
            return Check(
                "direnv",
                Status.FAIL,
                "Not installed",
                "Install via Nix: nix profile install nixpkgs#direnv"
            )

    def check_docker(self) -> Check:
        """Check Docker installation and daemon"""
        success, output = self._run_command(['docker', '--version'])

        if not success:
            return Check(
                "Docker",
                Status.FAIL,
                "Not installed",
                "Install: https://docs.docker.com/get-docker/"
            )

        # Check if daemon is running
        daemon_success, _ = self._run_command(['docker', 'ps'])

        if daemon_success:
            return Check("Docker", Status.PASS, "Installed and running")
        else:
            return Check(
                "Docker",
                Status.WARN,
                "Installed but daemon not running",
                "Start daemon: sudo systemctl start docker"
            )

    def check_cuda(self) -> Check:
        """Check NVIDIA CUDA availability"""
        success, output = self._run_command(['nvidia-smi'])

        if success:
            # Parse GPU info
            lines = output.strip().split('\n')
            gpu_line = [l for l in lines if 'NVIDIA' in l]
            gpu_info = gpu_line[0] if gpu_line else "Available"

            return Check("CUDA/GPU", Status.PASS, f"Available - {gpu_info[:50]}")
        else:
            return Check(
                "CUDA/GPU",
                Status.INFO,
                "No NVIDIA GPU detected or drivers not installed",
                "Optional: Install NVIDIA drivers for GPU acceleration"
            )

    def check_disk_space(self) -> Check:
        """Check available disk space"""
        stat = shutil.disk_usage(Path.cwd())
        free_gb = stat.free / (1024**3)

        if free_gb < 5:
            return Check(
                "Disk Space",
                Status.FAIL,
                f"Only {free_gb:.1f} GB free - insufficient",
                "Free up disk space or use different directory"
            )
        elif free_gb < 20:
            return Check(
                "Disk Space",
                Status.WARN,
                f"{free_gb:.1f} GB free - may be tight for ML work"
            )
        else:
            return Check("Disk Space", Status.PASS, f"{free_gb:.1f} GB available")

    def check_python_env(self) -> Check:
        """Check Python environment"""
        version = sys.version_info

        if version >= (3, 11):
            return Check("Python", Status.PASS, f"{version.major}.{version.minor}.{version.micro}")
        elif version >= (3, 8):
            return Check(
                "Python",
                Status.WARN,
                f"{version.major}.{version.minor}.{version.micro} - recommend 3.11+",
                "Use Nix flake environment for Python 3.11"
            )
        else:
            return Check(
                "Python",
                Status.FAIL,
                f"{version.major}.{version.minor}.{version.micro} - too old",
                "Use Nix flake environment for Python 3.11"
            )

    def check_network(self) -> Check:
        """Check internet connectivity"""
        success, _ = self._run_command(['ping', '-c', '1', '-W', '2', '8.8.8.8'])

        if success:
            return Check("Network", Status.PASS, "Internet connectivity OK")
        else:
            return Check(
                "Network",
                Status.FAIL,
                "No internet connectivity",
                "Check network connection"
            )

    def check_project_structure(self) -> Check:
        """Validate project directory structure"""
        required_files = ['flake.nix', 'README.md']
        missing = [f for f in required_files if not Path(f).exists()]

        if not missing:
            return Check("Project Files", Status.PASS, "All required files present")
        else:
            return Check(
                "Project Files",
                Status.FAIL,
                f"Missing: {', '.join(missing)}",
                "Ensure you're in the project root directory"
            )

    def run_all_checks(self) -> List[Check]:
        """Run all validation checks"""
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console
        ) as progress:
            task = progress.add_task("[cyan]Running validation checks...", total=None)

            self.checks = [
                self.check_project_structure(),
                self.check_nix(),
                self.check_flakes(),
                self.check_direnv(),
                self.check_python_env(),
                self.check_docker(),
                self.check_cuda(),
                self.check_disk_space(),
                self.check_network(),
            ]

            progress.update(task, completed=True)

        return self.checks

    def display_results(self):
        """Display validation results in a nice table"""
        table = Table(title="Environment Validation Results", show_header=True)
        table.add_column("Component", style="cyan", width=20)
        table.add_column("Status", width=10)
        table.add_column("Details", style="white")

        for check in self.checks:
            status_color = {
                Status.PASS: "green",
                Status.WARN: "yellow",
                Status.FAIL: "red",
                Status.INFO: "blue"
            }[check.status]

            status_text = f"[{status_color}]{check.status.value}[/{status_color}]"
            table.add_row(check.name, status_text, check.message)

        console.print(table)
        console.print()

    def display_fixes(self):
        """Display recommended fixes for failed checks"""
        failed_checks = [c for c in self.checks if c.status in [Status.FAIL, Status.WARN] and c.fix]

        if not failed_checks:
            console.print(Panel("[green]✓ All checks passed! Environment is ready.[/green]"))
            return

        console.print(Panel("[yellow]⚠  Some issues detected. Recommended fixes:[/yellow]"))

        tree = Tree("🔧 Fixes")
        for check in failed_checks:
            branch = tree.add(f"[yellow]{check.name}[/yellow]")
            branch.add(f"[red]Issue:[/red] {check.message}")
            if check.fix:
                fix_branch = branch.add("[green]Fix:[/green]")
                for line in check.fix.split('\n'):
                    fix_branch.add(line)

        console.print(tree)

    def generate_report(self, output: Path = Path("validation_report.json")):
        """Generate JSON report of validation results"""
        report = {
            'timestamp': subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'],
                                       capture_output=True, text=True).stdout.strip(),
            'system_info': self.system_info,
            'checks': [
                {
                    'name': c.name,
                    'status': c.status.name,
                    'message': c.message,
                    'fix': c.fix
                }
                for c in self.checks
            ],
            'summary': {
                'total': len(self.checks),
                'passed': len([c for c in self.checks if c.status == Status.PASS]),
                'warned': len([c for c in self.checks if c.status == Status.WARN]),
                'failed': len([c for c in self.checks if c.status == Status.FAIL])
            }
        }

        output.write_text(json.dumps(report, indent=2))
        console.print(f"[green]Report saved to {output}[/green]")

    def auto_fix(self):
        """Attempt to automatically fix common issues"""
        console.print(Panel("[cyan]Attempting automatic fixes...[/cyan]"))

        fixed = []
        for check in self.checks:
            if check.status == Status.FAIL and check.fix:
                console.print(f"[yellow]Fixing {check.name}...[/yellow]")

                # Only auto-fix safe operations
                if 'direnv' in check.name.lower():
                    # Add direnv hook
                    shell = os.getenv('SHELL', '').split('/')[-1]
                    rc_file = Path.home() / f'.{shell}rc'

                    hook_line = f'\neval "$(direnv hook {shell})"\n'
                    with open(rc_file, 'a') as f:
                        f.write(hook_line)

                    console.print(f"[green]✓ Added direnv hook to {rc_file}[/green]")
                    fixed.append(check.name)

                elif 'flakes' in check.name.lower():
                    # Enable flakes
                    nix_conf = Path.home() / '.config/nix/nix.conf'
                    nix_conf.parent.mkdir(parents=True, exist_ok=True)

                    with open(nix_conf, 'a') as f:
                        f.write('\nexperimental-features = nix-command flakes\n')

                    console.print(f"[green]✓ Enabled Nix flakes[/green]")
                    fixed.append(check.name)

        if fixed:
            console.print(f"\n[green]Fixed {len(fixed)} issues: {', '.join(fixed)}[/green]")
        else:
            console.print("[yellow]No safe automatic fixes available[/yellow]")


def main():
    """CLI interface for environment validator"""
    import argparse

    parser = argparse.ArgumentParser(description="Environment Setup & Validator")
    parser.add_argument("--auto-fix", action="store_true", help="Attempt automatic fixes")
    parser.add_argument("--report", action="store_true", help="Generate JSON report")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")

    args = parser.parse_args()

    if not args.quiet:
        console.print(Panel.fit(
            "[bold cyan]Ultimate Dev Environment Validator[/bold cyan]\n"
            "Intelligent setup and troubleshooting",
            border_style="cyan"
        ))

    validator = EnvironmentValidator()

    # Display system info
    if not args.quiet:
        info_table = Table(title="System Information", show_header=False)
        for key, value in validator.system_info.items():
            info_table.add_row(key.replace('_', ' ').title(), str(value))
        console.print(info_table)
        console.print()

    # Run validation
    validator.run_all_checks()
    validator.display_results()
    validator.display_fixes()

    # Auto-fix if requested
    if args.auto_fix:
        console.print()
        validator.auto_fix()

    # Generate report if requested
    if args.report:
        console.print()
        validator.generate_report()

    # Exit code based on results
    failed = len([c for c in validator.checks if c.status == Status.FAIL])
    return 1 if failed > 0 else 0


if __name__ == "__main__":
    exit(main())
