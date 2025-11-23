# Architecture Tracking & Documentation

> **Purpose**: Rastrear evolução arquitetural do repositório NixOS
> **Method**: Auto-generated tree diagrams + manual annotations
> **Frequency**: Pre/post major changes, monthly snapshots

---

## 🎯 Overview

Este documento estabelece o processo de tracking da arquitetura do repositório `/etc/nixos` através de:

1. **Auto-generated trees**: Snapshots automatizados da estrutura
2. **Manual annotations**: Anotações sobre decisões arquiteturais
3. **Change tracking**: Comparação entre snapshots
4. **Integration**: Links com planos de refatoração

---

## 📁 Arquivos Gerados

### Primary Outputs

| File | Format | Purpose | Update Frequency |
|------|--------|---------|------------------|
| `ARCHITECTURE-TREE.txt` | UTF-8 text | Current tree (human-readable) | On-demand |
| `ARCHITECTURE-TREE.md` | Markdown | Current tree (documentation) | On-demand |
| `docs/architecture/snapshot-YYYYMMDD-HHMMSS.txt` | UTF-8 text | Versioned snapshots | Major changes |

### Supporting Files

| File | Purpose |
|------|---------|
| `docs/ARCHITECTURE-TRACKING.md` | This file - tracking methodology |
| `docs/ML-ARCHITECTURE-REFACTORING.md` | ML refactoring plan |
| `docs/DEV-DIRECTORY-SECURITY.md` | ~/dev security hardening |
| `CLAUDE.md` | Repository restructuring plan |

---

## 🔄 Workflow

### When to Generate

**Mandatory**:
- ✅ Before major refactoring (baseline)
- ✅ After major refactoring (validation)
- ✅ Before git tags/releases
- ✅ Monthly (first Sunday)

**Optional**:
- When requested by maintainer
- After significant module additions
- For documentation updates

### Generation Command

```bash
# Basic generation
bash scripts/generate-architecture-tree.sh

# With custom depth
MAX_DEPTH=8 bash scripts/generate-architecture-tree.sh

# Show hidden files
SHOW_HIDDEN=true bash scripts/generate-architecture-tree.sh

# Custom output location
REPO_ROOT=/path/to/repo bash scripts/generate-architecture-tree.sh
```

### Integration with Git

```bash
# Pre-refactoring snapshot
bash scripts/generate-architecture-tree.sh
git add ARCHITECTURE-TREE.{txt,md} docs/architecture/snapshot-*.txt
git commit -m "docs: pre-refactoring architecture snapshot"

# Perform refactoring
# ... make changes ...

# Post-refactoring snapshot
bash scripts/generate-architecture-tree.sh
git add ARCHITECTURE-TREE.{txt,md} docs/architecture/snapshot-*.txt
git commit -m "docs: post-refactoring architecture snapshot"

# Compare
diff docs/architecture/snapshot-20251122-*.txt docs/architecture/snapshot-20251123-*.txt
```

---

## 📊 Tracking Methodology

### Baseline Snapshots

**Purpose**: Establish reference points before major changes

**Process**:
1. Generate snapshot: `bash scripts/generate-architecture-tree.sh`
2. Tag in git: `git tag -a arch-baseline-YYYYMMDD -m "Architecture baseline"`
3. Document in this file (see section below)

**Example**:
```bash
# 2025-11-22: Pre-ML-Refactoring Baseline
bash scripts/generate-architecture-tree.sh
git tag -a arch-baseline-20251122 -m "Pre ML refactoring baseline"
```

### Change Tracking

**Compare snapshots**:
```bash
# Quick diff (directories only)
diff -u \
  <(grep -E '├──|└──|│' docs/architecture/snapshot-OLD.txt) \
  <(grep -E '├──|└──|│' docs/architecture/snapshot-NEW.txt)

# Full diff
diff -u docs/architecture/snapshot-{OLD,NEW}.txt
```

**Metrics to track**:
- Total files/directories
- Size changes (especially `modules/ml/`)
- New modules added
- Removed modules
- Relocated files

### Manual Annotations

Add annotations to snapshots for context:

```
# docs/architecture/annotations/20251122-ml-refactoring.md

## Snapshot: 2025-11-22 Pre-ML-Refactoring

### Motivation
- modules/ml/ is 3.8GB (bloated)
- Build artifacts committed
- Applications mixed with NixOS modules

### Expected Changes
- Remove unified-llm/ (→ ~/dev/securellm-bridge)
- Remove Security-Architect/ (merge or separate)
- Remove offload/api/ (→ ~/dev/ml-offload-api)
- modules/ml/ should be ~100KB after

### Success Criteria
- 97% size reduction
- No build artifacts in git
- All services still functional
```

---

## 📈 Historical Snapshots

### Baseline: Pre-ML-Refactoring (2025-11-22)

**Stats**:
- Total files: ~1,200
- Total directories: ~250
- Repository size: 3.9GB
- modules/ml/ size: 3.8GB
- .nix files: ~180

**Key areas**:
- modules/ml/unified-llm/ (2.9GB) - to be extracted
- modules/ml/Security-Architect/ (354MB) - to be evaluated
- modules/ml/offload/ (540MB) - to be refactored

**Snapshot**: `docs/architecture/snapshot-20251122-000000.txt`

**Decisions**:
- Separate applications from NixOS modules
- Use flake inputs pattern
- Implement ~/dev/ security hardening

**Related docs**:
- ML-ARCHITECTURE-REFACTORING.md
- DEV-DIRECTORY-SECURITY.md

---

### Expected: Post-ML-Refactoring (2025-11-XX)

**Target Stats**:
- Repository size: ~200MB (95% reduction)
- modules/ml/ size: ~100KB (97% reduction)
- New repos: 2 (securellm-bridge, ml-offload-api)

