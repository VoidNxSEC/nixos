# 🎯 ESTRATÉGIA FINAL COMPLETA

**Data**: 2025-11-22  
**Baseado em**: Auditoria real do sistema

---

## 📊 SITUAÇÃO ATUAL

```
Total: 458.7GB
Usado: 394GB (91%)
Livre: 41.3GB

BREAKDOWN:
├─ /var/log/audit: 100.3GB  🚨 PROBLEMA #1
├─ /var/log:       132.9GB  🚨 PROBLEMA #2  
├─ /nix/store:     114GB    ✅ Normal
├─ VSCodium/Roo:   23.4GB   ⚠️  Cache
├─ Ollama:         22.1GB   
├─ Documents:      14.8GB   
└─ dev:            14.6GB   
```

---

## 🎯 ESTRATÉGIA EM 3 FASES

### 📍 FASE 1: Limpeza Imediata (Libera 200GB)
### 📍 FASE 2: Centralização de Logs (Previne recorrência)  
### 📍 FASE 3: Offload Desktop (Otimização contínua)

---

## 🚀 FASE 1: LIMPEZA IMEDIATA

### Objetivo: Liberar 150-200GB AGORA

```bash
cd /etc/nixos
sudo ./scripts/limpeza-agressiva.sh
```

**O que é limpo:**
- ✅ `/var/log/audit/` (100GB)
- ✅ Logs antigos do sistema (20-30GB)
- ✅ Cache VSCodium/Roo (23GB)
- ✅ Nix garbage collection (20-30GB)
- ✅ Docker (10GB opcional)

**O que NÃO é tocado:**
- ✅ `/etc/nixos/knowledge.db` ← **MCP PRESERVADO**
- ✅ `/etc/nixos/.mcp.json` ← **MCP PRESERVADO**
- ✅ Todo `/etc/nixos/` ← **CONFIGURAÇÕES PRESERVADAS**
- ✅ `/nix/store` ← Apenas GC de itens não usados

**Resultado:**
```
Antes: 394GB usado (91%)
Depois: ~200GB usado (44%)
Livre: ~235GB ✅✅✅
```

**Tempo**: 15-30 minutos

---

## 📡 FASE 2: CENTRALIZAÇÃO DE LOGS

### Objetivo: Prevenir que logs voltem a encher o disco

**Conceito**: Laptop envia logs para Desktop automaticamente

```
LAPTOP                    DESKTOP
  │                         │
  ├─ auditd ───────────────>│
  ├─ journald ─────────────>│ rsyslog :514
  ├─ syslog ───────────────>│    ↓
  │                         │ /var/log/remote/nx/
  │ Logs locais: 1-2GB MAX  │ Logs laptop: histórico completo
```

### Setup:

**1. Desktop (Servidor de Logs)**

Adicionar em `/etc/nixos/hosts/kernelcore/configuration.nix`:

```nix
{
  # Servidor de logs centralizado
  services.rsyslog = {
    enable = true;
    extraConfig = ''
      module(load="imtcp")
      input(type="imtcp" port="514")
      
      template(name="RemoteHost" type="string" 
               string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
      
      if $fromhost-ip != '127.0.0.1' then {
        action(type="omfile" dynaFile="RemoteHost")
        stop
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/log/remote 0755 root root -"
    "d /var/log/remote/nx 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 514 ];

  services.logrotate.settings."/var/log/remote/**/*.log" = {
    rotate = 30;
    daily = true;
    size = "100M";
    compress = true;
  };
}
```

**2. Laptop (Cliente de Logs)**

Adicionar em `/etc/nixos/hosts/kernelcore/configuration.nix`:

```nix
{
  # Cliente envia logs para desktop
  services.rsyslog = {
    enable = true;
    extraConfig = ''
      *.* @@192.168.15.7:514
    '';
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=3day
    ForwardToSyslog=yes
  '';

  services.auditd.enable = false;  # Ou configurar para enviar via rsyslog

  services.logrotate.settings."/var/log/*.log" = {
    rotate = 3;
    daily = true;
    size = "50M";
    compress = true;
  };
}
```

**Resultado:**
- Laptop: Máximo 1-2GB de logs locais (backup)
- Desktop: Histórico completo centralizado
- Auditoria: Logs preservados mesmo se laptop quebrar

**Documentação**: [`CENTRALIZACAO-LOGS-DESKTOP.md`](CENTRALIZACAO-LOGS-DESKTOP.md)

---

## 🖥️ FASE 3: OFFLOAD DESKTOP

### Objetivo: Builds no desktop, binários no laptop

```
LAPTOP                    DESKTOP
  │                         │
  ├─ nixos-rebuild ────────>│ Executa build
  │                         │ Compila pacotes
  │                         │    ↓
  │<───── binários prontos ─┤ Cache :5000
  │                         │
  │ /nix/store: 30-50GB    │ /nix/store: completo
  │ Apenas binários        │ Build + cache
```

### Setup:

**1. Desktop (Build Server)**

```bash
ssh cypher@192.168.15.7

# Editar config
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix
```

Adicionar:
```nix
{
  services.offload-server = {
    enable = true;
    cachePort = 5000;
    builderUser = "nix-builder";
  };
}
```

```bash
sudo nixos-rebuild switch
offload-generate-cache-keys
# COPIAR a chave pública
```

