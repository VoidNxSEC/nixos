{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Binary cache server configuration
  services.nix-serve = {
    enable = true;
    port = 5000;
    bindAddress = "0.0.0.0";
    secretKeyFile = "/etc/nixos/cache-keys/cache-priv-key.pem";
    extraParams = "--priority=30 --workers=4";
  };

  # OOM Protection and systemd service hardening
  systemd.services.nix-serve = {
    serviceConfig = {
      # Memory limits (512MB per worker, 4 workers = 2GB total + overhead)
      MemoryMax = "2.5G";
      MemoryHigh = "2G";
      MemoryAccounting = true;

      # CPU limits
      CPUQuota = "200%"; # Max 2 CPU cores worth
      CPUAccounting = true;

      # Process limits
      TasksMax = 50;

      # Fix home directory issue
      User = "nix-serve";
      Group = "nix-serve";
      WorkingDirectory = "/var/cache/nix-serve";
      Environment = [
        "HOME=/var/cache/nix-serve"
        "USER=nix-serve"
      ];

      # Security hardening - relaxed for nix access
      NoNewPrivileges = true;
      ProtectHome = false; # Need access to nix store
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;

      # Network restrictions
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];

      # File system restrictions - allow nix store access
      ReadWritePaths = [
        "/tmp"
        "/var/tmp"
        "/var/cache/nix-serve"
      ];
      ReadOnlyPaths = [ "/nix/store" ];
      PrivateTmp = true;
      PrivateDevices = true;

      # Restart policy for OOM situations
      Restart = lib.mkForce "on-failure";
      RestartSec = lib.mkForce "30s";
      StartLimitIntervalSec = "5min";
      StartLimitBurst = 3;

      # OOM handling
      OOMPolicy = "stop";
      OOMScoreAdjust = 100; # Make it more likely to be killed by OOM killer

      # Disable watchdog temporarily for debugging
      # WatchdogSec = "30s";
    };
  };

  # Create nix-serve user and group
  users.users.nix-serve = {
    isSystemUser = true;
    group = "nix-serve";
    home = "/var/cache/nix-serve";
    createHome = true;
  };

  users.groups.nix-serve = { };

  # NGINX reverse proxy - simplified for testing
  services.nginx = {
    enable = true;
    virtualHosts."cache.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];

      locations."/" = {
        proxyPass = "http://localhost:5000";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Cache settings for binary cache
          proxy_cache_valid 200 1d;
          proxy_cache_valid 404 1m;
          add_header X-Cache-Status $upstream_cache_status always;
        '';
      };
    };
  };

  # Binary cache configuration for this system
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "http://cache.local" # Local cache server (HTTP for testing)
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=" # Local cache public key
    ];
    trusted-users = [
      "root"
      "voidnx"
    ];
  };

  # Firewall configuration for cache server
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      5000
    ];
    allowedUDPPorts = [ ];
  };

  # Systemd service for cache management
  systemd.services.nix-cache-info = {
    description = "Generate nix-cache-info for binary cache";
    wantedBy = [ "multi-user.target" ];
    after = [ "nix-serve.service" ];

    script = ''
      mkdir -p /var/cache/nix-serve
      echo "StoreDir: /nix/store" > /var/cache/nix-serve/nix-cache-info
      echo "WantMassQuery: 1" >> /var/cache/nix-serve/nix-cache-info
      echo "Priority: 30" >> /var/cache/nix-serve/nix-cache-info
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Health check service
  systemd.services.cache-server-health = {
    description = "Cache server health monitoring";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "cache-health-check" ''
        set -e

        # Check nix-serve is responding
        if ! ${pkgs.curl}/bin/curl -f -s -m 10 http://localhost:5000/nix-cache-info > /dev/null; then
          echo "ERROR: nix-serve not responding on port 5000"
          exit 1
        fi

        # Check nginx is responding
        if ! ${pkgs.curl}/bin/curl -f -s -m 10 -k https://cache.local/nix-cache-info > /dev/null; then
          echo "WARNING: nginx SSL proxy not responding"
        fi

        # Check memory usage
        MEMORY_PERCENT=$(${pkgs.systemd}/bin/systemctl show nix-serve --property=MemoryCurrent --value | ${pkgs.gawk}/bin/awk '{print int($1/1024/1024)}')
        if [ "$MEMORY_PERCENT" -gt 2000 ]; then
          echo "WARNING: nix-serve using more than 2GB memory: $MEMORY_PERCENT MB"
        fi

        echo "Cache server health check passed"
      ''}";
    };
  };

  # Timer for regular health checks
  systemd.timers.cache-server-health = {
    description = "Timer for cache server health checks";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5"; # Every 5 minutes
      Persistent = true;
    };
  };

  # Management scripts
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "cache-server-status" ''
      echo "=== Cache Server Status ==="
      echo
      echo "Nix-serve service:"
      systemctl status nix-serve --no-pager -l
      echo
      echo "Nginx service:"
      systemctl status nginx --no-pager -l
      echo
      echo "=== Resource Usage ==="
      echo "Memory usage:"
      systemctl show nix-serve --property=MemoryCurrent,MemoryMax,MemoryHigh
      echo
      echo "CPU usage:"
      systemctl show nix-serve --property=CPUUsageNSec
      echo
      echo "=== Health Check ==="
      systemctl start cache-server-health
      journalctl -u cache-server-health --no-pager -l -n 5
    '')

    (writeShellScriptBin "cache-server-restart" ''
      echo "Restarting cache server services..."
      systemctl restart nix-serve
      systemctl restart nginx
      sleep 5
      echo "Services restarted. Running health check..."
      systemctl start cache-server-health
    '')

    (writeShellScriptBin "cache-server-logs" ''
      echo "Recent cache server logs:"
      echo "=== Nix-serve logs ==="
      journalctl -u nix-serve --no-pager -l -n 20
      echo
      echo "=== Nginx logs ==="
      journalctl -u nginx --no-pager -l -n 20
    '')
  ];
}
