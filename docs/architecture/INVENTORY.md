# Levantamento Completo do Repositório NixOS (INVENTORY)

> **Data do levantamento**: 2026-07-11
> **Branch**: main (commit base: `57617bbd`)
> **Metodologia**: varredura exaustiva de flake.nix, modules/ (292 arquivos .nix), hosts/, home-manager, lib/, overlays/ e diretórios auxiliares, com grep direto nas declarações de `options.*` para classificação de namespaces.
> **Documento par**: [TOPOLOGY.md](TOPOLOGY.md) — topologia definitiva proposta. Os problemas registrados aqui (P1–P9) são referenciados lá pelas mesmas etiquetas.

---

## 1. Sumário Executivo

| Métrica | Valor |
|---|---|
| Arquivos `.nix` em `modules/` | **292** (21 categorias, todas com `default.nix`) |
| Definições de options | **~1.312** (1.076 `mkOption` + 236 `mkEnableOption`) |
| Namespaces de options em uso | **12+** (`kernelcore.*`, `services.*`, `programs.*`, `shell.*`, `voidnxlabs.*`, `spectre.*`, `ai.*`, `modules.*`, `system.*`, `security.*`, `hardware.*`, `nix.*`) |
| Declarações de options **fora** de `kernelcore.*` | **61** (ver §5) |
| `hosts/kernelcore/configuration.nix` | **1.479 linhas** (monolítico) |
| home-manager (`hosts/kernelcore/home/`) | **29 arquivos .nix, ~9.800 linhas** |
| Inputs do flake | **~20 ativos + 8 comentados** |
| nixosConfigurations | 3 (`kernelcore`, `kernelcore-iso`, `k8s-node`) |
| Specialisations | 8 (niri comentada) |
| Módulos de config pura (sem options) | ~80 arquivos |
| TODOs/FIXMEs em modules/ | 10 (1 CRITICAL) |

**Diagnóstico em uma frase**: a estrutura de diretórios está boa (21 categorias, todas agregadas), mas os **namespaces de options estão fragmentados**, há **duplicações de módulos** e o **configuration.nix do host acumula implementação** que pertence a `modules/`.

---

## 2. Flake

**Arquivo**: `flake.nix` (407 linhas, ~19 KB) · lock: `flake.lock` (38 KB)

### 2.1 Inputs

| Input | Origem | Follows | Status |
|---|---|---|---|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-unstable` | — | ativo |
| `sops-nix` | `github:Mic92/sops-nix` | — | ativo |
| `flake-utils` | `github:numtide/flake-utils` | — | ativo |
| `flake-parts` | `github:hercules-ci/flake-parts` | — | ativo |
| `home-manager` | `github:nix-community/home-manager` | nixpkgs | ativo |
| `nixos-hardware` | `github:NixOS/nixos-hardware/master` | — | ativo |
| `nix-colors` | `github:misterio77/nix-colors` | — | ativo |
| `hyprland` | `git+https://github.com/hyprwm/Hyprland?submodules=1` | nixpkgs | ativo |
| `niri` | `github:sodiboo/niri-flake` | nixpkgs | ativo (módulo NixOS comentado no flake) |
| `securellm-mcp` | `github:VoidNxSEC/securellm-mcp` | nixpkgs, spider-nix | ativo |
| `securellm-bridge` | `github:VoidNxSEC/securellm-bridge` | nixpkgs | ativo |
| `cognitive-vault` | `github:VoidNxSEC/cognitive-vault` | nixpkgs | ativo |
| `spider-nix` | `github:VoidNxSEC/spider-nix` | nixpkgs | ativo |
| `i915-governor` | `github:VoidNxSEC/i915-governor` | nixpkgs | ativo |
| `swissknife` | `github:VoidNxSEC/swissknife` | nixpkgs | ativo |
| `arch-analyzer` | `github:VoidNxSEC/arch-analyzer` | nixpkgs | ativo |
| `spooknix` | `github:VoidNxSEC/spooknix` | nixpkgs | ativo |
| `actions-tv` | `github:VoidNxSEC/actions-tv` | nixpkgs | ativo |
| `ai-agent-os` | `github:VoidNxSEC/ai-agent-os` | nixpkgs | ativo |
| `ml-ops-api`, `vmctl`, `mercury`, `venus`, `owasaka`, `phantom`, `mlx-mcp`, `spider-nix-network` | — | — | **comentados** (estabilização) |

### 2.2 Outputs

- **`nixosModules.default`** — importa `./modules` + overlays + `allowUnfree`.
- **`templates.minimal`** (= `templates.default`) — `templates/minimal/`.
- **`packages.${system}`** (de `lib/packages.nix`): `vm-image`, `iso`, `securellm-mcp`, e 9 imagens Docker (`image-app`, `image-cuda-runtime`, `image-ollama`, `image-python-ml`, `image-nodejs-dev`, `image-go-dev`, `image-postgres-dev`, `image-nginx-proxy`, `image-redis`).
- **`devShells.${system}`** (de `lib/shells.nix`): `default`, `python`, `node`, `rust`, `infra`, `cuda` — cada shell carrega secrets via SOPS (`secrets/${ENV}.env.enc`).
- **`checks.${system}`**: `fmt` (nixfmt), `mcp-server`. Builds pesados (iso/vm/docker) comentados por performance.
- **`formatter.${system}`**: `nixfmt-tree`.

### 2.3 nixosConfigurations

