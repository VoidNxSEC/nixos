#!/bin/sh
# VSCodium wrapper with Firejail sandboxing and resource control

# Create systemd scope for resource management
SCOPE_NAME="vscodium-$$"

# Launch with systemd-run for cgroup-based resource control
exec /nix/store/zf8qy81dsw1vqwgh9p9n2h40s1k0g2l1-systemd-258.2/bin/systemd-run \
  --user \
  --scope \
  --unit="$SCOPE_NAME" \
  --property="MemoryMax=8G" \
  --property="CPUQuota=80%" \
  --property="Nice=10" \
  --property="IOSchedulingClass=best-effort" \
  --property="IOSchedulingPriority=4" \
  /nix/store/wc6krrdhwa6h1155lni4j4mp4flmlq7l-firejail-0.9.76/bin/firejail \
    --profile=/etc/firejail/vscodium.local \
    --private-etc=alternatives,fonts,ssl,pki,crypto-policies,resolv.conf,hostname,localtime \
    /nix/store/5n9dn9p82w9cs6vfsj8l8q4gb7vim5vm-vscodium-1.106.27818/bin/codium \
    --disable-telemetry \
    --disable-crash-reporter \
    --disable-update-check \
    "$@"
