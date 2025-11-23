# NIX EMERGENCY PROCEDURES - Guia Completo

> **Framework de Resposta a Emergências do Sistema**
> **Versão**: 1.0.0
> **Data**: 2025-11-23
> **Autor**: kernelcore

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Sintomas e Diagnósticos](#sintomas-e-diagnósticos)
3. [Comandos de Emergência](#comandos-de-emergência)
4. [Procedimentos por Situação](#procedimentos-por-situação)
5. [Monitoramento Automático](#monitoramento-automático)
6. [Prevenção](#prevenção)
7. [FAQ](#faq)

---

## 🎯 Visão Geral

### O que é este framework?

Sistema completo de resposta a emergências para situações críticas no NixOS:

- 🔥 **CPU Overheat** - Superaquecimento
- 💾 **SWAP Thrashing** - Disco virtual esgotado
- 🐏 **OOM** - Memória RAM esgotada
- ⚙️  **High Load** - Carga excessiva (builds massivos)
- 🔒 **System Freeze** - Sistema travado/lento

### Componentes

```
/etc/nixos/
├── scripts/
│   └── nix-emergency.sh           ← Script principal
├── modules/
│   ├── shell/aliases/
│   │   └── emergency.nix          ← Aliases rápidos
│   └── system/
│       └── emergency-monitor.nix  ← Monitoramento 24/7
└── docs/
    └── NIX-EMERGENCY-PROCEDURES.md ← Este documento
```

---

## 🚨 Sintomas e Diagnósticos

### Como Identificar Problemas

| Sintoma | Causa Provável | Severidade | Ação Recomendada |
|---------|----------------|------------|------------------|
| Sistema lento/travado | High Load + SWAP | 🔴 Crítico | `ema` (abort) |
| Ventilador alto/barulhento | CPU Overheat | 🟡 Alto | `emc` (cooldown) |
| Aplicações crashando | OOM (falta RAM) | 🔴 Crítico | `emswap` |
| Laptop não responde | Deadlock | 🔴 Crítico | `emn` (nuke) |
| Build demora horas | CPU overload | 🟡 Alto | `ema` (abort) |

### Diagnóstico Rápido

```bash
# Status completo do sistema
ems

# ou
emergency-status
```

**Output esperado**:
```
╔════════════════════════════════════════════════════════════╗
║          NIX EMERGENCY - STATUS DO SISTEMA                ║
╚════════════════════════════════════════════════════════════╝

🖥️  CPU:
   Uso: 98%
   Load Average: 76.36              ← 🔴 CRÍTICO!
   Temperatura: 85°C                ← 🔥 OVERHEAT!

💾 MEMÓRIA:
   RAM: 98%
   SWAP: 85%                         ← 🔴 CRÍTICO!

🔧 PROCESSOS NIX:
   nix builds: 1
   nixbld workers: 6                ← ⚠️  Builds ativos

📊 DIAGNÓSTICO:
   🔴 CPU OVERLOAD (load: 76.36)
   🔴 OVERHEAT (temp: 85°C)
   🔴 SWAP THRASHING (85%)

💡 RECOMENDAÇÃO:
   Execute: nix-emergency abort
```

---

## ⚡ Comandos de Emergência

### Comandos Principais

| Comando | Alias Curto | Descrição | Quando Usar |
|---------|-------------|-----------|-------------|
| `emergency-status` | `ems` | Ver status completo | Diagnóstico inicial |
| `emergency-abort` | `ema` | Abortar builds NIX | Sistema lento por builds |
| `emergency-cooldown` | `emc` | Reduzir temperatura | CPU superaquecendo |
| `emergency-swap` | `emswap` | Liberar SWAP | SWAP >80% |
| `emergency-nuke` | `emn` | ⚠️  Matar processos pesados | Último recurso |
| `emergency-monitor` | `emmon` | Monitor contínuo | Prevenção |
| `emergency-help` | `emhelp` | Ajuda completa | Dúvidas |

### Comandos Quick (Ultra-Rápidos)

| Alias | Descrição |
|-------|-----------|
| `knix` | Kill nix builds (instantâneo) |
| `kcc` | Kill compiladores |
| `ss` | System status (CPU+RAM+SWAP) |
| `nb` | Nix builds (listar ativos) |

---

## 🛠️ Procedimentos por Situação

### Situação 1: Sistema Travado/Lento

**Sintomas**:
- Interface gráfica lenta
- Mouse travando
- Aplicações não respondem
- Ventilador alto

**Diagnóstico**:
```bash
ems  # Ver status
```

**Se mostrar** "CPU OVERLOAD" ou "SWAP THRASHING":

**Solução**:
```bash
# 1. Abortar builds
ema

# 2. Aguardar 30s (sistema vai estabilizar)

# 3. Verificar recuperação
ems
```

**Resultado esperado**:
- Load average cai de 70+ para <10 em 60s
- SWAP reduz gradualmente
- Sistema volta a responder

---

### Situação 2: CPU Superaquecendo

**Sintomas**:
- Ventilador no máximo
- Temperatura >80°C
- Laptop quente ao toque
- Possível shutdown térmico

**Diagnóstico**:
```bash
cpu-temp  # Ver temperatura
```

**Solução**:
```bash
# 1. Cooldown imediato
emc

# 2. Aguardar cooldown (30s)

# 3. Verificar temperatura
cpu-temp
```

**Resultado esperado**:
- Temperatura reduz 10-15°C em 30s
- Ventilador reduz velocidade
- CPU em modo powersave

---

### Situação 3: SWAP Esgotado

**Sintomas**:
- Sistema muito lento
- Disco SSD em uso constante
- SWAP >80%
- Aplicações crashando (OOM killer)

**Diagnóstico**:
```bash
free -h  # Ver SWAP usage
```

**Solução**:
```bash
# 1. Emergência SWAP
emswap

# 2. Aguardar limpeza

# 3. Verificar SWAP
free -h
```

**Resultado esperado**:
- SWAP reduz de 14GB para <5GB
- Builds abortados
- Sistema estabiliza

---

### Situação 4: Laptop Não Responde (Deadlock)

**Sintomas**:
- Nada funciona
- TTY não responde
- SSH funciona (se houver)

**Solução via SSH** (se disponível):
```bash
# 1. SSH de outro computador
ssh kernelcore@laptop-ip

# 2. NUKE (último recurso)
emergency-nuke

# 3. Confirmar com 's'
```

**Solução via TTY** (Ctrl+Alt+F2):
```bash
# 1. Login no TTY2 (Ctrl+Alt+F2)

# 2. NUKE
sudo bash /etc/nixos/scripts/nix-emergency.sh nuke

# 3. Confirmar com 's'
```

**Resultado esperado**:
- Processos pesados terminados
- Sistema recupera em 60-120s
- RAM liberada

---

### Situação 5: `nix flake check` Travou Sistema

**Causa**:
- `nix flake check` compila TUDO simultaneamente
- ISO + VM + Docker + ML packages
- 10+ GB RAM + 20+ GB SWAP

**Sintomas**:
- Comando rodando há >30 minutos
- Load average >50
- Sistema inutilizável

**Solução**:
```bash
# 1. Abortar IMEDIATAMENTE
ema

# 2. Aguardar estabilização
sleep 30

# 3. Usar versão segura
safe-check  # = nix flake check --no-build
```

**Prevenção**:
```bash
# NUNCA rodar:
nix flake check            # ❌ Perigoso

# SEMPRE rodar:
nix flake check --no-build # ✅ Seguro
safe-check                 # ✅ Alias seguro
```

---

### Situação 6: Build Não Termina Nunca

**Sintomas**:
- `nixos-rebuild switch` há horas
- CPU 100% constante
- RAM+SWAP esgotados

**Diagnóstico**:
```bash
nb  # Ver builds ativos
nw  # Ver workers nixbld
```

**Solução**:
```bash
# 1. Abortar build
ema

# 2. Rebuild com recursos limitados
safe-rebuild  # = nixos-rebuild switch --max-jobs 2 --cores 4 --fast
```

**Resultado esperado**:
- Build termina em tempo razoável
- Sistema utilizável durante build

---

## 📊 Monitoramento Automático

### Habilitar Monitoramento 24/7

Adicione em `hosts/kernelcore/configuration.nix`:

```nix
{
  imports = [
    ../../modules/system/emergency-monitor.nix
  ];

  system.emergency = {
    enable = true;              # Ativar monitoramento
    autoIntervene = false;      # false = apenas alerta
                                # true = intervém automaticamente

    # Thresholds
    swapThreshold = 85;         # SWAP % crítico
    tempThreshold = 85;         # Temperatura CPU crítica
    loadThreshold = 32;         # Load average crítico (2x cores)
  };
}
```

### Modo Manual (Alerta Apenas)

```nix
system.emergency = {
  enable = true;
  autoIntervene = false;  # ← Apenas monitora e loga
};
```

**Comportamento**:
- Monitora sistema 24/7
- Loga alertas em `/var/log/emergency-monitor.log`
- **NÃO intervém automaticamente**
- Você decide quando agir

### Modo Automático (Intervenção)

```nix
system.emergency = {
  enable = true;
  autoIntervene = true;   # ← Intervém automaticamente
};
```

**Comportamento**:
- Monitora sistema 24/7
- **Intervém automaticamente**:
  - SWAP >85% → Executa `swap-emergency`
  - Temperatura >85°C → Executa `cooldown`
  - Load >32 + builds NIX → Executa `abort`

**⚠️  Cuidado**: Pode abortar builds legítimos!

### Verificar Logs

```bash
# Ver alertas recentes
sudo tail -50 /var/log/emergency-monitor.log

# Monitorar em tempo real
sudo tail -f /var/log/emergency-monitor.log

# Ver intervenções automáticas
sudo grep "AUTO-INTERVENTION" /var/log/emergency-monitor.log
```

---

## 🛡️ Prevenção

### 1. Configurar Limites no flake.nix

```nix
{
  nixConfig = {
    max-jobs = 2;           # Máximo 2 builds paralelos
    cores = 4;              # Máximo 4 cores por build
    max-silent-time = 300;  # Timeout 5min sem output
  };
}
```

### 2. Usar Comandos Seguros

```bash
# Validação (sem build)
safe-check

# Build limitado
safe-build <package>

# Rebuild limitado
safe-rebuild
```

### 3. Remover Checks Pesados

Em `flake.nix`, comente checks pesados:

```nix
checks.${system} = {
  fmt = ...;              # ✅ Leve
  # iso = ...;            # ❌ Desabilitado (2GB+)
  # vm = ...;             # ❌ Desabilitado (3GB+)
  # docker-app = ...;     # ❌ Desabilitado (1GB+)
};
```

### 4. Monitoramento Preventivo

```bash
# Monitorar durante build
watch-sys

# ou
emergency-monitor  # Monitor contínuo (Ctrl+C para sair)
```

---

## ❓ FAQ

### Q: O que significa Load Average 76?

**A**: Significa que 76 processos estão esperando por CPU (você tem 16 cores). Sistema está 4.75x sobre-capacidade.

**Normal**: <16 (número de cores)
**Alto**: 16-32
**Crítico**: >32
**Emergência**: >50

---

### Q: Por que SWAP é ruim?

**A**: SWAP usa SSD/HDD como RAM virtual. É **10-100x mais lento**. Quando SWAP está cheio, sistema fica inutilizável ("thrashing").

**Uso saudável**: <20%
**Preocupante**: 20-50%
**Crítico**: >50%
**Emergência**: >80%

---

### Q: `nix-emergency nuke` é seguro?

**A**: Mata processos **não-críticos** (builds, compiladores, apps pesados). **NÃO mata**:
- systemd
- dbus
- X/Wayland
- NetworkManager
- SSH

É **último recurso** quando sistema está totalmente travado.

---

### Q: Como evitar `nix flake check` travar sistema?

**A**:
```bash
# NUNCA:
nix flake check  # ❌

# SEMPRE:
nix flake check --no-build  # ✅
safe-check                  # ✅
```

---

### Q: Devo habilitar `autoIntervene = true`?

**A**:

**Sim** se:
- Você roda builds pesados frequentemente
- Esquece de monitorar recursos
- Quer proteção automática

**Não** se:
- Você quer controle total
- Builds são críticos (não podem ser abortados)
- Prefere intervir manualmente

**Recomendação**: Comece com `false`, teste manualmente, depois habilite se necessário.

---

### Q: Qual a diferença entre `abort` e `nuke`?

**A**:

| Comando | O que mata | Uso |
|---------|------------|-----|
| `abort` | Apenas builds NIX | Sistema lento por builds |
| `nuke` | Builds NIX + processos pesados | Sistema totalmente travado |

`abort` é **seguro**, `nuke` é **agressivo**.

---

### Q: O que fazer se laptop desligar sozinho?

**A**: Provável shutdown térmico (>95°C).

1. Desligar laptop
2. Aguardar esfriar (10 min)
3. Ligar e **imediatamente**:
   ```bash
   emc  # Cooldown preventivo
   ```
4. Habilitar monitoramento:
   ```nix
   system.emergency = {
     enable = true;
     tempThreshold = 75;  # ← Mais conservador
     autoIntervene = true;
   };
   ```

---

## 📚 Referências Técnicas

### Arquivos do Framework

```
/etc/nixos/scripts/nix-emergency.sh            ← Script principal
/etc/nixos/modules/shell/aliases/emergency.nix ← Aliases
/etc/nixos/modules/system/emergency-monitor.nix ← Systemd service
/var/log/nix-emergency.log                     ← Logs manuais
/var/log/emergency-monitor.log                 ← Logs auto-monitor
```

### Comandos de Diagnóstico

```bash
# CPU
uptime                  # Load average
top -b -n 1            # Processos por CPU
sensors                # Temperatura (se disponível)
cat /sys/class/thermal/thermal_zone0/temp  # Temperatura (fallback)

# Memória
free -h                # RAM + SWAP
swapon --show          # Info detalhada SWAP

# Processos NIX
pgrep -af "nix.*build"  # Builds ativos
pgrep nixbld           # Workers nixbld
ps aux | grep nixbld   # Workers com detalhes
```

---

## 🚀 Quick Reference (Cola)

```bash
# DIAGNÓSTICO
ems              # Status completo
ss               # Status rápido
cpu-temp         # Temperatura CPU
nb               # Builds NIX ativos

# EMERGÊNCIA (do mais seguro ao mais agressivo)
ema              # Abort builds NIX
emswap           # Limpar SWAP
emc              # Cooldown CPU
emn              # NUKE (último recurso)

# PREVENÇÃO
safe-check       # nix flake check --no-build
safe-rebuild     # nixos-rebuild (limitado)
emmon            # Monitor contínuo

# HELP
emhelp           # Ajuda completa
emguide          # Este guia
```

---

**Versão**: 1.0.0
**Última Atualização**: 2025-11-23
**Autor**: kernelcore
**License**: MIT