**`kernelcore`** (desktop principal):
```
overlays + allowUnfree
inputs.hyprland.nixosModules.default
./hosts/kernelcore/hardware-configuration.nix
./hosts/kernelcore                      # default.nix → users/
./hosts/kernelcore/configuration.nix
self.nixosModules.default               # → ./modules (tudo)
sops-nix.nixosModules.sops
home-manager.nixosModules.home-manager  # users.kernelcore = home/home.nix
inputs.spooknix.nixosModules.default
./profiles/k8s-lab.nix
```
- `specialArgs = { inherit inputs; colors = nix-colors; }`
- home-manager: `useGlobalPkgs`, `useUserPackages`, `sharedModules` = [spooknix HM, actions-tv waybar], backup custom com timestamp.

**`kernelcore-iso`**: installation-cd-minimal + sops + `./hosts/kernelcore`.

**`k8s-node`**: overlays + `./hosts/k8s-node/configuration.nix` + sops + home-manager.

---

## 3. Árvore da Raiz — Avaliação

| Diretório | Arquivos | Tamanho | Propósito | Avaliação |
|---|---|---|---|---|
| `modules/` | 350 (292 .nix) | 17M | Módulos do sistema (21 categorias) | ✅ ok — reorganizar internamente |
| `hosts/` | 80 | 2.9M | Configs por máquina + specialisations | ⚠️ configuration.nix monolítico; `k8s-original/` arquivado com `.zip` |
| `docs/` | 242 | 3.6M | Documentação | ✅ ok — consolidar relatórios gerados |
| `scripts/` | 167 | 1.9M | Scripts operacionais | ⚠️ volumoso; `__pycache__/` versionado |
| `skills/` | 30 | 468K | Skills do Claude Code | ✅ ok |
| `templates/` | 13 | 204K | Templates de configuração | 🔴 lixo iterativo (`fix-sudo{,2,3}.nix`, `desktop-cfg*`) |
| `secrets/` | 24 | 68K | SOPS (yaml criptografados) | ✅ ok — vários placeholders vazios e backups soltos |
| `tests/` | 11 | 72K | Testes (buildbot, integração, tailscale) | ✅ ok — subutilizado |
| `overlays/` | 7 | 32K | Overlays | ⚠️ agregador vazio (tudo comentado/desativado) |
| `lib/` | 4 | 32K | packages.nix, shells.nix, shell.nix, python.nix | ✅ ok |
| `nix/` | 6 | 48K | Utilitários misc (aliases, ssh, gitlab) | 🔴 propósito difuso — realocar |
| `pkgs/` | 1 | 8K | `securellm-mcp.nix` | ⚠️ 1 arquivo só — ok manter como convenção |
| `profiles/` | 1 | 12K | `k8s-lab.nix` (relaxa hardening p/ lab) | ⚠️ categoria órfã — mover para modules/ ou specialisation |
| `flakes/` | 1 | 8K | Exemplos de inputs | 🔴 realocar para docs/ ou remover |
| `home/` | 1 | 12K | `niri.nix` solto | 🔴 duplica `hosts/kernelcore/home/niri/` — remover/consolidar |
| `ux/` | 2 | 24K | Especificações de UX | ⚠️ mover para docs/ |
| `.claude/`, `.github/`, `.gitea/`, `.githooks/`, `.schema/` | — | — | Tooling/CI | ✅ ok |

**Não existem** repositórios git aninhados, submodules, nem os diretórios legados `nixtrap/`, `sec/`, `reports/`, `journal/` citados no CLAUDE.md do projeto (→ **P9**: documento desatualizado).

Arquivos `.nix` soltos na raiz: apenas `flake.nix` ✅.

---

## 4. Inventário de `modules/` (21 categorias)

Entry point: `modules/default.nix` (75 linhas) importa as 21 categorias.
Legenda de tipo: **O** = define options · **C** = config pura (sem options) · **A** = agregador.

### 4.1 applications/ (15 arquivos)

| Arquivo | Namespace | Tipo | Obs |
|---|---|---|---|
| `default.nix` | — | A | |
| `brave-hardened.nix` (21K) | `voidnxlabs.brave-hardened` | O | 🔴 namespace avulso; duplica brave-secure (**P2, P3**) |
| `brave-secure.nix` | `programs.brave-secure` | O | 🔴 duplicação Brave (**P3**) |
| `chromium.nix` | `services.chromiumOrg` | O | 🔴 namespace errado p/ app (**P1**) |
| `chromium-log-suppression.nix` | `kernelcore.chromium` | O | sobrepõe host (**P5**) |
| `electron-tuning.nix` | — | C | 🔴 v1 deprecated (**P3**) |
| `electron-tuning-v2.nix` | `kernelcore.electron` | O | canônico |
| `firefox-privacy.nix` | `programs.firefox-privacy` | O | |
| `nemo-full.nix` | `programs.nemo` | O | |
| `neoland.nix` | `programs.neoland` | O | |
| `vscode-remote-ssh.nix` | `programs.vscode-remote-ssh` | O | |
| `vscode-secure.nix` | `programs.vscode-secure` | O | par com vscodium (**P3**) |
| `vscodium-secure.nix` | `programs.vscodium-secure` | O | |
| `zellij.nix` | `kernelcore.applications` | O | |
| `cache-optimization.nix` | — | C | |

### 4.2 audio/ (3)

| Arquivo | Namespace | Tipo |
|---|---|---|
| `default.nix` | — | A |
| `production.nix` (646 linhas) | `modules.audio.production` | O 🔴 namespace avulso (**P2**) |
| `video-production.nix` | `modules.audio.videoProduction` | O 🔴 (**P2**) |

### 4.3 blockchain/ (4 + algorand/)

