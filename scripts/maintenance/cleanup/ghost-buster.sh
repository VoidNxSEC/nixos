#!/usr/bin/env bash
# ghost-buster.sh: Limpeza profunda de artefatos de dev e "fantasmas" do Nix
# Foco: Projetos Rust, Python, Symlinks Nix travados, Caches de Build

set -e

# Cores
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m"
BOLD="\033[1m"

PROJECTS_DIR="/home/kernelcore/dev/Project/"
USER_HOME="/home/kernelcore"

banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║           👻 GHOST BUSTER - LIMPEZA DEV 👻                ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

report_space() {
  echo -e "${YELLOW}Espaço Livre Atual: $(df -h / | awk 'NR==2 {print $4}')${NC}"
}

# ============================================================================
# 1. REMOÇÃO DE SYMLINKS NIX (CRÍTICO PARA O GC FUNCIONAR)
# ============================================================================
clean_nix_links() {
  echo -e "\n${BOLD}1. Caçando symlinks 'result' do Nix...${NC}"
  echo "   (Isso destrava o GC para remover builds antigos)"

  local links=$(find "$PROJECTS_DIR" -maxdepth 4 -name "result*" -type l 2>/dev/null)

  if [ -z "$links" ]; then
    echo -e "${GREEN}   ✓ Nenhum symlink travado encontrado.${NC}"
  else
    echo -e "${RED}   Links encontrados:${NC}"
    echo "$links" | head -n 5
    local count=$(echo "$links" | wc -l)
    if [ "$count" -gt 5 ]; then echo "... e mais $((count - 5))\n"; fi

    read -p "   🗑️  Remover $count symlinks para liberar o GC? (S/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]; then
      echo "$links" | xargs rm
      echo -e "${GREEN}   ✓ Links removidos. O próximo Nix GC será muito mais efetivo.${NC}"
    fi
  fi
}

# ============================================================================
# 2. LIMPEZA DE ARTEFATOS RUST (TARGET)
# ============================================================================
clean_rust_targets() {
  echo -e "\n${BOLD}2. Analisando diretórios 'target' do Rust...${NC}"

  local targets=$(find "$PROJECTS_DIR" -maxdepth 5 -type d -name "target" -not -path "*/node_modules/*" 2>/dev/null)

  if [ -z "$targets" ]; then
    echo -e "${GREEN}   ✓ Nenhum diretório target relevante encontrado.${NC}"
    return
  fi

  echo "   Calculando tamanhos (pode demorar um pouco)..."
  for target in $targets; do
    if [ -d "$target" ]; then
      size=$(du -sh "$target" 2>/dev/null | cut -f1)
      echo "   📦 $size  $target"
    fi
  done

  echo -e "${YELLOW}   ⚠️  Atenção: Deletar 'target' força recompilação total no próximo build.${NC}"
  read -p "   Deseja rodar 'cargo clean' em TODOS esses projetos? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    for target in $targets; do
      if [ -d "$target" ]; then
        parent=$(dirname "$target")
        echo -e "   Limpando $parent..."
        (cd "$parent" && cargo clean 2>/dev/null || rm -rf target)
      fi
    done
    echo -e "${GREEN}   ✓ Projetos Rust limpos.${NC}"
  fi
}

