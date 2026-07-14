#!/usr/bin/env bash

echo "==============================================="
echo "SSH Configuration Diagnostics"
echo "==============================================="
echo ""

echo "1. SSH Service Status:"
systemctl is-active sshd && echo "✓ SSH daemon is running" || echo "✗ SSH daemon is NOT running"
echo ""

echo "2. SSH Port Listening:"
ss -tlnp | grep :22 && echo "✓ SSH is listening on port 22" || echo "✗ SSH is NOT listening"
echo ""

echo "3. Authorized Keys:"
if [ -f /etc/ssh/authorized_keys.d/kernelcore ]; then
    echo "✓ Authorized keys file exists"
    echo "  Keys found:"
    cat /etc/ssh/authorized_keys.d/kernelcore | wc -l
    echo ""
    echo "  iPhone key fingerprint:"
    ssh-keygen -lf /etc/ssh/authorized_keys.d/kernelcore
else
    echo "✗ Authorized keys file NOT found"
fi
echo ""

echo "4. Critical SSH Settings:"
echo "  PasswordAuthentication: $(grep -i "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')"
echo "  PubkeyAuthentication: $(grep -i "^PubkeyAuthentication" /etc/ssh/sshd_config | awk '{print $2}')"
echo "  PermitRootLogin: $(grep -i "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')"
echo "  MaxAuthTries: $(grep -i "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')"
echo ""

echo "5. Crypto Algorithms (Server Config):"
echo "  Ciphers:"
grep "^Ciphers" /etc/ssh/sshd_config | tail -1 | sed 's/Ciphers /    /'
echo ""
echo "  MACs:"
grep "^MACs" /etc/ssh/sshd_config | tail -1 | sed 's/MACs /    /'
echo ""
echo "  KexAlgorithms:"
grep "^KexAlgorithms" /etc/ssh/sshd_config | tail -1 | sed 's/KexAlgorithms /    /' | fold -w 80 -s
echo ""
echo "  HostKeyAlgorithms:"
grep "^HostKeyAlgorithms" /etc/ssh/sshd_config | tail -1 | sed 's/HostKeyAlgorithms /    /'
echo ""

echo "6. Blink Shell Compatibility Check:"
echo "  ECDSA support: $(ssh -Q key | grep ecdsa-sha2-nistp256 > /dev/null && echo "✓ Supported" || echo "✗ NOT supported")"
echo "  ChaCha20 cipher: $(grep "chacha20-poly1305" /etc/ssh/sshd_config > /dev/null && echo "✓ Enabled" || echo "✗ NOT enabled")"
echo "  Curve25519 kex: $(grep "curve25519-sha256" /etc/ssh/sshd_config > /dev/null && echo "✓ Enabled" || echo "✗ NOT enabled")"
echo ""

echo "7. Firewall Status:"
if command -v nft > /dev/null; then
    echo "  SSH port (TCP 22): checking nftables..."
    # Simplified check - just verify service is running
    systemctl is-active nftables > /dev/null && echo "    ✓ nftables active" || echo "    ✗ nftables inactive"
fi
echo ""

echo "8. Potential Issues:"
ISSUES=0

# Check if ECDSA is in HostKeyAlgorithms
if ! grep "^HostKeyAlgorithms" /etc/ssh/sshd_config | grep -q "ecdsa"; then
    echo "  ⚠ ECDSA NOT in HostKeyAlgorithms - may block ECDSA keys from clients"
    ISSUES=$((ISSUES+1))
fi

# Check if server has ECDSA host key
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    echo "  ⚠ Server missing ECDSA host key - may cause connection issues"
    ISSUES=$((ISSUES+1))
fi

# Check MaxAuthTries
MAX_TRIES=$(grep -i "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$MAX_TRIES" -lt 3 ]; then
    echo "  ⚠ MaxAuthTries is very low ($MAX_TRIES) - may cause auth failures"
    ISSUES=$((ISSUES+1))
fi

# Check if KexAlgorithms is too restrictive
if grep "^KexAlgorithms" /etc/ssh/sshd_config | grep -q "curve25519-sha256" && \
   ! grep "^KexAlgorithms" /etc/ssh/sshd_config | grep -q "ecdh"; then
    echo "  ⚠ No ECDH algorithms in KexAlgorithms - may block some clients"
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "  ✓ No critical issues detected"
fi

echo ""
echo "==============================================="
echo "Summary:"
echo "==============================================="
echo "SSH daemon: $(systemctl is-active sshd)"
echo "iPhone key: $([ -f /etc/ssh/authorized_keys.d/kernelcore ] && echo "configured" || echo "NOT configured")"
echo "Issues found: $ISSUES"
echo ""

if [ $ISSUES -gt 0 ]; then
    echo "Recommendation: Review issues above and consider relaxing crypto requirements"
    echo "for better client compatibility while maintaining good security."
else
    echo "✓ Configuration looks good for Blink Shell connections!"
fi

