# 📡 Centralização de Logs no Desktop

**Objetivo**: Enviar logs do laptop para o desktop, economizando espaço e centralizando auditoria

---

## 🎯 Arquitetura

```
┌─────────────────────────────────┐
│   LAPTOP (Cliente)              │
│  ┌──────────────────────────┐   │
│  │ auditd → rsyslog         │   │
│  │ journald → rsyslog       │   │
│  │ system logs → rsyslog    │   │
│  └──────────┬───────────────┘   │
│             │ TCP/514           │
│             │ ou TCP/6514(TLS)  │
└─────────────┼───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│   DESKTOP (Servidor de Logs)    │
│  ┌──────────────────────────┐   │
│  │ rsyslog server :514      │   │
│  │ ↓                        │   │
│  │ /var/log/remote/laptop/  │   │
│  │  ├─ audit.log            │   │
│  │  ├─ syslog               │   │
│  │  └─ messages             │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

**Benefícios**:
- ✅ Laptop: logs mínimos (~1-2GB max)
- ✅ Desktop: todos os logs centralizados
- ✅ Auditoria: logs preservados mesmo se laptop quebrar
- ✅ Segurança: logs em máquina mais segura/estável

---

## 🔧 CONFIGURAÇÃO

### Parte 1: Desktop como Servidor de Logs

Adicionar em `/etc/nixos/hosts/kernelcore/configuration.nix` **do DESKTOP**:

```nix
{ config, pkgs, ... }:

{
  # ... configurações existentes ...

  # ===== SERVIDOR DE LOGS CENTRALIZADO =====
  services.rsyslog = {
    enable = true;
    
    # Receber logs via TCP (mais confiável que UDP)
    extraConfig = ''
      # Módulos necessários
      module(load="imtcp")
      
      # Escutar na porta 514 (TCP)
      input(type="imtcp" port="514")
      
      # Template para organizar logs por hostname
      template(name="RemoteHost" type="string" 
               string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
      
      # Salvar logs de hosts remotos
      if $fromhost-ip != '127.0.0.1' then {
        action(type="omfile" dynaFile="RemoteHost")
        stop
      }
      
      # Logs locais ficam em /var/log normal
    '';
  };

  # Criar diretórios para logs remotos
  systemd.tmpfiles.rules = [
    "d /var/log/remote 0755 root root -"
    "d /var/log/remote/nx 0755 root root -"  # nx = hostname do laptop
  ];

  # Abrir firewall para rsyslog
  networking.firewall = {
    allowedTCPPorts = [ 514 ];  # rsyslog
  };

  # Logrotate para logs remotos
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/remote/**/*.log" = {
        rotate = 30;         # Manter 30 dias
        daily = true;
        size = "100M";       # Rotacionar se > 100MB
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        create = "0640 root root";
      };
    };
  };
}
```

### Parte 2: Laptop como Cliente de Logs

Adicionar em `/etc/nixos/hosts/kernelcore/configuration.nix` **do LAPTOP**:

```nix
{ config, pkgs, ... }:

