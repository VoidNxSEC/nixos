#!/usr/bin/env bash
# ============================================================================
# NIXOS CACHE SERVER - CHEAT SHEET DE DEPLOY
# Comandos rápidos para copiar/colar
# ============================================================================

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║           NixOS Cache Server - Guia de Deploy Rápido              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════
FASE 1: BOOTSTRAP (no Live ISO)
═══════════════════════════════════════════════════════════════════

# Tornar root
sudo su

# Executar bootstrap
chmod +x nixos-cache-bootstrap.sh
./nixos-cache-bootstrap.sh

# Resultado: Configuração gerada em /etc/nixos/cache-server.nix

═══════════════════════════════════════════════════════════════════
FASE 2: INSTALAR NIXOS (comandos sequenciais)
═══════════════════════════════════════════════════════════════════

# Particionar (ajuste /dev/sda se necessário)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MB -8GB
parted /dev/sda -- mkpart primary linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

# Formatar
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Montar
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2

# Gerar config base
nixos-generate-config --root /mnt

# Copiar arquivos do bootstrap
cp /etc/nixos/cache-server.nix /mnt/etc/nixos/
cp -r /etc/nixos/cache-keys /mnt/etc/nixos/
cp -r /etc/nixos/certs /mnt/etc/nixos/
cp -r /etc/nixos/scripts /mnt/etc/nixos/

# Editar configuração principal
nano /mnt/etc/nixos/configuration.nix

# ADICIONAR estas linhas ao configuration.nix:
# -----------------------------------------------
# imports = [ ./hardware-configuration.nix ./cache-server.nix ];
# 
# boot.loader.systemd-boot.enable = true;
# boot.loader.efi.canTouchEfiVariables = true;
# 
# networking.hostName = "nixos-cache";
# networking.networkmanager.enable = true;
# 
# users.users.admin = {
#   isNormalUser = true;
#   extraGroups = [ "wheel" "networkmanager" ];
# };
# 
# services.openssh.enable = true;
# -----------------------------------------------

# Instalar
nixos-install

# Definir senha root
passwd

# Reiniciar
reboot

═══════════════════════════════════════════════════════════════════
FASE 3: PÓS-INSTALAÇÃO (após reiniciar)
═══════════════════════════════════════════════════════════════════

# Verificar serviços
systemctl status nix-serve
systemctl status nginx
systemctl status prometheus

# Testar cache (local)
curl http://localhost:5000/nix-cache-info

# Testar cache (via nginx/TLS)
curl -k https://localhost/nix-cache-info

# Ver chave pública (compartilhar com clientes)
cat /etc/nixos/cache-keys/cache-pub-key.pem

═══════════════════════════════════════════════════════════════════
FASE 4: SETUP API SERVER
═══════════════════════════════════════════════════════════════════

# Copiar script (se ainda não estiver lá)
sudo cp cache-api-server.sh /etc/nixos/scripts/
sudo chmod +x /etc/nixos/scripts/cache-api-server.sh

# Copiar service
sudo cp cache-api-server.service /etc/systemd/system/

# Habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable cache-api-server
sudo systemctl start cache-api-server

# Verificar
systemctl status cache-api-server
curl http://localhost:8080/api/metrics | jq

═══════════════════════════════════════════════════════════════════
FASE 5: DEPLOY DASHBOARD REACT
═══════════════════════════════════════════════════════════════════

# Na sua máquina de desenvolvimento:
cd nixos-cache-dashboard
npm install

# Desenvolvimento (local)
npm run dev
# Acesse: http://localhost:3000

# Produção (build)
npm run build