**Expected structure**:
```
modules/ml/
├── default.nix              [NEW - aggregator]
├── llama.nix                [KEPT]
├── models-storage.nix       [KEPT]
├── ollama-gpu-manager.nix   [KEPT]
├── mcp.nix                  [REFACTORED]
├── securellm-bridge.nix     [NEW - thin wrapper]
├── ml-offload.nix           [NEW - thin wrapper]
└── offload/
    ├── backends/default.nix [KEPT]
    ├── model-registry.nix   [KEPT]
    └── vram-intelligence.nix [KEPT]
```

**Validation**:
- [ ] All services start: llamacpp, ollama, mcp-server, ml-offload-api
- [ ] Flake inputs work
- [ ] Builds don't OOM
- [ ] Repository size target met

---

## 🔍 Analysis Tools

### Size Analysis

```bash
# Top 20 largest directories
du -h modules/ | sort -hr | head -20

# .nix files by size
find modules/ -name '*.nix' -exec du -h {} + | sort -hr | head -20

# Build artifacts check (should be empty after cleanup)
find . -name target -o -name node_modules -o -name build | grep -v .git
```

### Structure Validation

```bash
# Check for modules without default.nix
for dir in modules/*/; do
  if [ ! -f "$dir/default.nix" ]; then
    echo "Missing default.nix: $dir"
  fi
done

# Check for orphaned modules (not imported anywhere)
# (requires manual review)
```

### Diff Tools

```bash
# Compare two snapshots (structural changes only)
diff -u \
  <(grep -v '^  ' docs/architecture/snapshot-OLD.txt | grep -E '^[├└│]') \
  <(grep -v '^  ' docs/architecture/snapshot-NEW.txt | grep -E '^[├└│]')

# Show size changes
diff -u \
  <(grep 'size:' docs/architecture/snapshot-OLD.txt) \
  <(grep 'size:' docs/architecture/snapshot-NEW.txt)
```

---

## 🎨 Tree Diagram Features

### UTF-8 Box-Drawing

**Characters used**:
- `├──` - Middle branch
- `└──` - Last branch
- `│` - Vertical line
- `/` - Directory indicator
- `*` - Executable indicator

**Example**:
```
modules/
├── ml/
│   ├── llama.nix
│   ├── models-storage.nix
│   └── unified-llm/
│       ├── Cargo.toml
│       └── crates/
│           ├── core/
│           └── security/
└── security/
    └── audit.nix
```

Much more elegant than ASCII:
```
modules/
|-- ml/
|   |-- llama.nix
|   `-- unified-llm/
`-- security/
```

### Filters & Exclusions

**Always excluded**:
- `.git/` - Git internals
- `result*` - Nix build outputs
- `*.iso`, `*.qcow2` - Images
- `target/` - Rust build artifacts
- `node_modules/` - NPM dependencies
- `build/` - Build outputs
- `archive/` - Archived code

**Configurable**:
- `MAX_DEPTH` - Tree depth (default: 5)
- `SHOW_HIDDEN` - Show dotfiles (default: false)

---

## 📋 Maintenance Checklist

### Monthly (First Sunday)

- [ ] Generate snapshot: `bash scripts/generate-architecture-tree.sh`
- [ ] Commit: `git add ARCHITECTURE-TREE.* docs/architecture/snapshot-*.txt`
- [ ] Review size metrics
- [ ] Check for build artifacts
- [ ] Update this document if structure changed

### Pre-Refactoring

- [ ] Generate baseline snapshot
- [ ] Create git tag: `arch-baseline-YYYYMMDD`
- [ ] Document motivation and expected changes
- [ ] Save in `docs/architecture/annotations/`

### Post-Refactoring

- [ ] Generate new snapshot
- [ ] Compare with baseline: `diff -u snapshot-{old,new}.txt`
- [ ] Validate metrics (size reduction, file counts)
- [ ] Update this document with actual changes
- [ ] Create git tag: `arch-post-refactor-YYYYMMDD`

### Quarterly

- [ ] Review snapshot history
- [ ] Prune old snapshots (keep quarterly + major changes)
- [ ] Update methodology if needed
- [ ] Generate summary report

---

## 🔗 Integration with Refactoring Plans

### ML Refactoring Plan

**Before**: Generate baseline
```bash
bash scripts/generate-architecture-tree.sh
# Save as: docs/architecture/snapshot-ml-pre-refactor.txt
```

**During**: Track progress
- Phase 1 complete → snapshot
- Phase 2 complete → snapshot
- etc.

**After**: Validate
```bash
bash scripts/generate-architecture-tree.sh
# Compare with baseline
diff -u docs/architecture/snapshot-ml-{pre,post}-refactor.txt
```

**Metrics**:
- Target: 3.8GB → 100KB
- Actual: (to be measured)

### ~/dev Security

Track `~/dev/` structure (separate from /etc/nixos):

```bash
# Generate tree for ~/dev
tree -L 3 --charset utf-8 -I 'target|node_modules|build' ~/dev \
  > docs/architecture/dev-directory-snapshot-$(date +%Y%m%d).txt
```

---

## 📚 Resources

### Scripts
- `scripts/generate-architecture-tree.sh` - Main generator
- `scripts/generate-tree-diagram.sh` - Legacy (ASCII only)

### Documentation
- `ARCHITECTURE-TREE.txt` - Current structure (UTF-8)
- `ARCHITECTURE-TREE.md` - Current structure (Markdown)
- `docs/architecture/` - Versioned snapshots
- This file - Tracking methodology

### External Tools
- `tree` - Tree generation (required)
- `diff` - Snapshot comparison
- `du` - Size analysis

---

**Maintained by**: kernelcore
**Last updated**: 2025-11-22
**Version**: 1.0.0
