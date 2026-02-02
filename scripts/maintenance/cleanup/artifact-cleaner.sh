#!/usr/bin/env bash
# artifact-cleaner.sh: A "Bala de Prata" para limpeza segura de repositórios
# SEGURANÇA: Só deleta pastas de build se encontrar os arquivos de definição do projeto ao lado.

set -e

# Configurações
BASE_DIR="/home/kernelcore/arch"
DRY_RUN=true
TOTAL_FREED=0

# Cores
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"
BOLD="\033[1m"

usage() {
    echo -e "${BOLD}Artifact Cleaner - Limpeza Contextual Segura${NC}"
    echo "Uso: $0 [--force]"
    echo ""
    echo "  Por padrão, roda em modo SIMULAÇÃO (Dry Run)."
    echo "  Use --force para deletar os arquivos de fato."
    echo ""
}

# Verifica argumentos
if [[ "$1" == "--force" ]]; then
    DRY_RUN=false
else
    usage
fi

log_action() {
    local type="$1"
    local path="$2"
    local size="$3"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "[${YELLOW}SIMULAÇÃO${NC}] Encontrado ${type}: ${path} (${size})"
    else
        echo -e "[${RED}DELETADO${NC}] ${type}: ${path} (${size})"
    fi
}

calc_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           🛡️  ARTIFACT CLEANER (CONTEXT AWARE)            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}>>> MODO SIMULAÇÃO (Nenhum arquivo será tocado) <<<${NC}"
        echo -e "Use '$0 --force' para executar a limpeza real.\n"
    else
        echo -e "${RED}${BOLD}>>> MODO DESTRUTIVO (Arquivos serão removidos) <<<${NC}\n"
        # Delay de segurança
        echo -n "Iniciando em 5 segundos..."
        sleep 1; echo -n " 4..."
        sleep 1; echo -n " 3..."
        sleep 1; echo -n " 2..."
        sleep 1; echo -n " 1..."
        echo -e "\n"
    fi
}

# ============================================================================ 
# 1. RUST (Contexto: Cargo.toml)
# ============================================================================ 
scan_rust() {
    echo -e "${BOLD}🔍 Buscando artefatos Rust (target/)...${NC}"
    # Busca todas as pastas 'target'
    while IFS= read -r dir; do
        # VERIFICAÇÃO DE SEGURANÇA: Existe Cargo.toml no diretório pai?
        parent=$(dirname "$dir")
        if [[ -f "$parent/Cargo.toml" ]]; then
            size=$(calc_size "$dir")
            log_action "RUST TARGET" "$dir" "$size"
            
            if [ "$DRY_RUN" = false ]; then
                # Comando seguro: cargo clean é preferível, mas rm -rf é garantido se cargo falhar
                (cd "$parent" && cargo clean &>/dev/null) || rm -rf "$dir"
            fi
        else
            echo -e "${BLUE}  ℹ️  Ignorado (sem Cargo.toml): $dir${NC}"
        fi
    done < <(find "$BASE_DIR" -type d -name "target" -not -path "*/node_modules/*" 2>/dev/null)
}

# ============================================================================ 
# 2. NODE/JS (Contexto: package.json)
# ============================================================================ 
scan_node() {
    echo -e "\n${BOLD}🔍 Buscando artefatos Node (node_modules/)...${NC}"
    # Busca node_modules (prune para não descer infinitamente)
    while IFS= read -r dir; do
        parent=$(dirname "$dir")
        # VERIFICAÇÃO DE SEGURANÇA: Existe package.json?
        if [[ -f "$parent/package.json" ]]; then
            size=$(calc_size "$dir")
            log_action "NODE MODULES" "$dir" "$size"
            
            if [ "$DRY_RUN" = false ]; then
                rm -rf "$dir"
            fi
        else
            echo -e "${BLUE}  ℹ️  Ignorado (sem package.json): $dir${NC}"
        fi
    done < <(find "$BASE_DIR" -type d -name "node_modules" -prune 2>/dev/null)
}

# ============================================================================ 
# 3. PYTHON (Contexto: Recursivo Seguro)
# ============================================================================ 
scan_python() {
    echo -e "\n${BOLD}🔍 Buscando artefatos Python (__pycache__)...${NC}"
    # __pycache__ é gerado automaticamente pelo interpretador, geralmente seguro deletar
    # mas vamos garantir que estamos dentro de um projeto
    while IFS= read -r dir; do
        size=$(calc_size "$dir")
        log_action "PYCACHE" "$dir" "$size"
        
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$dir"
        fi
    done < <(find "$BASE_DIR" -type d -name "__pycache__" 2>/dev/null)
    
    # Arquivos .pyc isolados
    if [ "$DRY_RUN" = false ]; then
        find "$BASE_DIR" -name "*.pyc" -delete
    fi
}

# ============================================================================ 
# 4. NIX SYMLINKS (Contexto: is_symlink)
# ============================================================================ 
scan_nix() {
    echo -e "\n${BOLD}🔍 Buscando symlinks Nix (result)...${NC}"
    # Busca links 'result'
    while IFS= read -r link; do
        # VERIFICAÇÃO DE SEGURANÇA: É realmente um link simbólico?
        if [[ -L "$link" ]]; then
            # Verifica se aponta para /nix/store (extra safety)
            target=$(readlink -f "$link")
            if [[ "$target" == /nix/store/* ]]; then
                log_action "NIX RESULT" "$link" "(symlink)"
                
                if [ "$DRY_RUN" = false ]; then
                    rm "$link"
                fi
            else
                 echo -e "${YELLOW}  ⚠️  Ignorado (não aponta para /nix/store): $link${NC}"
            fi
        fi
    done < <(find "$BASE_DIR" -maxdepth 4 -name "result*" 2>/dev/null)
}

# ============================================================================ 
# MAIN
# ============================================================================ 

header
scan_rust
scan_node
scan_python
scan_nix

echo -e "\n${BOLD}========================================${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${GREEN}Simulação concluída.${NC}"
    echo -e "Para executar a limpeza real e liberar espaço, rode:"
    echo -e "${CYAN}sudo $0 --force${NC}"
else
    echo -e "${GREEN}Limpeza concluída!${NC}"
    echo -e "Recomendado: Rode 'nix-collect-garbage -d' agora para efetivar a liberação de espaço dos links Nix removidos."
fi
