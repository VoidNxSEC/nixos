#!/usr/bin/env bash
# home-cleanup.sh — Scan completo do home com dry-run
# Uso: ./home-cleanup.sh [--clean]
#   (sem args) = dry-run: mostra tudo que existe e o que seria removido
#   --clean     = executa a limpeza real

set -uo pipefail

DRY_RUN=true
[[ "${1:-}" == "--clean" ]] && DRY_RUN=false

# Sempre aponta pro home do usuário real, mesmo se rodado com sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    TARGET="${HOME:-/home/kernelcore}"
fi
BOLD="\033[1m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
DIM="\033[2m"
NC="\033[0m"

hr() { printf "${CYAN}%s${NC}\n" "────────────────────────────────────────────────────────────────"; }

hdr() {
    echo ""
    hr
    echo -e "${BOLD}  $1${NC}"
    hr
}

fmt_size() {
    # recebe bytes, imprime human-readable (sem bc - usa awk)
    local b=$1
    awk -v b="$b" 'BEGIN {
        if      (b >= 1073741824) printf "%.1fG\n", b/1073741824
        else if (b >= 1048576)    printf "%.1fM\n", b/1048576
        else if (b >= 1024)       printf "%.1fK\n", b/1024
        else                      printf "%dB\n",   b
    }'
}

# acumula bytes que seriam liberados
TOTAL_BYTES=0

