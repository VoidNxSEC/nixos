#!/usr/bin/env bash
# Script de Backup Rápido Antes de Formatar
# Transfere arquivos importantes para o desktop

set -e

DESKTOP_IP="192.168.15.7"
DESKTOP_USER="cypher"
BACKUP_DIR="backup-laptop-$(date +%Y%m%d-%H%M%S)"

echo "🔄 BACKUP RÁPIDO PARA DESKTOP"
echo "=============================="
echo ""
echo "Desktop: ${DESKTOP_USER}@${DESKTOP_IP}"
echo "Diretório: ~/${BACKUP_DIR}/"
echo ""

# Criar diretório no desktop
echo "📁 Criando diretório de backup no desktop..."
ssh ${DESKTOP_USER}@${DESKTOP_IP} "mkdir -p ~/${BACKUP_DIR}"

# 1. Configs do NixOS
echo ""
echo "📦 1/5: Backing up NixOS configs..."
tar czf /tmp/nixos-config.tar.gz /etc/nixos
scp /tmp/nixos-config.tar.gz ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/
echo "✅ NixOS configs backed up"

# 2. SSH keys
echo ""
echo "🔑 2/5: Backing up SSH keys..."
tar czf /tmp/ssh-keys.tar.gz ~/.ssh
scp /tmp/ssh-keys.tar.gz ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/
echo "✅ SSH keys backed up"

# 3. User configs
echo ""
echo "⚙️  3/5: Backing up user configs..."
tar czf /tmp/user-configs.tar.gz \
  ~/.zshrc \
  ~/.bashrc \
  ~/.gitconfig \
  ~/.config 2>/dev/null || true
scp /tmp/user-configs.tar.gz ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/
echo "✅ User configs backed up"

# 4. Lista de pacotes
echo ""
echo "📋 4/5: Saving package list..."
nix-env -q > /tmp/installed-packages.txt
scp /tmp/installed-packages.txt ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/
echo "✅ Package list saved"

# 5. Perguntar por dados pessoais
echo ""
echo "📂 5/5: Personal data backup..."
echo "Você tem dados pessoais para fazer backup? (Projects, Documents, etc.)"
read -p "Digite os diretórios separados por espaço (ou Enter para pular): " PERSONAL_DIRS

if [ -n "$PERSONAL_DIRS" ]; then
  echo "Backing up personal data..."
  tar czf /tmp/personal-data.tar.gz $PERSONAL_DIRS 2>/dev/null || true
  scp /tmp/personal-data.tar.gz ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/
  echo "✅ Personal data backed up"
else
  echo "⏭️  Skipped personal data backup"
fi

# Limpar arquivos temporários
rm -f /tmp/nixos-config.tar.gz \
      /tmp/ssh-keys.tar.gz \
      /tmp/user-configs.tar.gz \
      /tmp/installed-packages.txt \
      /tmp/personal-data.tar.gz

# Verificar backup no desktop
echo ""
echo "🔍 Verificando backup no desktop..."
ssh ${DESKTOP_USER}@${DESKTOP_IP} "ls -lh ~/${BACKUP_DIR}/ && du -sh ~/${BACKUP_DIR}/"

echo ""
echo "✅ BACKUP COMPLETO!"
echo ""
echo "📍 Localização no desktop:"
echo "   ${DESKTOP_USER}@${DESKTOP_IP}:~/${BACKUP_DIR}/"
echo ""
echo "🔥 PRÓXIMOS PASSOS:"
echo "1. Configurar offload-server no desktop (ver GUIA-BACKUP-E-REINSTALACAO.md)"
echo "2. Formatar este laptop"
echo "3. Reinstalar NixOS com offload configurado desde o início"
echo "4. Restaurar backup seletivamente"
echo ""
echo "📚 Documentação: GUIA-BACKUP-E-REINSTALACAO.md"