{
  # ... configurações existentes ...

  # ===== CLIENTE DE LOGS REMOTOS =====
  services.rsyslog = {
    enable = true;
    
    extraConfig = ''
      # Enviar todos os logs para o desktop
      # *.* = todos os facilities e severidades
      # @ = TCP (mais confiável que UDP)
      # 192.168.15.7:514 = desktop
      *.* @@192.168.15.7:514
      
      # Também manter cópias locais (mas com rotação agressiva)
      # Para debug imediato quando desktop está offline
    '';
  };

  # Configurar journald para não acumular logs
  services.journald.extraConfig = ''
    # Limitar journald localmente
    SystemMaxUse=500M
    MaxRetentionSec=3day
    ForwardToSyslog=yes  # Enviar para rsyslog
  '';

  # Desabilitar auditd localmente (logs vão para desktop)
  # OU configurar para enviar via rsyslog
  services.auditd = {
    enable = false;  # Desabilitar se não precisar localmente
    # OU se precisar:
    # enable = true;
    # E logs vão via rsyslog automaticamente
  };

  # Logrotate agressivo local (apenas backup)
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/*.log" = {
        rotate = 3;          # Manter apenas 3 dias localmente
        daily = true;
        size = "50M";        # Rotacionar se > 50MB
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };
}
```

---

## 🚀 SETUP PASSO A PASSO

### Passo 1: Configurar Desktop (5 min)

```bash
# 1. SSH no desktop
ssh cypher@192.168.15.7

# 2. Editar configuração
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix

# 3. Adicionar configuração do servidor de logs (copiar acima)

# 4. Aplicar
sudo nixos-rebuild switch

# 5. Verificar que rsyslog está escutando
sudo netstat -tlnp | grep 514
# Deve mostrar: tcp 0 0.0.0.0:514 LISTEN

# 6. Verificar diretório de logs
ls -la /var/log/remote/
```

### Passo 2: Configurar Laptop (5 min)

```bash
# 1. Editar configuração local
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix

# 2. Adicionar configuração do cliente (copiar acima)

# 3. Aplicar
sudo nixos-rebuild switch

# 4. Verificar que rsyslog está enviando
sudo systemctl status rsyslog

# 5. Testar envio de log
logger -t TEST "Teste de log centralizado"

# 6. No desktop, verificar se chegou:
ssh cypher@192.168.15.7 'sudo tail /var/log/remote/nx/TEST.log'
```

### Passo 3: Verificar Funcionamento

```bash
# No laptop, gerar alguns logs:
logger -p local0.info -t TESTE "Log de teste 1"
logger -p local0.warn -t TESTE "Log de teste 2"
logger -p local0.err -t TESTE "Log de teste 3"

# No desktop, verificar recebimento:
ssh cypher@192.168.15.7 'sudo tail -f /var/log/remote/nx/*.log'
```

---

## 📊 RESULTADO ESPERADO

### No Laptop (Após Setup):

```bash
# Logs locais: MÍNIMOS
du -sh /var/log
# Esperado: 500MB - 2GB (max)

# Journald limitado
journalctl --disk-usage
# Esperado: <500MB

# auditd desabilitado ou enviando remotamente
systemctl status auditd
# Desabilitado ou enviando para desktop
```

### No Desktop (Centralizando):

```bash
# Logs do laptop organizados
ls -lh /var/log/remote/nx/
# audit.log, syslog, messages, etc.

# Todos acessíveis para auditoria
du -sh /var/log/remote/nx/
# Crescimento controlado por logrotate
```

---

## 🔒 SEGURANÇA (Opcional - TLS)

Para logs mais sensíveis, use TLS:

### Desktop (Servidor):
```nix
services.rsyslog.extraConfig = ''
  # Carregar módulos TLS
  module(load="imtcp" 
         StreamDriver.Name="gtls"
         StreamDriver.Mode="1"
         StreamDriver.Authmode="anon")
  
  # Escutar com TLS
  input(type="imtcp" port="6514")
'';

networking.firewall.allowedTCPPorts = [ 6514 ];
```

### Laptop (Cliente):
```nix
services.rsyslog.extraConfig = ''
  # Enviar com TLS
  *.* action(type="omfwd"
             target="192.168.15.7"
             port="6514"
             protocol="tcp"
             StreamDriver="gtls"
             StreamDriverMode="1"
             StreamDriverAuthMode="anon")
'';
```

---

## 💾 SOBRE O CACHE DO MCP

**Tranquilo!** O script de limpeza **NÃO toca** em:

```bash
/etc/nixos/knowledge.db          ← MCP knowledge base (PRESERVADO)
/etc/nixos/.mcp.json             ← MCP config (PRESERVADO)
/etc/nixos/                      ← Todo /etc/nixos (PRESERVADO)
```

O que é limpo:
```bash
/var/log/audit/                  ← Logs audit (100GB)
/var/log/*.log                   ← Logs sistema
~/.config/VSCodium/*/tasks/      ← Cache Roo
~/.cache/                        ← Cache usuário (opcional)
```

**MCP permanece intacto com todos os trabalhos salvos!** ✅

---

## 🎯 VANTAGENS DA CENTRALIZAÇÃO

### 1. Espaço no Laptop
- Antes: 100GB+ em logs
- Depois: 1-2GB max (rotação agressiva)
- Economia: 98GB permanente ✅

### 2. Auditoria Centralizada
- Todos os logs em um lugar
- Fácil buscar/analisar
- Histórico preservado

### 3. Resiliência
- Logs sobrevivem se laptop quebrar
- Desktop é mais estável
- Backup mais fácil (um lugar só)

### 4. Performance
- Menos I/O no laptop
- SSD do laptop dura mais
- Writes vão para desktop

---

## 📋 CHECKLIST

### Desktop:
- [ ] rsyslog configurado como servidor
- [ ] Porta 514 aberta no firewall
- [ ] Diretório `/var/log/remote/` criado
- [ ] Logrotate configurado para logs remotos
- [ ] Testado: `sudo netstat -tlnp | grep 514`

### Laptop:
- [ ] rsyslog configurado como cliente
- [ ] Apontando para 192.168.15.7:514
- [ ] journald limitado a 500MB
- [ ] auditd desabilitado ou enviando remotamente
- [ ] Logrotate agressivo (3 dias local)
- [ ] Testado: logs chegando no desktop

---

## 🚀 EXECUTE AGORA

### 1. Desktop Primeiro:
```bash
ssh cypher@192.168.15.7
# Adicionar config de servidor de logs
sudo nixos-rebuild switch
```

### 2. Laptop Depois:
```bash
# Adicionar config de cliente
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix
sudo nixos-rebuild switch
```

### 3. Testar:
```bash
logger -t TESTE "Log centralizado funcionando"
ssh cypher@192.168.15.7 'sudo tail /var/log/remote/nx/TESTE.log'
```

---

**Ideia brilhante! Logs centralizados + MCP preservado + Offload = Sistema perfeito! 🎉**