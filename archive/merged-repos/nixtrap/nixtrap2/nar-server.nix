{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enhanced NAR file server with LAN distribution capabilities

  # Custom NAR file distribution service
  systemd.services.nar-server = {
    description = "Enhanced NAR file server for LAN distribution";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "nix-serve.service"
    ];
    requires = [ "nix-serve.service" ];

    serviceConfig = {
      Type = "simple";
      User = "nar-server";
      Group = "nar-server";
      WorkingDirectory = "/var/lib/nar-server";
      ExecStart = "${pkgs.writeShellScript "nar-server" ''
        #!/bin/sh

        # NAR Server Configuration
        CACHE_DIR="/var/cache/nar-server"
        STORAGE_DIR="/var/lib/nar-server/storage"
        LOG_FILE="/var/log/nar-server.log"
        PORT=8080

        # Ensure directories exist
        mkdir -p "$CACHE_DIR" "$STORAGE_DIR" "$(dirname "$LOG_FILE")"

        # Function to log with timestamp
        log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
        }

        log "Starting NAR Server on port $PORT"

        # Create simple HTTP server using busybox httpd or socat
        while true; do
          if command -v ${pkgs.busybox}/bin/httpd >/dev/null 2>&1; then
            log "Using busybox httpd for NAR distribution"
            cd "$STORAGE_DIR"
            ${pkgs.busybox}/bin/httpd -f -p "$PORT" -h "$STORAGE_DIR"
          else
            log "Using basic server fallback"
            ${pkgs.python3}/bin/python3 -m http.server "$PORT" --directory "$STORAGE_DIR"
          fi
          
          log "NAR Server stopped, restarting in 5 seconds..."
          sleep 5
        done
      ''}";

      # Resource limits
      MemoryMax = "512M";
      MemoryHigh = "256M";
      CPUQuota = "50%";

      # Security
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      NoNewPrivileges = true;

      # Restart policy
      Restart = "always";
      RestartSec = "10s";

      # File permissions
      ReadWritePaths = [
        "/var/cache/nar-server"
        "/var/lib/nar-server"
        "/var/log"
      ];
      ReadOnlyPaths = [ "/nix/store" ];
    };
  };

  # Create nar-server user and group
  users.users.nar-server = {
    isSystemUser = true;
    group = "nar-server";
    home = "/var/lib/nar-server";
    createHome = true;
  };

  users.groups.nar-server = { };

  # NAR file management service
  systemd.services.nar-manager = {
    description = "NAR file cache management and synchronization";
    wantedBy = [ "multi-user.target" ];
    after = [ "nix-serve.service" ];

    script = ''
            #!/bin/sh
            
            STORAGE_DIR="/var/lib/nar-server/storage"
            CACHE_INFO_DIR="/var/cache/nix-serve"
            LOG_FILE="/var/log/nar-manager.log"
            
            # Ensure directories exist
            mkdir -p "$STORAGE_DIR" "$CACHE_INFO_DIR"
            
            # Function to log with timestamp
            log() {
              echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
            }
            
            log "Starting NAR cache management"
            
            # Create NAR cache info for direct access
            cat > "$STORAGE_DIR/nix-cache-info" <<EOF
      StoreDir: /nix/store
      WantMassQuery: 1
      Priority: 30
      EOF
            
            # Create index of available NAR files
            create_nar_index() {
              log "Creating NAR file index"
              find /nix/store -name "*.nar.xz" -o -name "*.nar" | head -100 > "$STORAGE_DIR/nar-index.txt"
              
              # Create symbolic links to commonly used packages
              while IFS= read -r nar_file; do
                if [ -f "$nar_file" ]; then
                  basename_nar=$(basename "$nar_file")
                  if [ ! -L "$STORAGE_DIR/$basename_nar" ]; then
                    ln -sf "$nar_file" "$STORAGE_DIR/$basename_nar" 2>/dev/null || true
                  fi
                fi
              done < "$STORAGE_DIR/nar-index.txt"
              
              log "NAR index created with $(wc -l < "$STORAGE_DIR/nar-index.txt") entries"
            }
            
            # Monitor and sync periodically
            while true; do
              create_nar_index
              
              # Clean old symlinks
              find "$STORAGE_DIR" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
              
              # Update cache statistics
              echo "$(date): $(ls -1 "$STORAGE_DIR"/*.nar* 2>/dev/null | wc -l) NAR files available" > "$STORAGE_DIR/cache-stats.txt"
              
              log "NAR cache synchronized - $(ls -1 "$STORAGE_DIR"/*.nar* 2>/dev/null | wc -l) files available"
              
              sleep 300  # Update every 5 minutes
            done
    '';

    serviceConfig = {
      Type = "simple";
      User = "nar-server";
      Group = "nar-server";
      Restart = "always";
      RestartSec = "30s";
    };
  };

  # Enhanced NGINX configuration for NAR distribution
  services.nginx.virtualHosts."nar.local" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 8443;
        ssl = true;
      }
      {
        addr = "0.0.0.0";
        port = 8080;
      }
    ];

    # SSL configuration
    sslCertificate = "/etc/nixos/certs/server.crt";
    sslCertificateKey = "/etc/nixos/certs/server.key";

    locations."/" = {
      root = "/var/lib/nar-server/storage";
      extraConfig = ''
        autoindex on;
        autoindex_format json;

        # Enable file serving optimizations
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;

        # Cache headers for NAR files
        location ~* \.(nar|nar\.xz)$ {
          expires 1d;
          add_header Cache-Control "public, immutable";
          add_header X-NAR-Server "NixOS-Local";
        }

        # Special handling for cache info
        location = /nix-cache-info {
          expires 1h;
          add_header Content-Type text/plain;
        }

        # Statistics endpoint
        location = /stats {
          alias /var/lib/nar-server/storage/cache-stats.txt;
          add_header Content-Type text/plain;
        }
      '';
    };

    # Proxy to nix-serve for dynamic requests
    locations."/nar/" = {
      proxyPass = "http://localhost:5000/nar/";
      extraConfig = ''
        proxy_cache_valid 200 1d;
        proxy_cache_valid 404 1m;
        add_header X-Cache-Status $upstream_cache_status;
      '';
    };
  };

  # Additional firewall ports for NAR server
  networking.firewall.allowedTCPPorts = [
    8080
    8443
  ];

  # Host entry for NAR server
  networking.hosts."127.0.0.1" = [ "nar.local" ];

  # Management scripts
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "nar-server-status" ''
      echo "=== NAR Server Status ==="
      echo
      echo "NAR Server (port 8080):"
      systemctl status nar-server --no-pager -l
      echo
      echo "NAR Manager:"
      systemctl status nar-manager --no-pager -l
      echo
      echo "=== Storage Statistics ==="
      if [ -f /var/lib/nar-server/storage/cache-stats.txt ]; then
        cat /var/lib/nar-server/storage/cache-stats.txt
      else
        echo "No statistics available"
      fi
      echo
      echo "=== Available NAR Files ==="
      ls -lah /var/lib/nar-server/storage/*.nar* 2>/dev/null | head -10 || echo "No NAR files found"
      echo
      echo "=== Connectivity Test ==="
      curl -s -I http://localhost:8080/ | head -1 || echo "NAR server not responding"
      curl -s -I https://nar.local:8443/ 2>/dev/null | head -1 || echo "HTTPS NAR server not responding"
    '')

    (writeShellScriptBin "nar-server-logs" ''
      echo "=== NAR Server Logs ==="
      tail -50 /var/log/nar-server.log 2>/dev/null || echo "No server logs found"
      echo
      echo "=== NAR Manager Logs ==="
      tail -50 /var/log/nar-manager.log 2>/dev/null || echo "No manager logs found"
      echo
      echo "=== Recent systemd logs ==="
      journalctl -u nar-server -u nar-manager --no-pager -l -n 20
    '')

    (writeShellScriptBin "nar-server-restart" ''
      echo "Restarting NAR server services..."
      sudo systemctl restart nar-manager
      sudo systemctl restart nar-server
      sleep 3
      echo "Services restarted"
      nar-server-status
    '')
  ];
}
