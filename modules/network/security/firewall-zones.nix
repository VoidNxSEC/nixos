{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.security.firewall-zones;
in
{
  options.kernelcore.network.security.firewall-zones = {
    enable = mkEnableOption "Enable firewall security zones with nftables";
    
    # Zone Definitions
    zones = {
      dmz = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable DMZ zone for exposed services";
        };
        
        interfaces = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Network interfaces in DMZ zone";
          example = [ "eth0" ];
        };
        
        allowedTCPPorts = mkOption {
          type = types.listOf types.port;
          default = [ 80 443 ];
          description = "TCP ports allowed from DMZ";
        };
        
        allowedUDPPorts = mkOption {
          type = types.listOf types.port;
          default = [ 443 ]; # QUIC/HTTP3
          description = "UDP ports allowed from DMZ";
        };
      };
      
      internal = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable internal zone for private workloads";
        };
        
        interfaces = mkOption {
          type = types.listOf types.str;
          default = [ "tailscale0" ];
          description = "Network interfaces in internal zone";
        };
        
        allowedServices = mkOption {
          type = types.listOf types.str;
          default = [ "ssh" "postgresql" "ollama" "docker" ];
          description = "Services allowed from internal zone";
        };
      };
      
      admin = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable admin zone for management traffic";
        };
        
        allowedIPs = mkOption {
          type = types.listOf types.str;
          default = [ "100.64.0.0/10" ]; # Tailscale CGNAT range
          description = "IP addresses/ranges allowed in admin zone";
        };
        
        allowAllServices = mkOption {
          type = types.bool;
          default = true;
          description = "Allow all services from admin zone";
        };
      };
      
      isolated = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable isolated zone for untrusted workloads";
        };
        
        interfaces = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Network interfaces in isolated zone";
        };
        
        denyInterzone = mkOption {
          type = types.bool;
          default = true;
          description = "Deny traffic to other zones from isolated";
        };
      };
    };
    
    # Global Zone Settings
    defaultPolicy = mkOption {
      type = types.enum [ "drop" "reject" "accept" ];
      default = "drop";
      description = "Default policy for unmatched traffic";
    };
    
    enableLogging = mkOption {
      type = types.bool;
      default = true;
      description = "Enable logging of dropped packets";
    };
    
    logPrefix = mkOption {
      type = types.str;
      default = "[FW-ZONE]";
      description = "Prefix for firewall logs";
    };
    
    # Rate Limiting
    enableRateLimiting = mkOption {
      type = types.bool;
      default = true;
      description = "Enable rate limiting for connection attempts";
    };
    
    rateLimitBurst = mkOption {
      type = types.int;
      default = 10;
      description = "Burst size for rate limiting";
    };
  };
  
  config = mkIf cfg.enable {
    # Use nftables for advanced firewall features
    networking.nftables = {
      enable = true;
      
      ruleset = ''
        # Flush existing rules
        flush ruleset
        
        # Define tables
        table inet filter {
          # Define zones as sets
          ${optionalString (cfg.zones.dmz.interfaces != []) ''
          set dmz_interfaces {
            type ifname
            elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') cfg.zones.dmz.interfaces)} }
          }
          ''}

          ${optionalString (cfg.zones.internal.interfaces != []) ''
          set internal_interfaces {
            type ifname
            elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') cfg.zones.internal.interfaces)} }
          }
          ''}

          ${optionalString (cfg.zones.admin.allowedIPs != []) ''
          set admin_ips {
            type ipv4_addr
            flags interval
            elements = { ${concatStringsSep ", " cfg.zones.admin.allowedIPs} }
          }
          ''}
          
          # Input chain - traffic TO this host
          chain input {
            type filter hook input priority filter; policy ${cfg.defaultPolicy};
            
            # Allow established/related connections
            ct state {established, related} accept
            ct state invalid drop
            
            # Allow loopback
            iif lo accept
            
            # Allow ICMPv6 for neighbor discovery
            ip6 nexthdr icmpv6 icmpv6 type {
              nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert
            } accept
            
            # ADMIN ZONE - Full access
            ${optionalString (cfg.zones.admin.enable && cfg.zones.admin.allowedIPs != []) ''
              # Allow from admin IP ranges
              ip saddr @admin_ips accept comment "Admin zone - full access"
            ''}
            
            # INTERNAL ZONE - Trusted services
            ${optionalString (cfg.zones.internal.enable && cfg.zones.internal.interfaces != []) ''
              # Allow from internal interfaces (Tailscale)
              iifname @internal_interfaces accept comment "Internal zone - trusted"
            ''}
            
            # DMZ ZONE - Limited public access
            ${optionalString (cfg.zones.dmz.enable && cfg.zones.dmz.interfaces != []) ''
              # Allow specific ports from DMZ
              iifname @dmz_interfaces tcp dport { ${concatStringsSep ", " (map toString cfg.zones.dmz.allowedTCPPorts)} } accept
              iifname @dmz_interfaces udp dport { ${concatStringsSep ", " (map toString cfg.zones.dmz.allowedUDPPorts)} } accept
            ''}
            
            # Rate limiting
            ${optionalString cfg.enableRateLimiting ''
              # Limit new connections
              ct state new limit rate over 100/second burst ${toString cfg.rateLimitBurst} packets drop comment "Rate limit exceeded"
            ''}
            
            # Logging
            ${optionalString cfg.enableLogging ''
              # Log dropped packets
              limit rate 10/minute log prefix "${cfg.logPrefix} DROP: " level warn
            ''}
          }
          
          # Forward chain - traffic THROUGH this host
          chain forward {
            type filter hook forward priority filter; policy ${cfg.defaultPolicy};
            
            # Allow established/related
            ct state {established, related} accept
            ct state invalid drop
            
            # ISOLATED ZONE - Deny interzone traffic
            ${optionalString (cfg.zones.isolated.enable && cfg.zones.isolated.denyInterzone) ''
              # Deny traffic from isolated zone to other zones
              iifname { ${concatStringsSep ", " (map (x: ''"${x}"'') cfg.zones.isolated.interfaces)} } drop comment "Isolated zone - no interzone"
            ''}
            
            # Allow forwarding for Tailscale (internal zone)
            ${optionalString (cfg.zones.internal.enable && cfg.zones.internal.interfaces != []) ''
              iifname @internal_interfaces accept comment "Internal zone forwarding"
              oifname @internal_interfaces accept comment "Internal zone forwarding"
            ''}
            
            # Logging
            ${optionalString cfg.enableLogging ''
              limit rate 10/minute log prefix "${cfg.logPrefix} FORWARD DROP: " level warn
            ''}
          }
          
          # Output chain - traffic FROM this host
          chain output {
            type filter hook output priority filter; policy accept;
            
            # Allow all outgoing by default
            # Can be restricted further if needed
          }
        }
        
        # NAT table for masquerading
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            
            # Masquerade for Tailscale exit node
            oifname "tailscale0" masquerade comment "Tailscale exit node NAT"
          }
        }
      '';
    };
    
    # Integration with existing firewall
    networking.firewall = {
      enable = mkForce false; # Use nftables instead
      # Note: nftables replaces iptables-based firewall
    };
    
    # Management scripts
    environment.systemPackages = with pkgs; [
      nftables
    ];
    
    environment.shellAliases = {
      fw-status = "sudo nft list ruleset";
      fw-zones = "sudo nft list sets";
      fw-stats = "sudo nft list table inet filter";
      fw-reload = "sudo systemctl reload nftables";
      fw-logs = "journalctl -k | grep '${cfg.logPrefix}'";
    };
    
    # Firewall zone check script
    environment.etc."firewall/zone-check.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Firewall zone status check
        
        set -euo pipefail
        
        echo "======================================"
        echo "    FIREWALL ZONES STATUS"
        echo "======================================"
        echo ""
        
        # Check nftables status
        if systemctl is-active --quiet nftables; then
          echo "✓ nftables: Active"
        else
          echo "✗ nftables: Inactive"
          exit 1
        fi
        
        echo ""
        echo "Active Zones:"
        echo "-------------"
        
        ${optionalString cfg.zones.dmz.enable ''
          echo "• DMZ Zone: Enabled"
          echo "  Interfaces: ${concatStringsSep ", " cfg.zones.dmz.interfaces}"
          echo "  TCP Ports: ${concatStringsSep ", " (map toString cfg.zones.dmz.allowedTCPPorts)}"
        ''}
        
        ${optionalString cfg.zones.internal.enable ''
          echo "• Internal Zone: Enabled"
          echo "  Interfaces: ${concatStringsSep ", " cfg.zones.internal.interfaces}"
          echo "  Services: ${concatStringsSep ", " cfg.zones.internal.allowedServices}"
        ''}
        
        ${optionalString cfg.zones.admin.enable ''
          echo "• Admin Zone: Enabled"
          echo "  Allowed IPs: ${concatStringsSep ", " cfg.zones.admin.allowedIPs}"
        ''}
        
        ${optionalString cfg.zones.isolated.enable ''
          echo "• Isolated Zone: Enabled"
          echo "  Interfaces: ${concatStringsSep ", " cfg.zones.isolated.interfaces}"
          echo "  Interzone: ${if cfg.zones.isolated.denyInterzone then "Denied" else "Allowed"}"
        ''}
        
        echo ""
        echo "======================================"
      '';
    };
    
    # Warnings
    warnings = 
      (optional (cfg.zones.dmz.enable && cfg.zones.dmz.interfaces == [ ])
        "DMZ zone is enabled but no interfaces are configured."
      ) ++
      (optional (cfg.zones.isolated.enable && cfg.zones.isolated.interfaces == [ ])
        "Isolated zone is enabled but no interfaces are configured."
      );
  };
}