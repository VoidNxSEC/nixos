# Gitea Showcase - Declarative Setup Guide

## Overview

O módulo `gitea-showcase` agora é **100% declarativo**! Nada de scripts imperativos - tudo é gerenciado via systemd services e sops-nix para secrets.

## Arquitetura

### Systemd Services (Automáticos)

1. **`gitea-cloudflare-dns.service`** + **`.timer`**
   - Sincroniza DNS automaticamente no Cloudflare
   - Detecta IP público e atualiza registro A
   - Roda a cada hora (configurável)
   - Usa `LoadCredential` para secrets seguros

2. **`gitea-init-repos.service`**
   - Cria repositórios no Gitea automaticamente no primeiro boot
   - Usa `ConditionPathExists` para rodar apenas uma vez
   - Marca como concluído em `/var/lib/gitea/.repos-initialized`

3. **`gitea-mirror-showcases.service`** + **`.timer`**
   - Sincroniza projetos locais para o Gitea
   - Roda periodicamente (configurável)
   - Acessa diretórios do usuário com permissões corretas

## Setup Passo a Passo

### 1. Configurar Secrets (sops-nix)

Primeiro, adicione os secrets ao arquivo SOPS:

```bash
# Edit secrets file
cd /etc/nixos
sops secrets/api-keys/gitea-secrets.yaml
```

Adicione os seguintes campos:

```yaml
cloudflare-api-token: "your_cloudflare_api_token_here"
gitea-admin-token: "will_be_generated_later"
```

### 2. Configurar sops-nix no NixOS

Adicione ao seu `configuration.nix` ou módulo de secrets:

```nix
sops.secrets = {
  cloudflare-api-token = {
    sopsFile = ./secrets/api-keys/gitea-secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  gitea-admin-token = {
    sopsFile = ./secrets/api-keys/gitea-secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };
};
```

### 3. Obter Cloudflare Zone ID e API Token

#### Zone ID:
1. Acesse [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Selecione seu domínio (`voidnx.com`)
3. Copie o **Zone ID** da barra lateral direita

#### API Token:
1. Acesse [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Create Token > Edit zone DNS (template)
3. Permissions:
   - Zone > DNS > Edit
   - Zone > Zone > Read
4. Zone Resources:
   - Include > Specific zone > `voidnx.com`
5. Create Token e copie o valor

### 4. Atualizar configuration.nix

```nix
services.gitea-showcase = {
  enable = true;
  domain = "git.voidnx.com";
  httpsPort = 3443;

  cloudflare = {
    enable = true;
    zoneId = "abc123def456..."; # Seu Zone ID aqui
    apiTokenFile = "/run/secrets/cloudflare-api-token";
    updateInterval = "hourly";
  };

  gitea = {
    adminTokenFile = "/run/secrets/gitea-admin-token";
    autoInitRepos = true;
  };

  autoMirror = {
    enable = true;
    interval = "hourly";
  };
};
```

### 5. Rebuild e Inicializar

```bash
# Rebuild (sem flake check por enquanto)
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8

# Verificar serviços
systemctl status gitea.service
systemctl status gitea-cloudflare-dns.timer
systemctl status gitea-init-repos.service
```

### 6. Criar Admin Account no Gitea

1. Acesse: `https://git.voidnx.com:3443`
2. Crie o primeiro usuário (será admin automaticamente)
3. Settings > Applications > Generate Token
4. Copie o token

### 7. Adicionar Gitea Admin Token ao SOPS

```bash
# Edit secrets
sops secrets/api-keys/gitea-secrets.yaml

# Adicione:
gitea-admin-token: "token_copiado_do_gitea"
```

### 8. Restart Services para Carregar Token

```bash
# Restart para carregar o novo token
sudo systemctl restart gitea-init-repos.service
sudo systemctl restart gitea-mirror-showcases.service

# Verificar logs
journalctl -u gitea-init-repos.service -f
journalctl -u gitea-mirror-showcases.service -f
```

## Monitoring

### Verificar DNS Sync

```bash
# Check timer
systemctl status gitea-cloudflare-dns.timer

# Trigger manual
sudo systemctl start gitea-cloudflare-dns.service

# Watch logs
journalctl -u gitea-cloudflare-dns.service -f
```

### Verificar Repository Initialization

```bash
# Check status
systemctl status gitea-init-repos.service

# View logs
journalctl -u gitea-init-repos.service

# Check marker file
ls -la /var/lib/gitea/.repos-initialized
```

### Verificar Mirror Sync

```bash
# Check timer
systemctl status gitea-mirror-showcases.timer

# Trigger manual
sudo systemctl start gitea-mirror-showcases.service

# Watch logs
journalctl -u gitea-mirror-showcases.service -f
```

## Troubleshooting

### DNS não sincroniza

```bash
# Verificar credentials
sudo systemd-creds list | grep cloudflare

# Testar manualmente
sudo systemctl start gitea-cloudflare-dns.service
journalctl -u gitea-cloudflare-dns.service
```

### Repositórios não inicializam

```bash
# Verificar se Gitea está rodando
systemctl status gitea.service

# Verificar se token está correto
sudo systemd-creds list | grep gitea

# Remover marker e tentar novamente
sudo rm /var/lib/gitea/.repos-initialized
sudo systemctl restart gitea-init-repos.service
```

### Mirror falha

```bash
# Verificar projetos locais
ls -la /home/kernelcore/dev/projects/

# Verificar permissões
sudo -u root ls -la /home/kernelcore/dev/projects/

# Trigger manual com logs
sudo systemctl start gitea-mirror-showcases.service
journalctl -u gitea-mirror-showcases.service -f
```

## Vantagens da Abordagem Declarativa

✅ **Zero comandos imperativos** - Tudo no Nix
✅ **Secrets seguros** - Via sops-nix e LoadCredential
✅ **Automático no boot** - Systemd timers
✅ **Idempotente** - Pode rebuildar sem problemas
✅ **Monitorável** - journalctl para tudo
✅ **Rollback fácil** - Generations do NixOS

## Estrutura de Arquivos

```
/etc/nixos/
├── modules/services/gitea-showcase.nix  # Módulo principal (declarativo)
├── secrets/api-keys/
│   └── gitea-secrets.yaml               # Secrets encriptados (sops)
└── hosts/kernelcore/
    └── configuration.nix                # Configuração do host

/run/secrets/                            # Runtime secrets (sops-nix)
├── cloudflare-api-token
└── gitea-admin-token

/var/lib/gitea/
├── .repos-initialized                   # Marker de inicialização
└── repositories/                        # Repositórios Gitea
```

## Próximos Passos

- [ ] Configurar SSL/TLS via Let's Encrypt (declarativo)
- [ ] Adicionar backup automático dos repositórios
- [ ] Configurar webhook notifications
- [ ] Adicionar CI/CD integration (Gitea Actions)
