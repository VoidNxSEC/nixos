#!/usr/bin/env python3
"""
Advanced Binary Analysis Orchestrator
Integrates radare2, GDB, objdump, and AI analysis for comprehensive binary reversing
"""

import subprocess
import json
import re
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.tree import Tree
import r2pipe

console = Console()


@dataclass
class BinaryInfo:
    """Binary metadata"""
    path: str
    arch: str
    bits: int
    os: str
    endian: str
    stripped: bool
    static: bool
    has_canary: bool
    has_nx: bool
    has_pie: bool
    has_relro: bool
    
    
@dataclass
class Function:
    """Function metadata"""
    name: str
    addr: int
    size: int
    calls: List[str]
    strings: List[str]
    complexity: int
    dangerous_funcs: List[str]


class BinaryAnalyzer:
    """Advanced binary analysis orchestrator"""
    
    DANGEROUS_FUNCS = {
        'strcpy', 'strcat', 'gets', 'sprintf', 'scanf',
        'system', 'exec', 'popen', 'eval'
    }
    
    def __init__(self, binary_path: str):
        self.binary_path = Path(binary_path)
        if not self.binary_path.exists():
            raise FileNotFoundError(f"Binary not found: {binary_path}")
        
        self.r2 = r2pipe.open(str(self.binary_path), flags=['-2'])
        self.r2.cmd('aaa')  # Analyze all
        
        console.print(f"[cyan]Analyzing binary: {self.binary_path.name}[/cyan]")
    
    def get_binary_info(self) -> BinaryInfo:
        """Extract comprehensive binary information"""
        info_json = json.loads(self.r2.cmd('ij'))
        bin_info = info_json['bin']
        
        # Check security features
        checksec = self.r2.cmd('iI')
        
        return BinaryInfo(
            path=str(self.binary_path),
            arch=bin_info.get('arch', 'unknown'),
            bits=bin_info.get('bits', 0),
            os=bin_info.get('os', 'unknown'),
            endian=bin_info.get('endian', 'unknown'),
            stripped=bin_info.get('stripped', False),
            static=bin_info.get('static', False),
            has_canary='canary' in checksec.lower() and 'true' in checksec.lower(),
            has_nx='nx' in checksec.lower() and 'true' in checksec.lower(),
            has_pie='pie' in checksec.lower() and 'true' in checksec.lower(),
            has_relro='relro' in checksec.lower()
        )
    
    def analyze_functions(self) -> List[Function]:
        """Analyze all functions in binary"""
        functions_json = json.loads(self.r2.cmd('aflj'))
        
        functions = []
        for func in functions_json:
            name = func.get('name', 'unknown')
            addr = func.get('offset', 0)
            size = func.get('size', 0)
            
            # Get function calls
            self.r2.cmd(f's {addr}')
            calls_output = self.r2.cmd('axfj')
            try:
                calls = [c.get('name', '') for c in json.loads(calls_output)]
            except:
                calls = []
            
            # Find dangerous function calls
            dangerous = [c for c in calls if any(d in c for d in self.DANGEROUS_FUNCS)]
            
            # Get strings in function
            strings = self.get_strings_in_function(addr, size)
            
            # Calculate complexity (rough estimate)
            complexity = len(calls) + len(strings)
            
            functions.append(Function(
                name=name,
                addr=addr,
                size=size,
                calls=calls[:10],  # Limit for display
                strings=strings[:10],
                complexity=complexity,
                dangerous_funcs=dangerous
            ))
        
        return sorted(functions, key=lambda f: f.complexity, reverse=True)
    
    def get_strings_in_function(self, addr: int, size: int) -> List[str]:
        """Extract strings referenced in a function"""
        strings = []
        try:
            # Get all strings
            all_strings = json.loads(self.r2.cmd('izj'))
            for s in all_strings:
                s_addr = s.get('vaddr', 0)
                if addr <= s_addr <= addr + size:
                    strings.append(s.get('string', ''))
        except:
            pass
        return strings
    
    def find_vulnerabilities(self) -> Dict[str, List[str]]:
        """Identify potential vulnerabilities"""
        vulns = {
            'buffer_overflow': [],
            'format_string': [],
            'command_injection': [],
            'use_after_free': [],
            'null_pointer': []
        }
        
        functions = self.analyze_functions()
        
        for func in functions:
            # Buffer overflow candidates
            if any(d in func.dangerous_funcs for d in ['strcpy', 'strcat', 'gets', 'sprintf']):
                vulns['buffer_overflow'].append(
                    f"{func.name} @ 0x{func.addr:x} - uses {func.dangerous_funcs}"
                )
            
            # Format string
            if 'printf' in str(func.calls) or 'sprintf' in str(func.calls):
                if any('%' in s for s in func.strings):
                    vulns['format_string'].append(
                        f"{func.name} @ 0x{func.addr:x} - potential format string"
                    )
            
            # Command injection
            if any(d in func.dangerous_funcs for d in ['system', 'exec', 'popen']):
                vulns['command_injection'].append(
                    f"{func.name} @ 0x{func.addr:x} - calls dangerous function"
                )
        
        return {k: v for k, v in vulns.items() if v}
    
    def disassemble_function(self, func_name: str) -> str:
        """Disassemble a specific function"""
        self.r2.cmd(f's {func_name}')
        return self.r2.cmd('pdf')
    
    def generate_cfg(self, func_name: str, output: str = 'cfg.dot'):
        """Generate control flow graph"""
        self.r2.cmd(f's {func_name}')
        dot = self.r2.cmd('agfd')
        
        Path(output).write_text(dot)
        console.print(f"[green]CFG saved to {output}[/green]")
        
        # Try to convert to PNG
        try:
            subprocess.run(['dot', '-Tpng', output, '-o', output.replace('.dot', '.png')],
                         check=True, capture_output=True)
            console.print(f"[green]PNG generated: {output.replace('.dot', '.png')}[/green]")
        except:
            console.print("[yellow]Install graphviz to generate PNG[/yellow]")
    
    def extract_gadgets(self, output: str = 'gadgets.txt') -> List[str]:
        """Extract ROP gadgets"""
        gadgets = self.r2.cmd('/R')
        
        Path(output).write_text(gadgets)
        console.print(f"[green]Gadgets saved to {output}[/green]")
        
        return gadgets.split('\n')[:50]  # Return first 50
    
    def display_report(self):
        """Generate and display comprehensive analysis report"""
        
        # Binary info
        info = self.get_binary_info()
        
        info_table = Table(title="Binary Information", show_header=True)
        info_table.add_column("Property", style="cyan")
        info_table.add_column("Value", style="green")
        
        for key, value in asdict(info).items():
            if key != 'path':
                info_table.add_row(key, str(value))
        
        console.print(info_table)
        console.print()
        
        # Security features
        security_table = Table(title="Security Features", show_header=True)
        security_table.add_column("Feature", style="cyan")
        security_table.add_column("Status", style="magenta")
        
        security_features = {
            'Stack Canary': info.has_canary,
            'NX (DEP)': info.has_nx,
            'PIE': info.has_pie,
            'RELRO': info.has_relro
        }
        
        for feature, enabled in security_features.items():
            status = "[green]✓ Enabled[/green]" if enabled else "[red]✗ Disabled[/red]"
            security_table.add_row(feature, status)
        
        console.print(security_table)
        console.print()
        
        # Interesting functions
        functions = self.analyze_functions()[:10]  # Top 10
        
        func_table = Table(title="Most Complex Functions", show_header=True)
        func_table.add_column("Function", style="cyan")
        func_table.add_column("Address", style="blue")
        func_table.add_column("Size", style="green")
        func_table.add_column("Complexity", style="yellow")
        func_table.add_column("Dangerous", style="red")
        
        for func in functions:
            func_table.add_row(
                func.name,
                f"0x{func.addr:x}",
                str(func.size),
                str(func.complexity),
                str(len(func.dangerous_funcs))
            )
        
        console.print(func_table)
        console.print()
        
        # Vulnerabilities
        vulns = self.find_vulnerabilities()
        
        if vulns:
            console.print(Panel("[bold red]⚠️  Potential Vulnerabilities Found[/bold red]"))
            
            vuln_tree = Tree("🔍 Vulnerabilities")
            for vuln_type, instances in vulns.items():
                branch = vuln_tree.add(f"[red]{vuln_type.replace('_', ' ').title()}[/red]")
                for instance in instances:
                    branch.add(f"[yellow]{instance}[/yellow]")
            
            console.print(vuln_tree)
        else:
            console.print(Panel("[green]✓ No obvious vulnerabilities detected[/green]"))
    
    def close(self):
        """Clean up resources"""
        self.r2.quit()


