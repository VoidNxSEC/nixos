# NixOS Rebuild Guide - Comandos Coloridos

> **Status**: Production Ready
> **Module**: `modules/shell/aliases/nix/rebuild-helpers.nix`
> **Version**: 1.0.0

---

## 🚀 Quick Start

### Comando Principal: `rebuild`

O comando `rebuild` é um wrapper colorido e intuitivo para `nixos-rebuild`:

```bash
# Rebuild padrão (balanced mode)
rebuild

# Equivalente a:
# sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 4 --cores 4
```

---

## 📋 Comandos Disponíveis

### Rebuild Modes

| Comando | Descrição | Uso |
|---------|-----------|-----|
| `rebuild` | Switch com configuração padrão | Uso diário |
| `rebuild switch` | Mesmo que `rebuild` | Explícito |
| `rebuild test` | Testa sem adicionar ao bootloader | Testes seguros |
| `rebuild boot` | Adiciona ao bootloader, ativa no próximo boot | Updates planejados |
| `rebuild check` | Apenas valida o flake | Verificação rápida |
| `rebuild trace` | Switch com `--show-trace` | Debug de erros |
| `rb` | Alias rápido para `rebuild` | Digitação rápida |

### Performance Modes

| Modo | Max Jobs | Cores | Uso |
|------|----------|-------|-----|
| `balanced` | 4 | 4 | **Padrão** - Balanceado |
| `safe` | 1 | 4 | Builds pesados, evita OOM |
| `aggressive` | 6 | 2 | Builds rápidos, mais CPU |

**Exemplos**:
```bash
# Safe mode - low resource usage
rebuild switch safe

# Aggressive mode - fast builds
rebuild switch aggressive

# Test com safe mode
rebuild test safe
```

---

## 🎨 Features Visuais

### Progress Indicators
- ⚙️  Configuration display
- 🚀 Build progress
- ✅ Success confirmation
- ❌ Error reporting
- ⚠️  Warnings

### Color Coding
- **Green** - Success messages
- **Red** - Errors
- **Yellow** - Warnings
- **Cyan** - Info messages
- **Blue** - Progress updates

### Interactive Prompts
```bash
$ rebuild

╔════════════════════════════════════════════════════════╗
║          NixOS Rebuild - kernelcore              ║
╚════════════════════════════════════════════════════════╝

⚙️  Configuration:
  Flake:      /etc/nixos#kernelcore
  Command:    switch
  Mode:       balanced
  Max Jobs:   4
  Cores:      4

⚠️  This will modify your system configuration.
Continue? [Y/n]
```

---

## 🔧 Utility Commands

### Generation Management

```bash
# List all system generations (colorized)
generations
gens  # Short alias

# Output:
╔════════════════════════════════════════════════════════╗
║          NixOS System Generations                ║
╚════════════════════════════════════════════════════════╝

System Generations:

  42   2025-11-23 10:30:00
➜ 43   2025-11-24 08:15:00 (current)
  44   2025-11-24 09:20:00

Commands:
  rollback           - Rollback to previous generation
  rebuild switch     - Build and activate new generation
```

### Rollback

```bash
# Rollback to previous generation
rollback

# Rollback to specific generation
sudo nixos-rebuild switch --rollback --generation 42
```

### System Cleanup

```bash
# Interactive cleanup with size reporting
nixos-cleanup
cleanup  # Short alias
```

**What it does**:
1. Shows current store size
2. Removes generations older than 7 days
3. Runs garbage collection
4. Optimizes store (deduplicates files)
5. Shows space saved

**Example output**:
```
╔════════════════════════════════════════════════════════╗
║          NixOS System Cleanup                    ║
╚════════════════════════════════════════════════════════╝

Store size before: 45G

🔍 Current generations: 15

⚠️  This will:
  1. Remove all generations older than 7 days
  2. Run garbage collection
  3. Optimize Nix store (deduplicate files)

Continue? [y/N] y

🧹 Removing old generations...
🗑️  Running garbage collection...
⚡ Optimizing store...

✅ Cleanup complete!
Store size before: 45G
Store size after:  38G

Generations: 15 → 8
```

