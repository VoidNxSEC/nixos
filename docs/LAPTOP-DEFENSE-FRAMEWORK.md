# Laptop Defense Framework - Documentação Completa

> **Sistema Integrado de Proteção Térmica e Forensics**
> **Versão**: 1.0.0
> **Data**: 2025-11-23
> **Integração**: NixOS + MCP Server + Emergency Framework

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Componentes](#componentes)
3. [Rebuild Safety Hooks](#rebuild-safety-hooks)
4. [Thermal Forensics](#thermal-forensics)
5. [MCP Integration](#mcp-integration)
6. [Comandos e Aliases](#comandos-e-aliases)
7. [Configuração](#configuração)
8. [Casos de Uso](#casos-de-uso)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

### O que é?

Framework completo de proteção e análise forense para laptops NixOS, com foco em:

- 🛡️ **Proteção Térmica**: Prevent hardware damage durante rebuilds
- 🔬 **Forensics**: Análise científica de comportamento térmico
- 📊 **Evidence Collection**: Coleta automática de evidências
- 🔌 **MCP Integration**: Ferramentas disponíveis via MCP server
- 🚨 **Emergency Integration**: Conectado ao Emergency Framework

### Por que?

**Problema**: `nixos-rebuild` pode causar:
- Aquecimento extremo (>95°C)
- Danos permanentes ao hardware
- Shutdown térmico inesperado
- Perda de dados

**Solução**: Monitoramento proativo + Análise forense + Decisão automatizada

---

## 🏗️ Componentes

### 1. Flake Principal
**Localização**: `/etc/nixos/modules/hardware/laptop-defense/flake.nix`

**Packages disponíveis**:
```nix
thermal-forensics     # Análise forense completa
thermal-warroom       # Monitor em tempo real
laptop-verdict        # Decisão de substituição
mcp-log-extract       # Extração de MCP knowledge
full-investigation    # Suite completa
```

### 2. Rebuild Hooks
**Localização**: `/etc/nixos/modules/hardware/laptop-defense/rebuild-hooks.nix`

**Funcionalidades**:
- Pre-rebuild thermal check
- Durante-rebuild monitoring
- Post-rebuild evidence collection
- Thermal abort automático

### 3. MCP Integration
**Localização**: `/etc/nixos/modules/hardware/laptop-defense/mcp-integration.nix`

**Tools adicionadas ao MCP**:
- `thermal_forensics`
- `thermal_check`
- `rebuild_safety_check`
- `laptop_verdict`
- `mcp_knowledge_extract`

### 4. Shell Aliases
**Localização**: `/etc/nixos/modules/shell/aliases/laptop-defense.nix`

**30+ aliases** para acesso rápido

---

## 🛡️ Rebuild Safety Hooks

### Como Funcionam

```
┌─────────────────────────────────────────────────────────┐
│ REBUILD SAFETY FLOW                                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. PRE-REBUILD CHECK                                  │
│     ↓                                                   │
│     Temperatura < 75°C?                                │
│     ├─ SIM → Continua                                  │
│     └─ NÃO → ABORT (wait for cooling)                  │
│                                                         │
│  2. DURING REBUILD                                     │
│     ↓                                                   │
│     Monitor contínuo (cada 5s)                         │
│     ↓                                                   │
│     Temperatura < 90°C?                                │
│     ├─ SIM → Continua monitorando                      │
│     └─ NÃO → EMERGENCY ABORT                           │
│          ↓                                              │
│          Kill rebuild                                   │
│          Force CPU powersave                            │
│          Collect evidence                               │
│                                                         │
│  3. POST-REBUILD                                       │
│     ↓                                                   │
│     Success? → Log final temp                          │
│     Failure? → Collect evidence                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Habilitação

```nix
# Em hosts/kernelcore/configuration.nix

{
  imports = [
    ../../modules/hardware/laptop-defense/rebuild-hooks.nix
  ];

  hardware.rebuildHooks = {
    enable = true;

    thermalCheck = {
      enable = true;
      maxStartTemp = 75;      # °C - max para iniciar
      maxRunningTemp = 90;    # °C - max durante rebuild
      monitorInterval = 5;    # segundos entre checks
    };

    evidenceCollection = {
      enable = true;
      storePath = "/var/log/rebuild-evidence";
    };
  };
}
```

### Uso

**Rebuild Seguro**:
```bash
# Usa wrapper com proteção térmica
safe-rebuild
# ou
sr

# Com fast mode
safe-rebuild-fast
# ou
srf
```

**Rebuild Normal** (sem proteção):
```bash
# Bypass (não recomendado)
sudo nixos-rebuild switch
```

---

## 🔬 Thermal Forensics

### Full Investigation Suite

```bash
# Investigação completa (3 fases: baseline, stress, rebuild)
laptop-investigation
# ou
li
```

**Output**:
```
/tmp/thermal-evidence-YYYYMMDD-HHMMSS/
├── raw/
│   ├── thermal-timeline.csv       # Timeline completa
│   ├── stress-output.txt          # Stress test results
│   ├── rebuild-output.txt         # Rebuild logs
│   ├── cpu-info.txt               # CPU specs
│   ├── thermal-zones.txt          # Thermal zones
│   ├── cooling-devices.txt        # Fan status
│   ├── dmi-processor.txt          # DMI info
│   ├── dmi-system.txt             # System info
│   ├── clamav-status.txt          # ClamAV check
│   └── top-cpu-processes.txt      # Process list
│
├── analysis/
│   ├── thermal-analysis.json      # Parsed data
│   └── clamav-verdict.txt         # ClamAV verdict
│
├── VERDICT.txt                    # Decision matrix
└── FINAL-VERDICT.txt              # Automated verdict

Archive: /tmp/thermal-evidence-*.tar.gz
```

### Quick Commands

```bash
# Forensic analysis
thermal-forensics
# ou
tf

# Real-time monitor (war room)
thermal-warroom
# ou
tw

# Quick temperature check
temp-check
# ou
tc

# Continuous monitoring
temp-watch

# Check if safe to rebuild
can-rebuild
# ou
cr
```

### Automated Verdict

```bash
# Gerar veredicto de substituição
laptop-verdict /tmp/thermal-evidence-20251123-120000

# Output:
🎯 DECISION FRAMEWORK - Laptop Replacement Analysis
==================================================

Score: 45/100
Critical Flags: 0

════════════════════════════════════════
FINAL SCORE: 45/100
CRITICAL FLAGS: 0
════════════════════════════════════════

🟢 VERDICT: SOFTWARE ISSUE

Likely causes:
- ClamAV interfering with builds
- Misconfigured power management
- Background indexing services

Recommended actions:
1. Disable ClamAV during rebuilds
2. Optimize Nix daemon settings
3. Review systemd services
```

---

## 🔌 MCP Integration

### Tools Disponíveis

**1. thermal_check**
```json
{
  "name": "thermal_check",
  "description": "Quick thermal check before operation",
  "input": {
    "max_temp": 75  // opcional
  },
  "output": {
    "current_temp": 68,
    "max_acceptable": 75,
    "safe": true
  }
}
```

**2. rebuild_safety_check**
```json
{
  "name": "rebuild_safety_check",
  "output": {
    "thermal_temp": 68,
    "thermal_safe": true,
    "memory_available_mb": 8192,
    "memory_safe": true,
    "load_average": 2,
    "load_safe": true,
    "verdict": "SAFE"
  }
}
```

**3. thermal_forensics**
```json
{
  "name": "thermal_forensics",
  "description": "Run complete thermal forensics analysis",
  "input": {
    "duration": 180  // opcional, segundos
  }
}
```

**4. laptop_verdict**
```json
{
  "name": "laptop_verdict",
  "input": {
    "evidence_dir": "/tmp/thermal-evidence-20251123-120000"
  }
}
```

**5. mcp_knowledge_extract**
```json
{
  "name": "mcp_knowledge_extract",
  "description": "Extract MCP knowledge related to thermal/rebuild issues",
  "input": {
    "days_back": 7  // opcional
  }
}
```

### Uso via CLI

```bash
# Thermal check via MCP
mcp-thermal-check 75

# Rebuild safety check via MCP
mcp-rebuild-check

# Output: JSON com veredicto
{
  "thermal_temp": 68,
  "thermal_safe": true,
  "memory_available_mb": 8192,
  "memory_safe": true,
  "load_average": 2,
  "load_safe": true,
  "verdict": "SAFE"
}
```

### Habilitação

```nix
{
  imports = [
    ../../modules/hardware/laptop-defense/mcp-integration.nix
  ];

  services.mcp.laptopDefense.enable = true;
}
```

---

## ⚙️ Comandos e Aliases

### Quick Reference

| Alias | Comando Completo | Descrição |
|-------|------------------|-----------|
| `tf` | `thermal-forensics` | Análise forense completa |
| `tw` | `thermal-warroom` | Monitor em tempo real |
| `li` | `laptop-investigation` | Suite completa |
| `lv` | `laptop-verdict` | Veredicto de substituição |
| `sr` | `safe-rebuild` | Rebuild com proteção |
| `srf` | `safe-rebuild-fast` | Rebuild fast + proteção |
| `tc` | `temp-check` | Check temperatura |
| `cr` | `can-rebuild` | Verifica se pode rebuild |
| `fc` | `force-cooldown` | Force CPU powersave |
| `rp` | `reset-performance` | Volta a performance |
| `tel` | `thermal-evidence-list` | Lista evidências |
| `tl` | `thermal-log` | View thermal log |
| `ldg` | `laptop-defense-guide` | Este guia |

### Fluxo Típico

```bash
# 1. Verificar se pode fazer rebuild
cr

# Output: ✅ SAFE: Temperature 68°C

# 2. Fazer rebuild seguro
sr

# 3. Se falhar, investigar
li

# 4. Analisar evidências
laptop-verdict /tmp/thermal-evidence-YYYYMMDD-HHMMSS

# 5. Se necessário, monitor contínuo
tw
```

---

## 📊 Configuração

### Minimal Setup (Básico)

```nix
{
  imports = [
    ../../modules/hardware/laptop-defense/rebuild-hooks.nix
  ];

  hardware.rebuildHooks.enable = true;
}
```

### Recommended Setup

```nix
{
  imports = [
    ../../modules/hardware/laptop-defense/rebuild-hooks.nix
    ../../modules/hardware/laptop-defense/mcp-integration.nix
    ../../modules/hardware/laptop-defense/flake.nix
  ];

  hardware.rebuildHooks = {
    enable = true;
    thermalCheck.enable = true;
    evidenceCollection.enable = true;
  };

  services.mcp.laptopDefense.enable = true;
}
```

### Advanced Setup (Com proteção térmica automática)

```nix
{
  imports = [
    ../../modules/hardware/laptop-defense/rebuild-hooks.nix
    ../../modules/hardware/laptop-defense/mcp-integration.nix
    ../../modules/system/emergency-monitor.nix
  ];

  # Rebuild hooks
  hardware.rebuildHooks = {
    enable = true;

    thermalCheck = {
      enable = true;
      maxStartTemp = 70;      # Mais conservador
      maxRunningTemp = 85;    # Mais conservador
      monitorInterval = 3;    # Check mais frequente
    };

    evidenceCollection = {
      enable = true;
      storePath = "/var/log/rebuild-evidence";
    };
  };

  # Emergency monitor (integrado)
  system.emergency = {
    enable = true;
    autoIntervene = true;     # Auto-abort em emergência
    tempThreshold = 85;
  };

  # MCP integration
  services.mcp.laptopDefense.enable = true;

  # Thermal protection (do flake)
  hardware.thermalProtection = {
    enable = true;
    maxTemp = 95;  # Emergency brake
  };
}
```

---

## 🎯 Casos de Uso

### Caso 1: Rebuild Diário (Preventivo)

```bash
# Antes do rebuild, verificar condições
cr

# Se OK, rebuild seguro
sr

# Monitor em janela separada (opcional)
tw
```

### Caso 2: Investigar Problema Térmico

```bash
# 1. Coletar evidências
li

# Aguardar ~10 minutos (baseline + stress + rebuild)

# 2. Analisar resultado
LATEST=$(ls -td /tmp/thermal-evidence-* | head -1)
cat $LATEST/VERDICT.txt

# 3. Gerar veredicto
laptop-verdict $LATEST
```

### Caso 3: Decisão de Substituição

```bash
# 1. Full investigation
li

# 2. Extract MCP knowledge
mcp-extract

# 3. Analyze all evidence
LATEST=$(ls -td /tmp/thermal-evidence-* | head -1)
laptop-verdict $LATEST

# Responder perguntas:
# - Laptop sob garantia? (y/n)
# - Problema recorrente? (y/n)

# Output: REPLACE / INVESTIGATE / SOFTWARE ISSUE
```

### Caso 4: Integração com MCP Agent

```typescript
// No MCP agent/client

// Check antes de rebuild
const safetyCheck = await mcp.callTool('rebuild_safety_check');

if (safetyCheck.verdict === 'SAFE') {
  await mcp.callTool('nixos_rebuild', { mode: 'switch' });
} else {
  console.log('Unsafe conditions:', safetyCheck);
  // Wait or alert user
}
```

---

## 🔧 Troubleshooting

### Q: Rebuild abortou com "Temperature too high"

**A**: Sistema está protegendo hardware.

```bash
# 1. Verificar temperatura atual
tc

# 2. Se >75°C, aguardar cooldown
# Monitorar:
temp-watch

# 3. Se necessário, force cooldown
fc

# 4. Aguardar <70°C, tentar novamente
cr
sr
```

### Q: Como desabilitar proteção térmica?

**A**: Não recomendado, mas:

```nix
hardware.rebuildHooks.thermalCheck.enable = false;
```

Ou bypass:
```bash
sudo nixos-rebuild switch  # Sem safe-rebuild
```

### Q: Thermal forensics falhou

**A**: Verificar dependências:

```bash
# Instalar sensors
nix-shell -p lm_sensors stress-ng

# Testar
sensors
stress-ng --cpu 1 --timeout 10s
```

### Q: MCP tools não aparecem

**A**: Verificar integração:

```bash
# Check se MCP está rodando
systemctl status mcp-server

# Verificar tools file
cat /etc/mcp/tools/laptop-defense.json

# Rebuild para ativar
sudo nixos-rebuild switch
```

### Q: Evidence collection não funciona

**A**: Verificar permissões:

```bash
# Check directory
ls -la /var/log/rebuild-evidence/

# Criar se não existir
sudo mkdir -p /var/log/rebuild-evidence
sudo chmod 755 /var/log/rebuild-evidence
```

---

## 📚 Referências Técnicas

### Arquivos do Framework

```
/etc/nixos/modules/hardware/laptop-defense/
├── flake.nix                  # Packages principais
├── rebuild-hooks.nix          # Pre/post rebuild hooks
└── mcp-integration.nix        # MCP server tools

/etc/nixos/modules/shell/aliases/
└── laptop-defense.nix         # Shell aliases

/etc/nixos/docs/
├── LAPTOP-DEFENSE-FRAMEWORK.md   # Este documento
└── REBUILD-HOOKS.md              # Detalhes dos hooks

/var/log/
├── rebuild-thermal.log        # Monitor log
└── rebuild-evidence/          # Evidence archives
```

### Thresholds Recomendados

| Situação | maxStartTemp | maxRunningTemp | Ação |
|----------|--------------|----------------|------|
| **Conservador** | 70°C | 85°C | Laptops antigos/problema térmico |
| **Balanceado** (padrão) | 75°C | 90°C | Uso geral |
| **Agressivo** | 80°C | 95°C | Hardware novo/bom cooling |

### Integração com Outros Frameworks

**Emergency Framework**:
```nix
# emergency-abort também aborta rebuilds
ema
```

**MCP Knowledge**:
```bash
# Buscar problemas térmicos anteriores
mcp-search "thermal rebuild freeze"
```

---

## 🚀 Roadmap

### Futuro (v2.0)

- [ ] Machine learning para predição térmica
- [ ] Gráficos de temperatura (gnuplot integration)
- [ ] Webhook notifications (Discord/Slack)
- [ ] Cloud evidence upload (backup remoto)
- [ ] Multi-laptop comparison
- [ ] Historical trending analysis
- [ ] BIOS/UEFI integration checks
- [ ] Automated RMA evidence generation

---

**Versão**: 1.0.0
**Última Atualização**: 2025-11-23
**Autor**: kernelcore + Claude
**License**: MIT
**Integração**: Emergency Framework v1.0.0 + MCP Server v2.0.0
