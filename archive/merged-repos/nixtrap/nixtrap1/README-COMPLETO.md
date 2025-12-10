# 🚀 NixOS Cache Server - Solução Completa

Solução enterprise-grade para servidor de cache NixOS com TLS, monitoramento e dashboard React/TypeScript.

## 📋 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    NixOS Cache Server                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │  nix-serve   │─────▶│    nginx     │◀─── HTTPS (443)   │
│  │  (port 5000) │      │  (TLS proxy) │                    │
│  └──────────────┘      └──────────────┘                    │
│         │                                                   │
│         │              ┌──────────────┐                     │
│         └─────────────▶│  Prometheus  │◀─── HTTP (9090)    │
│                        │  (métricas)  │                     │
│                        └──────────────┘                     │
│                               │                             │
│                        ┌──────▼───────┐                     │
│                        │  API Server  │◀─── HTTP (8080)    │
│                        │  (REST JSON) │                     │
│                        └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                               │
                               │ REST API
                               ▼
                    ┌─────────────────────┐
                    │  React Dashboard    │
                    │  (Vite + TypeScript)│
                    └─────────────────────┘
```

## 🎯 Características

### ✅ Bootstrap Automatizado
- Diagnóstico de hardware inteligente
- Configuração otimizada baseada em recursos disponíveis
- Geração automática de chaves criptográficas
- Certificados TLS auto-assinados
- Scripts de monitoramento e manutenção

### 🔐 Segurança
- **Cache signing** com chaves assimétricas
- **TLS/HTTPS** via nginx reverse proxy
- **Firewall** configurado (apenas porta 443)
- **Service hardening** com systemd
- **Network isolation** pronto para uso

### 📊 Monitoramento
- **Prometheus** para métricas de longo prazo
- **API REST** para consumo em tempo real
- **Dashboard React** com gráficos interativos
- **Health checks** automatizados
- **Logging** estruturado via journald

### ⚡ Performance
- **Nginx caching** para acelerar requisições
- **TCP tuning** (BBR congestion control)
- **Auto garbage collection**
- **Storage optimization**
- **Build parallelism** otimizado

## 📦 Pré-requisitos

### No Servidor (NixOS Live ISO)
```bash
# Você já está no live ISO, então só precisa de:
- Acesso root
- Conexão com internet
- Espaço em disco adequado (mínimo 50GB recomendado)
```

### Para o Dashboard React (dev machine)
```bash
- Node.js 18+ e npm 9+
- Ou use o servidor para buildar (já tem Node no NixOS)
```

## 🚀 Quick Start - Guia Completo

### Fase 1: Bootstrap do Servidor

```bash
# 1. No NixOS live ISO, copie o script de bootstrap
sudo su
cd /root

# 2. Torne executável
chmod +x nixos-cache-bootstrap.sh

# 3. Execute o bootstrap
./nixos-cache-bootstrap.sh

# O script irá:
# - Diagnosticar o hardware
# - Gerar chaves e certificados
# - Criar configuração otimizada
# - Gerar scripts auxiliares
# - Criar documentação
```

### Fase 2: Instalação do NixOS

```bash
# 1. Particione o disco (exemplo para /dev/sda)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MB -8GB
parted /dev/sda -- mkpart primary linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

# 2. Formate as partições
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# 3. Monte as partições
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2

# 4. Gere a configuração base
nixos-generate-config --root /mnt

# 5. Integre a configuração do cache server
cp /etc/nixos/cache-server.nix /mnt/etc/nixos/
cp -r /etc/nixos/cache-keys /mnt/etc/nixos/
cp -r /etc/nixos/certs /mnt/etc/nixos/
cp -r /etc/nixos/scripts /mnt/etc/nixos/

# 6. Edite /mnt/etc/nixos/configuration.nix e adicione:
cat >> /mnt/etc/nixos/configuration.nix << 'EOF'

  # Importar configuração do cache server
  imports = [ ./cache-server.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network (ajuste para seu ambiente)
  networking.hostName = "nixos-cache";
  networking.networkmanager.enable = true;

  # Usuário admin (ajuste conforme necessário)
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      # Adicione sua chave SSH aqui
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };
EOF

