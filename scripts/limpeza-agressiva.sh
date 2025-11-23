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
echo "  1. Logs de audit (100GB+)"
echo "  2. Logs antigos do sistema (20-30GB)"
echo "  3. Cache VSCodium/Roo (23GB)"
echo "  4. Garbage collection Nix (20-30GB)"
echo "  5. Docker (10GB)"
echo "  6. Journal logs (configurável)"
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
echo "🗂️  FASE 3: LIMPAR CACHE VSCODIUM/ROO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks ]; then
    echo "3.1. Tamanho atual do cache Roo:"
    du -sh ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks
    
    echo ""
    echo "3.2. Limpando cache de tasks do Roo..."
    rm -rf ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks/*
    
    echo ""
    echo "✅ Cache Roo limpo!"
else
    echo "Cache Roo não encontrado ou já limpo"
fi

# Limpar outros caches do VSCodium
if [ -d ~/.config/VSCodium/Cache ]; then
    echo ""
    echo "3.3. Limpando cache geral do VSCodium..."
    rm -rf ~/.config/VSCodium/Cache/*
fi

report_space

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 FASE 4: GARBAGE COLLECTION NIX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "4.1. Tamanho atual do /nix/store:"
sudo du -sh /nix/store 2>/dev/null || echo "Não foi possível calcular"

echo ""
echo "4.2. Limpando gerações antigas do perfil de usuário..."
nix-env --delete-generations old 2>/dev/null || true

echo ""
echo "4.3. Garbage collection (pode demorar 5-10 minutos)..."
nix-collect-garbage -d

echo ""
echo "4.4. Garbage collection do sistema..."
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
echo "🐳 FASE 5: LIMPAR DOCKER (Opcional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v docker &> /dev/null; then
    if sudo systemctl is-active docker &>/dev/null; then
        echo "Docker está rodando. Limpar?"
        read -p "Limpar containers/images/volumes não usados? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Limpando Docker..."
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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 FASE 6: LIMPEZA ADICIONAL (Opcional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "6.1. Limpar cache de usuário..."
if [ -d ~/.cache ]; then
    echo "Cache atual: $(du -sh ~/.cache | cut -f1)"
    read -p "Limpar ~/.cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.cache/*
        echo "✅ Cache limpo!"
        report_space
    fi
fi

echo ""
echo "6.2. Limpar Downloads..."
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
echo "1. Verificar que tem >100GB livres agora"
echo "2. Configurar offload-server no desktop"
echo "3. Configurar laptop como build client"
echo "4. Configurar logrotate para prevenir recorrência"
echo ""
echo "📚 Ver: PLANO-ACAO-LIMPEZA.md para configurações preventivas"