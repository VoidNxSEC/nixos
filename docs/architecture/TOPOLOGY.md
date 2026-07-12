# Topologia Definitiva do Repositório NixOS (TOPOLOGY)

> **Status**: Proposta para aprovação
> **Data**: 2026-07-11
> **Base factual**: [INVENTORY.md](INVENTORY.md) (levantamento de 2026-07-11). Problemas referenciados como **P1–P9**.
> **Decisão de namespace (já tomada)**: **todas as options customizadas migram para `kernelcore.*`**.

---

## 1. Princípios

1. **Namespace único**: toda option definida neste repositório vive sob `kernelcore.<categoria>.<módulo>.*`. Os namespaces `services.*`, `programs.*`, `hardware.*`, `security.*` ficam reservados **exclusivamente** para options do nixpkgs/inputs (resolve P1/P2).
2. **Host declara, módulo implementa**: `hosts/*/configuration.nix` contém apenas ativações (`kernelcore.x.enable = true`) e valores específicos da máquina. Zero `mkOption`, zero `systemd.services` inline, zero `buildCommand` — exceto o estritamente ligado ao hardware físico (resolve P5).
3. **Todo módulo tem `enable`**: config pura é convertida em módulo com `mkEnableOption` (default conforme uso atual) ou absorvida pelo agregador da categoria. Nada se aplica só por ser importado (resolve P6).
4. **Um assunto, um módulo canônico**: variantes viram `profile`/`mode` dentro do mesmo módulo, nunca arquivos paralelos (resolve P3).
5. **Limite de tamanho**: módulo acima de ~400 linhas é candidato a split em subdiretório com `default.nix` + partes (resolve P4).
6. **Compatibilidade durante a migração**: todo rename de option passa por `mkRenamedOptionModule`/`mkAliasOptionModule` por pelo menos uma fase, para não quebrar specialisations e hosts.
7. **Cada fase fecha verde**: `nixos-rebuild dry-build --flake /etc/nixos#<host>` ao fim de cada fase; o switch é sempre do usuário.

---

## 2. Árvore-alvo da raiz

```
/
├── flake.nix
├── flake.lock
├── README.md                  # visão geral (atualizar)
├── CLAUDE.md                  # reescrever — hoje descreve estado de 2025-11 (P9)
├── modules/                   # implementação (ver §3)
├── hosts/                     # ativação por máquina (ver §6)
├── lib/                       # packages.nix, shells.nix, helpers
├── overlays/                  # religar agregador ou remover overlays mortos
├── pkgs/                      # derivations próprias (padrão nixpkgs-like)
├── docs/                      # documentação (relatórios gerados → docs/architecture/snapshots/)
├── scripts/                   # operacional (sem __pycache__; .gitignore)
├── secrets/                   # SOPS (limpar placeholders vazios e backups soltos)
├── skills/                    # skills Claude Code
├── templates/                 # APENAS minimal/ + module/ + host/ (ver §7.4)
└── tests/                     # plugar em flake checks
```

**Eliminações/realocações** (resolve P7):

| Hoje | Destino |
|---|---|
| `nix/` (aliases, ssh, gitlab misc) | conteúdo útil → `modules/` ou `scripts/`; diretório removido |
| `flakes/` (exemplos de inputs) | `docs/references/flake-inputs.md`; removido |
| `home/niri.nix` (raiz, duplicado) | removido (canônico: `hosts/kernelcore/home/niri/`) |
| `ux/` | `docs/ux/` |
| `profiles/k8s-lab.nix` | `hosts/kernelcore/specialisations/` (fundir com a specialisation k8s-lab, que já existe e cobre o mesmo caso) |
| `templates/fix-sudo{,2,3}.nix`, `desktop-cfg*`, `cypher-host.nix`, `test-remote-build.nix` | removidos (histórico fica no git) |
| `hosts/k8s-node/k8s-original/` (incl. k8s.zip) | removido (conteúdo já superado por `modules/kubernetes/`) |
| `scripts/__pycache__/` | removido + `.gitignore` |
| `secrets/*.backup*`, yamls placeholder vazios | removidos |

---

## 3. Árvore-alvo de `modules/`

