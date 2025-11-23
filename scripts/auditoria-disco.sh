#!/usr/bin/env bash
# Auditoria Completa de Uso de Disco
# Identifica exatamente o que está ocupando espaço

set -e

REPORT_FILE="auditoria-disco-$(date +%Y%m%d-%H%M%S).txt"

echo "🔍 AUDITORIA COMPLETA DE DISCO" | tee "$REPORT_FILE"
echo "==============================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Data: $(date)" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 1. Resumo Geral
echo "📊 1. RESUMO GERAL" | tee -a "$REPORT_FILE"
echo "==================" | tee -a "$REPORT_FILE"
df -h / | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 2. Top 30 Diretórios Maiores no Sistema
echo "📁 2. TOP 30 DIRETÓRIOS MAIORES" | tee -a "$REPORT_FILE"
echo "================================" | tee -a "$REPORT_FILE"
echo "Analisando... (pode demorar 2-5 minutos)" | tee -a "$REPORT_FILE"
sudo du -h / 2>/dev/null | sort -rh | head -30 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 3. Breakdown do /nix
echo "📦 3. BREAKDOWN DO /NIX" | tee -a "$REPORT_FILE"
echo "=======================" | tee -a "$REPORT_FILE"
echo "Total /nix:" | tee -a "$REPORT_FILE"
sudo du -sh /nix 2>/dev/null | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Subdiretorios:" | tee -a "$REPORT_FILE"
sudo du -sh /nix/* 2>/dev/null | sort -h | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 4. Análise do /nix/store
echo "🗄️  4. ANÁLISE DO /NIX/STORE" | tee -a "$REPORT_FILE"
echo "============================" | tee -a "$REPORT_FILE"
if [ -d /nix/store ]; then
  echo "Calculando tamanho total (pode demorar)..." | tee -a "$REPORT_FILE"
  STORE_SIZE=$(sudo du -sh /nix/store 2>/dev/null | cut -f1)
  echo "Tamanho total: $STORE_SIZE" | tee -a "$REPORT_FILE"
  echo "" | tee -a "$REPORT_FILE"
  
  echo "Número de itens no store:" | tee -a "$REPORT_FILE"
  STORE_COUNT=$(sudo ls /nix/store | wc -l)
  echo "$STORE_COUNT items" | tee -a "$REPORT_FILE"
  echo "" | tee -a "$REPORT_FILE"
  
  echo "Top 20 maiores pacotes individuais:" | tee -a "$REPORT_FILE"
  sudo du -sh /nix/store/* 2>/dev/null | sort -rh | head -20 | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# 5. Home Directory
echo "🏠 5. HOME DIRECTORY" | tee -a "$REPORT_FILE"
echo "====================" | tee -a "$REPORT_FILE"
du -sh ~/ 2>/dev/null | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Subdiretorios principais:" | tee -a "$REPORT_FILE"
du -sh ~/* 2>/dev/null | sort -h | tail -20 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 6. /var Analysis
echo "📋 6. /VAR DIRECTORY" | tee -a "$REPORT_FILE"
echo "====================" | tee -a "$REPORT_FILE"
sudo du -sh /var 2>/dev/null | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Subdiretorios:" | tee -a "$REPORT_FILE"
sudo du -sh /var/* 2>/dev/null | sort -h | tail -15 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 7. Logs Grandes
echo "📄 7. ARQUIVOS DE LOG GRANDES (>10MB)" | tee -a "$REPORT_FILE"
echo "======================================" | tee -a "$REPORT_FILE"
sudo find /var/log -type f -size +10M -exec ls -lh {} \; 2>/dev/null | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 8. Docker (se existir)
echo "🐳 8. DOCKER" | tee -a "$REPORT_FILE"
echo "============" | tee -a "$REPORT_FILE"
if command -v docker &> /dev/null; then
  if sudo systemctl is-active docker &>/dev/null; then
    echo "Docker está rodando:" | tee -a "$REPORT_FILE"
    sudo docker system df 2>/dev/null | tee -a "$REPORT_FILE" || echo "Erro ao obter info do Docker" | tee -a "$REPORT_FILE"
  else
    echo "Docker instalado mas não está rodando" | tee -a "$REPORT_FILE"
  fi
else
  echo "Docker não instalado" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# 9. Caches de Usuário
echo "💾 9. CACHES DE USUÁRIO" | tee -a "$REPORT_FILE"
echo "=======================" | tee -a "$REPORT_FILE"
if [ -d ~/.cache ]; then
  du -sh ~/.cache 2>/dev/null | tee -a "$REPORT_FILE"
  echo "Subdiretorios principais:" | tee -a "$REPORT_FILE"
  du -sh ~/.cache/* 2>/dev/null | sort -h | tail -10 | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# 10. Gerações do Sistema
echo "🔄 10. GERAÇÕES DO SISTEMA NIXOS" | tee -a "$REPORT_FILE"
echo "=================================" | tee -a "$REPORT_FILE"
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 11. Roots de GC
echo "🔗 11. GC ROOTS (o que impede garbage collection)" | tee -a "$REPORT_FILE"
echo "==================================================" | tee -a "$REPORT_FILE"
ROOTS_COUNT=$(nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | wc -l)
echo "Total de roots: $ROOTS_COUNT" | tee -a "$REPORT_FILE"
echo "Principais roots:" | tee -a "$REPORT_FILE"
nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | head -20 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 12. Arquivos Grandes no Sistema
echo "📦 12. TOP 50 MAIORES ARQUIVOS" | tee -a "$REPORT_FILE"
echo "===============================" | tee -a "$REPORT_FILE"
echo "Procurando arquivos >100MB... (pode demorar)" | tee -a "$REPORT_FILE"
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -50 | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 13. Resumo e Recomendações
echo "💡 13. RESUMO E RECOMENDAÇÕES" | tee -a "$REPORT_FILE"
echo "==============================" | tee -a "$REPORT_FILE"

STORE_SIZE_NUM=$(sudo du -s /nix/store 2>/dev/null | cut -f1)
TOTAL_SIZE_NUM=$(df / | tail -1 | awk '{print $3}')

if [ -n "$STORE_SIZE_NUM" ] && [ -n "$TOTAL_SIZE_NUM" ]; then
  STORE_PERCENT=$((STORE_SIZE_NUM * 100 / TOTAL_SIZE_NUM))
  echo "/nix/store ocupa aproximadamente ${STORE_PERCENT}% do disco usado" | tee -a "$REPORT_FILE"
  echo "" | tee -a "$REPORT_FILE"
  
  if [ $STORE_PERCENT -gt 70 ]; then
    echo "⚠️  CRÍTICO: /nix/store está ocupando >70% do espaço!" | tee -a "$REPORT_FILE"
    echo "Recomendações:" | tee -a "$REPORT_FILE"
    echo "1. Execute: sudo nix-collect-garbage -d" | tee -a "$REPORT_FILE"
    echo "2. Execute: sudo nix-store --optimise" | tee -a "$REPORT_FILE"
    echo "3. Considere reinstalação limpa com offload" | tee -a "$REPORT_FILE"
  fi
fi
echo "" | tee -a "$REPORT_FILE"

echo "✅ AUDITORIA COMPLETA!" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "📄 Relatório salvo em: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "💡 Para análise visual interativa, instale: nix-shell -p ncdu" | tee -a "$REPORT_FILE"
echo "   Depois execute: sudo ncdu /" | tee -a "$REPORT_FILE"

# Copiar para desktop
echo ""
echo "📤 Deseja copiar o relatório para o desktop? (y/n)"
read -r COPY_TO_DESKTOP
if [ "$COPY_TO_DESKTOP" = "y" ] || [ "$COPY_TO_DESKTOP" = "Y" ]; then
  scp "$REPORT_FILE" cypher@192.168.15.7:~/
  echo "✅ Relatório copiado para desktop:~/$REPORT_FILE"
fi