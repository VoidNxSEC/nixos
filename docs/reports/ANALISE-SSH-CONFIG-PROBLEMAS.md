# 🚨 Análise Crítica: ssh-config.nix - Problemas Identificados

**Data**: 2025-11-26
**Arquivo**: `/etc/nixos/modules/system/ssh-config.nix`
**Status**: ❌ CONFIGURAÇÃO INATIVA COM ERROS CRÍTICOS

---

## 🔴 PROBLEMA 1: CONFIGURAÇÃO COMPLETAMENTE DESABILITADA

### Evidência
**Linhas 125-208**: Todo o bloco de configuração SSH está comentado
```nix
# Uncomment if using home-manager:
/*
  home-manager.users.kernelcore = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        # ... toda a configuração aqui está DESABILITADA
      };
    };
  };
*/
```

### Impacto
- ❌ Nenhuma das configurações declarativas está ativa
- ❌ Aliases SSH (github.com-marcos, desktop, etc) NÃO funcionam
- ❌ Chaves SSH não são carregadas automaticamente
- ❌ IdentitiesOnly não está aplicado

### Causa
O módulo foi criado mas a seção home-manager foi deixada comentada, provavelmente aguardando ativação manual.

---

## 🔴 PROBLEMA 2: IP DO DESKTOP INCORRETO

### Evidência
**Linha 185**: Desktop configurado com IP errado
```nix
"desktop" = {
  hostname = "192.168.15.6";  # ❌ ERRADO!
  user = "kernelcore";
  identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.serverKey}";
  identitiesOnly = true;
  port = 22;
};
```

### IP Correto Confirmado
```bash
$ nmap -sn 192.168.15.0/24
Nmap scan report for 192.168.15.7
Host is up (0.0047s latency).
```

Desktop está em **192.168.15.7**, não .6

### Impacto
- ❌ Alias `ssh desktop` conectaria ao host errado
- ❌ Remote builds falhariam (IP incorreto)
- ❌ Poderia tentar conectar em host inexistente ou errado

---

## 🔴 PROBLEMA 3: CHAVE SSH INEXISTENTE

### Evidência
**Linha 187**: Tenta usar `id_ed25519_server` que não existe
```nix
identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.serverKey}";
# Expande para: /home/kernelcore/.ssh/id_ed25519_server
```

**Chaves realmente disponíveis no laptop:**
```bash
$ ls -la ~/.ssh/id_* | grep -v ".pub"
-rw------- 1 kernelcore users 411 Sep 29 16:58 /home/kernelcore/.ssh/id_ed25519
-rw------- 1 kernelcore users 484 Nov 26 XX:XX /home/kernelcore/.ssh/nix-builder
```

**Chaves que o módulo espera (mas não existem):**
- ❌ `id_ed25519_marcos` (linha 31)
- ❌ `id_ed25519_voidnxlabs` (linha 38)
- ❌ `id_ed25519_server` (linha 45)
- ❌ `id_ed25519_gitlab` (linha 52)

### Impacto
- ❌ SSH falharia tentando usar chaves inexistentes
- ❌ Configuração declarativa não funciona com realidade do sistema
- ❌ Aliases SSH quebrados

---

## 🔴 PROBLEMA 4: serverHost APONTA PARA O PRÓPRIO LAPTOP

### Evidência
**Linha 59**: Default do serverHost está errado
```nix
serverHost = mkOption {
  type = types.str;
  default = "192.168.15.9";  # ❌ Este é o IP do laptop!
  description = "Internal NixOS server hostname/IP";
};
```

**IP real do laptop:**
```bash
$ ip addr show wlp62s0 | grep "inet "
inet 192.168.15.9/24 brd 192.168.15.255 scope global dynamic
```

### Impacto
- ❌ Configuração "voidnx-server" aponta para localhost
- ❌ Conexões circulares
- ❌ Confusão sobre qual é o server vs laptop

---

## 🟡 PROBLEMA 5: MÓDULO PODE NÃO ESTAR HABILITADO

### Evidência
**Linha 70**: Configuração só ativa se habilitada
```nix
config = mkIf config.kernelcore.ssh.enable {
  # ...
};
```

### Status Desconhecido
Não verificamos se `kernelcore.ssh.enable = true;` está em `configuration.nix`

### Impacto Potencial
- Se não estiver habilitado: módulo completamente inativo
- Aliases não funcionam
- SSH agent não configurado

---

## 🔧 SOLUÇÕES PROPOSTAS

### Solução 1: Verificar e Habilitar o Módulo

```nix
# Em hosts/kernelcore/configuration.nix
kernelcore.ssh.enable = true;
```

### Solução 2: Corrigir IPs

```nix
# Linha 59: Corrigir serverHost (desktop, não laptop)
serverHost = mkOption {
  type = types.str;
  default = "192.168.15.7";  # ✅ Desktop correto
  description = "Desktop/builder hostname/IP";
};

# Linha 185: Confirmar IP do desktop
"desktop" = {
  hostname = "192.168.15.7";  # ✅ Corrigido
  user = "kernelcore";
  # ...
};
```

