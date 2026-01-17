#!/usr/bin/env bash
# GitLab Duo Nix Configuration - Setup Checklist
# Script interativo para verificar o setup

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
COMPLETED=0
PENDING=0

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_done() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((COMPLETED++))
}

check_pending() {
    echo -e "${YELLOW}[ ]${NC} $1"
    ((PENDING++))
}

main() {
    print_header "GitLab Duo Nix Configuration - Setup Checklist"
    echo ""
    
    # 1. API Key
    echo "🔐 Segurança"
    if [ -f ~/.config/gitlab-duo/api-key ]; then
        check_done "API Key configurada em ~/.config/gitlab-duo/api-key"
    else
        check_pending "API Key não configurada"
        echo "   Execute: mkdir -p ~/.config/gitlab-duo && echo 'your_key' > ~/.config/gitlab-duo/api-key"
    fi
    echo ""
    
    # 2. Nix Environment
    echo "🏗️  Ambiente Nix"
    if [ -f "nix/flake.nix" ]; then
        check_done "nix/flake.nix existe"
    else
        check_pending "nix/flake.nix não encontrado"
    fi
    
    if [ -f "nix/gitlab-duo/settings.yaml" ]; then
        check_done "nix/gitlab-duo/settings.yaml existe"
    else
        check_pending "nix/gitlab-duo/settings.yaml não encontrado"
    fi
    
    if [ -f "nix/gitlab-duo/module.nix" ]; then
        check_done "nix/gitlab-duo/module.nix existe"
    else
        check_pending "nix/gitlab-duo/module.nix não encontrado"
    fi
    echo ""
    
    # 3. Scripts
    echo "📝 Scripts"
    if [ -f "nix/scripts/validate-gitlab-duo.sh" ]; then
        check_done "nix/scripts/validate-gitlab-duo.sh existe"
    else
        check_pending "nix/scripts/validate-gitlab-duo.sh não encontrado"
    fi
    echo ""
    
    # 4. Documentation
    echo "📚 Documentação"
    local docs=(
        "nix/README.md"
        "nix/QUICK_REFERENCE.md"
        "nix/ARCHITECTURE.md"
        "nix/INTEGRATION.md"
        "nix/SETUP_SUMMARY.md"
        "nix/INDEX.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            check_done "$doc existe"
        else
            check_pending "$doc não encontrado"
        fi
    done
    echo ""
    
    # 5. Environment Variables
    echo "🌍 Variáveis de Ambiente"
    if [ -n "${GITLAB_DUO_ENABLED:-}" ]; then
        check_done "GITLAB_DUO_ENABLED está carregado"
    else
        check_pending "GITLAB_DUO_ENABLED não está carregado"
        echo "   Execute: nix develop ./nix"
    fi
    
    if [ -n "${GITLAB_DUO_API_KEY:-}" ]; then
        check_done "GITLAB_DUO_API_KEY está carregado"
    else
        check_pending "GITLAB_DUO_API_KEY não está carregado"
    fi
    echo ""
    
    # 6. Validation
    echo "✅ Validação"
    if command -v yq &> /dev/null; then
        check_done "yq está instalado"
    else
        check_pending "yq não está instalado"
        echo "   Execute: nix develop ./nix (inclui yq)"
    fi
    
    if [ -f "nix/gitlab-duo/settings.yaml" ] && command -v yq &> /dev/null; then
        if yq eval '.' nix/gitlab-duo/settings.yaml > /dev/null 2>&1; then
            check_done "settings.yaml tem sintaxe YAML válida"
        else
            check_pending "settings.yaml tem erro de sintaxe"
        fi
    fi
    echo ""
    
    # Summary
    print_header "Resumo"
    echo -e "${GREEN}Completo:${NC}  $COMPLETED"
    echo -e "${YELLOW}Pendente:${NC}  $PENDING"
    echo ""
    
    if [ $PENDING -eq 0 ]; then
        echo -e "${GREEN}✅ Setup Completo!${NC}"
        echo ""
        echo "Próximos passos:"
        echo "  1. nix develop ./nix"
        echo "  2. bash nix/scripts/validate-gitlab-duo.sh"
        echo "  3. Começar a usar GitLab Duo!"
        return 0
    else
        echo -e "${YELLOW}⚠️  Ainda há itens pendentes${NC}"
        echo ""
        echo "Próximos passos:"
        echo "  1. Completar os itens pendentes acima"
        echo "  2. Executar este script novamente"
        return 1
    fi
}

main "$@"