`default.nix` (A) · `chainscope.nix` (`kernelcore.blockchain.chainscope`, O) · `sops-secrets.nix` (C) · `algorand/default.nix` (`kernelcore.blockchain.algorand`, O) · `algorand/dao.nix` — **TODO CRITICAL** na linha 1 (**P8**).

### 4.4 containers/ (7)

| Arquivo | Namespace | Tipo | Obs |
|---|---|---|---|
| `default.nix` | — | A | |
| `docker.nix` | `services.chromiumOrg` (!) | O | 🔴 namespace incoerente com o conteúdo (**P1**) |
| `podman.nix`, `nixos-containers.nix`, `dev-containers.nix`, `docker-hub.nix` | `kernelcore.containers` | O | |
| `ml-containers.nix` (505 linhas) | `kernelcore.ml` | O | grande; cruza categoria ml/ |

### 4.5 debug/ (5)

`default.nix` (A) · `tools-integration.nix` (`kernelcore.swissknife`, O) · `debug-init.nix`, `io-monitor.nix`, `test-init.nix` (C).

### 4.6 desktop/ (4 + hyprland-modular/)

| Arquivo | Namespace | Tipo | Obs |
|---|---|---|---|
| `default.nix` | — | A | |
| `hyprland.nix` | `services.hyprland-desktop` | O | 🔴 duplica hyprland-modular (**P1, P3**); o home usa este toggle |
| `hyprland-performance.nix` | `kernelcore.hyprland` | O | |
| `i3-lightweight.nix` (567 linhas) | `kernelcore.desktop.i3` | O | |
| `hyprland-modular/default.nix` (852 linhas) | `programs.hyprland-modular` | O | 🔴 monólito + subdirs bindings/lib/plugins/profiles/rules/themes (**P4**); TODO syntax 0.53+ em `rules/default.nix:389` |

### 4.7 development/ (7)

`default.nix` (A) · `cicd.nix` (`kernelcore.ci`) · `claude-profiles.nix`, `environments.nix`, `jupyter.nix` (`kernelcore.development`) · `git-forge-tools.nix` (`programs.git-forge-tools`) · `ssh-git-forges.nix` (`programs.ssh.gitForges` — ⚠️ estende árvore upstream `programs.ssh`). Os dois últimos também são importados diretamente pelo **home-manager** (`home.nix`), cruzando fronteira sistema/usuário (**P5**).

### 4.8 devops/ (2 + gitlab-cli/)

`default.nix` (A) · `gitlab-cli/default.nix` (`programs.glab-custom`, O) + `lib/`.

### 4.9 hardware/ (9 + i915-governor/ + laptop-defense/)

| Arquivo | Namespace | Tipo | Obs |
|---|---|---|---|
| `default.nix` | — | A | |
| `bluetooth.nix` | `kernelcore.bluetooth` | O | fora de `kernelcore.hardware.*` |
| `intel.nix`, `lenovo-throttled.nix`, `nvidia.nix`, `thermal-profiles.nix`, `wifi-optimization.nix` | `kernelcore.hardware` | O | |
| `trezor.nix` | `hardware.trezor` | O | ⚠️ namespace upstream-like custom (**P2**) |
| `i915-governor/default.nix` | `services.i915-governor` | O | 🔴 (**P1**) |
| `laptop-defense/flake.nix` (760 linhas) | `hardware.thermalProtection` | O | 🔴 flake aninhado como módulo + monólito (**P2, P4**) |
| `laptop-defense/mcp-integration.nix` | `services.mcp.laptopDefense` | O | 🔴 (**P1**) |
| `laptop-defense/rebuild-hooks.nix` | `hardware.rebuildHooks` | O | ⚠️ (**P2**) |

### 4.10 kubernetes/ (6)

| Arquivo | Namespace | Obs |
|---|---|---|
| `default.nix` | — | A |
| `k3s-cluster.nix` | `services.k3s-cluster` | 🔴 (**P1**) |
| `cilium-cni.nix` | `services.cilium-cni` | 🔴 (**P1**) |
| `kind.nix` | `services.kind-lab` | 🔴 (**P1**) |
| `longhorn-storage.nix` | `services.longhorn-storage` | 🔴 (**P1**) |
| `spectre-k8s.nix` | `spectre.k8s` | 🔴 namespace avulso (**P2**) |

### 4.11 ml/ (35+ arquivos, 5 subárvores)

