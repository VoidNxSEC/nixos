#!/usr/bin/env bash
# COPIE E COLE ESTE SCRIPT NO DESKTOP (192.168.15.6)
# Execute como: bash /caminho/para/este/script.sh

set -e

echo "🖥️  DESKTOP - Adicionando chave do laptop"
echo "=========================================="
echo

# A chave pública que o LAPTOP gerou
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhQMUdwtcERELNkvzah839QJH2CiDmUCBnoa+ZsPcrk nix-builder@laptop-to-desktop"

# 1. Verificar/criar usuário nix-builder
echo "1️⃣  Verificando usuário nix-builder..."
if id nix-builder &>/dev/null; then
    echo "   ✅ Usuário já existe"
else
    echo "   📝 Criando usuário..."
    sudo useradd -m -s /bin/bash -c "Nix Remote Builder" nix-builder
    echo "   ✅ Usuário criado"
fi

# 2. Configurar SSH
echo
echo "2️⃣  Configurando SSH..."
sudo mkdir -p /home/nix-builder/.ssh
sudo chmod 700 /home/nix-builder/.ssh

# Adicionar chave (sem duplicar se já existir)
if ! sudo grep -q "nix-builder@laptop-to-desktop" /home/nix-builder/.ssh/authorized_keys 2>/dev/null; then
    echo "$PUBLIC_KEY" | sudo tee -a /home/nix-builder/.ssh/authorized_keys
    echo "   ✅ Chave adicionada"
else
    echo "   ✅ Chave já existe"
fi

sudo chmod 600 /home/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /home/nix-builder/.ssh

# 3. Verificar
echo
echo "3️⃣  Verificando configuração..."
echo "   Usuário: $(id nix-builder)"
echo
echo "   SSH directory:"
sudo ls -la /home/nix-builder/.ssh/
echo
echo "   Chave autorizada:"
sudo cat /home/nix-builder/.ssh/authorized_keys

# 4. Verificar trusted-users
echo
echo "4️⃣  Verificando trusted-users..."
TRUSTED=$(nix config show 2>/dev/null | grep "trusted-users" || echo "não encontrado")
echo "   Atual: $TRUSTED"

if echo "$TRUSTED" | grep -q "nix-builder"; then
    echo "   ✅ nix-builder já está em trusted-users"
else
    echo
    echo "   ⚠️  AÇÃO NECESSÁRIA!"
    echo "   nix-builder NÃO está em trusted-users"
    echo
    echo "   Arquivos onde trusted-users está definido:"
    grep -rn "trusted-users" /etc/nixos/*.nix /etc/nixos/modules/security/*.nix 2>/dev/null | grep -v ".git" | head -5
    echo
    echo "   Edite um desses arquivos e adicione \"nix-builder\":"
    echo "   Antes: trusted-users = [ \"@wheel\" ];"
    echo "   Depois: trusted-users = [ \"@wheel\" \"nix-builder\" ];"
    echo
    echo "   Depois rode: sudo nixos-rebuild switch"
fi

echo
echo "=========================================="
echo "✅ Configuração SSH completa!"
echo
echo "📋 PRÓXIMO PASSO NO LAPTOP:"
echo "   sudo ssh -i /etc/nix/builder_key nix-builder@192.168.15.6 'echo SSH OK'"
echo
