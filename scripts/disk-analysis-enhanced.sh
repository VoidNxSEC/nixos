#!/usr/bin/env bash

# disk-analysis-enhanced.sh: Funções avançadas de análise e limpeza de disco
# Para ser integrado ao emergency-cleanup.sh ou usado standalone

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# ============================================================================
# ANÁLISE DE DISCO DETALHADA
# ============================================================================

analyze_disk_usage() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         📊 ANÁLISE DETALHADA DE DISCO 📊                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${YELLOW}Status atual:${NC}"
    df -h / | grep -v Filesystem
    echo ""

    echo -e "${YELLOW}Analisando diretórios... (pode levar 1-2 minutos)${NC}"
    echo ""

    # Top 20 diretórios em /
    echo -e "${MAGENTA}TOP 20 DIRETÓRIOS MAIORES:${NC}"
    sudo du -h --max-depth=2 / 2>/dev/null | sort -hr | head -20 | \
        awk '{printf "  %-10s  %s\n", $1, $2}'

    echo ""
    echo -e "${MAGENTA}ANÁLISE DO /NIX:${NC}"
    if [ -d /nix ]; then
        sudo du -h --max-depth=2 /nix 2>/dev/null | sort -hr | head -10 | \
            awk '{printf "  %-10s  %s\n", $1, $2}'
    fi

    echo ""
    echo -e "${MAGENTA}ANÁLISE DO /VAR:${NC}"
    if [ -d /var ]; then
        sudo du -h --max-depth=2 /var 2>/dev/null | sort -hr | head -10 | \
            awk '{printf "  %-10s  %s\n", $1, $2}'
    fi

    echo ""
    echo -e "${MAGENTA}ANÁLISE DO /HOME:${NC}"
    if [ -d /home ]; then
        sudo du -h --max-depth=2 /home 2>/dev/null | sort -hr | head -10 | \
            awk '{printf "  %-10s  %s\n", $1, $2}'
    fi

    echo ""
    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# BUSCA DE ARQUIVOS GRANDES
# ============================================================================

