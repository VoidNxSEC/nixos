#!/usr/bin/env bash
# MOVE: Script
# Padrão base
PATTERN="\.programs\.[a-zA-Z0-9_-]+"

# Busca recursiva com contexto
rg -n "$PATTERN" --type nix | \
  awk -F: '{print "Arquivo: "$1"\nLinha "$2": "$3"\n---"}'

# Contagem por módulo
echo "=== ESTATÍSTICAS ==="
rg -l "$PATTERN" --type nix | \
  xargs -I {} basename {} | \
  sort | uniq -c | sort -nr