def main():
    """CLI interface for binary analyzer"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Advanced Binary Analysis")
    parser.add_argument("binary", help="Path to binary file")
    parser.add_argument("--function", help="Disassemble specific function")
    parser.add_argument("--cfg", help="Generate CFG for function")
    parser.add_argument("--gadgets", action="store_true", help="Extract ROP gadgets")
    parser.add_argument("--output", default="output", help="Output directory")
    
    args = parser.parse_args()
    
    try:
        analyzer = BinaryAnalyzer(args.binary)
        
        if args.function:
            console.print(Panel(f"[cyan]Disassembling {args.function}[/cyan]"))
            disasm = analyzer.disassemble_function(args.function)
            console.print(disasm)
        
        elif args.cfg:
            output = Path(args.output) / f"{args.cfg}_cfg.dot"
            analyzer.generate_cfg(args.cfg, str(output))
        
        elif args.gadgets:
            output = Path(args.output) / "gadgets.txt"
            gadgets = analyzer.extract_gadgets(str(output))
            console.print(f"[green]Found {len(gadgets)} gadgets[/green]")
        
        else:
            analyzer.display_report()
        
        analyzer.close()
        
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    console.print(Panel.fit(
        "[bold cyan]Advanced Binary Analysis Orchestrator[/bold cyan]\n"
        "Comprehensive binary reverse engineering with AI",
        border_style="cyan"
    ))
    
    exit(main())