### Solução 3: Usar Chaves Existentes

**Opção A: Renomear chaves existentes**
```bash
# No laptop:
cd ~/.ssh
cp id_ed25519 id_ed25519_server
# Ou criar links simbólicos
```

**Opção B: Modificar módulo para usar chaves reais**
```nix
# Linha 31-54: Alterar defaults
personalKey = mkOption {
  type = types.str;
  default = "id_ed25519";  # ✅ Existe
  description = "Personal SSH key filename";
};

serverKey = mkOption {
  type = types.str;
  default = "id_ed25519";  # ✅ Usar chave padrão
  description = "Server SSH key filename";
};

# Ou usar nix-builder para desktop:
"desktop" = {
  hostname = "192.168.15.7";
  user = "nix-builder";  # Se for para builds remotos
  identityFile = "~/.ssh/nix-builder";  # ✅ Esta chave existe
  identitiesOnly = true;
};
```

### Solução 4: Descomentar Home Manager Config

```nix
# Linha 125-208: Descomentar APENAS se home-manager estiver instalado
# Verificar primeiro se home-manager está disponível:
```

```bash
# Verificar se home-manager está no sistema
nix show-config | grep home-manager
# ou
which home-manager
```

Se home-manager NÃO estiver instalado, usar configuração alternativa via `extraConfig`.

### Solução 5: Configuração Manual Temporária

Enquanto o módulo não é corrigido, criar `~/.ssh/config` manual:

```bash
cat > ~/.ssh/config <<'EOF'
# Desktop/Builder
Host desktop
  HostName 192.168.15.7
  User kernelcore
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

# Nix Builder (remote builds)
Host desktop-builder
  HostName 192.168.15.7
  User nix-builder
  IdentityFile ~/.ssh/nix-builder
  IdentitiesOnly yes

# GitHub
Host github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

# Global settings
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 120
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 600
EOF

chmod 600 ~/.ssh/config
```

---

## 📋 PLANO DE CORREÇÃO RECOMENDADO

### Passo 1: Verificar Home Manager

```bash
# Verificar se home-manager está instalado
which home-manager
nix-env -q | grep home-manager
```

### Passo 2: Escolher Abordagem

**Se home-manager ESTÁ instalado:**
- Descomentar linhas 125-208
- Corrigir IPs
- Ajustar chaves para usar existentes

**Se home-manager NÃO está:**
- Mover configuração para `programs.ssh.extraConfig`
- Criar arquivo ~/.ssh/config via activation script
- Ajustar aliases

### Passo 3: Implementar Correções

```nix
# Correção mínima necessária (sem home-manager):

programs.ssh.extraConfig = ''
  # Desktop/Builder
  Host desktop
    HostName 192.168.15.7
    User kernelcore
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

  Host desktop-builder
    HostName 192.168.15.7
    User nix-builder
    IdentityFile ~/.ssh/nix-builder
    IdentitiesOnly yes

  # GitHub
  Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
'';
```

### Passo 4: Rebuild e Testar

```bash
# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Testar
ssh desktop "hostname"
ssh desktop-builder "echo 'Remote build ready'"
```

---

## 🎯 CORREÇÕES PRIORITÁRIAS

### Alta Prioridade (Bloqueador)
1. ✅ **Corrigir IP do desktop**: .6 → .7
2. ✅ **Usar chaves existentes**: id_ed25519 e nix-builder
3. ✅ **Habilitar módulo**: `kernelcore.ssh.enable = true;`

### Média Prioridade
4. ⚠️ **Descomentar home-manager** (se instalado)
5. ⚠️ **Criar configuração alternativa** (se não tem home-manager)

### Baixa Prioridade
6. 💡 **Documentar chaves reais** no README
7. 💡 **Criar script de validação** de chaves SSH

---

## ✅ VALIDAÇÃO PÓS-CORREÇÃO

```bash
# 1. Verificar configuração SSH gerada
cat ~/.ssh/config

# 2. Testar conexão desktop
ssh -vvv desktop "hostname"

# 3. Testar conexão builder
ssh -vvv desktop-builder "echo OK"

# 4. Verificar chaves carregadas
ssh-add -l

# 5. Testar remote build
nix-build '<nixpkgs>' -A hello --option builders 'ssh://nix-builder@192.168.15.7'
```

---

## 📊 RESUMO DOS PROBLEMAS

| # | Problema | Severidade | Impacto | Status |
|---|----------|------------|---------|--------|
| 1 | Config desabilitada (comentada) | 🔴 Crítico | SSH declarativo não funciona | Pendente |
| 2 | IP desktop incorreto (.6 → .7) | 🔴 Crítico | Conexões falham | Pendente |
| 3 | Chaves inexistentes | 🔴 Crítico | Autenticação falha | Pendente |
| 4 | serverHost aponta laptop | 🟡 Médio | Confusão de hosts | Pendente |
| 5 | Módulo não habilitado? | 🟡 Médio | Inativo completamente | Verificar |

---

**Este arquivo documenta todos os problemas encontrados no ssh-config.nix que explicam por que o SSH não está funcionando entre laptop e desktop.**