# Deploy (copiar para servidor)
scp -r dist/* admin@SERVIDOR_IP:/var/www/dashboard/

# Configurar nginx para servir (adicionar ao cache-server.nix):
# services.nginx.virtualHosts."dashboard.local" = {
#   root = "/var/www/dashboard";
#   locations."/" = {
#     tryFiles = "$uri $uri/ /index.html";
#   };
# };

═══════════════════════════════════════════════════════════════════
CONFIGURAR CLIENTE (em outra máquina NixOS)
═══════════════════════════════════════════════════════════════════

# Adicionar ao configuration.nix do cliente:

nix.settings = {
  substituters = [
    "https://IP_DO_SERVIDOR"
    "https://cache.nixos.org"
  ];
  
  trusted-public-keys = [
    "COLE_CHAVE_PUBLICA_AQUI"
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
};

# Reconstruir cliente
sudo nixos-rebuild switch

# Testar
nix-build '<nixpkgs>' -A hello

═══════════════════════════════════════════════════════════════════
COMANDOS ÚTEIS
═══════════════════════════════════════════════════════════════════

# Monitor em tempo real
/etc/nixos/scripts/monitor.sh

# Health check
/etc/nixos/scripts/health-check.sh

# Backup de chaves
/etc/nixos/scripts/backup-keys.sh

# Ver logs
journalctl -u nix-serve -f
journalctl -u nginx -f
journalctl -u cache-api-server -f

# Garbage collection
sudo nix-collect-garbage -d

# Verificar store
sudo nix-store --verify --check-contents

# Ver uso de disco
du -sh /nix/store
df -h /

# Reiniciar serviços
sudo systemctl restart nix-serve
sudo systemctl restart nginx
sudo systemctl restart cache-api-server

# Atualizar sistema
sudo nix-channel --update
sudo nixos-rebuild switch

# Rollback se algo quebrar
sudo nixos-rebuild --rollback switch

═══════════════════════════════════════════════════════════════════
TROUBLESHOOTING RÁPIDO
═══════════════════════════════════════════════════════════════════

# Serviço não inicia?
journalctl -xeu NOME_DO_SERVICO
sudo nixos-rebuild dry-build  # Verificar config

# Certificado não confiável? (dev/staging)
curl -k https://...  # Ignorar temporariamente

# Dashboard não conecta?
systemctl status cache-api-server
curl http://localhost:8080/api/metrics
# Verificar vite.config.ts proxy

# Disco cheio?
sudo nix-collect-garbage -d
sudo nix-collect-garbage --delete-older-than 7d

# Out of memory?
# Reduzir max-jobs em cache-server.nix
# Adicionar ZRAM

═══════════════════════════════════════════════════════════════════
URLS IMPORTANTES
═══════════════════════════════════════════════════════════════════

Cache Server (TLS):     https://SERVIDOR_IP/
Cache Info:             https://SERVIDOR_IP/nix-cache-info
API Métricas:           http://SERVIDOR_IP:8080/api/metrics
API Health:             http://SERVIDOR_IP:8080/api/health
Prometheus:             http://SERVIDOR_IP:9090
Dashboard React:        http://localhost:3000 (dev)

═══════════════════════════════════════════════════════════════════
ARQUIVOS IMPORTANTES
═══════════════════════════════════════════════════════════════════

/etc/nixos/configuration.nix              # Config principal
/etc/nixos/cache-server.nix               # Config do cache
/etc/nixos/cache-keys/cache-priv-key.pem  # ⚠️  PRIVADA - BACKUP!
/etc/nixos/cache-keys/cache-pub-key.pem   # Pública - compartilhar
/etc/nixos/certs/server.crt               # Cert TLS
/etc/nixos/certs/server.key               # ⚠️  PRIVADA - BACKUP!
/etc/nixos/scripts/                       # Scripts auxiliares
/var/log/nixos-cache-api.log              # Log da API

═══════════════════════════════════════════════════════════════════
PRÓXIMOS PASSOS RECOMENDADOS
═══════════════════════════════════════════════════════════════════

1. ✅ Testar build em cliente: nix-build '<nixpkgs>' -A firefox
2. ✅ Monitorar recursos por 24h com /etc/nixos/scripts/monitor.sh
3. ✅ Fazer backup das chaves: /etc/nixos/scripts/backup-keys.sh
4. 🔄 Substituir cert auto-assinado por Let's Encrypt (produção)
5. 📊 Configurar alertas (email/slack) para problemas
6. 📝 Documentar sua topologia de rede específica
7. 🔧 Ajustar GC policy baseado em uso real
8. 🚀 Avaliar distributed builds se hardware limitado

═══════════════════════════════════════════════════════════════════

EOF
