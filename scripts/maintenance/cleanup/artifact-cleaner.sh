#!/usr/bin/env bash
# artifact-cleaner.sh: Limpeza contextual segura de artefatos de build
# SEGURANÇA: Só deleta pastas de build se encontrar os arquivos de definição do projeto ao lado.
# v2 - multi-dir, Go, frontend builds, coverage, .direnv, contador total

set -e

# Diretórios padrão — adicionados se existirem
DEFAULT_DIRS=(
  "/home/kernelcore/master"
  "/home/kernelcore/dev"
  "/home/kernelcore/projects"
  "/home/kernelcore/workspace"
  "/home/kernelcore/src"
  "/home/kernelcore/arch"
)
DRY_RUN=true

# Cores
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"
BOLD="\033[1m"

# Contador global (em KB)
TOTAL_KB=0
TOTAL_ITEMS=0

usage() {
  echo -e "${BOLD}Artifact Cleaner v2 - Limpeza Contextual Segura${NC}"
  echo "Uso: $0 [--force] [dir1 dir2 ...]"
  echo ""
  echo "  Por padrão, roda em modo SIMULAÇÃO (Dry Run)."
  echo "  Use --force para deletar os arquivos de fato."
  echo "  Diretórios extras podem ser passados como argumentos adicionais."
  echo ""
}

# Parseia argumentos
SCAN_DIRS=()
for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then
    DRY_RUN=false
  elif [[ -d "$arg" ]]; then
    SCAN_DIRS+=("$arg")
  elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
    usage; exit 0
  fi
done

