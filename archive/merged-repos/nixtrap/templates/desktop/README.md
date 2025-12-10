# NixTrap Desktop Template

Quickly set up a lightweight i3 desktop with distributed build support.

## Quick Start

```bash
# 1. Initialize from template
nix flake init -t github:yourusername/nixtrap#desktop

# 2. Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 3. Edit configuration.nix (hostname, username, timezone)
vim configuration.nix

# 4. Edit home.nix (git config, aliases)
vim home.nix

# 5. Deploy
sudo nixos-rebuild switch --flake .#desktop
```

## What's Included

- i3 window manager with sensible defaults
- LightDM display manager
- Essential desktop applications
- Distributed build offloading (configure in modules)
- Binary cache client
- Memory optimization (ZRAM, kernel tuning)

## Customization

Edit `configuration.nix` to customize:
- Hostname
- Username
- Timezone
- Additional packages

Edit `home.nix` for:
- Git configuration
- Shell aliases
- User-specific settings
