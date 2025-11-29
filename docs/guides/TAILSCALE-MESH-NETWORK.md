# Tailscale Mesh Network - Complete Implementation Guide

## 🎯 Overview

This guide covers the complete Tailscale VPN implementation with NGINX reverse proxy, advanced security zones, mesh networking, exit nodes, and full service integration for your NixOS system.

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Security & ACLs](#security--acls)
6. [Service Exposure](#service-exposure)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)
9. [Performance Optimization](#performance-optimization)
10. [Advanced Features](#advanced-features)

---

## 🏗️ Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    Tailscale Mesh Network                    │
│                     (100.64.0.0/10 CGNAT)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Desktop    │◄───────►│    Laptop    │                 │
│  │ kernelcore   │         │  (Client)    │                 │
│  │ 100.64.0.1   │         │ 100.64.0.2   │                 │
│  │              │         │              │                 │
│  │ • Exit Node  │         │ • Routes via │                 │
│  │ • Sub Router │         │   Desktop    │                 │
│  │ • Services   │         │              │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                                                    │
│         │ Advertises 192.168.15.0/24                       │
│         ▼                                                    │
│  ┌─────────────────────────────────┐                       │
│  │    Local Network Services       │                       │
│  │    192.168.15.0/24              │                       │
│  └─────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Security Zones

1. **DMZ Zone**: Exposed services (HTTP/HTTPS)
2. **Internal Zone**: Trusted Tailscale network
3. **Admin Zone**: Management access
4. **Isolated Zone**: Untrusted workloads

### Service Architecture

```
Remote Client → Tailscale → NGINX Proxy → Local Service
                   (VPN)      (TLS/HTTP3)   (ollama, etc)
```

---

## 📦 Prerequisites

### Required Accounts & Keys

1. **Tailscale Account**: Sign up at https://tailscale.com
2. **Auth Key**: Generate at https://login.tailscale.com/admin/settings/keys
   - Create a reusable key
   - Set appropriate expiration
   - Note the key format: `tskey-auth-xxxxx-yyyyyyy`

### System Requirements

- NixOS 23.11 or later
- SOPS for secrets management
- Minimum 2GB RAM
- Network connectivity

---

## 🚀 Installation

### Step 1: Add Modules to Your Configuration

Add to your `flake.nix` imports:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        # ... your existing modules
        ./modules/network/vpn/tailscale.nix
        ./modules/network/proxy/nginx-tailscale.nix
        ./modules/network/proxy/tailscale-services.nix
        ./modules/network/security/firewall-zones.nix
        ./modules/network/monitoring/tailscale-monitor.nix
        ./modules/secrets/tailscale.nix
        sops-nix.nixosModules.sops
      ];
    };
  };
}
```

### Step 2: Configure Secrets

Create and encrypt your Tailscale secrets:

```bash
# Create secrets file
sudo nano /etc/nixos/secrets/tailscale.yaml

# Add your auth key:
# authkey: tskey-auth-xxxxx-yyyyyyy
# preauthkey: tskey-auth-xxxxx-yyyyyyy (optional)
# api_token: your-api-token (optional)
# tailnet: your-tailnet-name.ts.net

# Encrypt with SOPS
sudo sops -e -i /etc/nixos/secrets/tailscale.yaml
```

### Step 3: Enable in Configuration

Add to your `configuration.nix`:

```nix
{
  # Enable complete Tailscale stack
  kernelcore.network.proxy.tailscale-services = {
    enable = true;
    tailnetDomain = "your-tailnet-name.ts.net";  # Replace with your tailnet
  };
  
  # Enable monitoring
  kernelcore.network.monitoring.tailscale = {
    enable = true;
    checkInterval = 30;
    maxLatency = 200;
    maxPacketLoss = 5;
    enableAutoFailover = true;
  };
  
  # Enable firewall zones
  kernelcore.network.security.firewall-zones = {
    enable = true;
    defaultPolicy = "drop";
    enableLogging = true;
  };
}
```

### Step 4: Rebuild System

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Step 5: Verify Connection

```bash
# Check Tailscale status
tailscale status

# View assigned IP
tailscale ip -4

# Test connectivity
tailscale ping kernelcore

