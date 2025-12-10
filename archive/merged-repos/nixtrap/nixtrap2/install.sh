#!/bin/bash

echo "🚀 NixOS Modern i3 Setup - Installation Script"
echo "=============================================="
echo ""

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Error: flake.nix not found. Please run this script from /etc/nixos directory."
    exit 1
fi

echo "📋 Pre-installation checklist:"
echo "✓ Modern i3 window manager with themes"
echo "✓ Polybar status bar with system monitors"
echo "✓ Rofi application launcher with custom themes"
echo "✓ Picom compositor with transparency effects"
echo "✓ System management scripts and aliases"
echo "✓ Binary cache server configuration"
echo ""

read -p "🤔 Do you want to proceed with the installation? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "🔄 Starting installation..."

# Test the configuration first
echo "1️⃣ Testing configuration..."
if ! nixos-rebuild test --flake . --show-trace; then
    echo "❌ Configuration test failed. Please check the errors above."
    exit 1
fi

echo "✅ Configuration test passed!"
echo ""

# Apply the configuration
echo "2️⃣ Applying configuration..."
if ! nixos-rebuild switch --flake . --show-trace; then
    echo "❌ Configuration application failed. Please check the errors above."
    echo "ℹ️  Your system is still in the previous working state."
    exit 1
fi

echo "✅ Configuration applied successfully!"
echo ""

# Initialize themes
echo "3️⃣ Setting up themes..."
if command -v i3-theme-dark >/dev/null 2>&1; then
    i3-theme-dark
    echo "dark" > ~/.config/i3/current-theme 2>/dev/null || true
    echo "✅ Dark theme initialized"
else
    echo "⚠️  Theme scripts will be available after reboot/re-login"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📚 Quick Start Guide:"
echo "==================="
echo ""
echo "🎨 Theme Management:"
echo "  • Super+T          - Toggle between light/dark theme"
echo "  • theme-toggle     - Command line theme toggle"
echo ""
echo "⚡ Quick Settings:"
echo "  • Super+Ctrl+S     - Open quick settings panel"
echo "  • Super+Ctrl+P     - Power menu (lock/suspend/reboot)"
echo ""
echo "🔧 System Management:"
echo "  • nrs              - Rebuild NixOS (nixos-rebuild switch)"
echo "  • nup              - Update system (nix flake update)"
echo "  • status           - System status report"
echo "  • ncl              - Cleanup old generations"
echo ""
echo "🚀 Application Shortcuts:"
echo "  • Super+W          - Firefox"
echo "  • Super+B          - Vivaldi"
echo "  • Super+E          - File Manager"
echo "  • Super+Return     - Terminal"
echo "  • Super+D          - App Launcher"
echo ""
echo "📖 For complete reference: cat /etc/nixos/README.md"
echo ""
echo "🔄 Next Steps:"
echo "1. Reboot or log out and back in to start using i3"
echo "2. Try Super+Ctrl+S for quick settings"
echo "3. Use 'status' command to check system health"
echo ""
echo "✨ Enjoy your modern i3 desktop environment!"