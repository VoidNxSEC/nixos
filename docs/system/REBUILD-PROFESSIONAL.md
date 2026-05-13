# NixOS Rebuild - Professional Edition

> **Version**: 2.0.0 - Professional Edition
> **Status**: Production Ready
> **Module**: `modules/shell/aliases/nix/rebuild-advanced.nix`

---

## 🚀 Overview

Sistema profissional de rebuild com UX sofisticada, métricas detalhadas, analytics e monitoramento em tempo real.

### Key Features

- ✨ **Interface Sofisticada**: Design profissional com cores, ícones e box drawing
- 📊 **Métricas Detalhadas**: CPU, memória, disco, store size
- ⚡ **Pre-flight Checks**: Validação completa antes do build
- 📈 **Analytics**: Histórico completo de builds
- 🎯 **Performance Tracking**: Duração, taxa de sucesso, recursos utilizados
- 📋 **Log Management**: Logs estruturados com timestamps
- 🔍 **Real-time Monitoring**: Monitor de recursos durante builds
- 🎨 **256-color Support**: Cores e gradientes avançados

---

## 📋 Quick Reference

### Main Commands

```bash
rebuild                    # Main rebuild command (professional UI)
rb                         # Quick alias
rebuild --help             # Show detailed help
```

### Analytics & Monitoring

```bash
build-history              # Show build statistics and history
bh                         # Quick alias

build-logs                 # View and manage build logs
bl                         # Quick alias

build-monitor              # Real-time system monitoring
bm                         # Quick alias

generations                # Advanced generation manager
gens                       # Quick alias
```

---

## 🎨 Professional UX Features

### Visual Design

#### Header Design
```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     🚀  NixOS Rebuild Professional Edition                     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

  Host: kernelcore | Timestamp: 2025-11-24 10:30:00
```

#### Section Headers
```
╭────────────────────────────────────────────────────────────╮
│ Build Configuration                                        │
╰────────────────────────────────────────────────────────────╯

  Flake Path:          /etc/nixos#kernelcore
  Command:             switch
  Mode:                balanced
  Max Jobs:            4
  Cores per Job:       4
  Keep Going:          true
```

### Color Coding

| Color | Usage |
|-------|-------|
| **Green** | Success states, completions |
| **Red** | Errors, failures |
| **Yellow** | Warnings, high resource usage |
| **Cyan** | Section headers, info |
| **Blue** | Progress indicators |
| **Magenta** | Special markers |
| **Gray** | Dimmed text, timestamps |
| **White/Bold** | Important values |

### Icons

| Icon | Meaning |
|------|---------|
| 🚀 | Launch, starting |
| ✅ | Success, passed |
| ❌ | Failed, error |
| ⚠️  | Warning |
| ℹ️  | Information |
| ⚙️  | Configuration |
| 📦 | Package, store |
| 🔥 | Hot, active |
| ⏱️  | Time, duration |
| 📊 | Statistics, charts |
| 🧹 | Cleanup |
| 🔒 | Security, locked |
| 🛡️  | Shield, protection |
| 🔧 | Tools, maintenance |
| 🔍 | Search, inspect |
| ⚡ | Fast, performance |
| 💾 | Disk, storage |
| 🧠 | Memory |
| 🔬 | CPU, processing |

---

## 🎯 Usage Guide

### Basic Rebuild

