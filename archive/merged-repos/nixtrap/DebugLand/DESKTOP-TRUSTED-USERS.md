# 🔑 DESKTOP - Adicionar nix-builder aos Trusted Users

## ⚠️ IMPORTANTE
O usuário `nix-builder` precisa estar em `trusted-users` para poder executar builds remotos!

## 📋 Verificar Configuração Atual

```bash
# Ver trusted-users atual
nix config show | grep trusted-users

# Buscar onde está definido
grep -r "trusted-users" /etc/nixos/
```

## ✅ Adicionar nix-builder

### Opção 1: Módulo de Segurança (Recomendado)

Editar o arquivo relevante (ex: `modules/security/nix-daemon.nix`):

```nix
# Antes:
trusted-users = [ "@wheel" ];

# Depois:
trusted-users = [ "@wheel" "nix-builder" ];
```

### Opção 2: Configuration.nix Direto

Se não tiver módulos, edite `/etc/nixos/configuration.nix`:

```nix
nix.settings.trusted-users = [ "root" "@wheel" "nix-builder" ];
```

### Opção 3: Adicionar Declarativamente (Melhor Prática)

Criar módulo dedicado em `/etc/nixos/modules/services/nix-builder.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.nix-builder.enable = mkEnableOption "Enable remote Nix builder user";
  };

  config = mkIf config.services.nix-builder.enable {
    # Criar usuário
    users.users.nix-builder = {
      isSystemUser = true;
      group = "nix-builder";
      home = "/home/nix-builder";
      createHome = true;
      shell = pkgs.bash;
      description = "Nix Remote Builder";
      openssh.authorizedKeys.keys = [
        # Chave pública do laptop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhQMUdwtcERELNkvzah839QJH2CiDmUCBnoa+ZsPcrk nix-builder@laptop-to-desktop"
      ];
    };

    users.groups.nix-builder = {};

    # Adicionar aos trusted-users
    nix.settings.trusted-users = [ "nix-builder" ];
  };
}
```

Depois no `configuration.nix` ou `flake.nix`:
```nix
{
  imports = [ ./modules/services/nix-builder.nix ];
  services.nix-builder.enable = true;
}
```

## 🔄 Aplicar Mudanças

```bash
# Verificar sintaxe
nix flake check

# Aplicar
sudo nixos-rebuild switch

# Verificar
nix config show | grep trusted-users
id nix-builder
```

## ✅ Resultado Esperado

Depois do rebuild:
```bash
nix config show | grep trusted-users
# Deve mostrar: trusted-users = root @wheel nix-builder
```

## 🧪 Testar

No laptop, depois que desktop fizer rebuild:
```bash
offload-test-build
```

Deve funcionar sem erros de permissão!
