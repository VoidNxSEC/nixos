#!/usr/bin/env bash
# Script completo para configurar o DESKTOP como builder remoto
# Uso: ./DESKTOP-COMPLETE-SETUP.sh

set -e

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhQMUdwtcERELNkvzah839QJH2CiDmUCBnoa+ZsPcrk nix-builder@laptop-to-desktop"

echo "🖥️  DESKTOP - Configuração Completa do Builder"
echo "=============================================="
echo

# Passo 1: Criar usuário
echo "📝 Passo 1: Criando usuário nix-builder..."
if id nix-builder &>/dev/null; then
    echo "   ✅ Usuário já existe"
else
    sudo useradd -m -s /bin/bash -c "Nix Remote Builder" nix-builder
    echo "   ✅ Usuário criado"
fi

# Passo 2: Configurar SSH
echo
echo "🔑 Passo 2: Configurando SSH..."
sudo mkdir -p /home/nix-builder/.ssh
sudo chmod 700 /home/nix-builder/.ssh
echo "$PUBLIC_KEY" | sudo tee /home/nix-builder/.ssh/authorized_keys > /dev/null
sudo chmod 600 /home/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /home/nix-builder/.ssh
echo "   ✅ Chave SSH adicionada"

# Passo 3: Verificar trusted-users
echo
echo "⚙️  Passo 3: Verificando trusted-users..."
CURRENT_TRUSTED=$(nix config show 2>/dev/null | grep "trusted-users" || echo "")
echo "   Atual: $CURRENT_TRUSTED"

if echo "$CURRENT_TRUSTED" | grep -q "nix-builder"; then
    echo "   ✅ nix-builder já está em trusted-users"
else
    echo "   ⚠️  nix-builder NÃO está em trusted-users!"
    echo
    echo "   🔧 AÇÃO NECESSÁRIA:"
    echo "   Adicione 'nix-builder' aos trusted-users editando:"
    grep -r "trusted-users.*@wheel" /etc/nixos/ 2>/dev/null | head -5
    echo
    echo "   Exemplo (escolha um dos arquivos acima):"
    echo "   # Antes:"
    echo "   trusted-users = [ \"@wheel\" ];"
    echo
    echo "   # Depois:"
    echo "   trusted-users = [ \"@wheel\" \"nix-builder\" ];"
    echo
    echo "   Depois rode: sudo nixos-rebuild switch"
fi

# Passo 4: Verificação
echo
echo "✅ Passo 4: Verificação final..."
echo "   Usuário: $(id nix-builder)"
echo "   SSH config:"
sudo ls -la /home/nix-builder/.ssh/
echo
echo "   Chave autorizada:"
sudo cat /home/nix-builder/.ssh/authorized_keys

# Passo 5: Serviços
echo
echo "🔍 Passo 5: Verificando serviços..."
systemctl is-active sshd && echo "   ✅ sshd rodando" || echo "   ❌ sshd não está rodando"
systemctl is-active nix-daemon && echo "   ✅ nix-daemon rodando" || echo "   ❌ nix-daemon não está rodando"
curl -s -I http://localhost:5000/nix-cache-info >/dev/null 2>&1 && echo "   ✅ Cache HTTP rodando" || echo "   ⚠️  Cache HTTP não está rodando"

echo
echo "=============================================="
echo "✅ Configuração básica completa!"
echo
echo "📋 PRÓXIMOS PASSOS:"
echo
echo "1. Se nix-builder NÃO está em trusted-users:"
echo "   - Editar arquivo de configuração (veja acima)"
echo "   - Adicionar \"nix-builder\" à lista"
echo "   - Rodar: sudo nixos-rebuild switch"
echo
echo "2. Monitorar tentativas de conexão do laptop:"
echo "   sudo journalctl -f -u sshd"
echo
echo "3. No LAPTOP, testar:"
echo "   offload-test-build"
echo
