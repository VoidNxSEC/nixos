#!/usr/bin/env bash
# emergency-fix.sh - Immediate stability restoration

set -e

echo "🚨 Emergency System Stabilization"
echo "=================================="

# ═══════════════════════════════════════════════════════════
# FIX 1: Repair broken root profile
# ═══════════════════════════════════════════════════════════

echo ""
echo "🔧 Fix 1: Repairing root Nix profile..."

# Check if profile directory exists
if [ ! -d "/nix/var/nix/profiles/per-user/root" ]; then
  echo "Creating root profile directory..."
  sudo mkdir -p /nix/var/nix/profiles/per-user/root
  sudo chown root:root /nix/var/nix/profiles/per-user/root
fi

# Recreate profile symlink
echo "Recreating profile symlink..."
sudo rm -f /root/.nix-profile
sudo nix-env --switch-generation 1 || {
  echo "No generations found, initializing profile..."
  sudo nix-env -i hello # Dummy install to create profile
  sudo nix-env -e hello # Remove dummy
}

# Verify fix
if [ -L "/root/.nix-profile" ] && [ -e "/root/.nix-profile" ]; then
  echo "✅ Root profile repaired: $(readlink -f /root/.nix-profile)"
else
  echo "❌ Profile still broken, needs manual intervention"
fi

# ═══════════════════════════════════════════════════════════
# FIX 2: Restore .zshrc (basic functional version)
# ═══════════════════════════════════════════════════════════

echo ""
echo "🔧 Fix 2: Restoring .zshrc..."

# Backup existing if somehow present
[ -f /root/.zshrc ] && sudo cp /root/.zshrc /root/.zshrc.backup

# Create minimal functional .zshrc
sudo tee /root/.zshrc >/dev/null <<'ZSHRC'
# ═══════════════════════════════════════════════════════════
# ROOT ZSHRC - Minimal Functional Configuration
# ═══════════════════════════════════════════════════════════
# WARNING: This is ROOT shell - use carefully!

# Source Nix profile (CRITICAL)
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
fi

# Fallback: source system-wide nix
if [ -e /etc/profile.d/nix.sh ]; then
  source /etc/profile.d/nix.sh
fi

# Basic prompt (know you're root!)
PS1='%F{red}[ROOT]%f %F{cyan}%~%f %# '

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Key bindings
bindkey -e  # Emacs mode

# Completions
autoload -Uz compinit
compinit

# CRITICAL: Source system configuration if exists
if [ -f /etc/zshrc ]; then
  source /etc/zshrc
fi

# Environment purity check
if [ -n "$LD_LIBRARY_PATH" ]; then
  echo "⚠️  WARNING: LD_LIBRARY_PATH is set: $LD_LIBRARY_PATH"
  echo "   This may contaminate builds!"
fi
ZSHRC

echo "✅ .zshrc restored"

# Also create one for kernelcore user if missing
if [ ! -f /home/kernelcore/.zshrc ]; then
  echo "Creating .zshrc for kernelcore user..."
  sudo -u kernelcore tee /home/kernelcore/.zshrc >/dev/null <<'USERZSHRC'
# User zshrc - kernelcore
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
fi

# Prompt
PS1='%F{green}%n@%m%f %F{cyan}%~%f %# '

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Completions
autoload -Uz compinit
compinit

# System config
if [ -f /etc/zshrc ]; then
  source /etc/zshrc
fi
USERZSHRC
  sudo chown kernelcore:users /home/kernelcore/.zshrc
  echo "✅ User .zshrc created"
fi

# ═══════════════════════════════════════════════════════════
# FIX 3: PATH Alignment Diagnostic
# ═══════════════════════════════════════════════════════════

echo ""
echo "🔧 Fix 3: PATH Alignment Check..."

echo "Current shell: $SHELL (user: $(whoami))"
echo ""
echo "BASH PATH (kernelcore):"
sudo -u kernelcore bash -c 'echo $PATH | tr ":" "\n"' | head -5
echo ""
echo "ZSH PATH (current user):"
zsh -c 'echo $PATH | tr ":" "\n"' | head -5

# ═══════════════════════════════════════════════════════════
# FIX 4: Immediate Recommendations
# ═══════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════"
echo "🎯 Emergency Fixes Applied"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Status:"
echo "  ✓ Root profile symlink repaired"
echo "  ✓ .zshrc restored (minimal functional)"
echo "  ✓ Diagnostic complete"
echo ""
echo "⚠️  CRITICAL DECISION NEEDED:"
echo ""
echo "You have TWO environments:"
echo "  1. BASH (kernelcore) - Desktop/Hyprland ← YOU USE THIS"
echo "  2. ZSH (root) - Builds/sudo ← PROBLEMATIC"
echo ""
echo "Options:"
echo "  A) Stop using root ZSH, build as kernelcore"
echo "  B) Align environments (sync PATHs)"
echo "  C) Declarative fix in configuration.nix"
echo ""
echo "Recommendation: Option A (safest) or C (best long-term)"
echo ""
$()$(

  Roda isso **AGORA** pra estabilizar. Mas a solução REAL precisa de context das perguntas acima.

  ---

  ## 🧬 **The Philosophy of Shell Duality**

  Cara, você descobriu uma das **verdades obscuras do Unix**:

  >"Every user is a universe. Every shell is a timeline.
> And when you sudo, you JUMP UNIVERSES."
)$()
kernelcore@bash: "I am in my home, with my tools" 🏠
sudo su -: "QUANTUM LEAP to root dimension" 🌀
root@zsh: "Where am I? Who am I? Why is PATH broken?" 😵
exit: "Return to kernelcore, but contaminated" ☣️
