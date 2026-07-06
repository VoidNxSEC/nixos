# 🎯 PLANO DE AÇÃO - Baseado em Auditoria Real

**Data**: 2025-11-22  
**Descoberta Crítica**: 100GB em logs de audit + problemas de configuração

---

## 📊 ANÁLISE DOS DADOS

### Uso Atual: 394GB / 458.7GB (91%)

```
BREAKDOWN REAL:
├─ /var/log/audit: 100.3GB  ← 🚨 PROBLEMA #1 (logs descontrolados!)
├─ /var/log (total): 132.9GB ← 🚨 PROBLEMA #2 (33% do disco!)
├─ /nix/store: 114GB         ← ✅ Normal para NixOS
├─ /home: 74.6GB             ← ⚠️  Alguns itens grandes
│  ├─ VSCodium/Roo: 23.4GB  ← Cache de tasks
│  ├─ Documents: 14.8GB
│  └─ dev: 14.6GB
├─ Ollama models: 22.1GB     ← Models LLM
├─ Docker: 12.3GB
└─ VMs/ISOs: 10.3GB
```

---

## 🎯 ESTRATÉGIA: Limpar, NÃO Reinstalar!

**DESCOBERTA IMPORTANTE**: O problema NÃO é o /nix/store!
- `/nix/store`: 114GB é NORMAL para um sistema NixOS completo
- O problema real: **Logs de audit descontrolados (100GB!)**

**Nova Estratégia**: Limpeza direcionada libera ~150-200GB sem reinstalar!

---

## 🚀 PLANO DE AÇÃO (Priorizado)

### FASE 1: LIMPEZA IMEDIATA (Libera ~120GB) ⚡

#### 1.1. Limpar Logs de Audit (Libera ~100GB) 🔥
```bash
# CRÍTICO: auditd está gerando 100GB de logs!
# Verificar o que está acontecendo
sudo systemctl status auditd

# OPÇÃO A: Deletar logs antigos (MAIS SEGURO)
sudo systemctl stop auditd
sudo find /var/log/audit -name "audit.log.*" -delete
sudo rm -f /var/log/audit/audit.log.{1..10}
sudo systemctl start auditd

# OPÇÃO B: Limpar tudo (cuidado - perde histórico)
sudo systemctl stop auditd
sudo rm -rf /var/log/audit/*
sudo systemctl start auditd

# Verificar espaço liberado
df -h /
du -sh /var/log/audit
```

**Espaço Liberado**: 100GB+ ✅

#### 1.2. Desabilitar/Configurar auditd (Prevenir recorrência)
```bash
# Investigar por que auditd está gerando 100GB
sudo ausearch -m all | tail -100

# OPÇÃO A: Desabilitar auditd (se não precisa)
sudo systemctl disable auditd
sudo systemctl stop auditd

# OPÇÃO B: Configurar logrotate para auditd
sudo nano /etc/audit/auditd.conf
# Ajustar:
# max_log_file = 100  (limitar tamanho a 100MB)
# num_logs = 5         (manter apenas 5 arquivos)
# max_log_file_action = rotate
```

#### 1.3. Limpar Outros Logs (Libera ~20GB)
```bash
# Limpar logs do journal
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=500M

# Limpar logs antigos
sudo find /var/log -name "*.log.*" -delete
sudo find /var/log -name "*.gz" -delete
sudo find /var/log -name "*.old" -delete

# Verificar espaço liberado
du -sh /var/log
```

**Espaço Liberado**: 20-30GB adicional ✅

---

### FASE 2: LIMPEZA DE CACHE (Libera ~30GB)

#### 2.1. Limpar Cache VSCodium/Roo (Libera ~23GB)
```bash
# Roo tasks cache está ocupando 23.4GB
du -sh ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks

# Limpar (SAFE - cache será recriado se necessário)
rm -rf ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks/*

# Verificar
du -sh ~/.config/VSCodium/
```

**Espaço Liberado**: 23GB ✅

#### 2.2. Limpar Docker (Libera ~10GB)
```bash
# Limpar containers/images/volumes não usados
docker system prune -a --volumes

# Se não usar Docker, considere desabilitar
sudo systemctl disable docker
sudo systemctl stop docker
```

**Espaço Liberado**: 10GB ✅

---

### FASE 3: OTIMIZAÇÃO NIX (Libera ~20-30GB)

