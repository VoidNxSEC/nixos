#!/usr/bin/env bash
# Setup Desktop as Remote Builder Server
# This script configures SSH keys and enables offload-server

set -e

DESKTOP_IP="192.168.15.7"
DESKTOP_USER="kernelcore"  # Ajuste se necessário

echo "🔧 Desktop Offload Setup Script"
echo "================================"
echo ""
echo "Este script vai configurar:"
echo "  • Chaves SSH para builds remotos"
echo "  • Desktop (${DESKTOP_IP}) como build server"  
echo "  • Laptop como build client"
echo ""

# Verificar conectividade
echo "📡 Verificando conectividade com desktop..."
if ! timeout 3 bash -c "echo > /dev/tcp/${DESKTOP_IP}/22" 2>/dev/null; then
    echo "❌ Erro: Desktop não está acessível em ${DESKTOP_IP}"
    exit 1
fi
echo "✅ Desktop acessível"
echo ""

# Etapa 1: Copiar chave pública para o desktop
echo "🔑 Etapa 1: Configurar autenticação SSH"
echo "---------------------------------------"
echo ""
echo "Vamos copiar sua chave SSH pública para o desktop."
echo "Você precisará digitar a senha do desktop UMA VEZ."
echo ""
read -p "Pressione ENTER para continuar..."

if [ -f ~/.ssh/id_ed25519.pub ]; then
    SSH_KEY=~/.ssh/id_ed25519.pub
elif [ -f ~/.ssh/id_rsa.pub ]; then
    SSH_KEY=~/.ssh/id_rsa.pub
else
    echo "⚠️  Nenhuma chave SSH encontrada. Gerando nova chave..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    SSH_KEY=~/.ssh/id_ed25519.pub
fi

echo "Copiando chave: ${SSH_KEY}"
ssh-copy-id -i "${SSH_KEY}" "${DESKTOP_USER}@${DESKTOP_IP}"

# Testar autenticação sem senha
echo ""
echo "🧪 Testando autenticação SSH..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 "${DESKTOP_USER}@${DESKTOP_IP}" 'echo "SSH OK"' 2>/dev/null; then
    echo "✅ Autenticação SSH funcionando!"
else
    echo "❌ Erro: Autenticação SSH falhou"
    echo "Execute: ssh ${DESKTOP_USER}@${DESKTOP_IP}"
    echo "E verifique se consegue conectar."
    exit 1
fi

echo ""
echo "🖥️  Etapa 2: Configurar Desktop como Build Server"
echo "--------------------------------------------------"
echo ""
echo "Agora vamos configurar o desktop para aceitar builds remotos."
echo "Isso será feito via SSH (sem senha agora)."
echo ""

# Criar script de configuração no desktop
DESKTOP_SETUP_SCRIPT=$(cat <<'EOF'
#!/usr/bin/env bash
# Executado no DESKTOP

echo "Configurando offload-server no desktop..."

# Habilitar o offload-server na configuração
CONFIG_FILE="/etc/nixos/hosts/kernelcore/configuration.nix"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# Verificar se offload-server já está habilitado
if grep -q "services.offload-server.enable = true" "$CONFIG_FILE"; then
    echo "✅ offload-server já está habilitado"
else
    echo "Habilitando offload-server..."
    # Adicionar configuração (você pode ajustar conforme necessário)
    echo ""
    echo "# Build server para offload remoto"
    echo "services.offload-server = {"
    echo "  enable = true;"
    echo "  cachePort = 5000;"
    echo "  builderUser = \"nix-builder\";"
    echo "};"
    echo ""
    echo "⚠️  ATENÇÃO: Adicione a configuração acima manualmente ao seu configuration.nix"
    echo "Localização: $CONFIG_FILE"
fi

# Criar usuário nix-builder se não existir
if ! id nix-builder >/dev/null 2>&1; then
    echo "Criando usuário nix-builder..."
    sudo useradd -r -d /var/lib/nix-builder -s /bin/bash nix-builder
    sudo mkdir -p /var/lib/nix-builder/.ssh
    sudo chown -R nix-builder:nix-builder /var/lib/nix-builder
fi

# Copiar chave pública do laptop para nix-builder
echo "Copiando chave SSH do laptop para nix-builder..."
LAPTOP_KEY="$1"
if [ -n "$LAPTOP_KEY" ]; then
    echo "$LAPTOP_KEY" | sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
    sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
    sudo chown nix-builder:nix-builder /var/lib/nix-builder/.ssh/authorized_keys
    echo "✅ Chave adicionada"
fi

echo ""
echo "✅ Configuração do desktop concluída!"
echo ""
echo "Próximos passos NO DESKTOP:"
echo "1. Edite: /etc/nixos/hosts/kernelcore/configuration.nix"
echo "2. Adicione:"
echo "   services.offload-server = {"
echo "     enable = true;"
echo "     cachePort = 5000;"
echo "   };"
echo "3. Execute: sudo nixos-rebuild switch"
echo "4. Gere chaves do cache: offload-generate-cache-keys"
echo "5. Verifique status: offload-server-status"
EOF
)

# Enviar e executar no desktop
echo "Enviando script de configuração para o desktop..."
echo "$DESKTOP_SETUP_SCRIPT" | ssh "${DESKTOP_USER}@${DESKTOP_IP}" 'cat > /tmp/desktop-setup.sh && chmod +x /tmp/desktop-setup.sh'

# Enviar chave pública do laptop
LAPTOP_PUB_KEY=$(cat "${SSH_KEY}")
ssh "${DESKTOP_USER}@${DESKTOP_IP}" "bash /tmp/desktop-setup.sh '$LAPTOP_PUB_KEY'"

echo ""
echo "🔧 Etapa 3: Configurar Laptop como Build Client"
echo "-----------------------------------------------"
echo ""
echo "Agora vamos habilitar o laptop para usar o desktop como builder."
echo ""

# Atualizar IP no laptop-offload-client.nix
OFFLOAD_CLIENT="/etc/nixos/modules/services/laptop-offload-client.nix"

if [ -f "$OFFLOAD_CLIENT" ]; then
    echo "Atualizando IP no ${OFFLOAD_CLIENT}..."
    sudo sed -i "s/desktopIP = \"192.168.15.6\"/desktopIP = \"${DESKTOP_IP}\"/" "$OFFLOAD_CLIENT"
    echo "✅ IP atualizado para ${DESKTOP_IP}"
else
    echo "⚠️  Arquivo não encontrado: $OFFLOAD_CLIENT"
fi

echo ""
echo "📋 PRÓXIMOS PASSOS MANUAIS:"
echo "=========================="
echo ""
echo "NO DESKTOP (${DESKTOP_IP}):"
echo "1. ssh ${DESKTOP_USER}@${DESKTOP_IP}"
echo "2. Edite /etc/nixos/hosts/kernelcore/configuration.nix"
echo "3. Adicione:"
echo "   services.offload-server = {"
echo "     enable = true;"
echo "     cachePort = 5000;"
echo "   };"
echo "4. sudo nixos-rebuild switch"
echo "5. offload-generate-cache-keys"
echo "6. offload-server-status"
echo ""
echo "NO LAPTOP (aqui):"
echo "1. Edite /etc/nixos/flake.nix"
echo "2. Descomente a linha 75:"
echo "   ./modules/services/laptop-offload-client.nix"
echo "3. sudo nixos-rebuild switch"
echo "4. offload-status"
echo "5. offload-test-build"
echo ""
echo "✅ Script de setup concluído!"
echo ""