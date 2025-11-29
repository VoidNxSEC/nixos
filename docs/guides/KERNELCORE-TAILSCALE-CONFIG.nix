# Tailscale VPN Stack - Production Configuration for kernelcore
# This configuration uses your actual Tailscale credentials
# 
# ⚠️ SECURITY: Encrypt secrets file immediately after setup!
# Run: sudo sops -e -i /etc/nixos/secrets/tailscale.yaml

{ config, lib, pkgs, ... }:

{
  # ============================================
  # STEP 1: Add these imports to your flake.nix
  # ============================================
  #
  # Add to flake.nix modules list:
  #   ./modules/network/vpn/tailscale.nix
  #   ./modules/network/proxy/nginx-tailscale.nix
  #   ./modules/network/proxy/tailscale-services.nix
  #   ./modules/network/security/firewall-zones.nix
  #   ./modules/network/monitoring/tailscale-monitor.nix
  #   ./modules/secrets/tailscale.nix
  
  # ============================================
  # PRODUCTION CONFIGURATION
  # ============================================
  
  # Complete Tailscale stack with all services
  kernelcore.network.proxy.tailscale-services = {
    enable = true;
    tailnetDomain = "tailb3b82e.ts.net";  # Your actual tailnet domain
  };
  
  # This automatically configures:
  # - Tailscale VPN with mesh networking
  # - Subnet routing (192.168.15.0/24)
  # - Exit node functionality
  # - MagicDNS
  # - NGINX reverse proxy with HTTP/3
  # - Service exposure (Ollama, LlamaCPP, PostgreSQL, Gitea)
  
  # Real-time monitoring with auto-failover
  kernelcore.network.monitoring.tailscale = {
    enable = true;
    checkInterval = 30;          # Check every 30 seconds
    maxLatency = 200;            # Alert if latency > 200ms
    maxPacketLoss = 5;           # Alert if packet loss > 5%
    enableAutoFailover = true;   # Auto-switch to local network on issues
    alertEmail = null;           # Add email for alerts (optional)
  };
  
  # Advanced firewall zones
  kernelcore.network.security.firewall-zones = {
    enable = true;
    defaultPolicy = "drop";      # Drop all unmatched traffic
    enableLogging = true;        # Log dropped packets
    enableRateLimiting = true;   # Protect against DoS
  };
  
  # ============================================
  # ALTERNATIVE: Manual Fine-Tuning
  # ============================================
  # Uncomment and customize if you need more control:
  
  # Tailscale VPN (already configured by tailscale-services)
  # kernelcore.network.vpn.tailscale = {
  #   enable = true;
  #   authKeyFile = config.sops.secrets."tailscale-authkey".path;
  #   hostname = "kernelcore";
  #   
  #   # Subnet router
  #   enableSubnetRouter = true;
  #   advertiseRoutes = [ 
  #     "192.168.15.0/24"  # Local network
  #     "172.17.0.0/16"    # Docker network (optional)
  #   ];
  #   
  #   # Exit node
  #   exitNode = true;
  #   exitNodeAllowLANAccess = true;
  #   
  #   # DNS
  #   acceptDNS = true;
  #   enableMagicDNS = true;
  #   
  #   # Security tags
  #   tags = [ "tag:server" "tag:desktop" ];
  #   
  #   # Performance
  #   enableConnectionPersistence = true;
  #   reconnectTimeout = 30;
  # };
  
  # NGINX Proxy (already configured by tailscale-services)
  # kernelcore.network.proxy.nginx-tailscale = {
  #   enable = true;
  #   hostname = "kernelcore";
  #   tailnetDomain = "tailb3b82e.ts.net";
  #   enableHTTP3 = true;
  #   
  #   services = {
  #     ollama = {
  #       enable = true;
  #       subdomain = "ollama";
  #       upstreamPort = 11434;
  #       rateLimit = "20r/s";
  #       maxBodySize = "500M";
  #       timeout = 600;
  #     };
  #     
  #     llamacpp = {
  #       enable = true;
  #       subdomain = "llama";
  #       upstreamPort = 8080;
  #       rateLimit = "10r/s";
  #     };
  #     
  #     postgresql = {
  #       enable = false;  # Enable if you want to expose PostgreSQL
  #       subdomain = "db";
  #       upstreamPort = 5432;
  #       enableAuth = true;
  #     };
  #   };
  # };
}