# 7. Instale o NixOS
nixos-install

# 8. Defina senha de root
nixos-enter --root /mnt -c 'passwd'

# 9. Reinicie
reboot
```

### Fase 3: Configurar API Server

```bash
# Após reiniciar e logar no novo sistema:

# 1. Copie o script da API
sudo cp /home/claude/cache-api-server.sh /etc/nixos/scripts/
sudo chmod +x /etc/nixos/scripts/cache-api-server.sh

# 2. Copie o serviço systemd
sudo cp /home/claude/cache-api-server.service /etc/systemd/system/

# 3. Habilite e inicie o serviço
sudo systemctl daemon-reload
sudo systemctl enable cache-api-server
sudo systemctl start cache-api-server

# 4. Verifique o status
sudo systemctl status cache-api-server

# 5. Teste a API
curl http://localhost:8080/api/metrics | jq
curl http://localhost:8080/api/health | jq
```

### Fase 4: Configurar Firewall para API (opcional)

```bash
# Se quiser expor a API externamente (para o dashboard):
sudo systemctl edit nginx.service

# Adicione uma configuração adicional ao nginx ou abra porta 8080:
# Opção 1: Reverse proxy via nginx (recomendado)
# Adicione ao cache-server.nix:

# Opção 2: Abrir porta diretamente (menos seguro)
sudo nano /etc/nixos/cache-server.nix
# Adicione na seção networking.firewall.allowedTCPPorts:
#   allowedTCPPorts = [ 443 8080 ];

# Reconstrua
sudo nixos-rebuild switch
```

### Fase 5: Deploy do Dashboard React

```bash
# Opção A: Desenvolvimento (na sua máquina)
cd nixos-cache-dashboard
npm install
npm run dev

# Acesse: http://localhost:3000
# Configure a URL da API no .env se necessário

# Opção B: Produção (build e deploy)
npm run build