---

## 📊 Quick Info Commands

```bash
# Check Nix store size
nix-size
du -sh /nix/store

# List generations
gens

# Show flake metadata
nix flake show

# Search packages
nx-search <package>
```

---

## 🎯 Common Workflows

### Daily Development

```bash
# Quick rebuild after config changes
rb

# Test changes without committing to bootloader
rebuild test

# Debug rebuild issues
rebuild trace
```

### Heavy Builds (ML packages, CUDA, etc.)

```bash
# Safe mode to prevent OOM
rebuild switch safe

# Or use offload (if desktop builder configured)
nx-rebuild-offload
```

### Before Rebooting

```bash
# Check configuration
rebuild check

# Build and add to bootloader (activate on next boot)
rebuild boot
```

### After Updates

```bash
# Check if everything works
rebuild test

# If OK, commit to bootloader
rebuild switch

# If issues, rollback
rollback
```

### Weekly Maintenance

```bash
# Update flake inputs
nix flake update

# Rebuild with updates
rebuild

# Clean old generations
cleanup
```

---

## 🐛 Troubleshooting

### Build Failed

```bash
# Get detailed trace
rebuild trace

# Check flake
rebuild check

# Try safe mode (less parallelism)
rebuild switch safe
```

### Out of Memory (OOM)

```bash
# Use safe mode
rebuild switch safe

# Or kill heavy processes first
# (see emergency aliases: emg-abort, emg-nuke)
```

### System Won't Boot After Rebuild

```bash
# At boot, select previous generation from bootloader
# Or from rescue shell:
sudo nixos-rebuild switch --rollback
```

### "Conflict with existing generation"

```bash
# Remove conflicting generations
sudo nix-env --delete-generations old

# Or cleanup old generations
cleanup
```

---

## 📚 Reference

### All Available Aliases

#### Rebuild Commands
```bash
rebuild              # Main command
rb                   # Quick alias
rebuild-safe         # rebuild switch safe
rebuild-test         # rebuild test
rebuild-boot         # rebuild boot
rebuild-trace        # rebuild trace
rebuild-check        # rebuild check
```

#### Generation Management
```bash
generations          # List generations
gens                 # Short alias
rollback             # Rollback to previous
```

#### Cleanup
```bash
nixos-cleanup        # Full cleanup
cleanup              # Short alias
nix-size             # Check store size
```

#### Classic Aliases (still available)
```bash
nx-rebuild           # Standard rebuild
nx-rebuild-safe      # Safe mode
nx-rebuild-balanced  # Balanced mode
nx-rebuild-test      # Test mode
nx-gc                # Garbage collection
nx-optimize          # Optimize store
```

---

## 🔗 Related Documentation

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Flakes**: https://nixos.wiki/wiki/Flakes
- **Module**: `/etc/nixos/modules/shell/aliases/nix/rebuild-helpers.nix`
- **Classic Aliases**: `/etc/nixos/modules/shell/aliases/nix/system.nix`

---

## 💡 Tips & Best Practices

### Performance
- Use **balanced mode** (default) for daily use
- Use **safe mode** for heavy packages (ML, CUDA)
- Use **aggressive mode** only for quick rebuilds

### Safety
- Always `rebuild check` before major changes
- Use `rebuild test` to verify before committing
- Keep at least 2-3 recent generations

### Maintenance
- Run `cleanup` weekly to free space
- Check `nix-size` periodically
- Review `generations` before cleanup

### Debugging
- Start with `rebuild check` for syntax errors
- Use `rebuild trace` for build failures
- Check `journalctl -xe` for runtime errors

---

**Last Updated**: 2025-11-24
**Maintained By**: NixOS declarative configuration
**Module**: `/etc/nixos/modules/shell/aliases/nix/rebuild-helpers.nix`
