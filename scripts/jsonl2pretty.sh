#!/usr/bin/env bash
# Conversor direto: JSONL → JSON formatado
# USO: ./jsonl2pretty.sh entrada.jsonl [saida.json]

INPUT="${1:-/dev/stdin}"
OUTPUT="${2:-/dev/stdout}"

# Verifica se jq está instalado
if ! command -v jq &>/dev/null; then
  echo "ERRO: jq não encontrado! Instale com: sudo apt install jq"
  exit 1
fi

echo "[" >"$OUTPUT"

# Processa linha por linha, formatando com jq
FIRST=true
while IFS= read -r line; do
  if [ "$FIRST" = false ]; then
    echo "," >>"$OUTPUT"
  fi
  echo "$line" | jq '.' >>"$OUTPUT"
  FIRST=false
done <"$INPUT"

echo "]" >>"$OUTPUT"

echo "✅ CONVERSÃO CONCLUÍDA: $INPUT → $OUTPUT"
