#!/usr/bin/env bash
# Método simples: descriptografar, adicionar, re-criptografar com metadados originais

cd /etc/nixos

# 1. Descriptografar
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d secrets/api.yaml > /tmp/plain.yaml

# 2. Adicionar novos campos
cat >> /tmp/plain.yaml <<'FIELDS'

# Google Cloud / Gemini Configuration
google_cloud_project: gen-lang-client-0530325234
google_cloud_location: us-central1
FIELDS

# 3. Backup do original
cp secrets/api.yaml secrets/api.yaml.pre-update

# 4. Re-criptografar usando o updatekeys para preservar metadados
SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops --config .sops.yaml -e /tmp/plain.yaml > secrets/api.yaml

# 5. Limpar
rm /tmp/plain.yaml

echo "✓ Secrets updated successfully!"
echo "  Backup saved to: secrets/api.yaml.pre-update"
