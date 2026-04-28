# Changelog — Commits b7fc104, a2b22cd, af0b0dc

**Data**: 2026-04-27  
**Branch**: main

---

## Commit 1 — `b7fc104` · "test: trigger github actions and apply recent config changes"
**Horário**: 02:45 -0300  
**Arquivos**: `.gitignore`, `flake.lock`, `configuration.nix`, `home.nix`, `llama-cpp-swap.nix`, `gpu-orchestration.nix`

### .gitignore
- Adicionado `.claude/settings.local.json` ao ignore

### flake.lock
- Update em massa de vários inputs (408 linhas alteradas)

### configuration.nix
- **llama-swap · perfil `coder`**: modelo trocado para `HauhauCS_Qwen3.5-9B`, gpuLayers 40 → 42
- **llamacpp-swap**: `mlock = true` → `false`, adicionado `extraFlags = []`
- **forgejo**: `publicUrl` de `https://forgejo.voidnx.com/` → `http://localhost:3002/`

### home.nix
- **Spooknix keybind**: `SUPER, S` → `SUPER, R`
- **Neovim symlink**: `.config/nvim` desabilitado (comentado)

### llama-cpp-swap.nix
- `n_gpu_layers` default: 45 → 37
- `embeddings` default: `false` → `true`

### gpu-orchestration.nix
- Migração de `llamacpp-turbo` → `llamacpp-swap` em todos os targets, scripts e status checks
- Porta de acesso LlamaCPP atualizada: `8080` → `8081`
- Limpeza de comentários mortos

---

## Commit 2 — `a2b22cd` · "update: lock file"
**Horário**: 02:57 -0300  
**Arquivos**: `flake.lock`, `hosts/kernelcore/configuration.nix`

### flake.lock
| Input | Rev anterior | Rev novo |
|---|---|---|
| `rust-overlay` (oxalica) | `e65c31bc` | `a6cb2224` |
| `securellm-mcp` | `ae463c9` (revCount 147) | `8d28282` (revCount 148) |

### configuration.nix
- **llama-swap · perfil `coder`**: modelo trocado de `DarkSapling-V2-Ultra-Quality-7B` para `HauhauCS_Qwen3.5-9B-Uncensored-Q4_K_M`

---

## Commit 2 — `af0b0dc` · "checkpoint: investigating issues"
**Horário**: 09:11 -0300  
**Arquivos**: `flake.lock`, `hosts/kernelcore/configuration.nix`, `modules/ai/ml-ops-api/default.nix`

### flake.lock — inputs bumped
| Input | Rev anterior | Rev novo |
|---|---|---|
| `adr-ledger` (local path) | `1777236975` | `1777286959` |
| `aquamarine` (hyprwm) | `9a1ca6b8` | `648a13d0` |
| `home-manager` | `6012cf1f` | `7f8bbc93` |
| `hyprland` | `b65714e3` (revCount 7171) | `80763b13` (revCount 7187) |
| `hyprutils` | `eedd6080` | `fa3992be` |
| `hyprwayland-scanner` | `4c2fcc06` | `fec9cf1a` |
| `niri-flake` | `535ebbe0` | `2bb22af2` |
| `niri-unstable` | `74d2b186` | `a85b9229` |
| `nixpkgs-stable` | `10e7ad5b` | `a4bf0661` |
| `nixpkgs_5` | `b12141ef` | `0726a0ec` |
| `xdg-desktop-portal-hyprland` | `4a293523` | `ecfcdcc7` |

### configuration.nix
- **GitHub Runner**: migrado de runner por-repo (`VoidNxSEC/nixos`) para runner org-level (`VoidNxSEC`) — cobre todos os repos automaticamente, labels: `linux`, `gpu`, `nix`
- **gpu-orchestration**: `enable = true` → `enable = false`
- **spooknix**: `enable = true` → `enable = false`

### modules/ai/ml-ops-api/default.nix — refactor completo
Módulo reescrito de Python/FastAPI para gateway Rust (`ml-offload-api`):

| Aspecto | Antes | Depois |
|---|---|---|
| Runtime | Python FastAPI / Triton / vLLM / Rust enum | Binário Rust (`cfg.package`) |
| Porta padrão | 8080 | 9000 |
| Usuário | `ml-ops` | `ml-offload` |
| Suporte K8s | Opções de `kubernetes.serviceType`, `replicaCount` | Removido |
| GPU config | `gpu.enable`, `gpu.count`, `runtimeClass` | Removido |

**Novas options adicionadas**:
- `host` — bind address
- `corsEnabled` — CORS para dev local
- `dataDir`, `modelsPath`, `dbPath` — storage
- `llamacppUrl`, `vllmUrl` — backends
- `apiKeysSecretFile` — auth via sops-nix EnvironmentFile
- `rateLimitRpm` — rate limiting por chave
- `orchestrator.workers`, `maxConcurrent`, `timeoutSecs` — pool de workers
- `natsUrl` — event publishing (opcional)
- `resources.memoryMb`, `cpuPercent` — limites de recurso

**Hardening systemd adicionado**: `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`, `ProtectHome`

---

## Contexto — Bug dos 50 GiB

O commit `a2b22cd` bumped `securellm-mcp` de revCount 147 → 148. Esse novo rev:
1. Tinha `npmDepsHash` desatualizado (`picomatch 4.0.3` → `4.0.4` via tinyglobby)
2. Ao ser combinado com o estado do flake onde `inputs.spider-nix.follows` estava comentado, o securellm-mcp puxava seu próprio `spider-nix` que trazia uma cópia duplicada de `nixpkgs` — causando ~41 GiB de download extra

**Fix aplicado**: restaurado `inputs.spider-nix.follows = "spider-nix"` no `flake.nix`, removido o pin de rev, atualizado para `securellm-mcp 2.1.0` com hash correto.
