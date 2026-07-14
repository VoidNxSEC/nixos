#!/usr/bin/env bash
# ------------------------------------------------------------------
# bootstrap-project.sh – cria um esqueleto de repositório Git
#
# Uso:
#   ./bootstrap-project.sh <nome-do-projeto>
#
# O script cria:
#   • diretório raiz <nome-do-projeto>
#   • sub‑diretórios src/, tests/, docs/
#   • .gitignore (padrão para Rust + Linux)
#   • README.md com título e badge de licença
#   • inicializa o repositório git
# ------------------------------------------------------------------

set -euo pipefail

# ---------- Funções auxiliares ----------
die() { echo "❌  $*" >&2; exit 1; }

# ---------- Verificações iniciais ----------
if [[ $# -ne 1 ]]; then
    die "Forneça exatamente um argumento: o nome do projeto."
fi

PROJECT_NAME=$1
ROOT_DIR=$(pwd)/"$PROJECT_NAME"

if [[ -e "$ROOT_DIR" ]]; then
    die "Diretório '$ROOT_DIR' já existe. Escolha outro nome ou remova-o."
fi

# ---------- Criação da árvore de diretórios ----------
mkdir -p "$ROOT_DIR"/{src,tests,docs}
echo "📁  Diretórios criados em $ROOT_DIR"

# ---------- .gitignore ----------
cat > "$ROOT_DIR/.gitignore" <<'EOF'
# Arquivos de compilação Rust
target/
**/*.rs.bk

# IDE / Editor
.idea/
.vscode/
*.swp
*~

# Sistema
.DS_Store
Thumbs.db

# Logs
*.log

# Binários
*.exe
*.dll
*.so
*.dylib

# Pacotes
*.crate
Cargo.lock

# Outros artefatos temporários
/tmp/
/temp/
EOF
echo "🗑️  .gitignore criado"

# ---------- README.md ----------
cat > "$ROOT_DIR/README.md" <<EOF
# $PROJECT_NAME

Descrição curta do projeto. Explique o objetivo, principais funcionalidades e como começar a usar.

## Começando

```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/$PROJECT_NAME.git
cd $PROJECT_NAME

# Build (exemplo Rust)
cargo build --release
