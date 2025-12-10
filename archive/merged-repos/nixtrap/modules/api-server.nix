{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.nixos-cache-api;

  # API server script
  apiServerScript = pkgs.writeShellScript "cache-api-server" ''
    #!/usr/bin/env bash
    # ============================================================================
    # API Server para Monitoramento
    # Expõe métricas do servidor via HTTP JSON para consumo do app React
    # ============================================================================

    set -euo pipefail

    PORT=${toString cfg.port}
    LOG_FILE="${cfg.logFile}"

    log() {
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
    }

    # Função para coletar métricas do sistema
    collect_metrics() {
        cat <<EOF
    {
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "system": {
        "hostname": "$(hostname)",
        "uptime_seconds": $(cat /proc/uptime | awk '{print int($1)}'),
        "load_average": {
          "1min": $(${pkgs.procps}/bin/uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs),
          "5min": $(${pkgs.procps}/bin/uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | xargs),
          "15min": $(${pkgs.procps}/bin/uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | xargs)
        }
      },
      "cpu": {
        "count": $(${pkgs.coreutils}/bin/nproc),
        "usage_percent": $(${pkgs.procps}/bin/top -bn1 | ${pkgs.gnugrep}/bin/grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
      },
      "memory": {
        "total_gb": $(${pkgs.procps}/bin/free -g | ${pkgs.gnugrep}/bin/grep Mem | awk '{print $2}'),
        "used_gb": $(${pkgs.procps}/bin/free -g | ${pkgs.gnugrep}/bin/grep Mem | awk '{print $3}'),
        "available_gb": $(${pkgs.procps}/bin/free -g | ${pkgs.gnugrep}/bin/grep Mem | awk '{print $7}'),
        "used_percent": $(${pkgs.procps}/bin/free | ${pkgs.gnugrep}/bin/grep Mem | awk '{printf "%.1f", $3/$2*100}')
      },
      "disk": {
        "root": {
          "total": "$(${pkgs.coreutils}/bin/df -h / | tail -1 | awk '{print $2}')",
          "used": "$(${pkgs.coreutils}/bin/df -h / | tail -1 | awk '{print $3}')",
          "available": "$(${pkgs.coreutils}/bin/df -h / | tail -1 | awk '{print $4}')",
          "used_percent": "$(${pkgs.coreutils}/bin/df -h / | tail -1 | awk '{print $5}')"
        },
        "nix_store": {
          "size": "$(${pkgs.coreutils}/bin/du -sh /nix/store 2>/dev/null | awk '{print $1}')",
          "path_count": $(${pkgs.findutils}/bin/find /nix/store -maxdepth 1 -type d 2>/dev/null | ${pkgs.coreutils}/bin/wc -l)
        }
      },
      "network": {
        "connections": {
          "established": $(${pkgs.iproute2}/bin/ss -tan | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l),
          "time_wait": $(${pkgs.iproute2}/bin/ss -tan | ${pkgs.gnugrep}/bin/grep TIME-WAIT | ${pkgs.coreutils}/bin/wc -l),
          "listen": $(${pkgs.iproute2}/bin/ss -tln | ${pkgs.gnugrep}/bin/grep LISTEN | ${pkgs.coreutils}/bin/wc -l)
        },
        "interfaces": [
          $(${pkgs.iproute2}/bin/ip -j addr show | ${pkgs.jq}/bin/jq -c '.[] | select(.operstate == "UP") | {name: .ifname, ip: .addr_info[0].local}' | paste -sd,)
        ]
      },
      "services": {
        "nix_serve": {
          "active": $(${pkgs.systemd}/bin/systemctl is-active nix-serve 2>/dev/null || echo "inactive"),
          "memory_mb": $(${pkgs.systemd}/bin/systemctl show nix-serve -p MemoryCurrent 2>/dev/null | cut -d= -f2 | awk '{printf "%.0f", $1/1024/1024}')
        },
        "nginx": {
          "active": $(${pkgs.systemd}/bin/systemctl is-active nginx 2>/dev/null || echo "inactive"),
          "memory_mb": $(${pkgs.systemd}/bin/systemctl show nginx -p MemoryCurrent 2>/dev/null | cut -d= -f2 | awk '{printf "%.0f", $1/1024/1024}')
        },
        "prometheus": {
          "active": $(${pkgs.systemd}/bin/systemctl is-active prometheus 2>/dev/null || echo "inactive")
        }
      },
      "cache": {
        "recent_builds": [
          $(${pkgs.systemd}/bin/journalctl -u nix-daemon --since "10 minutes ago" --no-pager -o json | ${pkgs.gnugrep}/bin/grep -i "building\|built" | tail -5 | ${pkgs.jq}/bin/jq -c '{time: .["__REALTIME_TIMESTAMP"], message: .MESSAGE}' | paste -sd, 2>/dev/null || echo "")
        ]
      }
    }
    EOF
    }

    # Função para health check
    health_check() {
        local status="healthy"
        local issues=[]

        # Check disk space
        disk_usage=$(${pkgs.coreutils}/bin/df / | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt 85 ]; then
            status="warning"
            issues+=("Disk usage above 85%")
        fi

        # Check services
        if ! ${pkgs.systemd}/bin/systemctl is-active nix-serve &>/dev/null; then
            status="unhealthy"
            issues+=("nix-serve not running")
        fi

        if ! ${pkgs.systemd}/bin/systemctl is-active nginx &>/dev/null; then
            status="unhealthy"
            issues+=("nginx not running")
        fi

        cat <<EOF
    {
      "status": "$status",
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "checks": {
        "disk_space": $([ "$disk_usage" -lt 85 ] && echo "true" || echo "false"),
        "nix_serve": $(${pkgs.systemd}/bin/systemctl is-active nix-serve &>/dev/null && echo "true" || echo "false"),
        "nginx": $(${pkgs.systemd}/bin/systemctl is-active nginx &>/dev/null && echo "true" || echo "false")
      }
    }
    EOF
    }

    # HTTP handler simples
    handle_request() {
        local method=$1
        local path=$2

        case "$path" in
            "/api/metrics")
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: application/json"
                echo "Access-Control-Allow-Origin: *"
                echo ""
                collect_metrics
                ;;
            "/api/health")
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: application/json"
                echo "Access-Control-Allow-Origin: *"
                echo ""
                health_check
                ;;
            "/api/logs")
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: application/json"
                echo "Access-Control-Allow-Origin: *"
                echo ""
                echo '{"logs": ['
                ${pkgs.systemd}/bin/journalctl -u nix-daemon --since "1 hour ago" --no-pager -o json -n 50 | \
                    ${pkgs.jq}/bin/jq -c '{time: .["__REALTIME_TIMESTAMP"], priority: .PRIORITY, message: .MESSAGE}' | \
                    paste -sd,
                echo ']}'
                ;;
            *)
                echo "HTTP/1.1 404 Not Found"
                echo "Content-Type: application/json"
                echo ""
                echo '{"error": "Endpoint not found"}'
                ;;
        esac
    }

    # Server loop
    log "Starting NixOS Cache API Server on port $PORT"

    while true; do
        # Listen usando nc (netcat)
        {
            read -r request_line
            method=$(echo "$request_line" | awk '{print $1}')
            path=$(echo "$request_line" | awk '{print $2}')

            # Skip headers
            while read -r line; do
                [ -z "$line" ] || [ "$line" = $'\r' ] && break
            done

            log "Request: $method $path"
            handle_request "$method" "$path"
        } | ${pkgs.netcat}/bin/nc -l -p "$PORT" -q 1
    done
  '';

