# CI/CD — VoidNxSEC/nixos

Workflows enxutos para o propósito deste repo: **validar a configuração NixOS**.
Padrões e reusables centrais vivem em [`VoidNxSEC/voidnxlabs-workflows`](https://github.com/VoidNxSEC/voidnxlabs-workflows).

> **Deploy/switch é sempre manual** (`sudo nixos-rebuild switch`), nunca por CI.

## Workflows

| Workflow | Trigger | O que faz |
| :--- | :--- | :--- |
| `ci.yml` | push/PR em `main` | `nix fmt` + diff check, eval do toplevel das 3 nixosConfigurations (`kernelcore`, `kernelcore-iso`, `k8s-node`), `nix flake check --no-build`, build do check leve `mcp-server` (+ push Cachix em `main`) |
| `quality.yml` | push/PR em `main` | statix (anti-patterns), deadnix (código morto), typos (`.typos.toml`), actionlint, métricas de código no job summary (tokei + contagens de módulos/options) |
| `docs.yml` | push em `main` (docs/modules/hosts) | Gera referência das options `kernelcore.*` (`nix build .#options-doc`, via nixosOptionsDoc) + site mdBook de `docs/` → GitHub Pages |
| `security.yml` | push/PR em `main` + semanal | Secret scan via `reusable-security.yml@main` (central) + vulnix non-blocking |
| `update-flake-lock.yml` | semanal (seg 03:45 UTC) + manual | `nix flake update` → PR em `auto_update_deps` |

Documentação didática dos módulos segue a skill [`skills/nix-doc-didatico`](../skills/nix-doc-didatico/SKILL.md):
descriptions das options são a fonte da referência publicada — documentar
código = escrever descriptions, e o Pages atualiza sozinho.

CI é **eval-only**: o build completo do sistema (CUDA, kernels) não cabe em
`ubuntu-latest`. A validação canônica local continua sendo:

```bash
nix build --dry-run .#nixosConfigurations.kernelcore.config.system.build.toplevel
```

## Secrets

| Secret | Obrigatório | Uso |
| :--- | :--- | :--- |
| `CACHIX_AUTH_TOKEN` | Não | Push de artefatos para o cache `voidnxlabs` (job `checks`, só em `main`; `continue-on-error`). |

Todos os inputs do flake são públicos — CI não precisa de chave SSH.

## Pré-requisitos (uma vez)

- `voidnxlabs-workflows` → Settings → Actions → Access:
  **"Accessible from repositories in the organization"** (o repo é privado;
  sem isso o caller `security.yml` falha).
- Este repo → Settings → Pages → Source = **"GitHub Actions"** (para `docs.yml`).

## Por que não usar `reusable-nix-ci.yml` central?

Ele assume `nix build .` (um `packages.default` buildável) — este repo é uma
configuração NixOS validada por eval, então os jobs Nix são bespoke aqui,
seguindo o mesmo baseline de versões da org (`checkout@v6`,
`install-nix-action@v31`, `cachix-action@v16`, `create-pull-request@v8`,
`ubuntu-latest`).
