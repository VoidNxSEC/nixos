---
name: nix-doc-didatico
description: Gera comentários didáticos e documentação automática para módulos NixOS deste repo. Use ao documentar módulos kernelcore.*, escrever descriptions de options, preparar o options-doc (nixosOptionsDoc) ou revisar a cobertura de documentação antes da Fase 6.
---

# Nix Doc Didático

Padroniza como este repo documenta código Nix para que a documentação
automática (`nix build .#options-doc` → GitHub Pages via `docs.yml`)
produza uma referência de verdade, e para que qualquer módulo seja
legível por quem nunca o abriu.

## Pipeline de documentação do repo

1. **Fonte**: `description` de cada `mkOption`/`mkEnableOption` + comentário
   de cabeçalho de cada módulo.
2. **Geração**: `lib/packages.nix` → `options-doc` usa `pkgs.nixosOptionsDoc`
   sobre `nixosConfigurations.kernelcore.options.kernelcore` — tudo que tem
   `description` aparece na referência com tipo, default e link pro arquivo.
3. **Publicação**: `.github/workflows/docs.yml` monta mdBook de `docs/` +
   a referência de options e publica no GitHub Pages.

Consequência prática: **documentar é escrever descriptions** — não .md solto.

## Template de cabeçalho de módulo

Todo módulo em `modules/` começa com:

```nix
{ config, lib, pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# <NOME DO MÓDULO> — <uma linha do que faz>
#
# Propósito : por que este módulo existe (problema que resolve)
# Ativação  : kernelcore.<caminho>.enable = true;
# Depende de: <outros módulos kernelcore.* ou serviços upstream>
# Segurança : <impacto de segurança, se houver — senão omitir>
# ═══════════════════════════════════════════════════════════
```

## Regras para descriptions de options

- **Toda** option nova tem `description` (o `options-doc` mostra as que
  faltam como entradas vazias — isso é dívida).
- Descrição diz o *efeito* (“Abre a porta X no firewall e sobe o serviço Y”),
  não repete o nome (“Enable feature”).
- Default não-óbvio → explicar no `description` ou usar `defaultText`.
- `example` em options com formato não trivial (attrsets, listas de peers).
- Comentário inline só para restrição que o código não mostra
  (workaround de bug upstream, ordem obrigatória, mkForce e por quê).

## Checklist de cobertura (rodar antes de fechar a Fase 6)

```bash
# Options sem description em modules/
grep -rn "mkOption {" modules --include="*.nix" -A4 | grep -L description

# Módulos sem cabeçalho didático (primeiras 5 linhas sem comentário de bloco)
for f in $(find modules -name '*.nix'); do
  head -6 "$f" | grep -q '^#' || echo "$f"
done

# Gerar e inspecionar a referência
nix build .#options-doc && head -50 result/options.md
```

## O que NÃO fazer

- Não duplicar em `docs/*.md` o que a description já diz — o .md rota,
  a description compila.
- Não escrever comentário que narra a linha seguinte ("# habilita o serviço").
- Não usar `lib.mdDoc` (deprecated no nixpkgs atual — descriptions já são
  Markdown por padrão).