# ─── dry-run ou rm -rf ───────────────────────────────────────────────────────
zap() {
    # $1 = label, restantes = paths
    local label="$1"; shift
    local bytes=0
    local hits=()

    for p in "$@"; do
        # expande globs sem erro se vazio
        for expanded in $p; do
            [[ -e "$expanded" ]] || continue
            local b
            b=$(du -sb "$expanded" 2>/dev/null | awk '{print $1}')
            bytes=$(( bytes + b ))
            hits+=("$expanded")
        done
    done

    (( ${#hits[@]} == 0 )) && return

    TOTAL_BYTES=$(( TOTAL_BYTES + bytes ))
    local szh
    szh=$(fmt_size "$bytes")

    if $DRY_RUN; then
        printf "  ${YELLOW}%-12s${NC}  ${DIM}%-60s${NC}  %s\n" "[DRY-RUN]" "$label" "$szh"
        for p in "${hits[@]}"; do
            printf "             ${DIM}↳ %s${NC}\n" "$p"
        done
    else
        printf "  ${RED}%-12s${NC}  %-60s  %s\n" "[REMOVENDO]" "$label" "$szh"
        for p in "${hits[@]}"; do
            printf "             ${DIM}↳ %s${NC}\n" "$p"
            rm -rf "$p"
        done
    fi
}

# ─── HEADER ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  HOME DIRECTORY SCAN — ${TARGET}${NC}"
$DRY_RUN \
    && echo -e "  ${YELLOW}modo DRY-RUN — nenhum arquivo será removido${NC}" \
    || echo -e "  ${RED}${BOLD}modo CLEAN — arquivos SERÃO removidos${NC}"

# ─── 1. VISÃO GERAL ──────────────────────────────────────────────────────────

hdr "1. VISÃO GERAL DO HOME (depth=1)"
du -sh "${TARGET}"/.[!.]* "${TARGET}"/* 2>/dev/null \
    | sort -h \
    | awk '{printf "  %-8s  %s\n", $1, $2}'

echo ""
echo -e "  ${BOLD}TOTAL: $(du -sh "${TARGET}" 2>/dev/null | awk '{print $1}')${NC}"

# ─── 2. DEPTH=2 (top offenders) ──────────────────────────────────────────────

hdr "2. TOP 40 DIRETÓRIOS (depth=2)"
du -h --max-depth=2 "${TARGET}" 2>/dev/null \
    | sort -h \
    | tail -40 \
    | awk '{printf "  %-8s  %s\n", $1, $2}'

# ─── 3. DEPTH=3 (onde mora o problema) ───────────────────────────────────────

hdr "3. TOP 50 DIRETÓRIOS (depth=3)"
du -h --max-depth=3 "${TARGET}" 2>/dev/null \
    | sort -h \
    | tail -50 \
    | awk '{printf "  %-8s  %s\n", $1, $2}'

# ─── 4. ARQUIVOS GRANDES AVULSOS (>50MB) ─────────────────────────────────────

hdr "4. ARQUIVOS AVULSOS >50MB"
find "${TARGET}" -type f -size +50M 2>/dev/null \
    | while read -r f; do
        sz=$(du -sb "$f" 2>/dev/null | awk '{print $1}')
        echo "$sz $f"
      done \
    | sort -rn \
    | awk '{
        bytes=$1; $1=""
        sub(/^ /,"")
        file=$0
        if      (bytes>=1073741824) sz=sprintf("%.1fG", bytes/1073741824)
        else if (bytes>=1048576)    sz=sprintf("%.1fM", bytes/1048576)
        else                        sz=sprintf("%.1fK", bytes/1024)
        printf "  %-8s  %s\n", sz, file
      }'

# ─── 5. CANDIDATOS A LIMPEZA ─────────────────────────────────────────────────

hdr "5. CANDIDATOS A LIMPEZA"

echo -e "\n${CYAN}── Caches de browser ──${NC}"
zap "Firefox cache"   "${TARGET}/.cache/mozilla/firefox/*/cache2"
zap "Chromium cache"  "${TARGET}/.cache/chromium/Default/Cache" \
                      "${TARGET}/.cache/chromium/Default/Code Cache"
zap "Brave cache"     "${TARGET}/.cache/BraveSoftware/Brave-Browser/Default/Cache" \
                      "${TARGET}/.cache/BraveSoftware/Brave-Browser/Default/Code Cache"

echo -e "\n${CYAN}── Electron / IDEs ──${NC}"
zap "VSCode cache"    "${TARGET}/.config/Code/Cache" \
                      "${TARGET}/.config/Code/CachedData" \
                      "${TARGET}/.config/Code/CachedExtensionVSIXs" \
                      "${TARGET}/.config/Code/logs"
zap "VSCodium cache"  "${TARGET}/.config/VSCodium/Cache" \
                      "${TARGET}/.config/VSCodium/CachedData" \
                      "${TARGET}/.config/VSCodium/CachedExtensionVSIXs" \
                      "${TARGET}/.config/VSCodium/logs"
zap "Electron cache"  "${TARGET}/.cache/vscode-cpptools" \
                      "${TARGET}/.config/JetBrains"

echo -e "\n${CYAN}── npm / node ──${NC}"
zap "npm cache"       "${TARGET}/.npm/_cacache"
zap "yarn cache"      "${TARGET}/.yarn/cache" "${TARGET}/.cache/yarn"
zap "pnpm store"      "${TARGET}/.local/share/pnpm/store"
zap "node_modules"    "${TARGET}/node_modules" \
                      $(find "${TARGET}" -maxdepth 4 -name node_modules -type d 2>/dev/null | head -20)

echo -e "\n${CYAN}── Python ──${NC}"
zap "pip cache"       "${TARGET}/.cache/pip"
zap "uv cache"        "${TARGET}/.cache/uv"
zap "__pycache__"     $(find "${TARGET}" -maxdepth 6 -name __pycache__ -type d 2>/dev/null | head -50)
zap "*.pyc avulsos"   $(find "${TARGET}" -maxdepth 6 -name "*.pyc" 2>/dev/null | head -100)
zap "virtualenvs"     "${TARGET}/.cache/pypoetry/virtualenvs" \
                      "${TARGET}/.local/share/virtualenvs" \
                      $(find "${TARGET}" -maxdepth 4 \( -name ".venv" -o -name "venv" -o -name ".env" \) -type d 2>/dev/null | head -20)

echo -e "\n${CYAN}── Rust ──${NC}"
zap "Cargo registry"  "${TARGET}/.cargo/registry/cache" \
                      "${TARGET}/.cargo/registry/src"
zap "Cargo git"       "${TARGET}/.cargo/git/db" \
                      "${TARGET}/.cargo/git/checkouts"
zap "target/ (builds)" $(find "${TARGET}" -maxdepth 5 -name target -type d \
                          -not -path "*/.cargo/*" 2>/dev/null | head -20)

echo -e "\n${CYAN}── Go ──${NC}"
zap "Go mod cache"    "${TARGET}/go/pkg/mod/cache"
zap "Go build cache"  "${TARGET}/.cache/go-build"

echo -e "\n${CYAN}── Java / JVM ──${NC}"
zap "Gradle caches"   "${TARGET}/.gradle/caches" \
                      "${TARGET}/.gradle/wrapper/dists"
zap "Maven repo"      "${TARGET}/.m2/repository"

echo -e "\n${CYAN}── ML / modelos ──${NC}"
zap "Ollama models"   "${TARGET}/.ollama/models"
zap "HuggingFace"     "${TARGET}/.cache/huggingface/hub"
zap "torch cache"     "${TARGET}/.cache/torch"

echo -e "\n${CYAN}── Containers ──${NC}"
zap "Podman storage"  "${TARGET}/.local/share/containers/storage"
zap "Docker config"   "${TARGET}/.docker"

echo -e "\n${CYAN}── Misc sistema ──${NC}"
zap "Thumbnails"      "${TARGET}/.cache/thumbnails"
zap "FontConfig"      "${TARGET}/.cache/fontconfig"
zap "Mesa shader"     "${TARGET}/.cache/mesa_shader_cache"
zap "Trash/files"     "${TARGET}/.local/share/Trash/files" \
                      "${TARGET}/.local/share/Trash/info"
zap "Journal pessoal" "${TARGET}/.local/share/recently-used.xbel"
zap "SSH sessions db" $(find "${TARGET}" -maxdepth 5 -name "ssh_sessions.db" 2>/dev/null)
zap "Core dumps"      "${TARGET}"/core.*
zap "*.log avulsos"   $(find "${TARGET}" -maxdepth 5 -name "*.log" -size +10M 2>/dev/null | head -30)

# ─── 6. TUDO em .cache que sobrou ────────────────────────────────────────────

hdr "6. TODO O .cache (para referência)"
du -sh "${TARGET}/.cache"/* 2>/dev/null \
    | sort -h \
    | awk '{printf "  %-8s  %s\n", $1, $2}'

# ─── 7. RESUMO ───────────────────────────────────────────────────────────────

hdr "7. RESUMO"
echo ""
if $DRY_RUN; then
    echo -e "  ${YELLOW}${BOLD}Espaço que seria liberado: $(fmt_size $TOTAL_BYTES)${NC}"
    echo ""
    echo -e "  Para executar:  ${BOLD}bash $0 --clean${NC}"
else
    echo -e "  ${GREEN}${BOLD}Espaço liberado: $(fmt_size $TOTAL_BYTES)${NC}"
    echo ""
    echo -e "  Home agora: $(du -sh "${TARGET}" 2>/dev/null | awk '{print $1}')"
fi
echo ""
