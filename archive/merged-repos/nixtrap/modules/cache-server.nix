{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.nixos-cache-server;

  # Hardware-aware configuration
  cpuCount =
    if builtins ? currentSystem then
      (builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile (
          pkgs.runCommand "cpu-count" { } ''
            echo $(nproc 2>/dev/null || echo "4") > $out
          ''
        )
      ))
    else
      "4";

  # Signing key path
  signingKeyPath = cfg.secretKeyFile;

in
{
  options.services.nixos-cache-server = {
    enable = mkEnableOption "NixOS Binary Cache Server";

    hostName = mkOption {
      type = types.str;
      default = "cache.local";
      description = "Hostname for the cache server";
    };

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port for nix-serve to listen on";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind nix-serve to (use 0.0.0.0 for external access)";
    };

    priority = mkOption {
      type = types.int;
      default = 40;
      description = "Cache priority (lower = higher priority)";
    };

    enableTLS = mkOption {
      type = types.bool;
      default = true;
      description = "Enable TLS/HTTPS via nginx reverse proxy";
    };

    enableMonitoring = mkOption {
      type = types.bool;
      default = false;
      description = "Enable monitoring endpoints and health checks";
    };

    workers = mkOption {
      type = types.int;
      default = 4;
      description = "Number of nix-serve worker processes";
    };

    secretKeyFile = mkOption {
      type = types.path;
      default = "/var/cache-nix-serve/cache-priv-key.pem";
      description = "Path to the signing key file";
    };

    publicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public key for cache (auto-read from pub key file if null)";
    };

    # Resource limits (from nixtrap2)
    resources = {
      memoryMax = mkOption {
        type = types.str;
        default = "2.5G";
        description = "Maximum memory limit for nix-serve";
      };

      memoryHigh = mkOption {
        type = types.str;
        default = "2G";
        description = "High memory threshold for nix-serve";
      };

      cpuQuota = mkOption {
        type = types.str;
        default = "200%";
        description = "CPU quota (percentage of CPU cores)";
      };

      tasksMax = mkOption {
        type = types.int;
        default = 50;
        description = "Maximum number of tasks";
      };
    };

    storage = {
      maxSize = mkOption {
        type = types.str;
        default = "100G";
        description = "Maximum size for the Nix store";
      };

      gcKeepOutputs = mkOption {
        type = types.bool;
        default = true;
        description = "Keep outputs of derivations during garbage collection";
      };

      gcKeepDerivations = mkOption {
        type = types.bool;
        default = true;
        description = "Keep derivations during garbage collection";
      };

      autoOptimise = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically optimise the Nix store";
      };
    };

    ssl = {
      certificatePath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL certificate (generates self-signed if null)";
      };

      keyPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL private key (generates self-signed if null)";
      };

      enableHTTP = mkOption {
        type = types.bool;
        default = false;
        description = "Enable plain HTTP access (port 80) alongside HTTPS";
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration for nginx";
    };
  };

  config = mkIf cfg.enable {
    # Generate signing keys if they don't exist
    system.activationScripts.nixServeKeys = ''
      if [ ! -f ${signingKeyPath} ]; then
        mkdir -p $(dirname ${signingKeyPath})
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key \
          ${cfg.hostName} \
          ${signingKeyPath} \
          $(dirname ${signingKeyPath})/cache-pub-key.pem
        chmod 600 ${signingKeyPath}
        chmod 644 $(dirname ${signingKeyPath})/cache-pub-key.pem
      fi
    '';

    # Generate self-signed SSL certificates if needed
    system.activationScripts.nixServeCerts = mkIf (cfg.enableTLS && cfg.ssl.certificatePath == null) ''
      if [ ! -f /var/lib/nixos-cache/cert.pem ]; then
        mkdir -p /var/lib/nixos-cache
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
          -keyout /var/lib/nixos-cache/key.pem \
          -out /var/lib/nixos-cache/cert.pem \
          -days 365 -nodes \
          -subj "/CN=${cfg.hostName}"
        chmod 600 /var/lib/nixos-cache/key.pem
        chmod 644 /var/lib/nixos-cache/cert.pem
      fi
    '';

    # Configure nix-serve with resource limits
    services.nix-serve = {
      enable = true;
      port = cfg.port;
      bindAddress = cfg.bindAddress;
      secretKeyFile = signingKeyPath;
      extraParams = "--priority=${toString cfg.priority} --workers=${toString cfg.workers}";
    };

    # Enhanced systemd service configuration with resource limits
    systemd.services.nix-serve = {
      serviceConfig = {
        # Memory limits (from nixtrap2)
        MemoryMax = cfg.resources.memoryMax;
        MemoryHigh = cfg.resources.memoryHigh;
        MemoryAccounting = true;

        # CPU limits
        CPUQuota = cfg.resources.cpuQuota;
        CPUAccounting = true;

        # Process limits
        TasksMax = cfg.resources.tasksMax;

        # User and environment
        User = "nix-serve";
        Group = "nix-serve";
        WorkingDirectory = "/var/cache/nix-serve";
        Environment = [
          "HOME=/var/cache/nix-serve"
          "USER=nix-serve"
        ];

        # Security hardening
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

        # File system restrictions
        ReadWritePaths = [
          "/tmp"
          "/var/tmp"
          "/var/cache/nix-serve"
        ];
        ReadOnlyPaths = [ "/nix/store" ];
        PrivateTmp = true;
        PrivateDevices = true;

        # Restart policy for OOM situations
        Restart = mkForce "on-failure";
        RestartSec = mkForce "30s";
        StartLimitIntervalSec = "5min";
        StartLimitBurst = 3;

        # OOM handling
        OOMPolicy = "stop";
        OOMScoreAdjust = 100;
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

    # Configure nginx as reverse proxy
    services.nginx = mkIf cfg.enableTLS {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.${cfg.hostName} = {
        # HTTPS configuration
        enableACME = false; # Use manual certs
        forceSSL = !cfg.ssl.enableHTTP;
        addSSL = cfg.ssl.enableHTTP;

        sslCertificate =
          if cfg.ssl.certificatePath != null then
            cfg.ssl.certificatePath
          else
            "/var/lib/nixos-cache/cert.pem";

        sslCertificateKey =
          if cfg.ssl.keyPath != null then cfg.ssl.keyPath else "/var/lib/nixos-cache/key.pem";

        # HTTP listener (if enabled)
        listen = mkIf cfg.ssl.enableHTTP [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];

        locations."/" = {
          proxyPass = "http://${cfg.bindAddress}:${toString cfg.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Cache settings
            proxy_cache_valid 200 1d;
            proxy_cache_valid 404 1m;
            add_header X-Cache-Status $upstream_cache_status always;

            ${cfg.extraConfig}
          '';
        };
      };
    };

    # Nix store optimization
    nix.settings = {
      auto-optimise-store = cfg.storage.autoOptimise;
      keep-outputs = cfg.storage.gcKeepOutputs;
      keep-derivations = cfg.storage.gcKeepDerivations;
    };

    # Generate nix-cache-info
    systemd.services.nix-cache-info = {
      description = "Generate nix-cache-info for binary cache";
      wantedBy = [ "multi-user.target" ];
      after = [ "nix-serve.service" ];

      script = ''
        mkdir -p /var/cache/nix-serve
        echo "StoreDir: /nix/store" > /var/cache/nix-serve/nix-cache-info
        echo "WantMassQuery: 1" >> /var/cache/nix-serve/nix-cache-info
        echo "Priority: ${toString cfg.priority}" >> /var/cache/nix-serve/nix-cache-info
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Health monitoring (if enabled)
    systemd.services.cache-server-health = mkIf cfg.enableMonitoring {
      description = "Cache server health monitoring";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "cache-health-check" ''
          set -e

          # Check nix-serve is responding
          if ! ${pkgs.curl}/bin/curl -f -s -m 10 http://${cfg.bindAddress}:${toString cfg.port}/nix-cache-info > /dev/null; then
            echo "ERROR: nix-serve not responding on port ${toString cfg.port}"
            exit 1
          fi

          ${optionalString cfg.enableTLS ''
            # Check nginx is responding
            if ! ${pkgs.curl}/bin/curl -f -s -m 10 -k https://${cfg.hostName}/nix-cache-info > /dev/null; then
              echo "WARNING: nginx SSL proxy not responding"
            fi
          ''}

          # Check memory usage
          MEMORY_MB=$(${pkgs.systemd}/bin/systemctl show nix-serve --property=MemoryCurrent --value | ${pkgs.gawk}/bin/awk '{print int($1/1024/1024)}')
          MEMORY_LIMIT=$(echo "${cfg.resources.memoryHigh}" | ${pkgs.gnused}/bin/sed 's/G/*1024/g' | ${pkgs.bc}/bin/bc)
          if [ "$MEMORY_MB" -gt "$MEMORY_LIMIT" ]; then
            echo "WARNING: nix-serve using high memory: $MEMORY_MB MB"
          fi

          echo "Cache server health check passed"
        ''}";
      };
    };

    # Timer for regular health checks
    systemd.timers.cache-server-health = mkIf cfg.enableMonitoring {
      description = "Timer for cache server health checks";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5"; # Every 5 minutes
        Persistent = true;
      };
    };

    # Firewall configuration
    networking.firewall = {
      allowedTCPPorts =
        (optional (!cfg.enableTLS) cfg.port)
        ++ (optional cfg.enableTLS 443)
        ++ (optional (cfg.enableTLS && cfg.ssl.enableHTTP) 80);
    };

    # Management scripts
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "cache-server-status" ''
        echo "=== Cache Server Status ==="
        echo
        echo "Nix-serve service:"
        systemctl status nix-serve --no-pager -l
        echo
        ${optionalString cfg.enableTLS ''
          echo "Nginx service:"
          systemctl status nginx --no-pager -l
          echo
        ''}
        echo "=== Resource Usage ==="
        echo "Memory usage:"
        systemctl show nix-serve --property=MemoryCurrent,MemoryMax,MemoryHigh
        echo
        echo "CPU usage:"
        systemctl show nix-serve --property=CPUUsageNSec
        ${optionalString cfg.enableMonitoring ''
          echo
          echo "=== Health Check ==="
          systemctl start cache-server-health
          journalctl -u cache-server-health --no-pager -l -n 5
        ''}
      '')

      (writeShellScriptBin "cache-server-restart" ''
        echo "Restarting cache server services..."
        systemctl restart nix-serve
        ${optionalString cfg.enableTLS "systemctl restart nginx"}
        sleep 5
        ${optionalString cfg.enableMonitoring ''
          echo "Services restarted. Running health check..."
          systemctl start cache-server-health
        ''}
      '')

      (writeShellScriptBin "cache-server-logs" ''
        echo "Recent cache server logs:"
        echo "=== Nix-serve logs ==="
        journalctl -u nix-serve --no-pager -l -n 20
        ${optionalString cfg.enableTLS ''
          echo
          echo "=== Nginx logs ==="
          journalctl -u nginx --no-pager -l -n 20
        ''}
      '')
    ];
  };
}