```bash
# Standard rebuild with professional UI
rebuild

# Output:
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     🚀  NixOS Rebuild Professional Edition                     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

  Host: kernelcore | Timestamp: 2025-11-24 10:30:00

╭────────────────────────────────────────────────────────────╮
│ Build Configuration                                        │
╰────────────────────────────────────────────────────────────╯

  Flake Path:          /etc/nixos#kernelcore
  Command:             switch
  Mode:                balanced
  Max Jobs:            4
  Cores per Job:       4
  Keep Going:          true
  Log File:            /var/log/nixos-rebuild/rebuild_20251124_103000.log
  Metrics File:        ~/.cache/nixos-rebuild/metrics_20251124_103000.json

▸ System Metrics
────────────────────────────────────────────────────────

  🔬  CPU:
    Cores:             8 cores
    Load Average:      2.15

  🧠  Memory:
    Total:             16.0G
    Used:              8.2G (51%)

  💾  Disk (/nix):
    Total:             500G
    Used:              245G (49%)
    Store Size:        198G

╭────────────────────────────────────────────────────────────╮
│ Pre-flight Checks                                          │
╰────────────────────────────────────────────────────────────╯

  🔍 Checking flake path... ✅
  🔍 Checking flake.nix... ✅
  🔍 Checking flake.lock... ✅
  💾 Checking disk space... ✅ (49% used)
  🧠 Checking memory... ✅ (51% used)
  🔒 Checking root access... ✅

  Checks Passed:       6/6
  ⭐ All checks passed!

⚠️  This will modify your system configuration.
  Continue? [Y/n] y

╭────────────────────────────────────────────────────────────╮
│ Building System                                            │
╰────────────────────────────────────────────────────────────╯

🚀 Starting nixos-rebuild...

  This may take several minutes. Building derivations...

$ sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 4 --cores 4 --keep-going

[build output...]

╭────────────────────────────────────────────────────────────╮
│ Build Summary                                              │
╰────────────────────────────────────────────────────────────╯

✅ Build completed successfully!

  Status:              SUCCESS
  Duration:            3m 42s
  Log File:            /var/log/nixos-rebuild/rebuild_20251124_103000.log
  Metrics:             ~/.cache/nixos-rebuild/metrics_20251124_103000.json

▸ Resource Usage
────────────────────────────────────────────────────────

  CPU Load:            3.85
  Memory:              10.5G / 16.0G (65%)
  Disk:                247G / 500G (49%)

⚡ Configuration activated and live!
```

### Commands & Modes

```bash
# Different commands
rebuild switch         # Build and activate (default)
rebuild test           # Test without bootloader
rebuild boot           # Add to bootloader only
rebuild check          # Validate flake only
rebuild trace          # Debug with --show-trace

# Performance modes
rebuild switch balanced    # 4 jobs, 4 cores (default)
rebuild switch safe        # 1 job, 4 cores (low resource)
rebuild switch aggressive  # 6 jobs, 2 cores (fast)

# Combined
rebuild test safe          # Test build in safe mode
```

---

## 📊 Build Analytics

### Build History

```bash
build-history
bh  # Quick alias

# Output:
╔════════════════════════════════════════════════════════════════╗
║          NixOS Build History & Analytics              ║
╚════════════════════════════════════════════════════════════════╝

📊 Build Statistics
────────────────────────────────────────────────────────────────

  Total Builds:             42
  Successful:               39
  Failed:                   3
  Success Rate:             92%

⏱️  Build Performance
────────────────────────────────────────────────────────────────

  Fastest Build:            2m 15s
  Average Build:            4m 32s
  Slowest Build:            12m 45s

📋 Recent Builds (last 10)
────────────────────────────────────────────────────────────────

  ✓ 2025-11-24 10:30:00 switch (3m42s)
  ✓ 2025-11-24 08:15:00 switch (4m12s)
  ✗ 2025-11-23 22:40:00 switch (1m5s)
  ✓ 2025-11-23 18:20:00 test (3m55s)
  ✓ 2025-11-23 14:10:00 switch (4m8s)
  ...

Logs: /var/log/nixos-rebuild
Metrics: ~/.cache/nixos-rebuild
```

### Metrics Data

Each build creates a JSON metrics file:

```json
{
  "timestamp": "2025-11-24T10:30:00-03:00",
  "host": "kernelcore",
  "command": "switch",
  "mode": "balanced",
  "max_jobs": 4,
  "cores": 4,
  "duration_seconds": 222,
  "exit_code": 0,
  "system": {
    "cpu_cores": 8,
    "cpu_load": 3.85,
    "mem_total": 17179869184,
    "mem_used": 11274289152,
    "mem_percent": 65,
    "disk_total": 536870912000,
    "disk_used": 265231360000,
    "disk_percent": 49,
    "store_size": 212680949760
  },
  "log_file": "/var/log/nixos-rebuild/rebuild_20251124_103000.log"
}
```

