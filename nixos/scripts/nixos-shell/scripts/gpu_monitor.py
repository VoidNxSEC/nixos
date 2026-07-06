#!/usr/bin/env python3
"""
GPU Monitor - Monitor NVIDIA GPU usage avançado
Comandos disponíveis via aliases:
  - gpu-monitor         : Monitor básico em tempo real
  - gpu-monitor-json    : Output JSON para parsing
  - gpu-monitor-summary : Resumo consolidado
"""

import subprocess
import json
import time
import sys
from datetime import datetime
from typing import Dict, List, Optional

class GPUMonitor:
    """Monitor avançado para GPUs NVIDIA"""

    def __init__(self):
        self.query_fields = [
            "index",
            "name",
            "temperature.gpu",
            "utilization.gpu",
            "utilization.memory",
            "memory.used",
            "memory.total",
            "power.draw",
            "power.limit",
            "clocks.gr",
            "clocks.mem",
        ]

    def query_nvidia_smi(self) -> Optional[str]:
        """Executa nvidia-smi e retorna output"""
        try:
            query_str = ",".join(self.query_fields)
            result = subprocess.run(
                [
                    "nvidia-smi",
                    f"--query-gpu={query_str}",
                    "--format=csv,noheader,nounits"
                ],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"✗ Error querying nvidia-smi: {e}", file=sys.stderr)
            return None
        except FileNotFoundError:
            print("✗ nvidia-smi not found. Is NVIDIA driver installed?", file=sys.stderr)
            return None

    def parse_gpu_data(self, output: str) -> List[Dict]:
        """Parse output nvidia-smi para dict"""
        gpus = []
        for line in output.split('\n'):
            if not line.strip():
                continue

            values = [v.strip() for v in line.split(',')]
            if len(values) != len(self.query_fields):
                continue

            gpu = dict(zip(self.query_fields, values))

            # Conversão de tipos
            try:
                gpu["index"] = int(gpu["index"])
                gpu["temperature.gpu"] = int(gpu["temperature.gpu"])
                gpu["utilization.gpu"] = int(gpu["utilization.gpu"])
                gpu["utilization.memory"] = int(gpu["utilization.memory"])
                gpu["memory.used"] = int(gpu["memory.used"])
                gpu["memory.total"] = int(gpu["memory.total"])
                gpu["power.draw"] = float(gpu["power.draw"])
                gpu["power.limit"] = float(gpu["power.limit"])
                gpu["clocks.gr"] = int(gpu["clocks.gr"])
                gpu["clocks.mem"] = int(gpu["clocks.mem"])
            except (ValueError, KeyError) as e:
                print(f"Warning: Failed to parse GPU data: {e}", file=sys.stderr)

            gpus.append(gpu)

        return gpus

    def format_monitor_output(self, gpus: List[Dict]) -> str:
        """Formata output para console (human-readable)"""
        lines = []
        lines.append("=" * 80)
        lines.append(f"  GPU Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append("=" * 80)

        for gpu in gpus:
            lines.append("")
            lines.append(f"GPU {gpu['index']}: {gpu['name']}")
            lines.append("-" * 80)

            # Temperature
            temp = gpu['temperature.gpu']
            temp_indicator = "🟢" if temp < 70 else ("🟡" if temp < 85 else "🔴")
            lines.append(f"  Temperature:  {temp_indicator} {temp}°C")

            # Utilization
            util_gpu = gpu['utilization.gpu']
            util_mem = gpu['utilization.memory']
            util_indicator = "🟢" if util_gpu < 80 else "🔴"
            lines.append(f"  Utilization:  {util_indicator} GPU: {util_gpu}% | Memory: {util_mem}%")

            # Memory
            mem_used = gpu['memory.used']
            mem_total = gpu['memory.total']
            mem_percent = (mem_used / mem_total * 100) if mem_total > 0 else 0
            mem_bar = self._create_bar(mem_percent, width=40)
            lines.append(f"  Memory:       {mem_bar} {mem_used}/{mem_total} MiB ({mem_percent:.1f}%)")

            # Power
            power_draw = gpu['power.draw']
            power_limit = gpu['power.limit']
            power_percent = (power_draw / power_limit * 100) if power_limit > 0 else 0
            lines.append(f"  Power:        {power_draw:.1f}W / {power_limit:.1f}W ({power_percent:.1f}%)")

            # Clocks
            lines.append(f"  Clocks:       GPU: {gpu['clocks.gr']} MHz | Memory: {gpu['clocks.mem']} MHz")

        lines.append("=" * 80)
        return "\n".join(lines)

    def _create_bar(self, percent: float, width: int = 40) -> str:
        """Cria barra de progresso visual"""
        filled = int(width * percent / 100)
        bar = "█" * filled + "░" * (width - filled)
        return bar

    def monitor_loop(self, interval: float = 1.0):
        """Loop de monitoramento contínuo"""
        try:
            while True:
                output = self.query_nvidia_smi()
                if output:
                    gpus = self.parse_gpu_data(output)
                    if gpus:
                        # Clear terminal
                        print("\033[2J\033[H", end="")
                        print(self.format_monitor_output(gpus))
                    else:
                        print("✗ No GPUs detected", file=sys.stderr)
                else:
                    print("✗ Failed to query GPU", file=sys.stderr)

                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")
            sys.exit(0)

    def output_json(self) -> str:
        """Output em formato JSON"""
        output = self.query_nvidia_smi()
        if not output:
            return json.dumps({"error": "Failed to query GPU"})

        gpus = self.parse_gpu_data(output)
        return json.dumps({
            "timestamp": datetime.now().isoformat(),
            "gpus": gpus
        }, indent=2)

    def output_summary(self):
        """Output resumo consolidado"""
        output = self.query_nvidia_smi()
        if not output:
            print("✗ Failed to query GPU", file=sys.stderr)
            return

        gpus = self.parse_gpu_data(output)
        if not gpus:
            print("✗ No GPUs detected", file=sys.stderr)
            return

        print("╔════════════════════════════════════════╗")
        print("║         GPU Summary                    ║")
        print("╚════════════════════════════════════════╝")
        print()

        for gpu in gpus:
            print(f"GPU {gpu['index']}: {gpu['name']}")
            print(f"  Temp: {gpu['temperature.gpu']}°C | Util: {gpu['utilization.gpu']}% | Mem: {gpu['memory.used']}/{gpu['memory.total']} MiB")
        print()


def main():
    """Entry point"""
    monitor = GPUMonitor()

    if len(sys.argv) < 2:
        # Default: monitor contínuo
        monitor.monitor_loop(interval=1.0)
    else:
        command = sys.argv[1]

        if command == "json":
            print(monitor.output_json())
        elif command == "summary":
            monitor.output_summary()
        elif command == "watch":
            interval = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
            monitor.monitor_loop(interval=interval)
        else:
            print(f"Unknown command: {command}")
            print("Available commands: json, summary, watch [interval]")
            sys.exit(1)


if __name__ == "__main__":
    main()
