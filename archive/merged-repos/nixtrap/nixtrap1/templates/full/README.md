# Full-Featured NixOS Cache Server Template

This template provides a complete NixOS cache server with monitoring, API, and observability.

## Features

- ✅ Nix binary cache server (nix-serve)
- ✅ TLS/HTTPS via nginx reverse proxy
- ✅ Automatic cache signing with key generation
- ✅ REST API for metrics and health checks
- ✅ Prometheus monitoring
- ✅ Node Exporter for system metrics
- ✅ Nginx Exporter for web server metrics
- ✅ Grafana dashboards
- ✅ Alerting rules for common issues
- ✅ Hardened systemd services
- ✅ Automatic garbage collection
- ✅ Store optimization
- ✅ Helper scripts for monitoring and health checks

## Quick Start

### 1. Copy Template

```bash
nix flake init -t github:yourusername/nixtrap#full
```

### 2. Generate Hardware Configuration

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

### 3. Customize Configuration

Edit `flake.nix` and update:

- **hostName**: Your domain name (e.g., `cache.example.com`)
- **boot.loader.grub.device**: Your boot device (e.g., `/dev/sda`)
- **time.timeZone**: Your timezone
- **users.users.admin.openssh.authorizedKeys.keys**: Your SSH public keys
- **services.nixos-cache-monitoring.grafana.adminPassword**: Strong password

### 4. Install

```bash
nixos-install --flake .#cache-server
```

### 5. Reboot

```bash
reboot
```

## Post-Installation

### Get Cache Public Key

```bash
cat /var/cache-nix-serve/cache-pub-key.pem
```

### View Cache Information

```bash
/etc/nixos-cache/scripts/show-cache-info.sh
```

### Health Check

```bash
/etc/nixos-cache/scripts/health-check.sh
```

### Real-Time Monitoring

```bash
/etc/nixos-cache/scripts/monitor.sh
```

## Accessing Services

### Cache Server

- **URL**: `https://cache.example.com`
- **Info**: `https://cache.example.com/nix-cache-info`

### API Endpoints

- **Metrics**: `http://localhost:8080/api/metrics`
- **Health**: `http://localhost:8080/api/health`
- **Logs**: `http://localhost:8080/api/logs`

### Monitoring (via SSH tunnel)

```bash
# Prometheus
ssh -L 9090:localhost:9090 admin@cache.example.com
# Access: http://localhost:9090

# Grafana
ssh -L 3000:localhost:3000 admin@cache.example.com
# Access: http://localhost:3000
```

## Client Configuration

Add to your client's `configuration.nix`:

```nix
{
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
}
```

## Monitoring Alerts

Pre-configured alerts:

- **HighDiskUsage**: Disk usage > 85%
- **NixServeDown**: nix-serve service stopped
- **NginxDown**: nginx service stopped
- **HighMemoryUsage**: Memory usage > 90%
- **HighCPUUsage**: CPU usage > 80% for 10 minutes
- **HighLoadAverage**: Load average too high

## Maintenance

### Manual Garbage Collection

```bash
sudo nix-collect-garbage -d
```

### Update System

```bash
sudo nixos-rebuild switch --flake /etc/nixos
```

### View Service Logs

```bash
journalctl -u nix-serve -f
journalctl -u nginx -f
journalctl -u nixos-cache-api -f
```

## Security Considerations

1. **Change Grafana password** immediately after installation
2. **Add SSH keys** instead of using passwords
3. **Use Let's Encrypt** for production (replace self-signed certs)
4. **Keep monitoring ports internal** (use SSH tunneling)
5. **Backup private keys** from `/var/cache-nix-serve/`
6. **Enable automatic updates** or schedule regular updates
7. **Monitor alerts** and set up notifications

## Backup

Important files to backup:

```bash
/var/cache-nix-serve/cache-priv-key.pem  # Cache signing key (CRITICAL)
/var/cache-nix-serve/cache-pub-key.pem   # Public key
/var/lib/nixos-cache/                    # SSL certificates
```

## Troubleshooting

### Cache not working

```bash
# Check service status
systemctl status nix-serve
systemctl status nginx

# Test cache endpoint
curl http://localhost:5000/nix-cache-info
curl https://cache.example.com/nix-cache-info
```

### High disk usage

```bash
# Check disk usage
df -h /nix/store

# Manual cleanup
sudo nix-collect-garbage -d
sudo nix-store --gc

# Optimize store
sudo nix-store --optimise
```

### Check logs

```bash
journalctl -u nix-serve --since today
journalctl -u nginx --since today
journalctl -u nixos-cache-api --since today
```

## Performance Tuning

### Adjust workers based on CPU

```nix
services.nixos-cache-server.workers = 8; # Set to CPU count
```

### Increase cache size

```nix
services.nixos-cache-server.storage.maxSize = "500G";
```

### Adjust retention

```nix
services.nixos-cache-monitoring.prometheus.retention = "90d";
```

## Support

- Documentation: [GitHub Repository](https://github.com/yourusername/nixtrap)
- Issues: [GitHub Issues](https://github.com/yourusername/nixtrap/issues)
- NixOS Manual: https://nixos.org/manual/