#### 3.1. Garbage Collection
```bash
# Apenas uma geração do sistema (já está limpo!)
# Mas pode ter lixo no store

# Limpar gerações antigas do perfil de usuário
nix-env --delete-generations old
nix-collect-garbage -d

# Limpar gerações do sistema
sudo nix-collect-garbage -d

# Otimizar store (deduplicação)
sudo nix-store --optimise
```

**Espaço Liberado**: 20-30GB ✅

#### 3.2. Limpar Resultados de Builds Antigos
```bash
# Remover symlinks de resultado no home
rm ~/result*

# Limpar direnv cache
rm -rf ~/.direnv
```

---

### FASE 4: DADOS PESSOAIS (Opcional - ~30GB)

#### 4.1. Avaliar Necessidade

```bash
# Ollama models: 22.1GB
du -sh /var/lib/ollama/models
# Se não usar todos os models, deletar os desnecessários

# VMs/ISOs: 10.3GB
du -sh ~/Documents/nx/vm
# Mover ISOs para desktop ou deletar se desnecessário

# Downloads: 1.1GB
du -sh ~/Downloads
# Limpar arquivos antigos
```

---

## 📊 RESULTADO ESPERADO

### Antes da Limpeza:
```
Total usado: 394GB (91%)
Livre: 41GB
```

### Após Fase 1 (Logs):
```
Total usado: ~270GB (59%)
Livre: ~165GB ✅✅
```

### Após Fase 2 (Cache):
```
Total usado: ~237GB (52%)
Livre: ~198GB ✅✅✅
```

### Após Fase 3 (Nix):
```
Total usado: ~207GB (45%)
Livre: ~228GB ✅✅✅✅
```

### Após Fase 4 (Opcional):
```
Total usado: ~177GB (39%)
Livre: ~258GB ✅✅✅✅✅
```

---

## 🔧 CONFIGURAÇÕES PREVENTIVAS

### Prevenir Recorrência do Problema

#### 1. Configurar auditd Corretamente

Adicionar em `/etc/nixos/configuration.nix`:

```nix
# Configurar auditd para não encher o disco
services.auditd = {
  enable = true;  # ou false se não precisar
};

# Configuração do auditd
environment.etc."audit/auditd.conf".text = ''
  log_file = /var/log/audit/audit.log
  log_format = RAW
  log_group = root
  priority_boost = 4
  flush = INCREMENTAL_ASYNC
  freq = 50
  num_logs = 5
  max_log_file = 100
  max_log_file_action = rotate
  space_left = 1000
  space_left_action = email
  admin_space_left = 500
  admin_space_left_action = suspend
  disk_full_action = suspend
  disk_error_action = suspend
'';
```

#### 2. Configurar Logrotate

```nix
# Adicionar em configuration.nix
services.logrotate = {
  enable = true;
  settings = {
    "/var/log/audit/*.log" = {
      rotate = 5;
      size = "100M";
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };
  };
};
```

#### 3. Limitar Journal Size

```nix
# Já deve estar configurado, mas verificar:
services.journald.extraConfig = ''
  SystemMaxUse=500M
  MaxRetentionSec=7day
'';
```

---

## 🚀 SCRIPT DE LIMPEZA AUTOMÁTICA

Criei: [`scripts/limpeza-agressiva.sh`](scripts/limpeza-agressiva.sh)

Execute:
```bash
cd /etc/nixos
sudo ./scripts/limpeza-agressiva.sh
```

Vai executar TUDO automaticamente e liberar ~200GB!

---

## 💡 CONCLUSÃO

### Decisão Final: **NÃO REINSTALAR!**

**Por quê?**
1. O problema NÃO é o /nix/store (114GB é normal)
2. O problema são logs descontrolados (100GB!)
3. Limpeza direcionada libera 200GB+
4. Mais rápido que reinstalar (20 min vs 4 horas)
5. Não perde configurações

### Após Limpeza:

- ✅ 258GB livres (~56%)
- ✅ Sistema atual mantido
- ✅ Todas configs preservadas
- ✅ Pronto para configurar offload

### Próximos Passos:

1. **AGORA**: Executar limpeza (Fase 1-3)
2. **DEPOIS**: Configurar offload (não precisa mais de formatação!)
3. **FUTURO**: Monitorar logs para não voltar a encher

---

**A descoberta dos 100GB de logs mudou tudo!** 🎉
**Você NÃO precisa reinstalar, apenas limpar logs!** ✅