# Usa padrão se nenhum dir foi passado
if [[ ${#SCAN_DIRS[@]} -eq 0 ]]; then
  for d in "${DEFAULT_DIRS[@]}"; do
    [[ -d "$d" ]] && SCAN_DIRS+=("$d")
  done
fi

if [[ ${#SCAN_DIRS[@]} -eq 0 ]]; then
  echo -e "${RED}Nenhum diretório válido encontrado. Passe diretórios como argumento ou ajuste DEFAULT_DIRS.${NC}"
  exit 1
fi

# Retorna tamanho em KB (para aritmética)
size_kb() {
  du -sk "$1" 2>/dev/null | cut -f1 || echo 0
}

# Retorna tamanho human-readable
calc_size() {
  du -sh "$1" 2>/dev/null | cut -f1 || echo "?"
}

# Converte KB para string human-readable (sem bc)
human_size() {
  local kb="$1"
  if   (( kb >= 1048576 )); then awk "BEGIN{printf \"%.1f GB\", $kb/1048576}"
  elif (( kb >= 1024 ));    then awk "BEGIN{printf \"%.1f MB\", $kb/1024}"
  else                           printf "%d KB" "$kb"
  fi
}

# Registra e opcionalmente deleta — atualiza contador global
process() {
  local type="$1"
  local path="$2"
  local is_file="${3:-false}"   # true para arquivos individuais

  local kb=0
  local hr="?"
  if [[ -e "$path" || -L "$path" ]]; then
    if [[ "$is_file" == "true" ]]; then
      kb=$(du -sk "$path" 2>/dev/null | cut -f1 || echo 0)
    else
      kb=$(du -sk "$path" 2>/dev/null | cut -f1 || echo 0)
    fi
    hr=$(human_size "$kb")
  fi

  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))

  if [ "$DRY_RUN" = true ]; then
    echo -e "  [${YELLOW}DRY${NC}] ${BOLD}${type}${NC}: ${path} (${hr})"
    TOTAL_KB=$((TOTAL_KB + kb))
  else
    echo -e "  [${RED}DEL${NC}] ${BOLD}${type}${NC}: ${path} (${hr})"
    TOTAL_KB=$((TOTAL_KB + kb))
    if [[ "$is_file" == "true" ]]; then
      rm -f "$path"
    else
      rm -rf "$path"
    fi
  fi
}

header() {
  clear
  echo -e "${BLUE}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║       🛡️  ARTIFACT CLEANER v2 (CONTEXT AWARE)            ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${CYAN}Diretórios escaneados:${NC}"
  for d in "${SCAN_DIRS[@]}"; do echo "  → $d"; done
  echo ""
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}>>> MODO SIMULAÇÃO — nenhum arquivo será tocado <<<${NC}"
    echo -e "Use '${BOLD}$0 --force${NC}' para execução real.\n"
  else
    echo -e "${RED}${BOLD}>>> MODO DESTRUTIVO — arquivos serão removidos <<<${NC}\n"
    echo -n "Iniciando em 5..."
    for i in 4 3 2 1; do sleep 1; echo -n " $i..."; done
    echo -e "\n"
  fi
  echo -e "Espaço livre atual: ${GREEN}$(df -h / | awk 'NR==2 {print $4}')${NC}\n"
}

# ============================================================================
# 1. RUST (Contexto: Cargo.toml)
# ============================================================================
scan_rust() {
  echo -e "${BOLD}🦀 [1/7] Rust target/ ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    while IFS= read -r dir; do
      parent=$(dirname "$dir")
      if [[ -f "$parent/Cargo.toml" ]]; then
        found=$((found + 1))
        if [ "$DRY_RUN" = true ]; then
          process "RUST TARGET" "$dir"
        else
          process "RUST TARGET" "$dir"
          # cargo clean já feito pelo process via rm -rf; ou usar cargo clean
          (cd "$parent" && cargo clean &>/dev/null) 2>/dev/null || true
        fi
      else
        echo -e "  ${BLUE}ℹ Ignorado (sem Cargo.toml): $dir${NC}"
      fi
    done < <(find "$base" -type d -name "target" \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 2. GO (Contexto: go.mod)
# ============================================================================
scan_go() {
  echo -e "\n${BOLD}🐹 [2/7] Go build outputs (bin/, dist/, build/) ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    while IFS= read -r gomod; do
      parent=$(dirname "$gomod")
      for builddir in bin dist build; do
        if [[ -d "$parent/$builddir" ]]; then
          found=$((found + 1))
          process "GO BUILD" "$parent/$builddir"
        fi
      done
    done < <(find "$base" -name "go.mod" -not -path "*/.git/*" 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 3. NODE/JS — node_modules + frontend build dirs
# (Contexto: package.json / framework config)
# ============================================================================
scan_node() {
  echo -e "\n${BOLD}📦 [3/7] Node: node_modules/ + frontend builds ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    # node_modules
    while IFS= read -r dir; do
      parent=$(dirname "$dir")
      if [[ -f "$parent/package.json" ]]; then
        found=$((found + 1))
        process "NODE MODULES" "$dir"
      fi
    done < <(find "$base" -type d -name "node_modules" -prune 2>/dev/null)

    # Frontend build dirs — só com contexto de framework
    for build_dir in ".next" ".nuxt" ".output" ".svelte-kit" "out"; do
      while IFS= read -r dir; do
        parent=$(dirname "$dir")
        if [[ -f "$parent/package.json"      ]] || \
           [[ -f "$parent/next.config.js"    ]] || \
           [[ -f "$parent/next.config.ts"    ]] || \
           [[ -f "$parent/nuxt.config.ts"    ]] || \
           [[ -f "$parent/svelte.config.js"  ]] || \
           [[ -f "$parent/vite.config.ts"    ]]; then
          found=$((found + 1))
          process "FRONTEND BUILD" "$dir"
        fi
      done < <(find "$base" -type d -name "$build_dir" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" 2>/dev/null)
    done
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 4. PYTHON caches
# ============================================================================
scan_python() {
  echo -e "\n${BOLD}🐍 [4/7] Python caches ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    for cache_dir in "__pycache__" ".pytest_cache" ".mypy_cache" ".ruff_cache" ".ipynb_checkpoints"; do
      while IFS= read -r dir; do
        found=$((found + 1))
        process "PY CACHE" "$dir"
      done < <(find "$base" -type d -name "$cache_dir" 2>/dev/null)
    done
    # .pyc soltos — conta e apaga individualmente
    while IFS= read -r f; do
      found=$((found + 1))
      process "PYC FILE" "$f" true
    done < <(find "$base" -name "*.pyc" 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 5. COVERAGE / PROFILING (Contexto: arquivo de projeto ao lado)
# ============================================================================
scan_coverage() {
  echo -e "\n${BOLD}📊 [5/7] Coverage / profiling artifacts ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    for cov_dir in "coverage" "htmlcov" ".coverage_cache" "lcov-report"; do
      while IFS= read -r dir; do
        parent=$(dirname "$dir")
        if ls "$parent"/Cargo.toml "$parent"/pyproject.toml "$parent"/package.json \
              "$parent"/go.mod "$parent"/setup.py 2>/dev/null | grep -q .; then
          found=$((found + 1))
          process "COVERAGE" "$dir"
        fi
      done < <(find "$base" -type d -name "$cov_dir" \
        -not -path "*/node_modules/*" 2>/dev/null)
    done
    # profdata / lcov soltos
    while IFS= read -r f; do
      found=$((found + 1))
      process "PROFDATA" "$f" true
    done < <(find "$base" \( -name "*.profdata" -o -name "lcov.info" \) 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 6. .DIRENV em projetos (Contexto: .envrc ao lado)
# ============================================================================
scan_direnv() {
  echo -e "\n${BOLD}🔧 [6/7] .direnv em projetos ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    while IFS= read -r dir; do
      parent=$(dirname "$dir")
      if [[ -f "$parent/.envrc" ]]; then
        found=$((found + 1))
        process ".DIRENV" "$dir"
      fi
    done < <(find "$base" -type d -name ".direnv" 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# 7. NIX SYMLINKS result* (Contexto: aponta para /nix/store)
# ============================================================================
scan_nix() {
  echo -e "\n${BOLD}❄️  [7/7] Nix result symlinks ...${NC}"
  local found=0
  for base in "${SCAN_DIRS[@]}"; do
    while IFS= read -r link; do
      if [[ -L "$link" ]]; then
        target=$(readlink -f "$link")
        if [[ "$target" == /nix/store/* ]]; then
          found=$((found + 1))
          # Symlinks não têm tamanho real — conta como 0 KB
          TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
          if [ "$DRY_RUN" = true ]; then
            echo -e "  [${YELLOW}DRY${NC}] ${BOLD}NIX RESULT${NC}: ${link} (symlink)"
          else
            echo -e "  [${RED}DEL${NC}] ${BOLD}NIX RESULT${NC}: ${link} (symlink)"
            rm "$link"
          fi
        else
          echo -e "  ${YELLOW}⚠ Ignorado (não aponta para /nix/store): $link${NC}"
        fi
      fi
    done < <(find "$base" -maxdepth 5 -name "result*" 2>/dev/null)
  done
  [[ $found -eq 0 ]] && echo -e "  ${GREEN}✓ Nenhum encontrado.${NC}"
}

# ============================================================================
# MAIN
# ============================================================================

header
FREE_BEFORE=$(df / | awk 'NR==2 {print $4}')

scan_rust
scan_go
scan_node
scan_python
scan_coverage
scan_direnv
scan_nix

FREE_AFTER=$(df / | awk 'NR==2 {print $4}')
ACTUALLY_FREED=$(( FREE_AFTER - FREE_BEFORE ))

echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}📊 RESUMO${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Itens encontrados : ${BOLD}${TOTAL_ITEMS}${NC}"
if [ "$DRY_RUN" = true ]; then
  echo -e "  Potencial a liberar: ${YELLOW}${BOLD}$(human_size $TOTAL_KB)${NC}"
else
  echo -e "  Contabilizado    : ${BOLD}$(human_size $TOTAL_KB)${NC}"
  echo -e "  Efetivamente liberado (df): ${GREEN}${BOLD}$(human_size $ACTUALLY_FREED)${NC}"
fi
echo -e "  Espaço livre agora : ${GREEN}$(df -h / | awk 'NR==2 {print $4}')${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}Simulação concluída.${NC}"
  echo -e "Para executar a limpeza real:"
  echo -e "  ${CYAN}$0 --force${NC}"
  echo -e "Para escanear dirs adicionais:"
  echo -e "  ${CYAN}$0 --force /path/extra${NC}"
else
  echo -e "${GREEN}✅ Limpeza concluída!${NC}"
  echo -e "Próximo passo: ${CYAN}nix-collect-garbage -d${NC} para liberar o store dos symlinks removidos."
fi