find_large_files() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         🔍 BUSCA DE ARQUIVOS GRANDES 🔍                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${YELLOW}Escolha o tamanho mínimo:${NC}"
    echo "  1) >500MB"
    echo "  2) >1GB"
    echo "  3) >2GB"
    echo "  4) >5GB"
    echo "  0) Voltar"
    echo ""
    read -p "Escolha > " size_choice

    local size_param=""
    local size_desc=""

    case $size_choice in
        1) size_param="+500M"; size_desc="500MB" ;;
        2) size_param="+1G"; size_desc="1GB" ;;
        3) size_param="+2G"; size_desc="2GB" ;;
        4) size_param="+5G"; size_desc="5GB" ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${NC}"; return ;;
    esac

    echo ""
    echo -e "${YELLOW}Buscando arquivos maiores que ${size_desc}... (pode demorar)${NC}"
    echo -e "${YELLOW}Excluindo: /nix/store, /proc, /sys, /dev${NC}"
    echo ""

    # Busca arquivos excluindo diretórios do sistema
    local temp_file="/tmp/large-files-$$.txt"

    sudo find / \
        -type f \
        -size "$size_param" \
        -not -path "/nix/store/*" \
        -not -path "/proc/*" \
        -not -path "/sys/*" \
        -not -path "/dev/*" \
        -printf "%s %p\n" 2>/dev/null | \
        sort -rn | \
        head -50 > "$temp_file"

    if [ ! -s "$temp_file" ]; then
        echo -e "${GREEN}✓ Nenhum arquivo encontrado${NC}"
        rm -f "$temp_file"
        read -p "Pressione ENTER..."
        return
    fi

    echo -e "${MAGENTA}TOP 50 ARQUIVOS MAIORES QUE ${size_desc}:${NC}"
    echo ""

    local total_size=0
    local count=0

    while IFS= read -r line; do
        local size=$(echo "$line" | awk '{print $1}')
        local file=$(echo "$line" | cut -d' ' -f2-)
        local size_mb=$((size / 1024 / 1024))

        printf "  %6dMB  %s\n" "$size_mb" "$file"

        total_size=$((total_size + size))
        count=$((count + 1))
    done < "$temp_file"

    local total_gb=$((total_size / 1024 / 1024 / 1024))

    echo ""
    echo -e "${CYAN}Total: ${count} arquivos = ${total_gb}GB${NC}"

    rm -f "$temp_file"

    echo ""
    echo -e "${YELLOW}Ações:${NC}"
    echo "  d) Deletar arquivo específico (digite o caminho)"
    echo "  l) Salvar lista em /tmp/large-files-list.txt"
    echo "  q) Voltar"
    read -p "Escolha > " action

    case $action in
        d)
            read -p "Caminho completo do arquivo para deletar > " filepath
            if [ -f "$filepath" ]; then
                local fsize=$(du -h "$filepath" | awk '{print $1}')
                read -p "$(echo -e "${RED}Deletar $filepath ($fsize)? (s/N) > ${NC}")" confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    sudo rm -f "$filepath" && \
                        echo -e "${GREEN}✓ Arquivo deletado${NC}" || \
                        echo -e "${RED}✗ Erro ao deletar${NC}"
                fi
            else
                echo -e "${RED}Arquivo não encontrado${NC}"
            fi
            ;;
        l)
            sudo find / \
                -type f \
                -size "$size_param" \
                -not -path "/nix/store/*" \
                -not -path "/proc/*" \
                -not -path "/sys/*" \
                -not -path "/dev/*" \
                -exec ls -lh {} \; 2>/dev/null > /tmp/large-files-list.txt
            echo -e "${GREEN}✓ Lista salva em /tmp/large-files-list.txt${NC}"
            ;;
        *) ;;
    esac

    read -p "Pressione ENTER..."
}

# ============================================================================
# LIMPEZA AGRESSIVA DO NIX
# ============================================================================

aggressive_nix_cleanup() {
    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      🗑️  LIMPEZA AGRESSIVA DO NIX STORE 🗑️               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${YELLOW}Esta operação irá:${NC}"
    echo "  1. Deletar gerações antigas do sistema (manter apenas 3 últimas)"
    echo "  2. Deletar gerações do usuário (manter apenas 2 últimas)"
    echo "  3. Executar Nix GC agressivo"
    echo "  4. Otimizar Nix store (hardlinks duplicados)"
    echo ""
    echo -e "${RED}${BOLD}ATENÇÃO: Isso pode quebrar rollbacks antigos!${NC}"
    echo ""

    read -p "$(echo -e "${RED}Continuar? (s/N) > ${NC}")" confirm

    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Cancelado${NC}"
        return
    fi

    echo ""
    echo -e "${CYAN}Espaço ANTES:${NC}"
    df -h / | grep -v Filesystem
    echo ""

    # 1. Deletar gerações do sistema (manter 3)
    echo -e "${YELLOW}1/4 Deletando gerações antigas do sistema...${NC}"
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
    echo -e "${GREEN}  ✓ Gerações antigas do sistema removidas${NC}"

    # 2. Deletar gerações do usuário (manter 2)
    echo ""
    echo -e "${YELLOW}2/4 Deletando gerações antigas do usuário...${NC}"
    nix-env --delete-generations +2
    echo -e "${GREEN}  ✓ Gerações antigas do usuário removidas${NC}"

    # 3. Garbage collection agressivo
    echo ""
    echo -e "${YELLOW}3/4 Executando Nix GC agressivo... (pode demorar 5-10 min)${NC}"
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
    echo -e "${GREEN}  ✓ Nix GC concluído${NC}"

    # 4. Otimizar store (hardlinks)
    echo ""
    echo -e "${YELLOW}4/4 Otimizando Nix store... (pode demorar 10-20 min)${NC}"
    echo -e "${CYAN}Criando hardlinks para arquivos duplicados...${NC}"
    sudo nix-store --optimize
    echo -e "${GREEN}  ✓ Nix store otimizado${NC}"

    echo ""
    echo -e "${GREEN}✅ LIMPEZA NIX CONCLUÍDA!${NC}"
    echo ""
    echo -e "${CYAN}Espaço DEPOIS:${NC}"
    df -h / | grep -v Filesystem

    read -p "Pressione ENTER..."
}