Mantém-se a espinha de 21 categorias — está boa. Mudanças cirúrgicas:

```
modules/
├── default.nix
├── applications/        # + absorve modules/programs/ (cognitive-vault, phantom→ml, vmctl→virtualization)
├── audio/
├── blockchain/
├── containers/
├── debug/
├── desktop/             # hyprland-modular vira o canônico; hyprland.nix vira shim (§5)
├── development/
├── devops/
├── hardware/            # laptop-defense/flake.nix desmontado em módulos normais
├── kubernetes/
├── ml/                  # hierarquia agents/ infrastructure/ services/ integrations/ mantida
├── network/
├── packages/
├── secrets/
├── security/            # + soc/ ; edr-infrastructure integrado como módulos normais
├── services/
├── shell/
├── system/
├── tools/
└── virtualization/      # único dono do vmctl
```

**Regras de fronteira entre categorias** (critério para P3):

- `applications/` = software de usuário com config de sistema (browsers, editores, terminal apps).
- `packages/` = empacotamento/instalação de binários (deb, tar, npm builds) — não configura comportamento.
- `services/` = daemons de infraestrutura genéricos; serviços de ML ficam em `ml/services/`.
- `programs/` **deixa de existir**: `cognitive-vault.nix` → `applications/`; `phantom.nix` → fundir com `ml/agents/phantom/`; `vmctl.nix` (959 linhas) → fundir com `virtualization/vmctl.nix`, dividido em `virtualization/vmctl/{default,options,cli,images}.nix`.
- Flakes aninhados usados como módulo (`hardware/laptop-defense/flake.nix`, `ml/agents/agent-hub/core/flake.nix`, `ml/orchestration/api/flake.nix`, `security/soc/edr-infrastructure/flake.nix`) → ou viram **input do flake raiz** (se são projetos independentes) ou viram **módulos normais** (se só existem aqui). Default: módulo normal.

---

## 4. Mapa de migração de namespaces (DE → PARA)

Cobertura: as 61 declarações listadas no INVENTORY §5.2. Options de serviços **upstream reais** (ex.: `services.forgejo.*` do nixpkgs que o módulo *seta*) não mudam — só o que este repo **declara**.

### 4.1 `services.*` custom → `kernelcore.*` (P1)

| DE | PARA |
|---|---|
| `services.llamacpp-swap` | `kernelcore.ml.inference.llamacpp-swap` |
| `services.llamacpp-turbo` | `kernelcore.ml.inference.llamacpp-turbo` |
| `services.llamacpp-model-router` | `kernelcore.ml.inference.router` |
| `services.vllm` | `kernelcore.ml.inference.vllm` |
| `services.tabbyapi` | `kernelcore.ml.inference.tabbyapi` |
| `services.cerebro` | `kernelcore.ml.agents.cerebro` |
| `services.neotron` | `kernelcore.ml.agents.neotron` |
| `services.phantom` | `kernelcore.ml.agents.phantom` |
| `services.ml-ops-api` | `kernelcore.ml.agents.ml-ops-api` |
| `services.ml-offload-api` | `kernelcore.ml.orchestration.offload-api` |
| `services.neoland-agents` | `kernelcore.ml.agents.neoland.agents` |
| `services.neoland-control-plane` | `kernelcore.ml.agents.neoland.controlPlane` |
| `services.neoland-checkpoints` | `kernelcore.ml.agents.neoland.checkpoints` |
| `services.neoland-dspy-pipeline` | `kernelcore.ml.agents.neoland.dspyPipeline` |
| `services.neoland-ledger-subscriber` | `kernelcore.ml.agents.neoland.ledgerSubscriber` |
| `services.neoland-loki` | `kernelcore.ml.agents.neoland.loki` |
| `services.neoland-vector` | `kernelcore.ml.agents.neoland.vector` |
| `services.k3s-cluster` | `kernelcore.kubernetes.k3s` |
| `services.cilium-cni` | `kernelcore.kubernetes.cilium` |
| `services.kind-lab` | `kernelcore.kubernetes.kind` |
| `services.longhorn-storage` | `kernelcore.kubernetes.longhorn` |
| `services.gitea-showcase` | `kernelcore.services.gitea-showcase` |
| `services.gitlabDuo` | `kernelcore.services.gitlab-duo` |
| `services.securellm-mcp` | `kernelcore.services.securellm-mcp` |
| `services.offload-server` | `kernelcore.services.offload-server` |
| `services.config-auditor` | `kernelcore.services.config-auditor` |
| `services.chromiumOrg` (em `applications/chromium.nix` **e** `containers/docker.nix`) | `kernelcore.applications.chromium` — e investigar/corrigir o uso incoerente em docker.nix |
| `services.hyprland-desktop` | `kernelcore.desktop.hyprland` (⚠️ home.nix condiciona import nesse toggle — atualizar junto) |
| `services.i915-governor` | `kernelcore.hardware.i915-governor` |
| `services.mcp.laptopDefense` | `kernelcore.hardware.laptop-defense.mcp` |
| `services.edr.alerting` / `services.edr.detection` | `kernelcore.soc.edr.alerting` / `kernelcore.soc.edr.detection` |