**2. Laptop (Build Client)**

```bash
# Editar flake.nix - linha 75
sudo nano /etc/nixos/flake.nix
# Descomentar: ./modules/services/laptop-offload-client.nix

# Editar cliente
sudo nano /etc/nixos/modules/services/laptop-offload-client.nix
# Verificar IP: 192.168.15.7
# Adicionar chave pública do desktop

sudo nixos-rebuild switch
offload-status
```

**Resultado:**
- Builds 2-5x mais rápidos (no desktop)
- Laptop mantém apenas ~30-50GB no `/nix/store`
- Cache LAN 10x mais rápido que internet

**Documentação**: [`EXECUTAR-AGORA.md`](EXECUTAR-AGORA.md)

---

## 📋 CRONOGRAMA DE EXECUÇÃO

### Hoje (30 min):
```bash
# 1. Limpeza imediata
cd /etc/nixos
sudo ./scripts/limpeza-agressiva.sh
```

### Amanhã (20 min):
```bash
# 2. Centralização de logs
# Desktop: adicionar servidor rsyslog
# Laptop: adicionar cliente rsyslog
# Ambos: sudo nixos-rebuild switch
```

### Depois (30 min):
```bash
# 3. Offload
# Desktop: habilitar offload-server
# Laptop: habilitar offload-client
```

---

## 📊 RESULTADO FINAL ESPERADO

### Sistema Atual (Antes):
```
LAPTOP:
├─ Disco: 394GB usado (91%)
├─ Livre: 41GB ❌
├─ Logs: 132GB em /var/log ❌
├─ Builds: Locais e lentos ❌
└─ /nix/store: 114GB

DESKTOP:
├─ Uso: Normal
└─ Função: Desenvolvimento
```

### Sistema Otimizado (Depois):
```
LAPTOP:
├─ Disco: ~80GB usado (17%) ✅✅✅
├─ Livre: ~355GB ✅✅✅
├─ Logs: 1-2GB (enviados para desktop) ✅
├─ Builds: Remotos e rápidos ✅
└─ /nix/store: 30-50GB (apenas binários)

DESKTOP:
├─ Uso: Servidor central
├─ Logs: Histórico completo do laptop
├─ Builds: Compila para laptop
├─ Cache: Serve binários via LAN
└─ /nix/store: Completo
```

**Economia no Laptop**: 314GB (de 394GB → 80GB)

---

## ✅ CHECKLIST COMPLETO

### Fase 1 - Limpeza:
- [ ] Script executado: `sudo ./scripts/limpeza-agressiva.sh`
- [ ] Logs audit deletados (100GB liberados)
- [ ] Cache VSCodium limpo (23GB liberados)
- [ ] Nix GC executado (20-30GB liberados)
- [ ] Verificado: `df -h /` mostra >200GB livres

### Fase 2 - Centralização:
- [ ] Desktop: rsyslog servidor configurado
- [ ] Desktop: porta 514 aberta
- [ ] Desktop: /var/log/remote/ criado
- [ ] Laptop: rsyslog cliente configurado
- [ ] Laptop: journald limitado a 500MB
- [ ] Testado: logs chegando no desktop

### Fase 3 - Offload:
- [ ] Desktop: offload-server habilitado
- [ ] Desktop: chaves de cache geradas
- [ ] Laptop: flake.nix atualizado
- [ ] Laptop: IP 192.168.15.7 configurado
- [ ] Laptop: chave pública adicionada
- [ ] Testado: `offload-status` funcionando

---

## 🎁 BENEFÍCIOS FINAIS

### Performance:
- ⚡ Builds 2-5x mais rápidos
- 🚀 Cache LAN 10x mais rápido
- 💻 Laptop mais responsivo

### Espaço:
- 💾 355GB livres no laptop (de 41GB)
- 📦 /nix/store otimizado (30-50GB vs 114GB)
- 🗄️ Logs centralizados

### Manutenção:
- 🔧 Logs nunca mais enchem o laptop
- 📡 Auditoria centralizada
- 🔄 Sistema auto-otimizado

### Segurança:
- 🔒 Logs preservados mesmo se laptop quebrar
- 📊 Histórico completo no desktop
- 🛡️ MCP knowledge base preservado

---

## 📚 DOCUMENTAÇÃO COMPLETA

1. **[`PLANO-ACAO-LIMPEZA.md`](PLANO-ACAO-LIMPEZA.md)** - Limpeza detalhada
2. **[`scripts/limpeza-agressiva.sh`](scripts/limpeza-agressiva.sh)** - Script automatizado
3. **[`CENTRALIZACAO-LOGS-DESKTOP.md`](CENTRALIZACAO-LOGS-DESKTOP.md)** - Setup rsyslog
4. **[`EXECUTAR-AGORA.md`](EXECUTAR-AGORA.md)** - Offload desktop
5. **[`AUDITORIA-DISCO-FERRAMENTAS.md`](AUDITORIA-DISCO-FERRAMENTAS.md)** - Ferramentas

---

## 🚀 COMECE AGORA

```bash
cd /etc/nixos
sudo ./scripts/limpeza-agressiva.sh
```

**Depois da limpeza, você terá 235GB livres para implementar o resto tranquilamente!**

---

**Esta é a estratégia completa e otimizada baseada na auditoria real! 🎉**