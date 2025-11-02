# SSH Configuration Guide - NixOS

## Overview

Este guia mostra **3 formas** de gerenciar SSH config no NixOS de forma declarativa.

## Método 1: Manual ~/.ssh/config (Atual)

**Vantagens:**
- Simples e direto
- Funciona imediatamente
- Familiar para usuários Linux

**Desvantagens:**
- Não é declarativo
- Não versionado no Git
- Precisa gerenciar manualmente

```bash
# Seu template atual
cat ~/.ssh/config
```

---

## Método 2: `programs.ssh` System-wide (Recomendado para single-user)

**Vantagens:**
- Declarativo (parte do NixOS config)
- Versionado no Git
- Rebuilt automaticamente

**Desvantagens:**
- Aplica para todos os usuários do sistema

### Como Usar:

**1. Habilitar o módulo em `configuration.nix`:**

```nix
{
  imports = [
    ./modules/system/ssh-config.nix
  ];

  kernelcore.ssh = {
    enable = true;

    # Customizar se necessário
    personalKey = "id_ed25519_marcos";
    orgKey = "id_ed25519_voidnxlabs";
    serverHost = "192.168.15.7";
  };
}
```

**2. Rebuild:**

```bash
sudo nixos-rebuild switch
```

**3. Usar:**

```bash
# Git com identidade pessoal
git clone git@github.com-marcos:username/repo.git

# Git com identidade da organização
git clone git@github.com-voidnxlabs:voidnxlabs/repo.git

# SSH para desktop
ssh desktop
# ou
ssh-desktop
```

---

## Método 3: Home-Manager (Mais flexível)

**Vantagens:**
- Configuração por usuário
- Melhor para multi-user systems
- Integra com dotfiles

**Desvantagens:**
- Requer setup do home-manager

### Setup:

**1. Instalar home-manager (se não tem):**

```nix
# Em flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

**2. Configurar em `home.nix`:**

```nix
{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;

    # Configuração global
    extraConfig = ''
      AddKeysToAgent yes
      ServerAliveInterval 60
      ForwardAgent no
    '';

    # Hosts específicos
    matchBlocks = {
      "github.com-marcos" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_marcos";
        identitiesOnly = true;
      };

      "github.com-voidnxlabs" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_voidnxlabs";
        identitiesOnly = true;
      };

      "desktop" = {
        hostname = "192.168.15.7";
        user = "kernelcore";
        identityFile = "~/.ssh/id_ed25519_server";
      };
    };
  };
}
```

**3. Rebuild home-manager:**

```bash
home-manager switch
```

---

## Comparação

| Feature | Manual | programs.ssh | home-manager |
|---------|--------|--------------|--------------|
| Declarativo | ❌ | ✅ | ✅ |
| Versionado | ❌ | ✅ | ✅ |
| Por usuário | ✅ | ❌ | ✅ |
| Setup simples | ✅ | ✅ | ⚠️ |
| Rollback | ❌ | ✅ | ✅ |
| Multi-host | ⚠️ | ✅ | ✅ |

---

## Recomendação

### Para seu caso (single-user, NixOS):

**Usar Método 2 (programs.ssh)** porque:
- ✅ Já está no NixOS config
- ✅ Simples de manter
- ✅ Versionado com o resto do sistema
- ✅ Não precisa home-manager adicional

### Se futuramente quiser multi-host:

**Migrar para home-manager** porque:
- Permite configs diferentes por máquina
- Melhor separação user/system config

---

## Migração do Template Atual

### Opção A: Manter manual + adicionar declarativo

```nix
# configuration.nix
programs.ssh.extraConfig = ''
  # Seu config atual aqui
'';
```

### Opção B: Migrar completamente

1. Copiar ~/.ssh/config atual
2. Converter para `matchBlocks` no módulo
3. Testar com `nix flake check`
4. Rebuild
5. Remover ~/.ssh/config manual

---

## Gerenciamento de Chaves

### Chaves no SOPS (Seguro)

Para chaves privadas sensíveis:

```nix
# secrets/ssh-keys.yaml (encrypted with SOPS)
github-deploy-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

```nix
# modules/secrets/ssh-keys.nix
{
  sops.secrets."github-deploy-key" = {
    mode = "0600";
    owner = "kernelcore";
    path = "/home/kernelcore/.ssh/id_ed25519_deploy";
  };
}
```

### Chaves Pessoais (No SOPS ou manual)

Chaves pessoais normais podem ficar em ~/.ssh/ normalmente, mas:
- ✅ Fazer backup
- ✅ Não commitar no Git
- ✅ Adicionar ~/.ssh/*.pub no Git (públicas OK)

---

## Aliases Úteis

Já incluídos no módulo:

```bash
ssh-desktop          # SSH para desktop
ssh-server           # SSH para server
ssh-add-all          # Adiciona todas as chaves
ssh-list             # Lista chaves no agent
ssh-test-github      # Testa conexão GitHub
ssh-keygen-ed25519   # Gera nova chave ed25519
```

---

## Próximos Passos

### 1. Testar o módulo:

```bash
# Habilitar em configuration.nix
kernelcore.ssh.enable = true;

# Rebuild
sudo nixos-rebuild switch

# Testar
ssh-test-github
ssh desktop
```

### 2. Migrar gradualmente:

- Começar com 1-2 hosts no módulo
- Testar que funciona
- Migrar resto aos poucos
- Manter backup do ~/.ssh/config original

### 3. Adicionar ao Git:

```bash
git add modules/system/ssh-config.nix
git commit -m "feat: Add declarative SSH configuration module"
```

---

## Troubleshooting

### Config não está sendo aplicado

```bash
# Verificar que o módulo foi importado
nix-instantiate --eval -E '(import <nixpkgs/nixos> {}).config.programs.ssh.extraConfig'

# Verificar arquivo gerado
cat /etc/ssh/ssh_config
```

### Chave errada sendo usada

```bash
# Debug verbose
ssh -vvv git@github.com-marcos 2>&1 | grep "identity file"

# Forçar chave específica
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_marcos git@github.com
```

### Agent não carrega chaves

```bash
# Verificar agent
ssh-add -l

# Reiniciar agent
systemctl --user restart ssh-agent
```

---

## Referências

- [NixOS Manual - SSH](https://nixos.org/manual/nixos/stable/options.html#opt-programs.ssh.extraConfig)
- [Home-Manager SSH](https://nix-community.github.io/home-manager/options.html#opt-programs.ssh.enable)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

---

**Maintained By**: kernelcore
**Last Updated**: 2025-11-02
**Status**: Ready for use