---

## 📋 Log Management

### View Build Logs

```bash
build-logs
bl  # Quick alias

# Output:
╔════════════════════════════════════════════════════════════════╗
║          NixOS Build Logs                             ║
╚════════════════════════════════════════════════════════════════╝

Available Logs (15):

   1. 2025-11-24 10:30:00 (2.4M)
   2. 2025-11-24 08:15:00 (1.8M)
   3. 2025-11-23 22:40:00 (845K)
   4. 2025-11-23 18:20:00 (2.1M)
   5. 2025-11-23 14:10:00 (1.9M)
   ...

Commands:
  build-logs view [N]    View log N (default: latest)
  build-logs tail [N]    Tail log N (default: latest)
  build-logs clean       Remove old logs (>7 days)
```

### Log Commands

```bash
# View latest log
build-logs
build-logs view

# View specific log
build-logs view 3

# Tail latest log (follow)
build-logs tail

# Tail specific log
build-logs tail 5

# Clean old logs
build-logs clean
```

---

## 🔍 Real-time Monitoring

### Build Monitor

```bash
build-monitor
bm  # Quick alias

# Refresh interval (default: 2s)
build-monitor 5  # Refresh every 5 seconds

# Output:
╔════════════════════════════════════════════════════════════════╗
║          NixOS Build Monitor                          ║
╚════════════════════════════════════════════════════════════════╝

Refreshing every 2s... (Ctrl+C to exit)

🔬 CPU:
  Load Average: 4.32 / 8 cores

🧠 Memory:
  Used: 12.5G / 16G (78.1%)

💾 Disk (/nix):
  Used: 247G / 500G (49%)

📦 Nix Store:
  Size: 198G

⚙️  Active Builds:
  ● nixos-rebuild: 1 process(es)
  ● nix build: 3 process(es)
```

---

## 🎛️ Generation Management

### Advanced Generations View

```bash
generations
gens  # Quick alias

# Output:
╔════════════════════════════════════════════════════════════════╗
║          NixOS System Generations                     ║
╚════════════════════════════════════════════════════════════════╝

Current Generation: #43

All Generations:
────────────────────────────────────────────────────────────────

  40   2025-11-22 08:00:00
  41   2025-11-23 10:30:00
  42   2025-11-23 18:20:00
➜ 43   2025-11-24 10:30:00 (current)

────────────────────────────────────────────────────────────────

Storage:
  Total generations size: 12.5G

Commands:
  rollback               Rollback to previous generation
  cleanup                Remove old generations (>7 days)
  rebuild switch         Build new generation
```

---

## 🔧 Advanced Features

### Pre-flight Checks

Antes de cada build, são executados 6 checks:

1. **Flake Path** - Verifica se `/etc/nixos` existe
2. **Flake.nix** - Valida existência do arquivo
3. **Flake.lock** - Verifica lock file (warning se ausente)
4. **Disk Space** - Alerta se >90% usado
5. **Memory** - Alerta se >80% usado
6. **Root Access** - Verifica sudo sem senha

### Resource Tracking

Métricas coletadas durante cada build:

- **CPU**: Load average, número de cores
- **Memory**: Total, usado, percentual
- **Disk**: Total, usado, percentual do `/nix`
- **Store**: Tamanho do `/nix/store`
- **Duration**: Tempo de build em segundos
- **Exit Code**: Status do build

### Log Structure

Logs salvos em: `/var/log/nixos-rebuild/rebuild_YYYYMMDD_HHMMSS.log`

- Timestamp no nome do arquivo
- Output completo do `nixos-rebuild`
- Stderr capturado
- Formatação preservada

### Metrics Storage

Metrics salvos em: `~/.cache/nixos-rebuild/metrics_YYYYMMDD_HHMMSS.json`

- Formato JSON para fácil parsing
- Informações completas do build
- Métricas de sistema antes e depois
- Linkado ao log file correspondente

---

## 💡 Pro Tips

### Performance Optimization

```bash
# Heavy builds (ML, CUDA, large packages)
rebuild switch safe

# Quick rebuilds (small changes)
rebuild switch aggressive

# Standard usage
rebuild  # Defaults to balanced mode
```

