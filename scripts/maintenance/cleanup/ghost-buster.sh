#!/usr/bin/env bash
# ghost-buster.sh: Limpeza profunda de artefatos dev + fantasmas do sistema
# Foco: ML/AI caches, Rust/Go global, system ghosts, Nix, Docker/Podman
# v2 - escopo de sistema completo

set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
NC="\033[0m"
BOLD="\033[1m"

# Diretórios de projetos — todos os lugares com código
PROJECT_DIRS=(
  "/home/kernelcore/master"
  "/home/kernelcore/dev"
  "/home/kernelcore/projects"
  "/home/kernelcore/workspace"
  "/home/kernelcore/src"
)
USER_HOME="/home/kernelcore"

banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║       👻 GHOST BUSTER v2 — SYSTEM SCOPE 👻               ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

report_space() {
  echo -e "${YELLOW}  Espaço livre: $(df -h / | awk 'NR==2 {print $4}') | Usado: $(df -h / | awk 'NR==2 {print $3}') ($(df -h / | awk 'NR==2 {print $5}'))${NC}"
}

ask() {
  # ask <prompt> — retorna 0 se S/Enter, 1 se N
  local prompt="$1"
  read -p "   $prompt (S/n) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]
}

ask_y() {
  # ask_y <prompt> — retorna 0 se Y, 1 caso contrário (default N)
  local prompt="$1"
  read -p "   $prompt (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

# ============================================================================
# 1. SYMLINKS NIX result* — destrava o GC
# ============================================================================
clean_nix_links() {
  echo -e "\n${BOLD}1. Caçando symlinks 'result*' do Nix...${NC}"
  echo -e "   ${CYAN}(Isso destrava o GC para remover builds antigos)${NC}"

  local all_links=""
  for d in "${PROJECT_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    local found
    found=$(find "$d" -maxdepth 5 -name "result*" -type l 2>/dev/null)
    [[ -n "$found" ]] && all_links+="$found"$'\n'
  done
  # também na home raiz
  local home_links
  home_links=$(find "$USER_HOME" -maxdepth 2 -name "result*" -type l 2>/dev/null)
  [[ -n "$home_links" ]] && all_links+="$home_links"$'\n'

  all_links=$(echo "$all_links" | grep -v '^$' || true)

  if [[ -z "$all_links" ]]; then
    echo -e "${GREEN}   ✓ Nenhum symlink travado encontrado.${NC}"
  else
    local count
    count=$(echo "$all_links" | wc -l)
    echo -e "${RED}   $count links encontrados:${NC}"
    echo "$all_links" | head -5 | sed 's/^/     /'
    [[ $count -gt 5 ]] && echo "     ... e mais $((count - 5))"
    if ask "🗑️  Remover $count symlinks para liberar o GC?"; then
      echo "$all_links" | xargs rm -f
      echo -e "${GREEN}   ✓ Links removidos.${NC}"
    fi
  fi
  report_space
}

# ============================================================================
# 2. RUST target/ em projetos
# ============================================================================
clean_rust_targets() {
  echo -e "\n${BOLD}2. Diretórios 'target/' Rust em projetos...${NC}"

  local targets=""
  for d in "${PROJECT_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    local found
    found=$(find "$d" -maxdepth 6 -type d -name "target" \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" 2>/dev/null)
    [[ -n "$found" ]] && targets+="$found"$'\n'
  done
  targets=$(echo "$targets" | grep -v '^$' || true)

  if [[ -z "$targets" ]]; then
    echo -e "${GREEN}   ✓ Nenhum target/ encontrado.${NC}"
    return
  fi

  echo "   Calculando tamanhos..."
  local total_targets=0
  while IFS= read -r t; do
    [[ -d "$t" ]] || continue
    total_targets=$((total_targets + 1))
    size=$(du -sh "$t" 2>/dev/null | cut -f1)
    echo "   📦 $size  $t"
  done <<< "$targets"

  echo -e "${YELLOW}   ⚠ Deletar target/ força recompilação total.${NC}"
  if ask_y "Rodar 'cargo clean' em todos esses projetos?"; then
    while IFS= read -r t; do
      [[ -d "$t" ]] || continue
      parent=$(dirname "$t")
      echo -e "   Limpando $parent..."
      (cd "$parent" && cargo clean 2>/dev/null) || rm -rf "$t"
    done <<< "$targets"
    echo -e "${GREEN}   ✓ Projetos Rust limpos.${NC}"
  fi
  report_space
}

# ============================================================================
# 3. RUST GLOBAL CACHE (~/.cargo/registry + git)
# ============================================================================
clean_rust_global_cache() {
  echo -e "\n${BOLD}3. Rust global cache (~/.cargo/registry, ~/.cargo/git)...${NC}"
  echo -e "   ${CYAN}(Esses caches aceleram builds — limpar força re-download)${NC}"

  local reg_size git_size
  reg_size=$(du -sh "$USER_HOME/.cargo/registry" 2>/dev/null | cut -f1 || echo "0")
  git_size=$(du -sh "$USER_HOME/.cargo/git"      2>/dev/null | cut -f1 || echo "0")

  echo -e "   📦 ~/.cargo/registry : $reg_size"
  echo -e "   📦 ~/.cargo/git      : $git_size"

  if ask_y "Limpar cargo registry e git cache?"; then
    rm -rf "$USER_HOME/.cargo/registry" "$USER_HOME/.cargo/git"
    echo -e "${GREEN}   ✓ Cargo global cache limpo.${NC}"
  fi
  report_space
}

# ============================================================================
# 4. GO global build cache
# ============================================================================
clean_go_cache() {
  echo -e "\n${BOLD}4. Go build cache (~/.cache/go-build)...${NC}"

  if [[ -d "$USER_HOME/.cache/go-build" ]]; then
    local size
    size=$(du -sh "$USER_HOME/.cache/go-build" | cut -f1)
    echo -e "   📦 ~/.cache/go-build : $size"
    if ask_y "Limpar Go build cache?"; then
      go clean -cache 2>/dev/null || rm -rf "$USER_HOME/.cache/go-build"
      echo -e "${GREEN}   ✓ Go cache limpo.${NC}"
    fi
  else
    echo -e "${GREEN}   ✓ Nenhum Go cache encontrado.${NC}"
  fi
  report_space
}

# ============================================================================
# 5. PYTHON + tool caches globais (pip, uv, pnpm, bun)
# ============================================================================
clean_dev_caches() {
  echo -e "\n${BOLD}5. Caches globais de dev (pip, uv, npm, pnpm, bun)...${NC}"

  local caches=(
    "$USER_HOME/.cache/pip:pip"
    "$USER_HOME/.cache/uv:uv"
    "$USER_HOME/.npm/_cacache:npm"
    "$USER_HOME/.pnpm-store:pnpm"
    "$USER_HOME/.bun/install/cache:bun"
    "$USER_HOME/.gradle/caches:gradle"
    "$USER_HOME/.m2/repository:maven"
  )

  for entry in "${caches[@]}"; do
    path="${entry%%:*}"
    label="${entry##*:}"
    if [[ -d "$path" ]]; then
      local size
      size=$(du -sh "$path" | cut -f1)
      echo -e "   📦 $label cache : $size"
      if ask_y "      Limpar $label cache?"; then
        case "$label" in
          npm)  npm cache clean --force 2>/dev/null || rm -rf "$path" ;;
          *)    rm -rf "$path" ;;
        esac
        echo -e "${GREEN}      ✓ Limpo.${NC}"
      fi
    fi
  done

  # Lixeira
  local trash="$USER_HOME/.local/share/Trash"
  if [[ -d "$trash" ]]; then
    local size
    size=$(du -sh "$trash" 2>/dev/null | cut -f1)
    echo -e "   🗑️  Lixeira: $size"
    if ask "Esvaziar Lixeira?"; then
      rm -rf "${trash:?}"/*
      echo -e "${GREEN}   ✓ Lixeira esvaziada.${NC}"
    fi
  fi
  report_space
}

# ============================================================================
# 6. ML/AI CACHES — O grande ocupador em sistemas com GPU
# ============================================================================
clean_ml_caches() {
  echo -e "\n${BOLD}6. 🤖 ML/AI Caches (HuggingFace, PyTorch, Transformers, Ollama)...${NC}"

  local ml_paths=(
    "$USER_HOME/.cache/huggingface:HuggingFace models"
    "$USER_HOME/.cache/torch:PyTorch cache"
    "$USER_HOME/.cache/transformers:Transformers cache"
    "$USER_HOME/.ollama/models:Ollama models"
    "$USER_HOME/.cache/diffusers:Diffusers cache"
    "$USER_HOME/.cache/clip:CLIP models"
  )

  for entry in "${ml_paths[@]}"; do
    path="${entry%%:*}"
    label="${entry##*:}"
    if [[ -d "$path" ]]; then
      local size
      size=$(du -sh "$path" | cut -f1)
      echo -e "   📦 $label : ${RED}$size${NC}"
      if ask_y "      Limpar $label?"; then
        rm -rf "$path"
        echo -e "${GREEN}      ✓ Limpo.${NC}"
      fi
    fi
  done

  # /var/lib/ml-models — bridge path customizado
  if [[ -d "/var/lib/ml-models" ]]; then
    echo ""
    echo -e "   ${RED}${BOLD}📦 /var/lib/ml-models (bridge custom):${NC}"
    sudo du -sh /var/lib/ml-models/ 2>/dev/null
    echo "   Conteúdo:"
    sudo ls -lh /var/lib/ml-models/ 2>/dev/null | head -20 | sed 's/^/     /'
    echo ""
    echo -e "   ${YELLOW}⚠ ATENÇÃO: Este diretório é o bridge de modelos das labels.${NC}"
    echo -e "   ${YELLOW}  Só limpe modelos que não são mais usados!${NC}"
    if ask_y "      Listar e selecionar modelos para remover?"; then
      echo ""
      echo "   Modelos disponíveis:"
      sudo ls /var/lib/ml-models/ 2>/dev/null | nl | sed 's/^/     /'
      echo ""
      echo -n "   Digite os nomes (separados por espaço) para remover, ou Enter para pular: "
      read -r models_to_remove
      if [[ -n "$models_to_remove" ]]; then
        for m in $models_to_remove; do
          if [[ -e "/var/lib/ml-models/$m" ]]; then
            sudo rm -rf "/var/lib/ml-models/$m"
            echo -e "${GREEN}   ✓ Removido: $m${NC}"
          else
            echo -e "${RED}   ✗ Não encontrado: $m${NC}"
          fi
        done
      fi
    fi
  fi
  report_space
}

# ============================================================================
# 7. DOCKER + PODMAN
# ============================================================================
clean_containers() {
  echo -e "\n${BOLD}7. Docker + Podman...${NC}"

  # Docker
  if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null 2>&1; then
    echo -e "   ${CYAN}Docker está ativo.${NC}"
    sudo docker system df 2>/dev/null | sed 's/^/   /'
    echo ""
    if ask_y "   Limpar Docker builder cache (builds >24h)?"; then
      sudo docker builder prune -f --filter "until=24h"
      echo -e "${GREEN}   ✓ Builder cache limpo.${NC}"
    fi
    if ask_y "   Limpar imagens/volumes/containers não usados (docker system prune)?"; then
      docker system prune -f --volumes
      echo -e "${GREEN}   ✓ Docker limpo.${NC}"
    fi
  else
    echo -e "   ${BLUE}Docker não está ativo.${NC}"
  fi

  # Podman
  if command -v podman &>/dev/null; then
    echo ""
    echo -e "   ${CYAN}Podman detectado.${NC}"
    podman system df 2>/dev/null | sed 's/^/   /' || true
    if ask_y "   Limpar Podman (system prune)?"; then
      podman system prune -f --volumes 2>/dev/null || true
      echo -e "${GREEN}   ✓ Podman limpo.${NC}"
    fi
  fi
  report_space
}

# ============================================================================
# 8. PYTHON artifacts em projetos
# ============================================================================
clean_python_artifacts() {
  echo -e "\n${BOLD}8. Python artifacts em projetos (__pycache__, pytest, mypy, ruff)...${NC}"

  local found_dirs=""
  for d in "${PROJECT_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    local f
    f=$(find "$d" -type d \( \
      -name "__pycache__" -o \
      -name ".pytest_cache" -o \
      -name ".mypy_cache" -o \
      -name ".ruff_cache" -o \
      -name ".ipynb_checkpoints" \
    \) 2>/dev/null)
    [[ -n "$f" ]] && found_dirs+="$f"$'\n'
  done
  found_dirs=$(echo "$found_dirs" | grep -v '^$' || true)

  if [[ -z "$found_dirs" ]]; then
    echo -e "${GREEN}   ✓ Nenhum cache Python encontrado.${NC}"
  else
    local count
    count=$(echo "$found_dirs" | wc -l)
    echo -e "${YELLOW}   $count diretórios de cache Python:${NC}"
    echo "$found_dirs" | head -5 | sed 's/^/   - /'
    [[ $count -gt 5 ]] && echo "   ... e mais $((count - 5))"
    if ask "🗑️  Remover todos?"; then
      echo "$found_dirs" | xargs rm -rf
      echo -e "${GREEN}   ✓ Caches Python removidos.${NC}"
    fi
  fi

  # .pyc soltos
  for d in "${PROJECT_DIRS[@]}"; do
    [[ -d "$d" ]] && find "$d" -name "*.pyc" -delete 2>/dev/null
  done
  echo -e "${GREEN}   ✓ Arquivos .pyc limpos.${NC}"
  report_space
}

# ============================================================================
# 9. SYSTEM GHOSTS — core dumps, /tmp grandes, direnv global
# ============================================================================
clean_system_ghosts() {
  echo -e "\n${BOLD}9. 👻 System Ghosts (core dumps, /tmp, direnv global)...${NC}"

  # Core dumps do systemd
  if [[ -d "/var/lib/systemd/coredump" ]]; then
    local size
    size=$(sudo du -sh /var/lib/systemd/coredump 2>/dev/null | cut -f1)
    echo -e "   💀 Core dumps: ${RED}$size${NC}"
    if ask_y "   Limpar core dumps?"; then
      sudo rm -rf /var/lib/systemd/coredump/*
      echo -e "${GREEN}   ✓ Core dumps removidos.${NC}"
    fi
  fi

  # Arquivos grandes em /tmp
  echo ""
  echo -e "   🗂️  Arquivos >100MB em /tmp:"
  local tmp_large
  tmp_large=$(find /tmp -maxdepth 3 -type f -size +100M 2>/dev/null | head -20)
  if [[ -n "$tmp_large" ]]; then
    echo "$tmp_large" | while read -r f; do
      echo "   $(du -sh "$f" 2>/dev/null | cut -f1)  $f"
    done
    if ask_y "   Remover esses arquivos de /tmp?"; then
      echo "$tmp_large" | xargs rm -f 2>/dev/null || true
      echo -e "${GREEN}   ✓ /tmp limpo.${NC}"
    fi
  else
    echo -e "${GREEN}   ✓ Nenhum arquivo grande em /tmp.${NC}"
  fi

  # direnv cache global
  if [[ -d "$USER_HOME/.direnv" ]]; then
    local size
    size=$(du -sh "$USER_HOME/.direnv" | cut -f1)
    echo ""
    echo -e "   📦 ~/.direnv global : $size"
    if ask_y "   Limpar ~/.direnv global?"; then
      rm -rf "$USER_HOME/.direnv"
      echo -e "${GREEN}   ✓ ~/.direnv removido.${NC}"
    fi
  fi
  report_space
}

# ============================================================================
# 10. NIX — GC Roots + Gerações antigas + Profile
# ============================================================================
clean_nix_generations() {
  echo -e "\n${BOLD}10. ❄️  Nix — Gerações e GC Roots...${NC}"

  # Gerações do sistema
  echo -e "   ${CYAN}Gerações do sistema:${NC}"
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | tail -10 | sed 's/^/   /'
  echo ""

  if ask_y "   Deletar gerações antigas do sistema (mantém a atual)?"; then
    sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
    echo -e "${GREEN}   ✓ Gerações do sistema removidas.${NC}"
  fi

  # Nix profile (novo sistema)
  if command -v nix &>/dev/null; then
    echo ""
    echo -e "   ${CYAN}Nix profile generations (usuário):${NC}"
    nix profile history 2>/dev/null | tail -5 | sed 's/^/   /' || true
    if ask_y "   Executar nix-collect-garbage -d (GC completo)?"; then
      echo "   Rodando GC de usuário..."
      nix-collect-garbage -d
      echo "   Rodando GC do sistema..."
      sudo nix-collect-garbage -d
      echo -e "${GREEN}   ✓ Nix GC concluído.${NC}"
    fi
  fi

  # GC roots que bloqueiam limpeza
  echo ""
  local roots_count
  roots_count=$(nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | wc -l)
  echo -e "   📍 GC roots ativos (bloqueando store): $roots_count"
  nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | head -10 | sed 's/^/   /'
  report_space
}

# ============================================================================
# MAIN
# ============================================================================

banner
report_space

echo ""
echo -e "${BOLD}Iniciando varredura — responda S/Enter para aceitar, N para pular cada seção.${NC}"
echo ""

clean_nix_links
clean_rust_targets
clean_rust_global_cache
clean_go_cache
clean_dev_caches
clean_ml_caches
clean_containers
clean_python_artifacts
clean_system_ghosts
clean_nix_generations

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}--- Ghost Buster finalizado ---${NC}"
report_space
echo ""
echo -e "${CYAN}Próximo passo recomendado:${NC}"
echo -e "  ${BOLD}limpeza-agressiva.sh${NC} → Nix GC final + logs de sistema"