in
{
  options.services.nixos-cache-api = {
    enable = mkEnableOption "NixOS Cache API Server";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the API server to listen on";
    };

    logFile = mkOption {
      type = types.path;
      default = "/var/log/nixos-cache-api.log";
      description = "Path to the log file";
    };

    user = mkOption {
      type = types.str;
      default = "nixos-cache-api";
      description = "User to run the API server as";
    };

    group = mkOption {
      type = types.str;
      default = "nixos-cache-api";
      description = "Group to run the API server as";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port for the API server";
    };

    extraAllowedIPs = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.1" ];
      description = "Extra IPs allowed to access the API (nginx config)";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "NixOS Cache API Server user";
    };

    users.groups.${cfg.group} = { };

    # Create log directory
    systemd.tmpfiles.rules = [
      "d /var/log 0755 root root -"
      "f ${cfg.logFile} 0644 ${cfg.user} ${cfg.group} -"
    ];

    # Systemd service
    systemd.services.nixos-cache-api = {
      description = "NixOS Cache Server API";
      documentation = [ "https://github.com/NixOS/nix" ];
      after = [
        "network.target"
        "nix-serve.service"
      ];
      wants = [ "nix-serve.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${apiServerScript}";
        Restart = "always";
        RestartSec = "10s";

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "cache-api";

        # User
        User = cfg.user;
        Group = cfg.group;

        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = [ "/nix/store" ];
        ReadWritePaths = [ "/var/log" ];

        # Resource limits
        MemoryMax = "256M";
        TasksMax = 10;

        # Network
        RestrictAddressFamilies = "AF_INET AF_INET6";
      };
    };

    # Nginx proxy for API (optional)
    services.nginx.virtualHosts = mkIf config.services.nginx.enable {
      "${config.services.nixos-cache-server.hostName or "cache.local"}" = {
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # Access control
            ${concatMapStringsSep "\n" (ip: "allow ${ip};") cfg.extraAllowedIPs}
            ${optionalString (cfg.extraAllowedIPs != [ ]) "deny all;"}
          '';
        };
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # Environment packages
    environment.systemPackages = with pkgs; [
      curl
      jq
    ];
  };
}
