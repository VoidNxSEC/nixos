#!/usr/bin/env bash
# Script de diagnóstico DNS completo

echo "==================================="
echo "   DNS DIAGNOSTICS TOOL"
echo "==================================="
echo ""

# 1. Status do systemd-resolved
echo "📡 [1/7] Systemd-resolved status:"
systemctl status systemd-resolved --no-pager | head -n 5
echo ""

# 2. Configuração atual
echo "⚙️  [2/7] Current DNS configuration:"
/nix/store/zf8qy81dsw1vqwgh9p9n2h40s1k0g2l1-systemd-258.2/bin/resolvectl status | grep "DNS Servers" -A 5
echo ""

# 3. Testar resolução local
echo "🔍 [3/7] Testing local resolver (127.0.0.53):"
if /nix/store/v8nx28wxq77aaypi5pqpawirj0nvyvch-bind-9.20.15/bin/dig +short +time=3 @127.0.0.53 google.com > /dev/null 2>&1; then
  echo "✅ Local resolver OK"
  /nix/store/v8nx28wxq77aaypi5pqpawirj0nvyvch-bind-9.20.15/bin/dig +short @127.0.0.53 google.com | head -n 1
else
  echo "❌ Local resolver FAILED"
fi
echo ""

# 4. Testar Cloudflare
echo "☁️  [4/7] Testing Cloudflare (1.1.1.1):"
if /nix/store/v8nx28wxq77aaypi5pqpawirj0nvyvch-bind-9.20.15/bin/dig +short +time=3 @1.1.1.1 google.com > /dev/null 2>&1; then
  echo "✅ Cloudflare OK"
else
  echo "❌ Cloudflare FAILED"
fi
echo ""

# 5. Testar Google DNS
echo "🔎 [5/7] Testing Google DNS (8.8.8.8):"
if /nix/store/v8nx28wxq77aaypi5pqpawirj0nvyvch-bind-9.20.15/bin/dig +short +time=3 @8.8.8.8 google.com > /dev/null 2>&1; then
  echo "✅ Google DNS OK"
else
  echo "❌ Google DNS FAILED"
fi
echo ""

# 6. Verificar DNSCrypt (se habilitado)


# 7. Verificar conectividade geral
echo "🌐 [7/7] Internet connectivity:"
if /nix/store/0rfz69vp1nl0q2hxzig20hc60sk72z62-curl-8.17.0-bin/bin/curl -s --max-time 5 https://1.1.1.1 > /dev/null 2>&1; then
  echo "✅ Internet connectivity OK"
else
  echo "❌ Internet connectivity FAILED"
fi
echo ""

# Resumo
echo "==================================="
echo "   SUMMARY"
echo "==================================="
/nix/store/zf8qy81dsw1vqwgh9p9n2h40s1k0g2l1-systemd-258.2/bin/resolvectl statistics
echo ""

# Logs recentes
echo "📋 Recent DNS errors (last 10):"
journalctl -u systemd-resolved -p err --since "10 minutes ago" --no-pager | tail -n 10
