#!/usr/bin/env bash
# ============================================================
# Brev CLI Wrapper for NixOS
# Addresses read-only ~/.ssh/config issues.
# ============================================================

set -e

# Real paths
REAL_HOME="$HOME"
BREV_HOME="$REAL_HOME/.brev"
NIX_BREV_CONFIG="$REAL_HOME/.ssh/brev_config"

# Check if Brev is installed
if ! command -v brev &> /dev/null; then
    echo "Error: brev command not found"
    exit 1
fi

# Determine if we're running a command that needs config updates
NEEDS_REFRESH=false
if [[ "$1" == "refresh" ]] || [[ "$1" == "login" ]] || [[ "$1" == "start" ]] || [[ "$1" == "open" ]] || [[ "$1" == "shell" ]]; then
    NEEDS_REFRESH=true
fi

# Create a fake home environment for SSH config checking
FAKE_HOME="/tmp/brev_fake_home_$$"
mkdir -p "$FAKE_HOME/.ssh"
# Brev needs to see this exact line or it will try to write to it and fail
echo 'Include "/home/kernelcore/.brev/ssh_config"' > "$FAKE_HOME/.ssh/config"
chmod 600 "$FAKE_HOME/.ssh/config"

# Symlink the real .brev directory so we don't lose session data
ln -s "$BREV_HOME" "$FAKE_HOME/.brev"

# Run the actual command with the fake HOME
HOME="$FAKE_HOME" brev "$@" || true

# Cleanup
rm -rf "$FAKE_HOME"

# If the command was refresh (or something that changes state), 
# make sure the config is copied to where Nix expects it
if [ "$NEEDS_REFRESH" = true ]; then
    echo "Syncing Brev SSH configuration for NixOS..."
    
    # Wait a moment to ensure Brev finishes writing
    sleep 1 
    
    if [ -f "$BREV_HOME/ssh_config" ]; then
        # Replace the fake home path with the real home path in the config
        sed "s|$FAKE_HOME|$REAL_HOME|g" "$BREV_HOME/ssh_config" > "$NIX_BREV_CONFIG"
        
        # Ensure correct permissions
        chmod 600 "$NIX_BREV_CONFIG"
        
        echo "✓ Brev SSH configuration successfully synced."
    else
        echo "Warning: $BREV_HOME/ssh_config not found. Did the refresh succeed?"
    fi
fi
