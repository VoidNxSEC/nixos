#!/usr/bin/env bash
# Este script atua como "editor" para o SOPS
# Adiciona as linhas necessárias ao arquivo descriptografado

INPUT_FILE="$1"

# Adicionar novos campos ao final do arquivo
cat >> "$INPUT_FILE" <<'NEWFIELDS'

# Google Cloud / Gemini Configuration
google_cloud_project: gen-lang-client-0530325234
google_cloud_location: us-central1
NEWFIELDS

echo "Campos adicionados ao arquivo temporário" >&2
