#!/usr/bin/env bash
# Limpeza Agressiva Baseada em Auditoria
# Foca em: Logs de audit (100GB), cache VSCodium, Nix GC

set -e

echo "🧹 LIMPEZA AGRESSIVA DO SISTEMA"
echo "================================"
echo ""
echo "⚠️  Este script vai liberar ~200GB de espaço!"
echo ""
echo "O que será limpo:"
echo "  1. Logs de audit (pode ser 100GB+)"
echo "  2. Logs antigos do sistema"
echo "  3. Editor caches (VSCodium, Code, etc)"
echo "  4. Garbage collection Nix + gerações antigas"
echo "  5. Docker / Podman"
echo "  6. ML/AI models e caches (/var/lib/ml-models, HuggingFace, PyTorch, Ollama)"
echo "  7. System ghosts (core dumps, /tmp grandes, cargo/go global)"
echo "  8. Cache de usuário geral"
echo ""
read -p "Continuar? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Abortado."
    exit 0
fi

echo ""
echo "📊 Espaço ANTES da limpeza:"
df -h / | grep -v Filesystem

# Função para reportar progresso
report_space() {
    CURRENT=$(df / | tail -1 | awk '{print $3}')
    FREE=$(df / | tail -1 | awk '{print $4}')
    echo "   Usado: ${CURRENT} | Livre: ${FREE}"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 FASE 1: LIMPAR LOGS DE AUDIT (100GB+)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1.1. Tamanho atual dos logs de audit:"
sudo du -sh /var/log/audit 2>/dev/null || echo "Diretório não encontrado"

echo ""
echo "1.2. Parando auditd..."
sudo systemctl stop auditd 2>/dev/null || echo "auditd não estava rodando"

echo ""
echo "1.3. Deletando logs de audit antigos..."
sudo find /var/log/audit -name "audit.log.*" -delete 2>/dev/null || true
sudo rm -f /var/log/audit/audit.log.{1..100} 2>/dev/null || true

echo ""
echo "1.4. Truncando log atual (mantém arquivo mas limpa conteúdo):"
sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null || true

echo ""
echo "1.5. Reiniciando auditd..."
sudo systemctl start auditd 2>/dev/null || echo "auditd não reiniciado"

echo ""
echo "✅ Logs de audit limpos!"
report_space

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 FASE 2: LIMPAR OUTROS LOGS DO SISTEMA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "2.1. Limpando journal (manter últimos 7 dias)..."
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=500M

echo ""
echo "2.2. Limpando logs antigos compactados..."
sudo find /var/log -name "*.log.*" -delete 2>/dev/null || true
sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
sudo find /var/log -name "*.old" -delete 2>/dev/null || true
sudo find /var/log -name "*.1" -delete 2>/dev/null || true

echo ""
echo "✅ Logs do sistema limpos!"
report_space

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️  FASE 3: EDITOR CACHES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# VSCodium
for editor_dir in \
    ~/.config/VSCodium \
    ~/.config/Code \
    ~/.config/code-oss \
    ~/.vscode-server; do
    if [ -d "$editor_dir/Cache" ]; then
        echo "3.x. Limpando $editor_dir/Cache: $(du -sh "$editor_dir/Cache" | cut -f1)"
        rm -rf "$editor_dir/Cache"/*
    fi
    if [ -d "$editor_dir/CachedData" ]; then
        echo "3.x. Limpando $editor_dir/CachedData: $(du -sh "$editor_dir/CachedData" | cut -f1)"
        rm -rf "$editor_dir/CachedData"/*
    fi
    if [ -d "$editor_dir/GPUCache" ]; then
        rm -rf "$editor_dir/GPUCache"/*
    fi
    # Storage de extensões pesadas (Roo, Cline, Copilot, etc)
    if [ -d "$editor_dir/User/globalStorage" ]; then
        echo "3.x. Cache globalStorage $editor_dir: $(du -sh "$editor_dir/User/globalStorage" | cut -f1)"
        # Remove task/conversation history de extensões AI sem remover as extensões
        find "$editor_dir/User/globalStorage" \
            -type d \( -name "tasks" -o -name "conversations" -o -name "checkpoints" \) \
            -exec rm -rf {}/* \; 2>/dev/null || true
    fi
done

echo "✅ Editor caches limpos!"
report_space

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 FASE 4: GARBAGE COLLECTION NIX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "4.1. Tamanho atual do /nix/store:"
sudo du -sh /nix/store 2>/dev/null || echo "Não foi possível calcular"

echo ""
echo "4.2. Limpando gerações antigas do sistema NixOS..."
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>/dev/null || true

echo ""
echo "4.3. Limpando gerações do perfil de usuário..."
nix-env --delete-generations old 2>/dev/null || true

echo ""
echo "4.4. Garbage collection (pode demorar 5-10 minutos)..."
nix-collect-garbage -d

echo ""
echo "4.5. Garbage collection do sistema..."
sudo nix-collect-garbage -d

echo ""
echo "4.5. Otimizando store (deduplicação - pode demorar)..."
echo "Isso pode economizar 10-20GB adicionais..."
sudo nix-store --optimise

echo ""
echo "4.6. Removendo symlinks de resultado..."
rm -f ~/result* 2>/dev/null || true

echo ""
echo "4.7. Limpando direnv cache..."
rm -rf ~/.direnv 2>/dev/null || true

echo ""
echo "✅ Nix limpo e otimizado!"
report_space

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 FASE 5: DOCKER + PODMAN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v docker &> /dev/null; then
    if sudo systemctl is-active docker &>/dev/null; then
        echo "5.1. Docker disk usage:"
        sudo docker system df 2>/dev/null || true
        read -p "Limpar containers/images/volumes não usados? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker system prune -a --volumes -f
            echo "✅ Docker limpo!"
            report_space
        else
            echo "⏭️  Docker não foi limpo"
        fi
    else
        echo "Docker não está rodando"
    fi
else
    echo "Docker não instalado"
fi

if command -v podman &>/dev/null; then
    echo ""
    echo "5.2. Podman disk usage:"
    podman system df 2>/dev/null || true
    read -p "Limpar Podman (system prune)? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman system prune -f --volumes 2>/dev/null || true
        echo "✅ Podman limpo!"
        report_space
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 FASE 6: ML/AI MODELS E CACHES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "6.1. Mapeando ML/AI caches do usuário..."
for ml_path in \
    "$HOME/.cache/huggingface" \
    "$HOME/.cache/torch" \
    "$HOME/.cache/transformers" \
    "$HOME/.cache/diffusers" \
    "$HOME/.ollama/models" \
    "$HOME/.cache/clip"; do
    if [ -d "$ml_path" ]; then
        size=$(du -sh "$ml_path" | cut -f1)
        echo "   📦 $ml_path : $size"
        read -p "      Limpar? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$ml_path"
            echo "   ✅ Limpo."
            report_space
        fi
    fi
done

echo ""
echo "6.2. /var/lib/ml-models (bridge custom de modelos)..."
if [ -d /var/lib/ml-models ]; then
    echo "   Tamanho total: $(sudo du -sh /var/lib/ml-models | cut -f1)"
    echo "   Conteúdo:"
    sudo ls -lh /var/lib/ml-models/ 2>/dev/null | sed 's/^/   /'
    echo ""
    echo "   ⚠️  ATENÇÃO: Bridge de modelos das labels — só remova o que não é mais usado!"
    read -p "   Abrir remoção seletiva? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Modelos:"
        sudo ls /var/lib/ml-models/ 2>/dev/null | nl | sed 's/^/   /'
        echo -n "   Nomes para remover (separados por espaço, Enter para pular): "
        read -r models_rm
        for m in $models_rm; do
            if sudo test -e "/var/lib/ml-models/$m"; then
                sudo rm -rf "/var/lib/ml-models/$m"
                echo "   ✅ Removido: $m"
            else
                echo "   ✗ Não encontrado: $m"
            fi
        done
    fi
    report_space
else
    echo "   /var/lib/ml-models não encontrado."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👻 FASE 7: SYSTEM GHOSTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "7.1. Core dumps (/var/lib/systemd/coredump)..."
if [ -d /var/lib/systemd/coredump ]; then
    echo "   Tamanho: $(sudo du -sh /var/lib/systemd/coredump | cut -f1)"
    read -p "   Limpar core dumps? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -rf /var/lib/systemd/coredump/*
        echo "   ✅ Core dumps removidos."
        report_space
    fi
else
    echo "   Nenhum core dump encontrado."
fi

echo ""
echo "7.2. Arquivos >100MB em /tmp..."
tmp_large=$(find /tmp -maxdepth 3 -type f -size +100M 2>/dev/null | head -20)
if [ -n "$tmp_large" ]; then
    echo "$tmp_large" | while read -r f; do
        echo "   $(du -sh "$f" 2>/dev/null | cut -f1)  $f"
    done
    read -p "   Remover esses arquivos de /tmp? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$tmp_large" | xargs rm -f 2>/dev/null || true
        echo "   ✅ /tmp limpo."
        report_space
    fi
else
    echo "   Nenhum arquivo grande em /tmp."
fi

echo ""
echo "7.3. Rust cargo global (~/.cargo/registry, ~/.cargo/git)..."
cargo_size=$(du -sh "$HOME/.cargo/registry" "$HOME/.cargo/git" 2>/dev/null | awk '{sum+=$1} END{print sum "K"}')
echo "   ~/.cargo/registry + git: $(du -sh "$HOME/.cargo/registry" 2>/dev/null | cut -f1) + $(du -sh "$HOME/.cargo/git" 2>/dev/null | cut -f1)"
read -p "   Limpar cargo global cache? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.cargo/registry" "$HOME/.cargo/git"
    echo "   ✅ Cargo cache limpo."
    report_space
fi

echo ""
echo "7.4. Go build cache (~/.cache/go-build)..."
if [ -d "$HOME/.cache/go-build" ]; then
    echo "   ~/.cache/go-build: $(du -sh "$HOME/.cache/go-build" | cut -f1)"
    read -p "   Limpar Go build cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        go clean -cache 2>/dev/null || rm -rf "$HOME/.cache/go-build"
        echo "   ✅ Go cache limpo."
        report_space
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 FASE 8: CACHE GERAL DO USUÁRIO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "8.1. Top 10 maiores entradas em ~/.cache:"
du -sh ~/.cache/*/ 2>/dev/null | sort -rh | head -10 | sed 's/^/   /'
echo ""
read -p "Limpar TODO ~/.cache? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.cache/*
    echo "✅ Cache limpo!"
    report_space
fi

echo ""
echo "8.2. Limpar Downloads..."
if [ -d ~/Downloads ]; then
    echo "Downloads: $(du -sh ~/Downloads | cut -f1)"
    read -p "Limpar ~/Downloads? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/Downloads/*
        echo "✅ Downloads limpos!"
        report_space
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ LIMPEZA COMPLETA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BEFORE_USED=$(df / | tail -1 | awk '{print $3}')

echo "📊 Espaço DEPOIS da limpeza:"
df -h / | grep -v Filesystem

echo ""
echo "📈 Resumo:"
df -h / | awk 'NR==2 {
    print "   Total:      " $2
    print "   Usado:      " $3 " (" $5 ")"
    print "   Disponível: " $4
}'

echo ""
echo "💡 PRÓXIMOS PASSOS:"
echo "1. Verificar espaço livre disponível para rebuild"
echo "2. sudo nixos-rebuild switch --show-trace"
echo "3. Monitorar: sudo journalctl -f durante o rebuild"
echo "4. Se ainda faltar espaço: nix-store --optimise (dedup do store)"