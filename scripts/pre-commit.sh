#!/bin/sh
# 🔫 Caçador de Segredos

SECRET_PATTERNS="API_KEY|TOKEN|PASSWORD|SECRET|PRIVATE_KEY|CREDENTIALS"
FILES=$(git diff --cached --name-only)

# Verifica padrões perigosos
for file in $FILES; do
    if grep -qE "$SECRET_PATTERNS" "$file"; then
        echo "[🚨 ALERTA] Possível segredo encontrado em: $file"
        exit 1  # Aborta commit
    fi
done

# Verifica arquivos proibidos
FORBIDDEN_FILES=$(git diff --cached --name-only | grep -E "\.env|secrets\.md|credentials\.json")
if [ ! -z "$FORBIDDEN_FILES" ]; then
    echo "[💀 ERRO] Arquivos proibidos no commit:"
    echo "$FORBIDDEN_FILES"
    exit 1
fi

echo "[✅] Commit limpo. Prossiga, agente."