# Copie os arquivos de dist/ para o servidor
scp -r dist/* admin@nixos-cache:/var/www/dashboard/

# Configure nginx para servir o dashboard
# Adicione ao cache-server.nix:
```

## 📝 Configuração Detalhada

### Ajustando Parâmetros de Performance

Edite `/etc/nixos/cache-server.nix`:

```nix
# Para hardware mais potente (8GB+ RAM):
nix.settings = {
  max-jobs = 4;    # Aumentar
  cores = 2;       # Aumentar
};

# Para hardware limitado (4GB RAM):
nix.settings = {
  max-jobs = 2;
  cores = 1;
  
  # Adicionar ZRAM para swap comprimido
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
};
```

### Configurando Clientes

No cliente NixOS, adicione ao `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  nix.settings = {
    substituters = [
      "https://IP_DO_SERVIDOR"
      "https://cache.nixos.org"
    ];
    
    trusted-public-keys = [
      "COLE_A_CHAVE_PUBLICA_AQUI"
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Para aceitar cert auto-assinado em dev/staging:
  security.pki.certificateFiles = [
    /path/to/server.crt
  ];
}
```

### Obtendo a Chave Pública

```bash
# No servidor:
cat /etc/nixos/cache-keys/cache-pub-key.pem
```

## 🔧 Operação e Manutenção

### Scripts Úteis

```bash
# Monitor em tempo real
/etc/nixos/scripts/monitor.sh

# Health check
/etc/nixos/scripts/health-check.sh

# Backup das chaves
/etc/nixos/scripts/backup-keys.sh
```

### Comandos Comuns

```bash
# Ver logs dos serviços
journalctl -u nix-serve -f
journalctl -u nginx -f
journalctl -u cache-api-server -f

# Verificar cache
curl -k https://localhost/nix-cache-info

# Garbage collection manual
sudo nix-collect-garbage -d

# Verificar integridade do store
sudo nix-store --verify --check-contents

# Ver espaço usado
du -sh /nix/store
df -h /
```

### Troubleshooting

#### Problema: Serviço não inicia
```bash
# Ver logs detalhados
journalctl -xeu nix-serve
journalctl -xeu nginx

# Verificar configuração
sudo nginx -t
sudo nixos-rebuild dry-build
```

#### Problema: Certificado TLS não confiável
```bash
# Para desenvolvimento, ignore temporariamente:
curl -k https://servidor/nix-cache-info

# Para produção, use Let's Encrypt:
# Adicione ao cache-server.nix:
security.acme = {
  acceptTerms = true;
  defaults.email = "seu@email.com";
};

services.nginx.virtualHosts."seu.dominio.com" = {
  enableACME = true;
  forceSSL = true;
  # ... resto da config
};
```

#### Problema: Dashboard não conecta à API
```bash
# Verifique se a API está rodando
systemctl status cache-api-server

# Teste manualmente
curl http://localhost:8080/api/metrics

# Verifique o proxy do Vite (vite.config.ts)
# Verifique CORS se rodando em produção
```

## 📊 Métricas e Monitoramento

### Prometheus
- URL: `http://servidor:9090`
- Consultas úteis:
  ```promql
  # CPU usage
  100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
  
  # Disk usage
  (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
  
  # Memory usage
  (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
  ```

### API Endpoints

```bash
# Métricas do sistema (JSON)
GET /api/metrics

# Health check
GET /api/health

# Logs recentes
GET /api/logs
```

## 🔄 Atualizações

### Atualizar NixOS
```bash
sudo nix-channel --update
sudo nixos-rebuild switch

# Se algo quebrar, rollback:
sudo nixos-rebuild --rollback switch
```

### Atualizar Dashboard
```bash
cd nixos-cache-dashboard
git pull  # ou baixe nova versão
npm install
npm run build
# Deploy novo build
```

## 🎨 Customização do Dashboard

### Cores e Tema
Edite `nixos-cache-dashboard/tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        // Suas cores aqui
      }
    }
  }
}
```

### Adicionar Novos Widgets
Crie componentes em `src/components/` e importe no `App.tsx`.

## 📚 Estrutura de Arquivos

```
nixos-cache-server/
├── nixos-cache-bootstrap.sh       # Script principal de bootstrap
├── cache-api-server.sh            # API server para métricas
├── cache-api-server.service       # Systemd service
│
├── /etc/nixos/                    # No servidor após instalação
│   ├── configuration.nix          # Config principal NixOS
│   ├── cache-server.nix           # Config do cache server
│   ├── cache-keys/                # Chaves criptográficas
│   │   ├── cache-priv-key.pem     # ⚠️  PRIVADA - NÃO COMPARTILHE
│   │   └── cache-pub-key.pem      # Pública - compartilhe com clientes
│   ├── certs/                     # Certificados TLS
│   │   ├── server.crt
│   │   └── server.key             # ⚠️  PRIVADA
│   └── scripts/                   # Scripts auxiliares
│       ├── monitor.sh
│       ├── health-check.sh
│       └── backup-keys.sh
│
└── nixos-cache-dashboard/         # App React
    ├── src/
    │   ├── App.tsx                # Componente principal
    │   ├── main.tsx               # Entry point
    │   └── index.css              # Estilos globais
    ├── package.json
    ├── vite.config.ts
    ├── tsconfig.json
    └── tailwind.config.js
```

## 🤝 Contribuindo

Este é um projeto template. Sinta-se livre para:
- Adaptar para suas necessidades
- Adicionar novos recursos ao dashboard
- Melhorar a segurança (Let's Encrypt, etc.)
- Adicionar mais métricas e gráficos

## 📄 Licença

MIT License - use livremente para projetos pessoais e comerciais.

## 🆘 Suporte

Para questões sobre:
- **NixOS**: https://nixos.org/manual/
- **Nix-serve**: https://github.com/edolstra/nix-serve
- **React/Vite**: https://vitejs.dev/

## 🎯 Roadmap

- [ ] Let's Encrypt automático
- [ ] Multi-server clustering
- [ ] Distributed builds
- [ ] Email/Slack alerts
- [ ] Grafana dashboards
- [ ] Backup automático para S3/B2
- [ ] WebSocket para updates em tempo real
- [ ] Auth/login para dashboard
- [ ] Dark mode no dashboard
- [ ] Mobile app (React Native)

---

**Desenvolvido com ❤️ para a comunidade NixOS**

**Nota**: Este é um sistema production-ready, mas sempre teste em ambiente de staging primeiro!