# Check network quality
tailscale netcheck
```

---

## ⚙️ Configuration

### Basic Tailscale Setup

```nix
kernelcore.network.vpn.tailscale = {
  enable = true;
  
  # Authentication
  authKeyFile = config.sops.secrets."tailscale-authkey".path;
  useAuthKeyFile = true;
  
  # Hostname
  hostname = "kernelcore";
  
  # Subnet routing
  enableSubnetRouter = true;
  advertiseRoutes = [ "192.168.15.0/24" ];
  
  # Exit node
  exitNode = true;
  exitNodeAllowLANAccess = true;
  
  # DNS
  acceptDNS = true;
  enableMagicDNS = true;
  
  # Security tags
  tags = [ "tag:server" "tag:desktop" ];
};
```

### NGINX Proxy Configuration

```nix
kernelcore.network.proxy.nginx-tailscale = {
  enable = true;
  hostname = "kernelcore";
  tailnetDomain = "your-tailnet.ts.net";
  
  # Performance
  enableHTTP3 = true;
  enableConnectionPooling = true;
  
  # Services
  services = {
    ollama = {
      enable = true;
      subdomain = "ollama";
      upstreamPort = 11434;
      rateLimit = "20r/s";
      maxBodySize = "500M";
    };
    
    llamacpp = {
      enable = true;
      subdomain = "llama";
      upstreamPort = 8080;
      rateLimit = "10r/s";
    };
  };
};
```

### Firewall Zones

```nix
kernelcore.network.security.firewall-zones = {
  enable = true;
  
  zones = {
    dmz = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 443 ]; # QUIC
    };
    
    internal = {
      enable = true;
      interfaces = [ "tailscale0" ];
      allowedServices = [ "ssh" "postgresql" "ollama" ];
    };
    
    admin = {
      enable = true;
      allowedIPs = [ "100.64.0.0/10" ];
      allowAllServices = true;
    };
  };
};
```

---

## 🔒 Security & ACLs

### Tailscale ACL Configuration

Configure ACLs in the Tailscale admin console (https://login.tailscale.com/admin/acls):

```json
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:client": ["autogroup:admin"],
    "tag:laptop": ["autogroup:admin"]
  },
  
  "acls": [
    // Allow all admin access
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["*:*"]
    },
    
    // Allow clients to access server services
    {
      "action": "accept",
      "src": ["tag:client", "tag:laptop"],
      "dst": ["tag:server:80,443,11434,8080,5432"]
    },
    
    // Deny direct access to sensitive ports
    {
      "action": "reject",
      "src": ["tag:client"],
      "dst": ["tag:server:22"]
    }
  ],
  
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:server"],
      "users": ["root", "kernelcore"]
    }
  ]
}
```

### Best Practices

1. **Use Tags**: Organize devices with meaningful tags
2. **Principle of Least Privilege**: Grant minimal necessary access
3. **Regular Audits**: Review ACLs monthly
4. **Enable MFA**: Require multi-factor authentication
5. **Monitor Logs**: Check access logs regularly

---

## 🌐 Service Exposure

### Accessing Services

Once configured, services are accessible via:

**Via MagicDNS:**
```bash
# Ollama
curl http://ollama.kernelcore.your-tailnet.ts.net/api/tags

# LlamaCPP
curl http://llama.kernelcore.your-tailnet.ts.net/health

# PostgreSQL
psql -h db.kernelcore.your-tailnet.ts.net -U postgres
```

**Via Tailscale IP:**
```bash
# Find your desktop's Tailscale IP
tailscale ip -4

# Access services directly
curl http://100.64.0.1:11434/api/tags
```

### Adding New Services

To expose a new service:

1. Add to NGINX configuration:

```nix
kernelcore.network.proxy.nginx-tailscale.services.myservice = {
  enable = true;
  subdomain = "myservice";
  upstreamPort = 8000;
  rateLimit = "10r/s";
  maxBodySize = "100M";
  enableAuth = true;  # If authentication needed
};
```

2. Rebuild: `sudo nixos-rebuild switch`

3. Access: `http://myservice.kernelcore.your-tailnet.ts.net`

---

## 📊 Monitoring

### Health Checks

```bash
# Overall Tailscale status
ts-status

# Connection quality
ts-quality

# Monitor logs
ts-monitor-logs

# Benchmark performance
ts-benchmark

# Firewall zones
fw-status
```

### Monitoring Service

The monitoring service continuously checks:
- Connection latency
- Packet loss
- Service availability
- Network quality

