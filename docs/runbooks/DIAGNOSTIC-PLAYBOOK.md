# 🩺 Diagnostic Playbook — NixOS Operational Triage

> **Status**: Living document  
> **Objetivo**: Triagem operacional em 3 níveis — do sintoma à raiz em tempo mínimo  
> **Filosofia**: Ferramenta certa no momento certo. Não disparar canhão em mosquito.

---

## Nível 1: CHECK RÁPIDO ⚡ (≤ 30s)

Rode após qualquer `nixos-rebuild` ou quando sentir comportamento estranho.

| # | Check | Comando | Saudável se |
|---|-------|---------|-------------|
| 1 | **Sintaxe Nix** | `nix-instantiate --parse hosts/kernelcore/configuration.nix` | exit 0 |
| 2 | **Build seco** | `sudo nixos-rebuild dry-build --flake /etc/nixos#kernelcore` | sem erros |
| 3 | **Consistência de config** | `audit-check` | `🚨 HIGH: 0` |
| 4 | **Serviços caídos** | `systemctl --failed` | `0 loaded units listed` |
| 5 | **Memória** | `free -h` | `available > 2GB` |
| 6 | **Swap pressure** | `cat /proc/pressure/memory | head -1` | `avg10 < 5.0` |
| 7 | **Disco** | `df -h / /nix` | `Use% < 90%` |
| 8 | **Temperatura** | `sensors 2>/dev/null \|\| cat /sys/class/thermal/thermal_zone*/temp` | `< 80°C` |

**Se todos passarem**: sistema saudável, pode seguir.  
**Se algum falhar**: desce pro Nível 2.

---

## Nível 2: INVESTIGAÇÃO 🔍 (≤ 5min)

### 2.1 — Build quebrado

```bash
# Sintoma: nixos-rebuild switch falha
sudo nixos-rebuild build --flake /etc/nixos#kernelcore 2>&1 | tail -50

# Padrões comuns na saída:
# "error: The option `X' does not exist"           → typo no path
# "error: attribute 'X' missing"                    → módulo não importado
# "error: hash mismatch in fixed-output derivation" → hash desatualizado
```

### 2.2 — Config fantasma (host sem módulo)

```bash
# Opções no configuration.nix que nenhum módulo declara
audit-dead
```

**Ações por severidade**:
| Ícone | Ação |
|-------|------|
| 👻 com value `{...}` | Bloco de agrupamento — ignorar |
| 👻 com value `true`/`false` | Possível dead config — verificar se módulo existe |
| 👻 sem módulo listado | Path não rastreável — verificar imports no flake |

### 2.3 — Módulo órfão (referencia path não configurado)

```bash
# Opções que módulos referenciam mas não estão no host config
audit-gap
```

**Interpretação**:
- `.enable` com default `true` no módulo → OK, usa default
- `.enable` com default `false` → provavelmente feature desabilitada
- Path sem `.enable` → verificar se é opção de valor (string, int)

### 2.4 — Path assumption quebrada

```bash
# Sintoma: ferramenta não encontra arquivo esperado
# Exemplo: chain_manager.py
find /home/kernelcore/master -name "chain_manager.py" 2>/dev/null
# Se encontrou em path diferente do esperado → bug de path assumption
```

**Correção**: symlink ou atualizar config da ferramenta.

### 2.5 — Hash inválido (npm/go/rust)

```bash
# Sintoma: "hash mismatch" no build
# Solução: trocar hash por lib.fakeHash, buildar, copiar o hash real

# 1. Substituir no arquivo .nix:
#    npmDepsHash = "sha256-...";  →  npmDepsHash = lib.fakeHash;

# 2. Buildar (vai falhar mostrando o hash correto):
nix build .#pacote 2>&1 | grep "got:" | awk '{print $2}'

# 3. Substituir lib.fakeHash pelo hash real
```

### 2.6 — Chain quebrada

```bash
# Sintoma: chain_sign retorna erro silencioso
# Diagnóstico:
ls -la /home/kernelcore/master/adr-ledger/.chain/
# Se chain_manager.py existe mas tool procura em outro path →
#   atualizar config ou criar symlink
```

---

## Nível 3: CIRÚRGICO 🏥 (análise profunda)

### 3.1 — Validação tripla da config

```bash
# Declarações (mkOption) ↔ Referências (config.kernelcore.*) ↔ Host config
audit-check
```

**Interpretação**:

| Severidade | Significado | Ação |
|------------|-------------|------|
| 🚨 HIGH | `config.kernelcore.X` usado mas `mkOption` não encontrado | Verificar se é nested declaration ou bug real |
| ⚠️ MED | Declarado + referenciado mas ausente do host config | OK se tem default; adicionar ao host se precisar explícito |
| 💤 LOW | `mkOption` existe mas nunca referenciado via `config.` | Dead code — remover ou wire up |

### 3.2 — Git forensics (quando a quebra foi introduzida)

```bash
# Últimas alterações em um arquivo
git --no-pager log --oneline -10 -- modules/system/memory.nix

# Quem mexeu e quando
git --no-pager blame modules/system/memory.nix | head -20

# Diff entre duas versões
git --no-pager diff HEAD~3 HEAD -- modules/system/memory.nix
```

### 3.3 — Rastreamento de paths

```bash
# Todas as referências a um path específico
grep -rn "kernelcore.security.hardening" modules/ hosts/