### Monitoring During Builds

```bash
# Terminal 1: Start rebuild
rebuild

# Terminal 2: Monitor in real-time
build-monitor
```

### Analyzing Build Patterns

```bash
# Check your build history
build-history

# Find slow builds
build-history | grep "Slowest"

# Check success rate
build-history | grep "Success Rate"
```

### Log Analysis

```bash
# View failed builds
build-logs clean  # Remove successful builds

# Tail latest build (in another terminal)
build-logs tail

# Search for errors in logs
grep -i "error" /var/log/nixos-rebuild/rebuild_*.log
```

---

## 🐛 Troubleshooting

### Build Failed

```bash
# 1. Check the log
build-logs view 1

# 2. Try with trace
rebuild trace

# 3. Try safe mode
rebuild switch safe

# 4. Check pre-flight warnings
rebuild  # Will show warnings before build
```

### High Resource Usage

```bash
# Monitor resources
build-monitor

# Use safe mode
rebuild switch safe

# Clean old generations
cleanup
```

### Disk Space Issues

```bash
# Check store size
du -sh /nix/store

# Run cleanup
cleanup

# Remove old logs
build-logs clean
```

---

## 📚 File Locations

### Logs
- **Location**: `/var/log/nixos-rebuild/`
- **Format**: `rebuild_YYYYMMDD_HHMMSS.log`
- **Cleanup**: `build-logs clean` (removes >7 days)

### Metrics
- **Location**: `~/.cache/nixos-rebuild/`
- **Format**: `metrics_YYYYMMDD_HHMMSS.json`
- **Retention**: Manual cleanup

### Configuration
- **Module**: `/etc/nixos/modules/shell/aliases/nix/rebuild-advanced.nix`
- **Analytics**: `/etc/nixos/modules/shell/aliases/nix/analytics.nix`
- **Legacy**: `/etc/nixos/modules/shell/aliases/nix/system.nix`

---

## 🎯 Command Summary

### Rebuild Commands
```bash
rebuild              # Main command (professional UI)
rb                   # Quick alias
rebuild --help       # Show help
rebuild switch       # Build and switch
rebuild test         # Test without bootloader
rebuild boot         # Add to bootloader
rebuild check        # Validate flake
rebuild trace        # Debug mode
```

### Performance Modes
```bash
balanced             # 4 jobs, 4 cores (default)
safe                 # 1 job, 4 cores
aggressive           # 6 jobs, 2 cores
```

### Analytics
```bash
build-history        # Build statistics
bh                   # Quick alias
build-logs           # Log viewer
bl                   # Quick alias
build-monitor        # Real-time monitor
bm                   # Quick alias
generations          # Generation manager
gens                 # Quick alias
```

### Utilities
```bash
cleanup              # System cleanup
rollback             # Rollback generation
nix-size             # Check store size
```

---

## 🚀 Migration from Old System

### Old Commands → New Commands

| Old | New | Notes |
|-----|-----|-------|
| `nx-rebuild` | `rebuild` | Professional UI |
| `nx-rebuild-safe` | `rebuild switch safe` | Same functionality |
| `nx-rebuild-balanced` | `rebuild` | Now default |
| `nx-rebuild-test` | `rebuild test` | Professional UI |
| `nx-flake-check` | `rebuild check` | Integrated |

### What's New

1. **Professional UI** - Box drawing, colors, icons
2. **Pre-flight Checks** - Validation before build
3. **Metrics Collection** - JSON metrics for each build
4. **Build Analytics** - History, statistics, performance tracking
5. **Log Management** - Structured logs with timestamps
6. **Real-time Monitoring** - Live resource tracking
7. **Advanced Generation Manager** - Detailed generation info

### Compatibility

- All old aliases still work (`nx-*` commands)
- New system is additive, not breaking
- Can use both old and new commands
- Gradual migration supported

---

**Last Updated**: 2025-11-24
**Version**: 2.0.0 - Professional Edition
**Maintainer**: kernelcore
**Module**: `/etc/nixos/modules/shell/aliases/nix/rebuild-advanced.nix`
