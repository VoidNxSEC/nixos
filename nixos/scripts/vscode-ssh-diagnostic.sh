#!/usr/bin/env bash
# VSCode Remote SSH Connection Diagnostic
# Simulates VSCode connection process

set -e

echo "=========================================="
echo "VSCode Remote SSH Diagnostic"
echo "=========================================="
echo ""

HOST="${1:-desktop}"

echo "📡 Testing SSH connection to: $HOST"
echo ""

# Test 1: Basic SSH connectivity
echo "1️⃣  Basic SSH Connectivity Test"
if ssh -o ConnectTimeout=10 "$HOST" "echo 'SSH: ✅ Connected'" 2>/dev/null; then
    echo "   ✅ SSH connection successful"
else
    echo "   ❌ SSH connection failed"
    exit 1
fi
echo ""

# Test 2: Check SSH config
echo "2️⃣  SSH Configuration Check"
ssh -G "$HOST" | grep -E "^hostname|^user|^identityfile|^port" | while read line; do
    echo "   $line"
done
echo ""

# Test 3: Check remote user and hostname
echo "3️⃣  Remote System Info"
echo "   User: $(ssh "$HOST" 'whoami' 2>/dev/null)"
echo "   Hostname: $(ssh "$HOST" 'hostname' 2>/dev/null)"
echo "   OS: $(ssh "$HOST" 'uname -s' 2>/dev/null)"
echo "   Kernel: $(ssh "$HOST" 'uname -r' 2>/dev/null)"
echo ""

# Test 4: Check for Node.js
echo "4️⃣  Node.js Availability"
if ssh "$HOST" "command -v node" &>/dev/null; then
    NODE_PATH=$(ssh "$HOST" "command -v node" 2>/dev/null)
    NODE_VERSION=$(ssh "$HOST" "node --version" 2>/dev/null)
    echo "   ✅ Node.js found: $NODE_PATH"
    echo "   Version: $NODE_VERSION"
else
    echo "   ⚠️  Node.js not in PATH"
    echo "   Checking nix-shell..."
    if ssh "$HOST" "nix-shell -p nodejs --run 'node --version'" &>/dev/null; then
        NODE_VERSION=$(ssh "$HOST" "nix-shell -p nodejs --run 'node --version'" 2>/dev/null)
        echo "   ✅ Node.js available via nix-shell: $NODE_VERSION"
    else
        echo "   ❌ Node.js not available"
    fi
fi
echo ""

# Test 5: Check for required commands
echo "5️⃣  Required Commands Check"
for cmd in bash tar gzip; do
    if ssh "$HOST" "command -v $cmd" &>/dev/null; then
        CMD_PATH=$(ssh "$HOST" "command -v $cmd" 2>/dev/null)
        echo "   ✅ $cmd: $CMD_PATH"
    else
        echo "   ❌ $cmd: NOT FOUND"
    fi
done
echo ""

# Test 6: Check home directory permissions
echo "6️⃣  Home Directory Permissions"
HOME_PERMS=$(ssh "$HOST" "ls -ld ~ | awk '{print \$1, \$3, \$4}'" 2>/dev/null)
echo "   $HOME_PERMS"
echo ""

# Test 7: Test creating .vscode-server directory
echo "7️⃣  VSCode Server Directory Test"
if ssh "$HOST" "mkdir -p ~/.vscode-server && echo 'test' > ~/.vscode-server/.test && rm ~/.vscode-server/.test" &>/dev/null; then
    echo "   ✅ Can create .vscode-server directory"
else
    echo "   ❌ Cannot create .vscode-server directory"
fi
echo ""

# Test 8: Check SSH key authentication
echo "8️⃣  SSH Key Authentication"
ssh -v "$HOST" "exit" 2>&1 | grep -i "authentication\|identity" | head -5 | while read line; do
    echo "   $line"
done
echo ""

# Test 9: Check for /etc/nix/builder_key references
echo "9️⃣  Check for problematic key references"
if grep -q "/etc/nix/builder_key" /etc/ssh/ssh_config 2>/dev/null; then
    echo "   ⚠️  Found /etc/nix/builder_key in /etc/ssh/ssh_config"
    grep -n "/etc/nix/builder_key" /etc/ssh/ssh_config
else
    echo "   ✅ No /etc/nix/builder_key references in system config"
fi
echo ""

# Test 10: Simulate VSCode connection sequence
echo "🔟 Simulating VSCode Connection Sequence"
echo "   Step 1: SSH handshake..."
if timeout 10 ssh "$HOST" "echo 'Handshake: OK'" &>/dev/null; then
    echo "   ✅ Handshake successful"
else
    echo "   ❌ Handshake failed or timed out"
fi

echo "   Step 2: Remote command execution..."
if ssh "$HOST" "uname -a && whoami" &>/dev/null; then
    echo "   ✅ Remote commands work"
else
    echo "   ❌ Remote commands failed"
fi

echo "   Step 3: Environment check..."
ssh "$HOST" "echo 'PATH=\$PATH'" 2>/dev/null | head -1
echo ""

echo "=========================================="
echo "✅ Diagnostic Complete"
echo "=========================================="
echo ""
echo "💡 If all tests passed, try reconnecting VSCode."
echo "💡 If Node.js is not in PATH, you may need to add it to the remote user's profile."