# Arquivos que importam um módulo
grep -rn "memory.nix" modules/ hosts/ flake.nix

# Paths órfãos (arquivos não importados por ninguém)
for f in $(find modules -name '*.nix'); do
  grep -q "$(basename $f)" hosts/ flake.nix modules/*/default.nix 2>/dev/null || echo "ÓRFÃO: $f"
done
```

### 3.4 — Inspeção de valores reais

```bash
# Valor de uma option específica (requer sistema buildado)
nix eval --impure --expr '
  let flake = builtins.getFlake "/etc/nixos";
  in flake.nixosConfigurations.kernelcore.config.kernelcore.system.memory
' --json | jq

# Todas as options kernelcore com valores
nix eval --impure --expr '
  let flake = builtins.getFlake "/etc/nixos";
      sys = flake.nixosConfigurations.kernelcore;
  in builtins.mapAttrs (n: v: v.value) sys.options.kernelcore
' --json | jq 'keys'
```

### 3.5 — Journal profundo

```bash
# Erros desde o último boot
journalctl -b -p err --no-pager

# Falhas de serviço específico
journalctl -u nix-daemon --no-pager -n 50

# Timeline de OOM kills
journalctl -b --no-pager | grep -i "oom\|killed process"

# Memory pressure timeline
journalctl -b --no-pager | grep -i "systemd-oomd"
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                  🩺 DIAGNOSTIC PLAYBOOK                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  NÍVEL 1 (30s):                                             │
│    nix-instantiate --parse hosts/kernelcore/configuration   │
│    audit-check                                              │
│    systemctl --failed                                       │
│    free -h                                                  │
│                                                             │
│  NÍVEL 2 (5min):                                            │
│    audit-dead          → config fantasma                    │
│    audit-gap           → módulo órfão                       │
│    find + symlink      → path assumption                    │
│    lib.fakeHash        → hash inválido                      │
│                                                             │
│  NÍVEL 3 (profundo):                                        │
│    audit-check         → validação tripla                   │
│    git --no-pager blame          → quando quebrou           │
│    grep -rn "path" modules/      → rastreamento             │
│    journalctl -b -p err          → logs de erro             │
│                                                             │
│  REGRA DE OURO:                                             │
│    Nível 1 sempre. Só desce se encontrar sintoma.           │
│    Nunca pule direto pro Nível 3 sem passar pelo 2.         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Anti-Patterns Conhecidos

| Anti-pattern | Sintoma | Diagnóstico | Correção |
|-------------|---------|-------------|----------|
| `drop_caches` periódico | I/O lento, cache nunca cresce | `grep drop_caches modules/` | Remover serviço |
| `swapoff -a` forçado | OOM kills em cascata | `grep swapoff modules/` | Remover serviço |
| `overcommit_memory=0` com Electron | malloc falha com RAM livre | `audit-gap` + `cat /proc/sys/vm/overcommit_memory` | Mudar para 1 + OOMD |
| `watermark_scale_factor` > 100 | Swap prematuro, CPU alta com compressão | `audit-gap` | Reduzir para 100 |
| `dirty_ratio` alto (>15%) | I/O stalls perceptíveis | `audit-gap` | Reduzir para 10% |
| Hash desatualizado | Build quebra com "mismatch" | Erro no build | `lib.fakeHash` → build → hash real |
| Path assumption quebrada | Ferramenta não acha arquivo | `find` vs path esperado | Symlink ou corrigir config |
| Sintaxe inválida após edit | `nix-instantiate --parse` falha | Erro de parse | Revisar diff, procurar linhas órfãs |

---

## Workflow Integrado

```bash
# Após qualquer alteração em módulos:
rebuild() {
  echo "🔍 Nível 1..."
  nix-instantiate --parse hosts/kernelcore/configuration.nix || return 1
  echo "✅ Sintaxe OK"

  echo "🔗 Nível 2..."
  audit-check 2>&1 | grep "HIGH: 0" || echo "⚠️  Verificar issues HIGH"

  echo "🏗️ Buildando..."
  sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
}
```

---

## Troubleshooting Rápido por Sintoma

| O que você vê | Provável causa | Primeiro comando |
|---------------|----------------|------------------|
| "The option X does not exist" | Typo ou módulo não importado | `grep -rn "X" modules/ hosts/` |
| "hash mismatch" | Dependência atualizada | `lib.fakeHash` → build |
| "cannot coerce X to Y" | Tipo errado na config | `audit-gap` — ver path |
| Sistema lento após rebuild | `drop_caches` ou swap excessivo | `grep -rn "drop_caches\|swapoff" modules/` |
| malloc falhando | `overcommit_memory=0` | `cat /proc/sys/vm/overcommit_memory` |
| Processos zumbi acumulando | Pais não dão `wait()` | `ps aux | awk '$8~/Z/'` |
| Chain não assina | Path assumption quebrada | `find ~/master -name chain_manager.py` |
| audit-check mostra 🚨 | Referência sem declaração | Inspecionar o módulo listado |

---

_Última atualização: 2026-05-30_  
_Mantido por: kernelcore_  
_Feedback: `audit` + abrir issue_
