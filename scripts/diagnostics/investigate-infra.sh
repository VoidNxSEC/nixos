#!/bin/bash

echo "=========================================="
echo "INFRASTRUCTURE INVESTIGATION"
echo "=========================================="
echo

echo "1. BINARY CACHE INVESTIGATION"
echo "------------------------------"
echo "Testing cache connectivity to 192.168.15.7:5000..."
timeout 5 curl -v http://192.168.15.7:5000/nix-cache-info 2>&1 | head -30

echo
echo "Checking nix substituters configuration..."
nix show-config | grep -E "(substituters|trusted-public-keys|builders-use-substitutes)" | head -20

echo
echo "Checking build machine configuration..."
nix show-config | grep -E "builders"

echo
echo
echo "2. SANDBOXING INVESTIGATION"
echo "------------------------------"
echo "Current sandbox settings:"
nix show-config | grep -i sandbox

echo
echo "Checking user namespace support:"
echo "  kernel.unprivileged_userns_clone = $(sysctl -n kernel.unprivileged_userns_clone 2>/dev/null || echo 'NOT SET')"
echo "  /proc/sys/user/max_user_namespaces = $(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo 'NOT SET')"

echo
echo "Checking if unprivileged user can create namespaces:"
unshare --user --pid --map-root-user echo "✓ User namespaces work" 2>&1 || echo "✗ User namespaces BLOCKED"

echo
echo "Checking kernel namespace support:"
ls -la /proc/self/ns/ 2>/dev/null | head -15

echo
echo "Kernel version and config:"
uname -r
echo "CONFIG_USER_NS: $(zgrep CONFIG_USER_NS /proc/config.gz 2>/dev/null || echo 'config.gz not available')"

echo
echo "Checking apparmor status:"
aa-status 2>&1 | head -10 || echo "AppArmor not active"

echo
echo "Relevant sysctl hardening settings:"
sysctl kernel.unprivileged_userns_clone kernel.unprivileged_bpf_disabled kernel.yama.ptrace_scope 2>/dev/null

