# Dedicated Cache Server Configuration

Production-ready binary cache server with TLS, monitoring, and resource limits.

## Features

- **Binary Cache**: nix-serve with cryptographic signing
- **TLS/HTTPS**: Nginx reverse proxy with automatic cert generation
- **Resource Limits**: Memory, CPU, and process limits
- **Monitoring**: Health checks and system metrics
- **Security**: Hardened systemd service, firewall rules
- **Automatic GC**: Weekly garbage collection

## Quick Start

```bash
# 1. Deploy from flake
sudo nixos-rebuild switch --flake /path/to/nixtrap#cache-server-full

# 2. Verify services are running
cache-server-status

# 3. Test cache endpoint
curl https://cache.example.com/nix-cache-info

# 4. Get public key for clients
cat /var/cache-nix-serve/cache-pub-key.pem
```

## Client Configuration

On client machines, add to `/etc/nixos/configuration.nix`:

```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://cache.example.com"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cache.example.com:YOUR_PUBLIC_KEY_HERE"
  ];
};
```

## Resource Requirements

### Minimum
- 2 CPU cores
- 4GB RAM
- 50GB disk

### Recommended
- 4+ CPU cores
- 8GB+ RAM
- 500GB+ SSD
- 1Gbps network

## Configuration Options

### Adjust Resource Limits

```nix
services.nixos-cache-server.resources = {
  memoryMax = "8G";
  memoryHigh = "7G";
  cpuQuota = "800%"; # 8 cores
  tasksMax = 200;
};
```

### Enable HTTP Access

```nix
services.nixos-cache-server.ssl.enableHTTP = true;
```

### Use Let's Encrypt

```nix
services.nixos-cache-server.ssl = {
  certificatePath = "/var/lib/acme/cache.example.com/fullchain.pem";
  keyPath = "/var/lib/acme/cache.example.com/key.pem";
};

security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};
```

## Monitoring

```bash
# Check service status
cache-server-status

# View logs
cache-server-logs

# Restart services
cache-server-restart

# Run health check
systemctl start cache-server-health
```

## Backup

**IMPORTANT**: Always backup your signing keys!

```bash
# Backup keys
sudo cp -r /var/cache-nix-serve /backup/location/

# Restore keys
sudo cp -r /backup/location/cache-nix-serve /var/
sudo chmod 600 /var/cache-nix-serve/cache-priv-key.pem
sudo chmod 644 /var/cache-nix-serve/cache-pub-key.pem
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u nix-serve -xe
journalctl -u nginx -xe

# Verify key file exists
ls -la /var/cache-nix-serve/

# Test nix-serve directly
curl http://localhost:5000/nix-cache-info
```

### High Memory Usage

Adjust resource limits:

```nix
services.nixos-cache-server.resources.memoryMax = "6G";
services.nixos-cache-server.workers = 4; # Reduce workers
```

### Clients Can't Connect

```bash
# Check firewall
sudo iptables -L -n

# Test from client
curl -k https://cache.example.com/nix-cache-info

# Verify nginx is running
systemctl status nginx
```

## Security Best Practices

1. **Use real SSL certificates** in production (Let's Encrypt)
2. **Backup signing keys** regularly
3. **Enable firewall** (only ports 22 and 443)
4. **Disable root SSH login**
5. **Keep system updated**: `nix-channel --update && nixos-rebuild switch`
6. **Monitor resource usage**: Check logs regularly
