#!/usr/bin/env bash
# Script para rodar NO DESKTOP (192.168.15.6)
# Cole a chave pública do laptop como argumento

set -e

if [ -z "$1" ]; then
    echo "❌ Erro: Forneça a chave pública como argumento!"
    echo
    echo "Uso:"
    echo "  $0 'ssh-ed25519 AAAAC3NzaC... nix-builder@laptop-to-desktop'"
    echo
    exit 1
fi

PUBLIC_KEY="$1"

echo "🖥️  Configurando usuário nix-builder no DESKTOP..."
echo "================================================"
echo

# Verificar se usuário existe
if id nix-builder &>/dev/null; then
    echo "✅ Usuário nix-builder já existe"
else
    echo "📝 Criando usuário nix-builder..."
    sudo useradd -m -s /bin/bash -c "Nix Remote Builder" nix-builder
fi

# Criar diretório SSH
echo "📁 Configurando SSH..."
sudo mkdir -p /home/nix-builder/.ssh
sudo chmod 700 /home/nix-builder/.ssh

# Adicionar chave pública
echo "🔑 Adicionando chave pública do laptop..."
echo "$PUBLIC_KEY" | sudo tee -a /home/nix-builder/.ssh/authorized_keys

# Ajustar permissões
echo "🔒 Ajustando permissões..."
sudo chmod 600 /home/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /home/nix-builder/.ssh

# Verificar
echo
echo "✅ Configuração completa!"
echo
echo "📋 Verificação:"
sudo ls -la /home/nix-builder/.ssh/
echo
echo "📝 Chave autorizada:"
sudo cat /home/nix-builder/.ssh/authorized_keys
echo
echo "✅ Agora teste no LAPTOP: offload-test-build"