# ============================================
# DEPLOYMENT INSTRUCTIONS
# ============================================
#
# 1. SETUP SECRETS (CRITICAL - DO THIS FIRST!)
#    ==========================================
#    The secrets file has been created at /tmp/tailscale-secrets.yaml
#    
#    a) Copy it to your secrets directory:
#       sudo cp /tmp/tailscale-secrets.yaml /etc/nixos/secrets/tailscale.yaml
#       sudo chmod 600 /etc/nixos/secrets/tailscale.yaml
#    
#    b) Encrypt immediately with SOPS:
#       sudo sops -e -i /etc/nixos/secrets/tailscale.yaml
#    
#    c) Verify encryption:
#       sudo cat /etc/nixos/secrets/tailscale.yaml
#       # Should see encrypted content, not plain text!
#    
#    d) Remove temporary file:
#       sudo rm /tmp/tailscale-secrets.yaml
#
# 2. UPDATE FLAKE.NIX
#    ==================
#    Add the module imports to your flake.nix:
#    
#    nixosConfigurations.kernelcore = nixpkgs.lib.nixosSystem {
#      modules = [
#        # ... existing modules ...
#        ./modules/network/vpn/tailscale.nix
#        ./modules/network/proxy/nginx-tailscale.nix
#        ./modules/network/proxy/tailscale-services.nix
#        ./modules/network/security/firewall-zones.nix
#        ./modules/network/monitoring/tailscale-monitor.nix
#        ./modules/secrets/tailscale.nix
#      ];
#    };
#
# 3. ADD TO CONFIGURATION.NIX
#    =========================
#    Copy the configuration above to your hosts/kernelcore/configuration.nix
#    OR use the simple one-liner:
#    
#    kernelcore.network.proxy.tailscale-services = {
#      enable = true;
#      tailnetDomain = "tailb3b82e.ts.net";
#    };
#
# 4. REBUILD SYSTEM
#    ===============
#    sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
#
# 5. VERIFY CONNECTION
#    ==================
#    tailscale status
#    tailscale ip -4
#    /etc/tailscale/health-check.sh
#
# 6. ACCESS YOUR SERVICES
#    =====================
#    Your services are now accessible at:
#    
#    • Ollama:     http://ollama.kernelcore.tailb3b82e.ts.net/api/tags
#    • LlamaCPP:   http://llama.kernelcore.tailb3b82e.ts.net/health
#    • PostgreSQL: db.kernelcore.tailb3b82e.ts.net:5432
#    • Gitea:      https://git.kernelcore.tailb3b82e.ts.net
#    
#    Or via Tailscale IP (check with: tailscale ip -4):
#    • curl http://100.64.0.x:11434/api/tags
#
# 7. CONFIGURE ACLS (OPTIONAL BUT RECOMMENDED)
#    ==========================================
#    Go to: https://login.tailscale.com/admin/acls
#    
#    Add these ACLs for security:
#    {
#      "tagOwners": {
#        "tag:server": ["autogroup:admin"],
#        "tag:client": ["autogroup:admin"]
#      },
#      "acls": [
#        {
#          "action": "accept",
#          "src": ["tag:client"],
#          "dst": ["tag:server:80,443,11434,8080,5432"]
#        }
#      ]
#    }
#
# 8. SETUP LAPTOP CLIENT (OPTIONAL)
#    ================================
#    See: docs/guides/TAILSCALE-LAPTOP-CLIENT.nix
#
# ============================================
# QUICK REFERENCE COMMANDS
# ============================================
#
# Status & Health:
#   tailscale status                    # View connection status
#   /etc/tailscale/health-check.sh      # Run full health check
#   ts-monitor-logs                     # View monitoring logs
#
# Network Quality:
#   tailscale netcheck                  # Check network quality
#   ts-benchmark                        # Run performance tests
#   tailscale ping <device>             # Ping another device
#
# Service Management:
#   systemctl status tailscaled         # Tailscale service
#   systemctl status nginx              # NGINX service
#   systemctl status tailscale-monitor  # Monitoring service
#
# NGINX:
#   nginx-test                          # Test configuration
#   nginx-reload                        # Reload after changes
#   nginx-logs                          # View all logs
#
# Firewall:
#   fw-status                           # View firewall rules
#   /etc/firewall/zone-check.sh         # Check security zones
#
# Troubleshooting:
#   journalctl -u tailscaled -f         # Tailscale logs
#   journalctl -u nginx -f              # NGINX logs
#   nft list ruleset                    # View firewall rules
#
# ============================================
# YOUR TAILSCALE INFORMATION
# ============================================
#
# Tailnet: tailb3b82e.ts.net
# Tailnet ID: TzVaCxkbJv11CNTRL
# 
# Admin Console: https://login.tailscale.com/admin/machines
# ACL Editor: https://login.tailscale.com/admin/acls
# DNS Settings: https://login.tailscale.com/admin/dns
#
# ============================================
# SECURITY NOTES
# ============================================
#
# ✅ Secrets are SOPS-encrypted
# ✅ Firewall zones protect services
# ✅ Rate limiting prevents abuse
# ✅ Auto-failover for reliability
# ✅ Real-time monitoring active
# ✅ All traffic encrypted (WireGuard + TLS)
#
# 🔐 NEVER commit unencrypted secrets to git!
# 🔐 Rotate auth keys periodically
# 🔐 Review ACLs regularly
# 🔐 Monitor logs for suspicious activity