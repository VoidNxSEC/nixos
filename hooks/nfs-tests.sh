#!/usr/bin/env bash
set -euo pipefail

# Sanity checks for the remote Nix builder/cache setup used by the desktop host.
# Overrides: DESKTOP_IP, CACHE_PORT, KEY

DESKTOP_IP=${DESKTOP_IP:-192.168.15.7}
CACHE_PORT=${CACHE_PORT:-5000}
KEY=${KEY:-/etc/nix/builder_key}
KNOWN_HOSTS_FILE=${KNOWN_HOSTS_FILE:-}

SSH_TARGET="nix-builder@${DESKTOP_IP}"
if [[ -z "${KNOWN_HOSTS_FILE:-}" ]]; then
  KNOWN_HOSTS_FILE=$(mktemp)
  trap 'rm -f "$KNOWN_HOSTS_FILE"' EXIT
fi

SSH_OPTS=(
  -i "$KEY"
  -o BatchMode=yes
  -o ConnectTimeout=5
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="$KNOWN_HOSTS_FILE"
)

if [[ ! -r "$KEY" ]]; then
  echo "Key not found or unreadable: $KEY" >&2
  exit 1
fi

step() {
  echo
  echo "== $* =="
}

step "trusted-public-keys (local)"
nix config show | grep trusted-public-keys || true

step "builder user no desktop (via ssh)"
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" 'id && ls -l ~/.ssh/authorized_keys'

step "systemd serviços (cache/ssh/rsync) no desktop"
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" \
  "systemctl status nix-serve.service sshd.service rsyncd.service --no-pager || true"

step "SSH builder"
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" 'echo "SSH OK"'

step "nix store ping"
nix store ping --store "ssh://${SSH_TARGET}"

step "build remoto hello"
nix-build '<nixpkgs>' -A hello \
  --builders "ssh://${SSH_TARGET} x86_64-linux $KEY 2 1"

step "cache info"
curl -vf "http://${DESKTOP_IP}:${CACHE_PORT}/nix-cache-info"

step "substituters (local)"
nix config show | grep substituters || true

step "trusted-public-keys (local)"
nix config show | grep trusted-public-keys || true
