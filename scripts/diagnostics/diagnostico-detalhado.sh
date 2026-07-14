#!/usr/bin/env bash
echo "🔍 DIAGNÓSTICO DETALHADO - O QUE ESTÁ OCUPANDO 394GB?"
echo "======================================================"
echo ""

echo "1️⃣ Tamanho dos principais diretórios:"
echo "----------------------------------------"
for dir in /nix /home /var /tmp /usr /opt; do
  if [ -d "$dir" ]; then
    size=$(sudo du -sh "$dir" 2>/dev/null | cut -f1)
    echo "$dir: $size"
  fi
done
echo ""

echo "2️⃣ Breakdown do /nix:"
echo "----------------------------------------"
sudo du -sh /nix/* 2>/dev/null | sort -h
echo ""

echo "3️⃣ Breakdown do /home:"
echo "----------------------------------------"
sudo du -sh /home/* 2>/dev/null | sort -h
echo ""

echo "4️⃣ Breakdown do /var:"
echo "----------------------------------------"
sudo du -sh /var/* 2>/dev/null | sort -h | tail -10
echo ""

echo "5️⃣ Logs grandes:"
echo "----------------------------------------"
sudo find /var/log -type f -size +100M -exec ls -lh {} \; 2>/dev/null
echo ""

echo "6️⃣ Docker (se existir):"
echo "----------------------------------------"
if command -v docker &> /dev/null; then
  docker system df 2>/dev/null || echo "Docker não rodando"
else
  echo "Docker não instalado"
fi
echo ""

echo "✅ Diagnóstico completo!"