# ============================================================================
# 3. LIMPEZA DE ARTEFATOS PYTHON (PYCACHE, ETC)
# ============================================================================
clean_python_artifacts() {
  echo -e "\n${BOLD}3. Analisando artefatos Python (pycache, pytest, ipynb)...${NC}"

  local patterns=(
    "__pycache__"
    ".pytest_cache"
    ".mypy_cache"
    ".ipynb_checkpoints"
    ".ruff_cache"
    "*.pyc"
  )

  echo "   Buscando artefatos em $PROJECTS_DIR..."

  local found_dirs=$(find "$PROJECTS_DIR" -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ipynb_checkpoints" -o -name ".ruff_cache" \) 2>/dev/null)

  if [ -z "$found_dirs" ]; then
    echo -e "${GREEN}   ✓ Nenhum cache de diretório Python relevante encontrado.${NC}"
  else
    local count_dirs=$(echo "$found_dirs" | wc -l)
    echo -e "${YELLOW}   Encontrados $count_dirs diretórios de cache Python (ex: __pycache__).${NC}"

    echo "$found_dirs" | head -n 3 | sed 's/^/   - /'
    if [ "$count_dirs" -gt 3 ]; then echo "   ... e mais $((count_dirs - 3))\n"; fi

    read -p "   🗑️  Remover todos esses caches Python? (S/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]; then
      echo "$found_dirs" | xargs rm -rf
      echo -e "${GREEN}   ✓ Diretórios de cache removidos.${NC}"
    fi
  fi

  echo "   Buscando arquivos .pyc soltos..."
  find "$PROJECTS_DIR" -name "*.pyc" -delete
  echo -e "${GREEN}   ✓ Arquivos .pyc limpos.${NC}"
}

# ============================================================================
# 4. LIMPEZA DE CACHES DE LINGUAGEM E FERRAMENTAS
# ============================================================================
clean_caches() {
  echo -e "\n${BOLD}4. Verificando Caches Globais de Dev...${NC}"

  if [ -d "$USER_HOME/.npm/_cacache" ]; then
    npm_size=$(du -sh "$USER_HOME/.npm/_cacache" | cut -f1)
    echo -e "   📦 NPM Cache: $npm_size"
    read -p "      Limpar NPM Cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      npm cache clean --force 2>/dev/null || rm -rf "$USER_HOME/.npm/_cacache"
      echo -e "${GREEN}      ✓ Limpo.${NC}"
    fi
  fi

  if [ -d "$USER_HOME/.cache/pip" ]; then
    pip_size=$(du -sh "$USER_HOME/.cache/pip" | cut -f1)
    echo -e "   📦 Pip Cache: $pip_size"
    read -p "      Limpar Pip Cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "$USER_HOME/.cache/pip"
      echo -e "${GREEN}      ✓ Limpo.${NC}"
    fi
  fi

  if [ -d "$USER_HOME/.cache/uv" ]; then
    uv_size=$(du -sh "$USER_HOME/.cache/uv" | cut -f1)
    echo -e "   📦 UV Cache: $uv_size"
    read -p "      Limpar UV Cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "$USER_HOME/.cache/uv"
      echo -e "${GREEN}      ✓ Limpo.${NC}"
    fi
  fi

  trash_path="$USER_HOME/.local/share/Trash"
  if [ -d "$trash_path" ]; then
    trash_size=$(du -sh "$trash_path" 2>/dev/null | cut -f1)
    echo -e "   🗑️  Lixeira: $trash_size"
    if [ "$trash_size" != "0" ]; then
      read -p "      Esvaziar Lixeira? (S/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]; then
        rm -rf "$trash_path"/*
        echo -e "${GREEN}      ✓ Lixeira esvaziada.${NC}"
      fi
    fi
  fi
}

# ============================================================================
# 5. LIMPEZA DOCKER BUILDER (FANTASMA COMUM)
# ============================================================================
clean_docker_ghosts() {
  echo -e "\n${BOLD}5. Verificando Cache de Build do Docker...${NC}"
  if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null; then
    echo "   Executando 'docker builder prune' (Cache de camadas de build)..."
    sudo docker builder prune -f --filter "until=24h"
    echo -e "${GREEN}   ✓ Cache de build recente mantido, antigos removidos.${NC}"
  else
    echo "   Docker não ativo ou não instalado."
  fi
}

# ============================================================================
# MAIN
# ============================================================================

banner
report_space

clean_nix_links
clean_rust_targets
clean_python_artifacts
clean_caches
clean_docker_ghosts

echo -e "\n${BOLD}--- Fim da fase de Caça aos Fantasmas ---${NC}"
report_space
echo -e "\n${CYAN}Recomendação: Agora rode o './limpeza-agressiva.sh' para finalizar o Garbage Collection do Nix.${NC}"
