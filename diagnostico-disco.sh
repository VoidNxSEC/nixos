#!/usr/bin/env bash
echo "🔍 DIAGNÓSTICO COMPLETO DO DISCO"
echo "================================="
echo ""

echo "📊 Resumo Geral:"
df -h /
echo ""

echo "📁 Top 20 Diretórios Maiores:"
sudo du -h --max-depth=2 / 2>/dev/null | sort -h | tail -20
echo ""

echo "🗑️  Gerações do Sistema:"
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -20
echo ""

echo "📦 Raízes de GC (o que impede limpeza):"
nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | wc -l
echo "Total de roots protegendo pacotes"