### 4.2 `programs.*` custom → `kernelcore.applications.*`

| DE | PARA |
|---|---|
| `programs.brave-secure` + `voidnxlabs.brave-hardened` | `kernelcore.applications.brave` (com `profile`, §5.1) |
| `programs.firefox-privacy` | `kernelcore.applications.firefox` |
| `programs.nemo` | `kernelcore.applications.nemo` |
| `programs.neoland` | `kernelcore.applications.neoland` |
| `programs.vscode-secure` | `kernelcore.applications.vscode` |
| `programs.vscodium-secure` | `kernelcore.applications.vscodium` |
| `programs.vscode-remote-ssh` | `kernelcore.applications.vscode.remoteSsh` |
| `programs.cognitive-vault` | `kernelcore.applications.cognitive-vault` |
| `programs.phantom` | fundir em `kernelcore.ml.agents.phantom` |
| `programs.vmctl` | `kernelcore.virtualization.vmctl` |
| `programs.hyprland-modular` | `kernelcore.desktop.hyprland` (canônico pós-fusão, §5.2) |
| `programs.glab-custom` | `kernelcore.devops.glab` |
| `programs.git-forge-tools` | `kernelcore.development.git-forge-tools` |

### 4.3 Namespaces avulsos (P2)

| DE | PARA |
|---|---|
| `spectre.k8s` | `kernelcore.kubernetes.spectre` |
| `ai.ecosystem` | `kernelcore.ml.agents.ecosystem` |
| `modules.audio.production` | `kernelcore.audio.production` |
| `modules.audio.videoProduction` | `kernelcore.audio.video-production` |
| `shell.*` (default.nix) | `kernelcore.shell.*` |
| `shell.gpu` | `kernelcore.shell.gpu` |
| `shell.trainingLogger` | `kernelcore.shell.training-logger` |
| `system.emergency` | `kernelcore.system.emergency-monitor` |
| `system.user` | `kernelcore.system.user` |
| `nix.*` (custom em system/nix.nix) | `kernelcore.system.nix` |
| `hardware.trezor` | `kernelcore.hardware.trezor` |
| `hardware.rebuildHooks` | `kernelcore.hardware.rebuild-hooks` |
| `hardware.thermalProtection` | `kernelcore.hardware.laptop-defense.thermal` |
| `security.hardening.apparmor.edr` / `security.hardening.seccomp.edr` | `kernelcore.soc.edr.hardening.{apparmor,seccomp}` |
| `security.hardening.*` (kernel.nix) | `kernelcore.security.kernel` (mantendo os `mkForce` internos) |
| `kernelcore.bluetooth` | `kernelcore.hardware.bluetooth` (normalização de 2º nível) |
| `kernelcore.chromium` / `kernelcore.electron` | `kernelcore.applications.{chromium,electron}` |
| `kernelcore.ssh` (security/ssh.nix + system/ssh-config.nix) | `kernelcore.security.ssh` (um único dono) |
| `kernelcore.swissknife` | `kernelcore.debug.swissknife` |
| `kernelcore.llama-swap` | `kernelcore.ml.inference.swap-control` |
| `kernelcore.hyprland` | `kernelcore.desktop.hyprland` |

