#!/usr/bin/env bash
# Example: Using GitLab Duo Configuration
# Este script demonstra como usar a configuração do GitLab Duo

set -euo pipefail

echo "🚀 GitLab Duo Configuration Example"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Verificar se está no ambiente Nix
if [ -z "${GITLAB_DUO_ENABLED:-}" ]; then
    echo "❌ GitLab Duo não está configurado"
    echo ""
    echo "Para ativar, execute:"
    echo "  nix develop ./nix"
    exit 1
fi

echo "✓ GitLab Duo está ativo"
echo ""

# 2. Mostrar configuração carregada
echo "📋 Configuração Carregada:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Endpoint: $GITLAB_DUO_ENDPOINT"
echo "Log Level: $GITLAB_DUO_LOG_LEVEL"
echo "Cache Enabled: $GITLAB_DUO_CACHE_ENABLED"
echo "Cache TTL: ${GITLAB_DUO_CACHE_TTL}s"
echo ""

# 3. Mostrar features habilitadas
echo "🎯 Features Habilitadas:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ "${GITLAB_DUO_FEATURES_CODE_COMPLETION:-false}" = "true" ] && echo "✓ Code Completion"
[ "${GITLAB_DUO_FEATURES_CODE_REVIEW:-false}" = "true" ] && echo "✓ Code Review"
[ "${GITLAB_DUO_FEATURES_SECURITY_SCANNING:-false}" = "true" ] && echo "✓ Security Scanning"
[ "${GITLAB_DUO_FEATURES_DOCUMENTATION:-false}" = "true" ] && echo "✓ Documentation Generation"
echo ""

# 4. Mostrar modelos configurados
echo "🤖 Modelos Configurados:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Code Generation: $GITLAB_DUO_MODEL_CODE_GENERATION"
echo "Code Review: $GITLAB_DUO_MODEL_CODE_REVIEW"
echo "Security: $GITLAB_DUO_MODEL_SECURITY"
echo ""

# 5. Mostrar rate limits
echo "⚡ Rate Limits:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Requests per Minute: $GITLAB_DUO_RATE_LIMIT_RPM"
echo "Tokens per Minute: $GITLAB_DUO_RATE_LIMIT_TPM"
echo ""

# 6. Exemplos de uso
echo "💡 Exemplos de Uso:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Validar configuração:"
echo "   bash nix/scripts/validate-gitlab-duo.sh"
echo ""
echo "2. Usar em scripts:"
echo "   if [ \"\$GITLAB_DUO_ENABLED\" = \"true\" ]; then"
echo "     # Usar GitLab Duo"
echo "   fi"
echo ""
echo "3. Acessar configuração:"
echo "   echo \$GITLAB_DUO_ENDPOINT"
echo "   echo \$GITLAB_DUO_LOG_LEVEL"
echo ""
echo "4. Customizar (editar):"
echo "   vim nix/gitlab-duo/settings.yaml"
echo ""

# 7. Verificar API key
echo "🔐 Verificação de Segurança:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -n "${GITLAB_DUO_API_KEY:-}" ]; then
    echo "✓ API Key carregada"
else
    echo "⚠ API Key não encontrada"
    echo "  Configure em: ~/.config/gitlab-duo/api-key"
fi
echo ""

echo "✅ GitLab Duo está pronto para usar!"