# ============================================================================
# ENCONTRAR ARQUIVOS TEMPORÁRIOS GRANDES
# ============================================================================

find_temp_files() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║    🗑️  ARQUIVOS TEMPORÁRIOS E CACHE GRANDES 🗑️           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${YELLOW}Buscando em:${NC}"
    echo "  - /tmp"
    echo "  - /var/tmp"
    echo "  - ~/.cache"
    echo "  - ~/.local/share/Trash"
    echo "  - ~/.config/*/Cache"
    echo ""

    local total=0

    # /tmp
    if [ -d /tmp ]; then
        local tmp_size=$(sudo du -sh /tmp 2>/dev/null | awk '{print $1}')
        echo -e "${MAGENTA}/tmp: ${tmp_size}${NC}"
        sudo du -h /tmp 2>/dev/null | sort -hr | head -5 | sed 's/^/  /'
        total=$((total + $(sudo du -s /tmp 2>/dev/null | awk '{print $1}')))
    fi

    echo ""

    # /var/tmp
    if [ -d /var/tmp ]; then
        local vartmp_size=$(sudo du -sh /var/tmp 2>/dev/null | awk '{print $1}')
        echo -e "${MAGENTA}/var/tmp: ${vartmp_size}${NC}"
        sudo du -h /var/tmp 2>/dev/null | sort -hr | head -5 | sed 's/^/  /'
        total=$((total + $(sudo du -s /var/tmp 2>/dev/null | awk '{print $1}')))
    fi

    echo ""

    # ~/.cache
    if [ -d ~/.cache ]; then
        local cache_size=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
        echo -e "${MAGENTA}~/.cache: ${cache_size}${NC}"
        du -h ~/.cache 2>/dev/null | sort -hr | head -5 | sed 's/^/  /'
        total=$((total + $(du -s ~/.cache 2>/dev/null | awk '{print $1}')))
    fi

    echo ""

    # Trash
    if [ -d ~/.local/share/Trash ]; then
        local trash_size=$(du -sh ~/.local/share/Trash 2>/dev/null | awk '{print $1}')
        echo -e "${MAGENTA}~/.local/share/Trash: ${trash_size}${NC}"
        du -h ~/.local/share/Trash 2>/dev/null | sort -hr | head -5 | sed 's/^/  /'
        total=$((total + $(du -s ~/.local/share/Trash 2>/dev/null | awk '{print $1}')))
    fi

    local total_gb=$((total / 1024 / 1024))

    echo ""
    echo -e "${CYAN}TOTAL ESTIMADO: ${total_gb}GB${NC}"
    echo ""

    echo -e "${YELLOW}Ações:${NC}"
    echo "  1) Limpar /tmp e /var/tmp"
    echo "  2) Limpar ~/.cache"
    echo "  3) Limpar Lixeira"
    echo "  4) Limpar TUDO"
    echo "  0) Voltar"
    read -p "Escolha > " action

    case $action in
        1)
            sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null
            echo -e "${GREEN}✓ /tmp e /var/tmp limpos${NC}"
            ;;
        2)
            rm -rf ~/.cache/*
            echo -e "${GREEN}✓ ~/.cache limpo${NC}"
            ;;
        3)
            rm -rf ~/.local/share/Trash/*
            echo -e "${GREEN}✓ Lixeira limpa${NC}"
            ;;
        4)
            sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null
            rm -rf ~/.cache/*
            rm -rf ~/.local/share/Trash/*
            echo -e "${GREEN}✓ Tudo limpo${NC}"
            ;;
        *) ;;
    esac

    read -p "Pressione ENTER..."
}

# ============================================================================
# ANÁLISE DE GERAÇÕES DO NIX
# ============================================================================

analyze_nix_generations() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         📦 ANÁLISE DE GERAÇÕES DO NIX 📦                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${YELLOW}GERAÇÕES DO SISTEMA:${NC}"
    sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -10

    local sys_count=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | wc -l)
    echo -e "${CYAN}Total: ${sys_count} gerações${NC}"

    echo ""
    echo -e "${YELLOW}GERAÇÕES DO USUÁRIO:${NC}"
    nix-env --list-generations | tail -10

    local user_count=$(nix-env --list-generations | wc -l)
    echo -e "${CYAN}Total: ${user_count} gerações${NC}"

    echo ""
    echo -e "${YELLOW}TAMANHO DO NIX STORE:${NC}"
    local store_size=$(sudo du -sh /nix/store 2>/dev/null | awk '{print $1}')
    echo -e "${CYAN}/nix/store: ${store_size}${NC}"

    echo ""
    read -p "Deletar gerações antigas? (s/N) > " confirm

    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        read -p "Quantas gerações do sistema manter? (padrão: 3) > " sys_keep
        sys_keep=${sys_keep:-3}

        read -p "Quantas gerações do usuário manter? (padrão: 2) > " user_keep
        user_keep=${user_keep:-2}

        sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +${sys_keep}
        nix-env --delete-generations +${user_keep}

        echo -e "${GREEN}✓ Gerações antigas removidas${NC}"
        echo -e "${YELLOW}Execute 'sudo nix-collect-garbage -d' para liberar espaço${NC}"
    fi

    read -p "Pressione ENTER..."
}

# ============================================================================
# MENU PRINCIPAL
# ============================================================================

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     📊 ANÁLISE E LIMPEZA AVANÇADA DE DISCO 📊             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    df -h / | grep -v Filesystem

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Ferramentas de Análise:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 📊 Análise detalhada de uso de disco"
    echo -e "  ${CYAN}2)${NC} 🔍 Buscar arquivos grandes (>500MB, >1GB, etc)"
    echo -e "  ${CYAN}3)${NC} 🗑️  Encontrar arquivos temporários/cache grandes"
    echo -e "  ${CYAN}4)${NC} 📦 Analisar gerações do Nix"
    echo ""
    echo -e "${BOLD}Ferramentas de Limpeza:${NC}"
    echo ""
    echo -e "  ${GREEN}5)${NC} 🗑️  Limpeza agressiva do Nix (GC + optimize)"
    echo -e "  ${GREEN}6)${NC} 🧹 Limpar temporários e cache"
    echo ""
    echo -e "  ${RED}0)${NC} 🚪 Sair"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -n "Escolha > "
}

main() {
    while true; do
        show_menu
        read choice

        case $choice in
            1) analyze_disk_usage ;;
            2) find_large_files ;;
            3) find_temp_files ;;
            4) analyze_nix_generations ;;
            5) aggressive_nix_cleanup ;;
            6) find_temp_files ;;
            0) echo -e "${GREEN}Saindo...${NC}"; exit 0 ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 1 ;;
        esac
    done
}

# Entry point
if [ "$#" -eq 0 ]; then
    main
else
    case "$1" in
        --analyze) analyze_disk_usage ;;
        --large-files) find_large_files ;;
        --temp) find_temp_files ;;
        --generations) analyze_nix_generations ;;
        --nix-cleanup) aggressive_nix_cleanup ;;
        *)
            echo "Uso: $0 [--analyze|--large-files|--temp|--generations|--nix-cleanup]"
            echo "Ou execute sem argumentos para menu interativo"
            exit 1
            ;;
    esac
fi