### 4.4 Casos especiais — extensões deliberadas de upstream (NÃO migram igual)

| Option | Tratamento |
|---|---|
| `services.forgejo.integration.*` | É extensão consciente da árvore upstream `services.forgejo`. **Opção adotada**: mover para `kernelcore.services.forgejo` e o módulo internamente seta `services.forgejo.*` upstream. Mantém a regra "services.* = só upstream". |
| `programs.ssh.gitForges` | Idem: mover para `kernelcore.development.ssh-git-forges`, setando `programs.ssh.*` upstream internamente. |

**Segundo nível canônico de `kernelcore.*`** (fechado — nada fora disto):
`system` · `security` · `soc` · `hardware` · `network` · `services` · `containers` · `virtualization` · `kubernetes` · `ml` · `development` · `devops` · `applications` · `packages` · `desktop` · `audio` · `shell` · `tools` · `debug` · `secrets` · `blockchain`

---

## 5. Resolução das duplicações (P3)

### 5.1 Brave
Um módulo `applications/brave.nix`:
```nix
kernelcore.applications.brave = {
  enable = ...;
  profile = mkOption { type = enum [ "secure" "hardened" ]; default = "secure"; };
};
```
Conteúdo de `brave-hardened.nix` vira o branch `hardened`; arquivos antigos removidos após aliases.

### 5.2 Hyprland
`hyprland-modular/` é o canônico → renomeado para `desktop/hyprland/` (com `default.nix` dividido: options, bindings, rules, themes — resolve as 852 linhas). `desktop/hyprland.nix` (`services.hyprland-desktop`) vira shim de compatibilidade e depois some. `hyprland-performance.nix` vira `kernelcore.desktop.hyprland.performance`.

### 5.3 Inferência ML
`kernelcore.ml.inference` ganha um seletor:
```nix
kernelcore.ml.inference = {
  backend = mkOption { type = enum [ "llamacpp-swap" "llamacpp-turbo" "vllm" "tabbyapi" ]; };
  router.enable = ...;   # llama-model-router por cima do backend
};
```
Cada backend continua em seu arquivo; o seletor garante exclusão mútua (assertions) e ponto único de ativação.

### 5.4 Electron
`electron-tuning-v2.nix` renomeado para `electron.nix` (canônico); v1 removido.

### 5.5 VSCode/VSCodium
Base comum `applications/vscode/common.nix` + dois wrappers finos (`vscode.nix`, `vscodium.nix`). `vscode-remote-ssh` vira sub-option.

### 5.6 vmctl
Fusão em `virtualization/vmctl/` (default + options + cli + images). `programs/vmctl.nix` removido.

### 5.7 phantom
`programs/phantom.nix` fundido em `ml/agents/phantom/`.

### 5.8 antigravity tuning
`tuning-fixed.nix` vira canônico (`tuning.nix`); o antigo removido.

---

## 6. hosts/ — desmonte do configuration.nix (P4/P5)

### 6.1 O que SAI do `configuration.nix` para `modules/`

| Hoje (inline no host) | Novo módulo |
|---|---|
| `options.kernelcore.electron` + config | já existe `applications/electron-tuning-v2.nix` — host só seta valores |
| `options.kernelcore.chromium.logSuppression` | já existe `applications/chromium-log-suppression.nix` — remover redefinição |
| `options.shell.trainingLogger` inline | já existe `shell/training-logger.nix` — remover redefinição |
| systemd service de GPU power-limit (linhas ~1456) | `hardware/nvidia.nix` → `kernelcore.hardware.nvidia.powerLimit = { enable, watts }` |
| ZRAM inline (linhas ~1472) | `system/memory.nix` → `kernelcore.system.memory.zram = { enable, percent, algorithm }` |
| ACPI DSDT override (buildCommand, linhas ~1422) | `hosts/kernelcore/acpi-dsdt.nix` (host-específico, mas fora do monólito) |

### 6.2 Estrutura-alvo do host

