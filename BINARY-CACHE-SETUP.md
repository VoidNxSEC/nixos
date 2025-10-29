# Binary Cache Configuration

## Overview

Binary caches speed up builds by downloading pre-compiled packages instead of building from source. This configuration supports:
- Local cache server (e.g., between desktop and laptop)
- Remote caches (e.g., Cachix, custom S3)
- Official NixOS cache (always enabled by default)

## Quick Setup

### Enable Binary Cache Module

Add to your `configuration.nix`:

```nix
kernelcore.system.binary-cache = {
  enable = true;

  # Optional: Use a local cache server
  local = {
    enable = true;
    url = "http://192.168.15.6:5000";  # Change to your local cache IP
    priority = 40;  # Lower = higher priority
  };

  # Optional: Add remote caches
  remote = {
    enable = true;
    substituers = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"  # Already enabled by default, but can be explicit
    ];
    trustedPublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
};
```

### Example: Desktop with Local Cache Disabled

```nix
# Desktop machine that BUILDS everything
kernelcore.system.binary-cache = {
  enable = true;
  local.enable = false;  # Don't try to use local cache server
  remote.enable = false;  # Only use official cache
};
```

### Example: Laptop Using Desktop as Cache

```nix
# Laptop that fetches builds from desktop
kernelcore.system.binary-cache = {
  enable = true;
  local = {
    enable = true;
    url = "http://192.168.15.6:5000";  # Desktop IP
    priority = 10;  # Check desktop first
  };
};
```

## Setting Up a Local Cache Server

### On the Server Machine (e.g., Desktop)

1. **Generate cache signing keys:**

```bash
sudo nix-store --generate-binary-cache-key cache-name /var/cache-priv-key.pem /var/cache-pub-key.pem
sudo chmod 600 /var/cache-priv-key.pem
sudo chmod 644 /var/cache-pub-key.pem
```

2. **Get the public key:**

```bash
cat /var/cache-pub-key.pem
# Example output: cache-name:abc123...xyz789=
```

3. **Enable nix-serve in configuration.nix:**

```nix
kernelcore.system.binary-cache = {
  enable = true;
  local.enable = true;  # This enables the config, not the server
};

# Manually enable the server
services.nix-serve = {
  enable = true;
  port = 5000;
  bindAddress = "0.0.0.0";  # Listen on all interfaces
  secretKeyFile = "/var/cache-priv-key.pem";
};

# Open firewall for cache
networking.firewall.allowedTCPPorts = [ 5000 ];
```

4. **Rebuild and verify:**

```bash
sudo nixos-rebuild switch
curl http://localhost:5000/nix-cache-info
```

### On Client Machines (e.g., Laptop)

1. **Add desktop cache to configuration.nix:**

```nix
kernelcore.system.binary-cache = {
  enable = true;
  local = {
    enable = true;
    url = "http://192.168.15.6:5000";  # Desktop IP
  };
  remote = {
    enable = true;
    trustedPublicKeys = [
      "cache-name:abc123...xyz789="  # Public key from desktop
    ];
  };
};
```

2. **Test the connection:**

```bash
curl http://192.168.15.6:5000/nix-cache-info
```

## Using Cachix

[Cachix](https://cachix.org/) is a free binary cache hosting service.

### Setup

1. **Create account at https://cachix.org/**

2. **Install cachix (optional, for publishing):**

```bash
nix-env -iA cachix -f https://cachix.org/api/v1/install
```

3. **Use a public cache:**

```nix
kernelcore.system.binary-cache = {
  enable = true;
  remote = {
    enable = true;
    substituers = [
      "https://nix-community.cachix.org"
      "https://yourcache.cachix.org"
    ];
    trustedPublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "yourcache.cachix.org-1:your-public-key-here"
    ];
  };
};
```

4. **Push to your cache (after authenticating):**

```bash
cachix push yourcache /nix/store/...
```

## Troubleshooting

### Cache Connection Errors

```
error: unable to download 'http://192.168.15.6:5000/...': Could not connect to server
```

**Solutions:**
1. Check if cache server is running:
   ```bash
   systemctl status nix-serve
   ```

2. Check firewall on server:
   ```bash
   sudo firewall-cmd --list-ports  # If using firewalld
   sudo iptables -L -n | grep 5000  # If using iptables
   ```

3. Test network connectivity:
   ```bash
   ping 192.168.15.6
   curl http://192.168.15.6:5000/nix-cache-info
   ```

4. Temporarily disable local cache:
   ```nix
   local.enable = false;
   ```

### "Untrusted public key" Errors

**Problem:** Nix refuses to use cached packages due to signature verification.

**Solution:** Add the cache's public key to `trustedPublicKeys`:

```nix
remote.trustedPublicKeys = [
  "cache-name:abc123...xyz789="
];
```

### Cache Priority

Lower priority = checked first:
- `priority = 10` - Check first (e.g., fast local cache)
- `priority = 40` - Check later (e.g., slower remote cache)
- `priority = 100` - Check last (e.g., fallback cache)

Default priorities:
- Local cache: 40
- cache.nixos.org: 40

## Advanced Configuration

### Multiple Local Caches

```nix
# Not directly supported by this module
# Use nix.settings.substituters directly:
nix.settings = {
  substituters = [
    "http://desktop.local:5000"
    "http://server.local:5000"
    "https://cache.nixos.org"
  ];
  trusted-public-keys = [
    "desktop:key1..."
    "server:key2..."
  ];
};
```

### S3-backed Cache

Use `nix-serve` with S3 backend:

```nix
services.nix-serve = {
  enable = true;
  port = 5000;
  secretKeyFile = "/var/cache-priv-key.pem";
};

# Configure S3 cache separately
```

### Testing Cache Usage

Build something and check which cache was used:

```bash
nix build --print-build-logs nixpkgs#hello 2>&1 | grep -i download
```

You should see:
```
copying path '/nix/store/...' from 'http://192.168.15.6:5000'...
```

## Security Considerations

1. **Private Network Only:** Run cache servers only on trusted networks (e.g., home LAN)
2. **Firewall:** Only open port 5000 to specific IPs if possible
3. **HTTPS:** Use HTTPS for caches on untrusted networks (not covered here)
4. **Key Protection:** Keep private signing keys secure (`chmod 600`)

## Benefits

- **Faster rebuilds** - Download instead of compile
- **Reduced CPU/disk usage** - No need to build everything
- **Shared builds** - Share between desktop and laptop
- **CI/CD optimization** - Cache GitHub Actions builds

## Monitoring

Check cache hit rate:
```bash
journalctl -u nix-serve -f  # On server
```

Check what's being fetched:
```bash
nix build --print-build-logs --option substituters http://192.168.15.6:5000
```

## References

- [NixOS Binary Cache](https://nixos.org/manual/nix/stable/package-management/binary-cache.html)
- [nix-serve Documentation](https://github.com/edolstra/nix-serve)
- [Cachix](https://cachix.org/)