View monitoring dashboard:
```bash
/etc/tailscale/monitoring-check.sh
```

### Auto-Failover

When connection quality degrades:
1. Monitor detects poor performance
2. After 3 consecutive failures, triggers failover
3. Switches to local network
4. Attempts to restore Tailscale periodically
5. Sends alert (if configured)

Configure failover thresholds:
```nix
kernelcore.network.monitoring.tailscale = {
  maxLatency = 200;  # milliseconds
  maxPacketLoss = 5;  # percent
  checkInterval = 30;  # seconds
};
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Tailscale Not Connecting

```bash
# Check service status
systemctl status tailscaled

# View logs
journalctl -u tailscaled -f

# Restart service
sudo systemctl restart tailscaled

# Force reconnection
sudo tailscale up --reset
```

#### 2. Services Not Accessible

```bash
# Check NGINX status
systemctl status nginx

# Test NGINX configuration
nginx-test

# View NGINX logs
nginx-logs

# Check firewall
fw-status
```

#### 3. Poor Performance

```bash
# Run benchmark
ts-benchmark

# Check network quality
tailscale netcheck

# Monitor real-time
ts-monitor-logs
```

#### 4. DNS Not Resolving

```bash
# Check MagicDNS status
tailscale status --json | jq '.MagicDNSSuffix'

# Test resolution
nslookup kernelcore.your-tailnet.ts.net

# Restart resolved
sudo systemctl restart systemd-resolved
```

### Debug Mode

Enable verbose logging:
```nix
systemd.services.tailscaled.environment = {
  TS_DEBUG_FIREWALL_MODE = "true";
};
```

---

## ⚡ Performance Optimization

### Network Tuning

```nix
# Kernel parameters for optimal performance
boot.kernel.sysctl = {
  # TCP optimization
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_rmem" = "4096 87380 67108864";
  "net.ipv4.tcp_wmem" = "4096 65536 67108864";
  
  # UDP optimization  
  "net.core.netdev_max_backlog" = 5000;
  
  # Connection tracking
  "net.netfilter.nf_conntrack_max" = 524288;
};
```

### NGINX Tuning

```nix
services.nginx = {
  appendConfig = ''
    worker_processes auto;
    worker_rlimit_nofile 65535;
    
    events {
      worker_connections 4096;
      use epoll;
      multi_accept on;
    }
  '';
};
```

### Monitoring Optimization

For low-resource systems:
```nix
kernelcore.network.monitoring.tailscale = {
  checkInterval = 60;  # Check less frequently
  enableAutoFailover = false;  # Disable if not needed
};
```

---

## 🚀 Advanced Features

### Docker Container Access

Access Docker containers via Tailscale:

```nix
# Enable Docker subnet in Tailscale
kernelcore.network.vpn.tailscale = {
  advertiseRoutes = [ 
    "192.168.15.0/24"  # Local network
    "172.17.0.0/16"    # Docker network
  ];
};
```

Access containers:
```bash
# From laptop
curl http://172.17.0.2:8000  # Container IP
```

### Multi-Exit Node Setup

Configure multiple exit nodes:

```bash
# List available exit nodes
tailscale exit-node list

# Use specific exit node
tailscale set --exit-node=kernelcore

# Switch exit nodes
tailscale set --exit-node=other-server

# Disable exit node
tailscale set --exit-node=
```

### Split DNS Configuration

Route specific domains through Tailscale:

```nix
services.resolved.extraConfig = ''
  [Resolve]
  DNS=100.100.100.100
  Domains=~your-tailnet.ts.net
'';
```

### Bandwidth Limits

Limit bandwidth for exit node traffic:

```bash
# Use tc (traffic control) for QoS
sudo tc qdisc add dev tailscale0 root tbf rate 10mbit burst 32kbit latency 400ms
```

---

## 📚 Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [nftables Wiki](https://wiki.nftables.org/)

## 🆘 Support

For issues or questions:
1. Check logs: `journalctl -u tailscaled -f`
2. Run diagnostics: `/etc/tailscale/health-check.sh`
3. Review this guide's troubleshooting section
4. Check Tailscale status page: https://status.tailscale.com/

---

**Last Updated**: 2025-11-26  
**Version**: 1.0.0  
**Author**: NixOS Tailscale Integration Team