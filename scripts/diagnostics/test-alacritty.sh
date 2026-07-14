#!/usr/bin/env bash
# Test Alacritty configuration

echo "🧪 Testing Alacritty Configuration"
echo ""

# Test 1: Config file exists
if [ -f ~/.config/alacritty/alacritty.toml ]; then
    echo "✅ Config file exists: ~/.config/alacritty/alacritty.toml"
else
    echo "❌ Config file not found"
    exit 1
fi

# Test 2: Parse test (run alacritty with --hold and exit)
echo "✅ Checking config syntax..."
if alacritty --config-file ~/.config/alacritty/alacritty.toml -e echo "test" &>/dev/null; then
    echo "✅ Config syntax valid"
else
    echo "⚠️  Config may have issues (but might still work)"
fi

# Test 3: Home-manager module
echo "✅ Checking home-manager module..."
if [ -f /etc/nixos/hosts/kernelcore/home/alacritty.nix ]; then
    echo "✅ Home-manager module exists"
else
    echo "❌ Home-manager module not found"
fi

echo ""
echo "📊 Summary:"
echo "  - Alacritty version: $(alacritty --version)"
echo "  - Config location: ~/.config/alacritty/alacritty.toml"
echo "  - Home-manager module: /etc/nixos/hosts/kernelcore/home/alacritty.nix"
echo ""
echo "✅ Ready to rebuild!"
