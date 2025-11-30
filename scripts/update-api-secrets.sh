#!/usr/bin/env bash
set -e

SECRETS_FILE="/etc/nixos/secrets/api.yaml"
TMP_DECRYPTED="/tmp/api-decrypted-$$.yaml"
TMP_UPDATED="/tmp/api-updated-$$.yaml"

# Descriptografar arquivo existente
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d "$SECRETS_FILE" > "$TMP_DECRYPTED"

# Verificar se os campos já existem
if grep -q "google_cloud_project" "$TMP_DECRYPTED"; then
    echo "✓ Google Cloud fields already exist in secrets"
    cat "$TMP_DECRYPTED"
    rm "$TMP_DECRYPTED"
    exit 0
fi

# Adicionar novos campos do Google Cloud
cat "$TMP_DECRYPTED" > "$TMP_UPDATED"
cat >> "$TMP_UPDATED" <<'EOF'

# Google Cloud / Gemini Configuration
google_cloud_project: gen-lang-client-0530325234
google_cloud_location: us-central1
EOF

# Re-criptografar
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e "$TMP_UPDATED" > "$SECRETS_FILE"

# Limpar
rm "$TMP_DECRYPTED" "$TMP_UPDATED"

echo "✓ Secrets updated successfully!"
