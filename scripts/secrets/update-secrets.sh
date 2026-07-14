#!/usr/bin/env bash
set -e
cd /etc/nixos

# Descriptografar
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d secrets/api.yaml > /tmp/api-dec.yaml

# Adicionar novos campos
cat >> /tmp/api-dec.yaml <<'EOF'

# Google Cloud / Gemini Configuration
google_cloud_project: gen-lang-client-0530325234
google_cloud_location: us-central1
EOF

# Re-criptografar (do diretório correto para encontrar .sops.yaml)
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -e /tmp/api-dec.yaml > secrets/api.yaml

# Limpar
rm /tmp/api-dec.yaml

echo "✓ Secrets atualizados!"
