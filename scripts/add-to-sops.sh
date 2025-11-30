#!/usr/bin/env bash
set -e

TMP=$(mktemp)
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d secrets/api.yaml > "$TMP"

# Adicionar novos campos
cat >> "$TMP" <<'EOF'

# Google Cloud / Gemini Configuration
google_cloud_project: gen-lang-client-0530325234
google_cloud_location: us-central1
EOF

# Usar sops para re-criptografar preservando metadados
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt EDITOR="cp $TMP" sops secrets/api.yaml

rm "$TMP"
echo "✓ Atualizado!"
