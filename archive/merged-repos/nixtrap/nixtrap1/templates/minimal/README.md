# Minimal NixOS Cache Server Template

This template provides a minimal NixOS cache server configuration.

## Quick Start

1. Copy this template to your configuration:
   ```bash
   nix flake init -t github:yourusername/nixtrap#minimal
   ```

2. Generate hardware configuration:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

3. Edit `flake.nix` and update:
   - `hostName` to your desired hostname
   - `boot.loader.grub.device` to your boot device
   - User configuration as needed

4. Install:
   ```bash
   nixos-install --flake .#cache-server
   ```

## Features Included

- ✅ Nix binary cache server (nix-serve)
- ✅ TLS/HTTPS via nginx
- ✅ Automatic cache signing
- ✅ Basic firewall configuration
- ✅ SSH access

## What's Not Included

- Monitoring (use full template for this)
- API server (use full template for this)
- Grafana dashboards (use full template for this)

## Next Steps

After installation:

1. Get your cache public key:
   ```bash
   cat /var/cache-nix-serve/cache-pub-key.pem
   ```

2. Configure clients to use your cache:
   ```nix
   nix.settings.substituters = [ "https://cache.local" ];
   nix.settings.trusted-public-keys = [ "cache.local:YOUR_PUBLIC_KEY" ];
   ```

3. Test the cache:
   ```bash
   curl https://cache.local/nix-cache-info
   ```