```
hosts/
├── common/                    # NOVO: base compartilhada entre hosts
│   └── default.nix            # locale, nix settings, users base
├── kernelcore/
│   ├── default.nix            # imports: hardware, acpi, users, specialisations, profile.nix
│   ├── hardware-configuration.nix
│   ├── acpi-dsdt.nix
│   ├── profile.nix            # SUBSTITUI configuration.nix: só kernelcore.* = valores
│   ├── home/                  # mantido (ver §7.1)
│   ├── specialisations/       # mantido; niri.nix reativada quando a migração de WM fechar
│   └── users/                 # mantido
├── k8s-node/                  # limpo (sem k8s-original/)
├── workstation/
└── _examples/
```
Meta: `profile.nix` ≤ ~400 linhas, apenas atribuições. O nome `configuration.nix` pode ser mantido se preferir — o que muda é o conteúdo.
`templates/configurations-template.nix` é o rascunho desse formato: vira `hosts/_examples/profile-template.nix` e sai de templates/.

### 6.3 home-manager (mantido, com ajustes)

- Estrutura e glassmorphism **preservados** (avaliação positiva no INVENTORY §7).
- Aposentar `theme.nix` e `flameshot.nix` (legados).
- Dividir `glassmorphism/waybar.nix` (1.404 linhas) em `waybar/{default,modules,style}.nix`; idem base comum com `waybar-niri.nix` (554) para não duplicar módulos de status.
- Cruzamento home→modules (`git-forge-tools`, `ssh-git-forges`): esses dois módulos ganham metade home-manager formal (exposta via `flake.homeManagerModules` ou `home-manager.sharedModules`) em vez de import por caminho relativo `../../../modules/...`.
- Toggle de WM formalizado: `kernelcore.desktop.wm = enum [ "hyprland" "niri" ]` no sistema; o home lê via `osConfig`.

---

## 7. Convenções definitivas

### 7.1 Template de módulo padrão

```nix
# modules/<categoria>/<nome>.nix
#
# Propósito: <uma linha>
# Impacto de segurança: <se houver>
{ config, lib, pkgs, ... }:
let
  cfg = config.kernelcore.<categoria>.<nome>;
in
{
  options.kernelcore.<categoria>.<nome> = {
    enable = lib.mkEnableOption "<descrição>";
    # demais options SEMPRE com description
  };

  config = lib.mkIf cfg.enable {
    # implementação; mkDefault para o que o host pode sobrescrever
  };
}
```

### 7.2 Regras de nomenclatura
- Arquivos e atributos multi-palavra: **kebab-case** no nome do arquivo, **camelCase** apenas para sub-options nix (`controlPlane`), nunca no 2º/3º nível do namespace.
- Nome do arquivo = último segmento do namespace (`kernelcore.ml.inference.vllm` → `ml/inference/vllm.nix`).
- Sem sufixos de versão (`-v2`, `-fixed`, `2`, `3`) — versões antigas são removidas, o git guarda o histórico.

### 7.3 Critério "novo módulo vs option em módulo existente"
- Mesmo daemon/assunto, variação de comportamento → **option/profile** no módulo existente.
- Daemon novo, unidade systemd própria, ciclo de vida próprio → **módulo novo**.
- Config pura recorrente (aliases, sysctl) → agregada no módulo da categoria com `enable` default true.

### 7.4 templates/ definitivo
```
templates/
├── minimal/            # flake template (mantido)
├── module.nix          # template §7.1
└── host-profile.nix    # template de hosts/<host>/profile.nix
```

### 7.5 mkForce / mkDefault
- `mkDefault` em módulos reutilizáveis; `mkForce` **apenas** em `kernelcore.security.*` (hardening tem a palavra final — regra atual do kernel.nix, mantida).

### 7.6 Governança (resolve P9)
- Reescrever `CLAUDE.md` do projeto refletindo este documento (o atual descreve estado de 2025-11 com nixtrap/, sec/, 61 módulos).
- `docs/architecture/INVENTORY.md` é re-gerável; relatórios automáticos (AI-ARCHITECTURE-REPORT-*) vão para `snapshots/` com rotação.

---

## 8. Plano de migração faseado

Cada fase é um passo fechado e testável; termina com `nixos-rebuild dry-build --flake /etc/nixos#nx` **verde** e um commit. Nenhuma fase remove funcionalidade (aditivo primeiro, limpeza depois de validado).