**agents/** — `ecosystem.nix` (`ai.ecosystem` 🔴 **P2**) · `cerebro/` (`services.cerebro`) · `neotron/` (`services.neotron`) · `phantom/` (`services.phantom`) · `ml-ops-api/` (`services.ml-ops-api`) · `neoland/` 8 arquivos (`services.neoland-agents|-checkpoints|-control-plane|-dspy-pipeline|-ledger-subscriber|-loki|-vector` — todos 🔴 **P1**) · `agent-hub/` (capabilities, core/flake.nix, infra, proto — flake aninhado).

**infrastructure/** — `model-profiles.nix`, `storage.nix`, `vram/monitoring.nix` (`kernelcore.ml` ✅) · TODOs: GPU scheduler (`vram/default.nix:14`), extração CUDA (`hardware/default.nix:13`) (**P8**).

**services/** — `llama-cpp-swap.nix` (682 linhas, `services.llamacpp-swap`) · `llama-cpp-turbo.nix` (`services.llamacpp-turbo`) · `llama-model-router.nix` (`services.llamacpp-model-router`) · `vllm.nix` (`services.vllm`) · `tabbyapi.nix` (`services.tabbyapi`) — todos 🔴 **P1**; cinco backends de inferência sem seletor comum (**P3**).

**orchestration/** — `api/flake.nix` (`services.ml-offload-api` 🔴 **P1**).

**integrations/** — `mcp/` (`services.mcp` base), `neovim/` (TODO extração).

### 4.12 network/ (15)

Todos em `kernelcore.network.*` ✅ (bridge, dns-resolver, spider-network-proxy, dns/adguard-home, monitoring/tailscale-monitor, proxy/nginx-public, proxy/nginx-tailscale, proxy/tailscale-services, security/firewall-zones, vpn/nordvpn, vpn/tailscale, vpn/wireguard). Config pura: `vpn/tailscale-desktop.nix`, `vpn/tailscale-laptop.nix` (**P6**).

### 4.13 packages/ (30+)

Todos em `kernelcore.packages.*` ✅ (appflowy, brev-cli, claude, custom/gemini-antigravity, f5-tts, gemini/*, hammer-ai, hubstaff, lynis, zellij). Config pura: `antigravity/{security,tuning,tuning-fixed}.nix` (⚠️ tuning vs tuning-fixed = iteração não resolvida), `lib/sandbox.nix`, `gemini/{build-gemini,builder,gemini-cli}.nix` (**P6**). TODOs: prefetch npm (`gemini-antigravity.nix:101`), sandbox de rede (`antigravity/security.nix:66`).

### 4.14 programs/ (4)

`default.nix` (A) · `cognitive-vault.nix` (`programs.cognitive-vault`) · `phantom.nix` (`programs.phantom` — ⚠️ colide conceitualmente com `ml/agents/phantom/` = `services.phantom`) · `vmctl.nix` (**959 linhas**, `programs.vmctl` — 🔴 maior módulo do repo, **P4**; ⚠️ existe também `virtualization/vmctl.nix`).

### 4.15 secrets/ (16)

Todos em `kernelcore.secrets.*` ✅ — anthropic, api-keys, aws-bedrock, blockchain, certificates, ci, forgejo, gcp-ml, gitea, github, gitlab, grok, k8s, sops-config, tailscale. **Categoria exemplar** — padrão a replicar.

### 4.16 security/ (18 + soc/ com 17+)

**Base (prevenção)**:

| Arquivo | Namespace | Tipo | Obs |
|---|---|---|---|
| `aide.nix`, `audit.nix`, `clamav.nix`, `hardening.nix`, `pam.nix`, `tls.nix`, `keyring.nix`, `nix-daemon.nix`, `auto-upgrade.nix`, `dev-directory-hardening.nix`, `packages.nix` | `kernelcore.security.*` | O | ✅ |
| `ssh.nix` | `kernelcore.ssh` | O | fora de `kernelcore.security` |
| `kernel.nix` | `security.hardening` | O | ⚠️ 20+ `mkForce` intencionais (prioridade sobre defaults nixpkgs) |
| `boot.nix`, `network.nix`, `compiler-hardening.nix`, `sec-hardening.nix` | — | C | (**P6**) |

**soc/ (detecção)**: `options.nix` centraliza `kernelcore.soc.*` ✅ · edr/ (edr, fim) · ids/ (suricata 508 linhas, threat-intel) · siem/ (log-aggregator, opensearch, wazuh) · network/ (dns-monitor, netflow) · dashboards/grafana · alerting/ · anduril/ · tools.nix (11K, C). **Exceção**: `edr-infrastructure/` é sub-projeto com flake próprio e namespaces `services.edr.*` + `security.hardening.{apparmor,seccomp}.edr` (🔴 **P1/P2**).

Separação prevenção (security/) vs detecção (soc/) está **bem desenhada**; sem conflitos de mkForce entre elas.

### 4.17 services/ (15 + gitlab-duo/)

| Arquivo | Namespace | Obs |
|---|---|---|
| `buildbot-local.nix`, `github-runner.nix`, `gpu-orchestration.nix`, `laptop-builder-client.nix`, `laptop-offload-client.nix`, `mobile-workspace.nix`, `mosh.nix` | `kernelcore.services` | ✅ |
| `config-auditor.nix` | `services.config-auditor` | 🔴 (**P1**) |
| `forgejo.nix` | `services.forgejo.integration.*` | ⚠️ **estende deliberadamente** a árvore upstream `services.forgejo` (22 sub-options). Caso especial no mapa de migração |
| `gitea-showcase.nix` | `services.gitea-showcase` | 🔴 (**P1**) |
| `gitlab-duo/default.nix` | `services.gitlabDuo` | 🔴 (**P1**) |
| `mcp-server.nix` (501 linhas) | `services.securellm-mcp` | 🔴 (**P1, P4**) |
| `offload-server.nix` | `services.offload-server` | 🔴 (**P1**) |
| `scripts.nix` | — | C |

### 4.18 shell/ (40+ com aliases/)

| Arquivo | Namespace | Obs |
|---|---|---|
| `default.nix` | `shell.*` (raiz!) | 🔴 (**P2**) |
| `gpu-flags.nix` | `shell.gpu` | 🔴 (**P2**) |
| `training-logger.nix` (647 linhas) | `shell.trainingLogger` | 🔴 (**P2, P4**) — options também setadas inline no host |
| `cli-helpers.nix`, `config-audit.nix`, `nix-ops.nix` (636), `aliases/llama-swap-control.nix` (550), `aliases/service-control.nix` (557), `aliases/nixos-explorer.nix` | `kernelcore.shell` | ✅ |
| aliases/ restante (~30 arquivos: ai/, amazon/, desktop/, docker/, gcloud/, kubernetes/, nix/ — incl. `rebuild-advanced.nix` 674 linhas —, security/, system/, emergency, laptop-defense, mcp, macos-kvm, sync) | — | C (**P6**) |

### 4.19 system/ (11)

| Arquivo | Namespace | Obs |
|---|---|---|
| `binary-cache.nix`, `memory.nix`, `ml-gpu-users.nix` | `kernelcore.system` | ✅ |
| `ssh-config.nix` | `kernelcore.ssh` | duplica prefixo com `security/ssh.nix` |
| `emergency-monitor.nix` | `system.emergency` | 🔴 (**P2**) |
| `user-config.nix` | `system.user` | 🔴 (**P2**) + TODO "PHASE 3" |
| `nix.nix` | `nix.*` custom | 🔴 (**P2**) |
| `aliases.nix`, `io-scheduler.nix`, `services.nix` | — | C (**P6**) |

### 4.20 tools/ (10 + arch-analyzer/)

Todos `kernelcore.tools.*` ✅ (dev, diagnostics, intel, llm, mcp, nix-utils, secops, arch-analyzer). `secrets.nix` — **deprecated declarado** na linha 1 (**P8**).

### 4.21 virtualization/ (4)

`macos-kvm.nix` (492), `vmctl.nix`, `vms.nix` (504) — todos `kernelcore.virtualization.*` ✅. ⚠️ `vmctl` existe aqui **e** em `programs/vmctl.nix` (959 linhas) com namespaces diferentes (**P3**).

---

## 5. Mapa de Namespaces

### 5.1 Distribuição

| Namespace | Declarações | Situação |
|---|---|---|
| `kernelcore.*` | ~99 arquivos | ✅ padrão do repo (sub-prefixos: system, security, soc, network, services, containers, ml, shell, tools, packages, secrets, hardware, bluetooth, chromium, electron, ci, development, desktop, hyprland, virtualization, blockchain, ssh, swissknife, ai, llama-swap, applications) |
| `services.*` (custom) | 30 | 🔴 **P1** — ocupa namespace do nixpkgs |
| `programs.*` (custom) | 14 | ⚠️ aceitável em parte (idiomático p/ apps), mas inconsistente com a decisão de unificar |
| `shell.*` | 3 | 🔴 **P2** |
| `system.*` | 2 | 🔴 **P2** |
| `security.hardening.*` | 3 | ⚠️ intencional em kernel.nix; edr-infra é P2 |
| `hardware.*` (custom) | 3 | ⚠️ **P2** |
| `modules.audio.*` | 2 | 🔴 **P2** |
| `voidnxlabs.*` | 1 | 🔴 **P2** |
| `spectre.*` | 1 | 🔴 **P2** |
| `ai.*` | 1 | 🔴 **P2** |
| `nix.*` (custom) | 1 | 🔴 **P2** |

### 5.2 Lista completa das 61 declarações fora de `kernelcore.*`

(verificadas por grep em 2026-07-11; esta é a fonte para o mapa DE→PARA do TOPOLOGY.md)

```
applications/brave-hardened.nix          voidnxlabs.brave-hardened
applications/brave-secure.nix            programs.brave-secure
applications/chromium.nix                services.chromiumOrg
applications/firefox-privacy.nix         programs.firefox-privacy
applications/nemo-full.nix               programs.nemo
applications/neoland.nix                 programs.neoland
applications/vscode-remote-ssh.nix       programs.vscode-remote-ssh
applications/vscode-secure.nix           programs.vscode-secure
applications/vscodium-secure.nix         programs.vscodium-secure
audio/production.nix                     modules.audio.production
audio/video-production.nix               modules.audio.videoProduction
containers/docker.nix                    services.chromiumOrg (!)
desktop/hyprland-modular/default.nix     programs.hyprland-modular
desktop/hyprland.nix                     services.hyprland-desktop
development/git-forge-tools.nix          programs.git-forge-tools
development/ssh-git-forges.nix           programs.ssh.gitForges        [estende upstream]
devops/gitlab-cli/default.nix            programs.glab-custom
hardware/i915-governor/default.nix       services.i915-governor
hardware/laptop-defense/flake.nix        hardware.thermalProtection
hardware/laptop-defense/mcp-integration.nix  services.mcp.laptopDefense
hardware/laptop-defense/rebuild-hooks.nix    hardware.rebuildHooks
hardware/trezor.nix                      hardware.trezor
kubernetes/cilium-cni.nix                services.cilium-cni
kubernetes/k3s-cluster.nix               services.k3s-cluster
kubernetes/kind.nix                      services.kind-lab
kubernetes/longhorn-storage.nix          services.longhorn-storage
kubernetes/spectre-k8s.nix               spectre.k8s
ml/agents/cerebro/default.nix            services.cerebro
ml/agents/ecosystem.nix                  ai.ecosystem
ml/agents/ml-ops-api/default.nix         services.ml-ops-api
ml/agents/neoland/agent-config.nix       services.neoland-agents
ml/agents/neoland/checkpoint-storage.nix services.neoland-checkpoints
ml/agents/neoland/control-plane.nix      services.neoland-control-plane
ml/agents/neoland/dspy-pipeline.nix      services.neoland-dspy-pipeline
ml/agents/neoland/ledger-subscriber.nix  services.neoland-ledger-subscriber
ml/agents/neoland/loki.nix               services.neoland-loki
ml/agents/neoland/vector.nix             services.neoland-vector
ml/agents/neotron/default.nix            services.neotron
ml/agents/phantom/default.nix            services.phantom
ml/orchestration/api/flake.nix           services.ml-offload-api
ml/services/llama-cpp-swap.nix           services.llamacpp-swap
ml/services/llama-cpp-turbo.nix          services.llamacpp-turbo
ml/services/llama-model-router.nix       services.llamacpp-model-router
ml/services/tabbyapi.nix                 services.tabbyapi
ml/services/vllm.nix                     services.vllm
programs/cognitive-vault.nix             programs.cognitive-vault
programs/phantom.nix                     programs.phantom
programs/vmctl.nix                       programs.vmctl
security/soc/edr-infrastructure/.../edr/alerting.nix    services.edr.alerting
security/soc/edr-infrastructure/.../edr/detection.nix   services.edr.detection
security/soc/edr-infrastructure/.../hardening/apparmor.nix  security.hardening.apparmor.edr
security/soc/edr-infrastructure/.../hardening/seccomp.nix   security.hardening.seccomp.edr
services/config-auditor.nix              services.config-auditor
services/forgejo.nix                     services.forgejo.integration.* [estende upstream]
services/gitea-showcase.nix              services.gitea-showcase
services/gitlab-duo/default.nix          services.gitlabDuo
services/mcp-server.nix                  services.securellm-mcp
services/offload-server.nix              services.offload-server
shell/default.nix                        shell.*
shell/gpu-flags.nix                      shell.gpu
shell/training-logger.nix                shell.trainingLogger
system/emergency-monitor.nix             system.emergency
system/user-config.nix                   system.user
system/nix.nix                           nix.* (custom)
```

**Observação técnica**: a maioria usa nomes com sufixo (`k3s-cluster`, `gitea-showcase`) que **não colidem literalmente** com options do nixpkgs hoje — mas ocupam namespaces reservados do upstream e podem colidir em qualquer atualização. Dois casos são **extensões deliberadas** de árvores upstream e exigem tratamento distinto: `services.forgejo.integration.*` e `programs.ssh.gitForges`.

---

## 6. hosts/

### 6.1 kernelcore/

```
hosts/kernelcore/
├── default.nix              (6 linhas → ./users)
├── configuration.nix        (1.479 linhas) 🔴 P4/P5
├── hardware-configuration.nix (67 linhas, gerado — LUKS ext4, EFI, ZRAM em vez de swap)
├── acpi-fix/                (dsdt.aml/.dat/.dsl — override ACPI via initrd)
├── home/                    (ver §7)
├── specialisations/         (8 + default.nix)
└── users/                   (claude-code, codex-agent, gemini-agent, gitlab-runner)
```

**configuration.nix por seção** (linhas aproximadas):

| Seção | Linhas | Conteúdo | Pertence a modules/? |
|---|---|---|---|
| Toggles custom inline | 10–32 | **define** `kernelcore.electron`, `kernelcore.chromium.logSuppression`, `shell.trainingLogger` | 🔴 sim — options definidas no host (**P5**) |
| Otimizações de sistema | 34–46 | memory/nix optimizations, binary cache | ✅ só ativação |
| Segurança | 48–92 | TLS (Cloudflare DNS), AIDE, SSH, kernel, PAM, keyring | ✅ só ativação |
| Rede | 94–188 | DNS resolver, proxy, bridge, VPN (NordVPN/WireGuard), Tailscale + nginx, Gitea público | ✅ ativação + valores |
| SOC | 192–201 | perfil, retenção, Suricata | ✅ |
| Hardware | 203–213 | NVIDIA CUDA + PRIME offload, bluetooth | ✅ |
| Pacotes | 217–248 | toggles per-package, builds Gemini/Antigravity | ✅ |
| Dev stacks | 252–286 | Rust/Go/Python/Node/Nix/Lua, Jupyter, CI/CD | ✅ |
| Containers/virt | 288–402 | Docker, Podman+NVIDIA, containers ML, storage de modelos | ✅ |
| Serviços | ~400–900 | K3s, Gitea, Forgejo, nginx, SOPS, LLM services, Prometheus/Grafana | ✅ |
| Desktop | ~1000–1103 | Hyprland, monitores 2.8K/144Hz, `programs.niri.enable`, PipeWire; importa `./specialisations` | ✅ |
| CLI helpers | 1414–1420 | `kernelcore.shell.{cli-helpers,nix-ops}` | ✅ |
| Boot/sistema | 1422–1478 | 🔴 ACPI DSDT inline (buildCommand), 🔴 ZRAM inline, 🔴 systemd service inline de power-limit da GPU, VSCode | parcial — serviços inline deviam ser módulos (**P5**) |

### 6.2 specialisations/ (8)

`k8s-lab`, `k8s-prod`, `development`, `cybersecurity`, `privacy-paranoia`, `stable`, `emergency` ativas; `niri` **comentada** no `default.nix` (aguardando migração Hyprland→Niri). Ativação: `nixos-rebuild switch --specialisation <nome>`.

### 6.3 Outros hosts

- **k8s-node/**: `configuration.nix` + hardware + 🔴 `k8s-original/k8s/` (arquivo morto: configs históricas + `k8s.zip` versionado — **P7**).
- **workstation/**: `configuration.nix` (176 linhas, exemplo "HyperLab").
- **_examples/**: `minimal-server.nix`, `desktop-workstation.nix`, `k8s-node.nix`.

---

## 7. home-manager (`hosts/kernelcore/home/`)

**Wiring**: integrado via `home-manager.nixosModules.home-manager` no flake; `users.kernelcore = import ./hosts/kernelcore/home/home.nix`; `sharedModules` = spooknix + actions-tv.

**home.nix** (440 linhas) importa: `./shell`, yazi, alacritty, git, tmux, flameshot, `./glassmorphism`, brave, electron-apps, firefox, **e dois módulos de `modules/development/`** (git-forge-tools, ssh-git-forges — 🔴 cruzamento sistema/home, **P5**). Condicionais: `hyprland.nix` se `osConfig.services.hyprland-desktop.enable`; `niri/niri.nix` + `niri/waybar-niri.nix` se `osConfig.programs.niri.enable`.

| Arquivo | Linhas | Tipo | Obs |
|---|---|---|---|
| `home.nix` | 440 | O+C | entry point |
| `shell/` (default, options, bash, zsh, git-deploy, p10k) | ~710 | O+C | `myShell.*` options — único módulo home com options próprias |
| `alacritty.nix` | 500 | C | |
| `yazi.nix` | 807 | C | |
| `git.nix` | 153 | C | |
| `tmux.nix` | 45 | C | |
| `theme.nix` | 48 | C | 🔴 legado, superado pelo glassmorphism |
| `flameshot.nix` | 111 | C | 🔴 legado (swappy é o atual) |
| `brave.nix`, `firefox.nix`, `electron-apps.nix`, `electron-config.nix` | ~270 | C | |
| `hyprland.nix` | 454 | C | condicional |
| `niri/niri.nix` | 427 | C | condicional; refatorado recentemente (−1.000 linhas) |
| `niri/waybar-niri.nix` | 554 | C | condicional |
| `aliases/nixos-aliases.nix` + 10 scripts .sh | — | C | |
| **glassmorphism/** | ~5.000 | C | design system |

**glassmorphism/**: tokens centralizados em `colors.nix` (342 linhas) consumidos por todos os componentes — `default.nix` (GTK/Qt/fonts, 229), `kitty` (388), `wallpaper` (314, swww), `waybar` (**1.404** 🔴 P4), `mako` (306), `wofi` (403), `zellij` (569), `swappy` (337), `hyprlock` (250), `wlogout` (256), `agent-hub` (418). Arquitetura **bem avaliada** — manter.

**Dual-WM**: Hyprland ativo (waybar.nix + hyprlock); Niri condicional (waybar-niri + swaylock). Toggle = `programs.niri.enable` no sistema.

---

## 8. Diretórios auxiliares

### lib/ (4)
- `packages.nix` (6.6K) — VM/ISO/imagens Docker → `packages.${system}`.
- `shells.nix` (8.8K) — 6 devShells + carregamento de secrets SOPS.
- `shell.nix` (2.5K), `python.nix` (2.1K) — wrappers.

### overlays/ (7)
- `default.nix` — **agregador vazio** (tudo comentado). Ativos-porém-não-plugados: `libcanberra-patch-fix`, `weston-patch-fix`, `python-packages`, `version-pinning`. `antigravity.nix.disabled`.

### pkgs/ (1) — `securellm-mcp.nix`.

### profiles/ (1) — `k8s-lab.nix` (143 linhas): relaxa firewall/AppArmor para lab K8s; importado direto no flake. ⚠️ Sobrepõe conceito com `specialisations/k8s-lab.nix`.

### templates/ (13)
- Legítimos: `minimal/` (flake template), `hardening-template.nix`, `configurations-template.nix` (novo, esboça hierarquia `kernelcore.*` centralizada — insumo do TOPOLOGY).
- 🔴 Lixo iterativo (**P7**): `fix-sudo.nix`, `fix-sudo2.nix`, `fix-sudo3.nix`, `desktop-cfg.nix`, `desktop-cfg2.nix`, `desktop-config-backup.nix`, `desktop-config-clean.nix`, `cypher-host.nix`, `test-remote-build.nix`.

### scripts/ (167)
Build/audit (audit-config.py, check-module-options.py, build-inventory.nix), admin (post-rebuild-validate, limpeza-agressiva), monitoramento (monitor-nix-store, swiss-monitor), subdirs: audit-pinix/, automation/, maintenance/, ml-tools/, nix-tools/, observability-sec/ (ir_capture.sh), SecOps/, surgical/ (io-surgeon, psi-sentinel, net-conflict...). 🔴 `__pycache__/` versionado (**P7**).

### secrets/ (24)
SOPS yaml: api-keys, gcp-ml, aws, grok, github, gitlab, gitea, forgejo, k8s, tailscale, endpoints, blockchain, certificates. ⚠️ Placeholders vazios (api, ssh, prod, vertex, database, ssh-keys/*) e backups soltos (`github.yaml.backup`, `gitlab.yaml.backup-20260123-*`).

### tests/ (11) — buildbot, integração, tailscale. Subutilizado; nenhum plugado em `checks`.

### docs/ (242) — bem estruturado (guides/, runbooks/, architecture/, proposals/, reports/, archive/). `docs/architecture/` contém relatórios gerados (AI-ARCHITECTURE-REPORT-*, snapshots) — candidatos a rotação/limpeza.

---

## 9. Registro de Problemas (P1–P9)

> Cada problema tem resolução correspondente no [TOPOLOGY.md](TOPOLOGY.md).

- **P1 — Ocupação do namespace `services.*` (30 declarações custom)**
  Módulos próprios declaram options sob `services.*` (llamacpp-*, vllm, tabbyapi, neoland-*, cerebro, neotron, phantom, ml-ops-api, ml-offload-api, k3s-cluster, cilium-cni, kind-lab, longhorn-storage, gitea-showcase, gitlabDuo, securellm-mcp, offload-server, config-auditor, chromiumOrg, hyprland-desktop, i915-governor, mcp.*, edr.*). Risco de colisão com nixpkgs a cada update; impossível distinguir option upstream de custom ao ler um host. Casos especiais (extensão deliberada de upstream): `services.forgejo.integration.*`, `programs.ssh.gitForges`.

- **P2 — Namespaces avulsos (14 declarações)**
  `voidnxlabs.brave-hardened`, `spectre.k8s`, `ai.ecosystem`, `shell.*` (3), `modules.audio.*` (2), `system.{emergency,user}`, `hardware.{trezor,rebuildHooks,thermalProtection}`, `nix.*`, `security.hardening.{apparmor,seccomp}.edr`.

- **P3 — Duplicações de módulos**
  brave-secure vs brave-hardened; electron-tuning vs electron-tuning-v2; vscode-secure vs vscodium-secure (par aceitável, mas sem base comum); desktop/hyprland.nix vs desktop/hyprland-modular/; programs/vmctl.nix vs virtualization/vmctl.nix; 5 backends de inferência (llamacpp-swap/turbo/router, vllm, tabbyapi) sem seletor; antigravity/tuning vs tuning-fixed; programs/phantom vs ml/agents/phantom.

- **P4 — Monólitos**
  `programs/vmctl.nix` (959), `hyprland-modular/default.nix` (852), `laptop-defense/flake.nix` (760), `llama-cpp-swap.nix` (682), `rebuild-advanced.nix` (674), `training-logger.nix` (647), `configuration.nix` do host (1.479), `glassmorphism/waybar.nix` (1.404).

- **P5 — Sobreposição host ↔ modules**
  Options **definidas** dentro de `configuration.nix` (electron, chromium.logSuppression, trainingLogger); serviços systemd inline (GPU power-limit, ZRAM, ACPI); home.nix importando módulos de `modules/development/`; chromium log-suppression existente nos dois lados.

- **P6 — ~80 módulos de config pura**
  Sem `enable`, aplicam-se incondicionalmente ao importar (security/boot, security/network, compiler-hardening, sec-hardening, ~30 aliases de shell, tailscale-desktop/laptop, antigravity/*, system/aliases|io-scheduler|services...). Impede specialisations/hosts de desligá-los seletivamente.

- **P7 — Resíduos e arquivos fora de lugar**
  `templates/` com 9 arquivos iterativos; `hosts/k8s-node/k8s-original/` (com `k8s.zip`); `home/niri.nix` na raiz (duplica home/niri do host); `nix/`, `flakes/`, `ux/` difusos; `scripts/__pycache__/`; backups de secrets soltos; overlays com agregador vazio; relatórios gerados acumulando em `docs/architecture/`.

- **P8 — TODOs pendentes** (ver Apêndice A)
  1 CRITICAL (DAO Algorand), GPU scheduler ausente, sintaxe Hyprland 0.53+, tools/secrets.nix deprecated, extrações ML pendentes.

- **P9 — Documentação de governança desatualizada**
  `CLAUDE.md` do projeto descreve estado de 2025-11 (nixtrap/, sec/, reports/, journal/, caminhos `/etc/nixos`) que não corresponde mais ao repositório; métricas defasadas (fala em 61 módulos; são 292).

---

## Apêndice A — TODOs/FIXMEs em modules/

| Arquivo:linha | Comentário | Prioridade |
|---|---|---|
| `blockchain/algorand/dao.nix:1` | "TODO: CRITICAL: implement a proper DAO smart contract" | 🔴 CRITICAL |
| `ml/infrastructure/vram/default.nix:14` | "TODO: Create central GPU scheduler" | Alta |
| `desktop/hyprland-modular/rules/default.nix:389` | "TODO: Research correct layerrule syntax for Hyprland 0.53+" | Alta |
| `tools/secrets.nix:1` | "TODO: This script are marked as deprecated" | Média |
| `ml/infrastructure/hardware/default.nix:13` | "TODO: Extract CUDA from existing configs" | Média |
| `ml/integrations/neovim/default.nix:13` | "TODO: Extract from offload/neovim/" | Média |
| `security/soc/default.nix:36` | "TODO: Future integration (edr/agent.nix...)" | Média |
| `system/user-config.nix:55` | "PHASE 3 TODO" | Média |
| `packages/antigravity/security.nix:66` | "TODO: network restrictions per-workspace" | Média |
| `packages/custom/gemini-antigravity.nix:101` | "TODO: prefetch-npm-deps package-lock.json" | Baixa |

## Apêndice B — Maiores módulos (linhas)

| # | Arquivo | Linhas |
|---|---|---|
| 1 | `hosts/kernelcore/configuration.nix` | 1.479 |
| 2 | `hosts/kernelcore/home/glassmorphism/waybar.nix` | 1.404 |
| 3 | `modules/programs/vmctl.nix` | 959 |
| 4 | `modules/desktop/hyprland-modular/default.nix` | 852 |
| 5 | `hosts/kernelcore/home/yazi.nix` | 807 |
| 6 | `modules/hardware/laptop-defense/flake.nix` | 760 |
| 7 | `modules/ml/services/llama-cpp-swap.nix` | 682 |
| 8 | `modules/shell/aliases/nix/rebuild-advanced.nix` | 674 |
| 9 | `modules/shell/training-logger.nix` | 647 |
| 10 | `modules/audio/production.nix` | 646 |
| 11 | `modules/shell/nix-ops.nix` | 636 |
| 12 | `modules/desktop/i3-lightweight.nix` | 567 |
| 13 | `modules/shell/aliases/service-control.nix` | 557 |
| 14 | `hosts/kernelcore/home/niri/waybar-niri.nix` | 554 |
| 15 | `modules/shell/aliases/llama-swap-control.nix` | 550 |