### Fase 0 — Limpeza sem impacto de build
Remover resíduos do §2 (templates iterativos, k8s-original/, home/niri.nix raiz, `__pycache__`, backups de secrets, flakes/, nix/, ux/→docs). Nada disso é importado pelo flake — risco zero.
**Gate**: dry-build verde + `git status` limpo dos resíduos.

### Fase 1 — Aliases de compatibilidade + renames de namespace (P1/P2)
Para cada linha do §4: renomear a declaração no módulo e adicionar `mkRenamedOptionModule` do caminho antigo → novo (num arquivo único `modules/compat.nix`, importado pelo agregador). Atualizar os pontos de uso conhecidos (configuration.nix, specialisations, home.nix condicionais).
Pode ser dividida em sub-fases por categoria (1a: ml/, 1b: kubernetes/, 1c: services/, 1d: applications/, 1e: avulsos) — cada uma com dry-build próprio.
**Gate**: dry-build verde; `grep -rn 'options\.\(services\|programs\|shell\|system\|hardware\|security\|ai\|spectre\|voidnxlabs\|modules\)\.' modules/` retorna apenas compat.nix e os dois casos upstream internos.

### Fase 2 — Fusões de duplicados (P3)
brave (5.1), electron (5.4), vmctl (5.6), phantom (5.7), antigravity (5.8), vscode base comum (5.5). Uma fusão por commit.
**Gate**: dry-build verde por fusão.

### Fase 3 — Desmonte do configuration.nix (P5)
Extrações do §6.1 + criação de `hosts/common/`. O host encolhe para atribuições puras.
**Gate**: dry-build verde; diff do `nix derivation show` do toplevel idealmente vazio (mesma closure).

### Fase 4 — Enable para config pura (P6)
Converter os ~80 arquivos C em módulos com `mkEnableOption` (default = comportamento atual, para não mudar a closure). Prioridade: security/ (boot, network, compiler-hardening), depois shell/aliases (podem ser agregados em blocos: `kernelcore.shell.aliases.{docker,k8s,nix,...}.enable`).
**Gate**: dry-build verde; specialisation `emergency` consegue desligar blocos pesados.

### Fase 5 — Splits de monólitos (P4)
vmctl/ (já na fase 2), hyprland/ (5.2), waybar (6.3), llama-cpp-swap, training-logger, laptop-defense.
**Gate**: dry-build verde por split.

### Fase 6 — Consolidação final
Remover `modules/compat.nix` (após 1+ ciclo de uso sem warnings), remover shims, reativar specialisation niri quando a migração de WM concluir, reescrever CLAUDE.md, plugar tests/ em `checks`.
**Gate**: dry-build verde + `nix flake check` verde + grep do gate da Fase 1 retorna vazio.

### Riscos e salvaguardas
- **Specialisations** referenciam options antigas → cobertas pelos renames da Fase 1; dry-build compila todas as specialisations.
- **Inputs externos VoidNxSEC** (spooknix, securellm-mcp...) declaram options próprias fora do repo → **fora do escopo**; só migram os declarados aqui.
- **nftables**: nenhuma fase toca `networking.nftables.enable` (regra de segurança do ambiente — quebra Docker).
- Rollback: tag git `topology-phase-N-pre` antes de cada fase.

---

## 9. Rastreabilidade P# → Resolução

| Problema (INVENTORY §9) | Resolução | Fase |
|---|---|---|
| P1 — services.* custom | §4.1, §4.4 | 1 |
| P2 — namespaces avulsos | §4.2, §4.3 | 1 |
| P3 — duplicações | §5 | 2 |
| P4 — monólitos | §5.2, §5.6, §6.1, §6.3, Fase 5 | 2/5 |
| P5 — host ↔ modules | §6 | 3 |
| P6 — config pura | Fase 4 | 4 |
| P7 — resíduos | §2 | 0 |
| P8 — TODOs | tratados nos módulos ao migrar cada categoria (dao.nix CRITICAL: decidir manter ou arquivar blockchain/ na Fase 1a) | 1–5 |
| P9 — CLAUDE.md desatualizado | §7.6 | 6 |
