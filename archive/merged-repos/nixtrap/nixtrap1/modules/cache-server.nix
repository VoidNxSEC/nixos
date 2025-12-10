{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.nixos-cache-server;

  # Generate hardware-aware configuration
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
  signingKeyPath = "/var/cache-nix-serve/cache-priv-key.pem";

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
      default = true;
      description = "Enable monitoring endpoints";
    };

    workers = mkOption {
      type = types.int;
      default = 4;
      description = "Number of nix-serve worker processes";
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
          /var/cache-nix-serve/cache-pub-key.pem
        chmod 600 ${signingKeyPath}
        chmod 644 /var/cache-nix-serve/cache-pub-key.pem
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

    # Configure nix-serve
    services.nix-serve = {
      enable = true;
      port = cfg.port;
      bindAddress = "127.0.0.1";
      secretKeyFile = signingKeyPath;
    };

    # Configure nginx as reverse proxy
    services.nginx = mkIf cfg.enableTLS {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.${cfg.hostName} = {
        forceSSL = cfg.enableTLS;

        sslCertificate =
          if cfg.ssl.certificatePath != null then
            cfg.ssl.certificatePath
          else
            "/var/lib/nixos-cache/cert.pem";

        sslCertificateKey =
          if cfg.ssl.keyPath != null then cfg.ssl.keyPath else "/var/lib/nixos-cache/key.pem";

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        locations."/nix-cache-info" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            add_header Content-Type text/plain;
          '';
        };

        # Monitoring endpoint
        locations."/nginx-status" = mkIf cfg.enableMonitoring {
          extraConfig = ''
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
          '';
        };

        extraConfig = cfg.extraConfig;
      };
    };

    # Nix daemon configuration
    nix = {
      settings = {
        # Build optimization
        max-jobs = cfg.workers;
        cores = 0; # Use all available cores per job

        # Cache settings
        substituters = mkDefault [ "https://cache.nixos.org" ];
        trusted-public-keys = mkDefault [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];

        # Store optimization
        auto-optimise-store = cfg.storage.autoOptimise;
        keep-outputs = cfg.storage.gcKeepOutputs;
        keep-derivations = cfg.storage.gcKeepDerivations;

        # Network settings
        connect-timeout = 10;
        download-attempts = 3;

        # Logging
        log-lines = 25;
        warn-dirty = false;
      };

      # Automatic garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d --max-freed ${cfg.storage.maxSize}";
      };

      # Optimise store automatically
      optimise = {
        automatic = cfg.storage.autoOptimise;
        dates = [ "daily" ];
      };
    };

    # Firewall configuration
    networking.firewall = {
      enable = true;
      allowedTCPPorts = mkIf cfg.enableTLS [ 443 ];
      allowedUDPPorts = [ ];
    };

    # System packages
    environment.systemPackages = with pkgs; [
      nix-serve
      curl
      jq
      htop
      tree
    ];

    # Systemd service hardening for nix-serve
    systemd.services.nix-serve = {
      serviceConfig = {
        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = [ "/nix/store" ];

        # Resource limits
        MemoryMax = "2G";
        TasksMax = 100;

        # Restart policy
        Restart = "always";
        RestartSec = "10s";
      };
    };

    # Export public key location
    environment.etc."nix-serve/public-key" = {
      source = "/var/cache-nix-serve/cache-pub-key.pem";
      mode = "0644";
    };

    # Create helper scripts
    environment.etc."nixos-cache/scripts/show-cache-info.sh" = {
      text = ''
        #!/usr/bin/env bash
        echo "=== NixOS Cache Server Info ==="
        echo ""
        echo "Hostname: ${cfg.hostName}"
        echo "Port: ${toString cfg.port}"
        echo "Priority: ${toString cfg.priority}"
        echo "TLS Enabled: ${if cfg.enableTLS then "Yes" else "No"}"
        echo ""
        echo "=== Public Key ==="
        cat /var/cache-nix-serve/cache-pub-key.pem
        echo ""
        echo "=== Cache Configuration ==="
        echo "StoreDir: /nix/store"
        echo "WantMassQuery: 1"
        echo "Priority: ${toString cfg.priority}"
        echo ""
        echo "=== Usage Instructions ==="
        echo "Add to client configuration.nix:"
        echo ""
        echo "  nix.settings.substituters = [ \"https://${cfg.hostName}\" ];"
        echo "  nix.settings.trusted-public-keys = ["
        echo "    \"$(cat /var/cache-nix-serve/cache-pub-key.pem)\""
        echo "  ];"
      '';
      mode = "0755";
    };

    environment.etc."nixos-cache/scripts/health-check.sh" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "=== NixOS Cache Server Health Check ==="
        echo ""

        # Check nix-serve
        if systemctl is-active --quiet nix-serve; then
          echo "✓ nix-serve: Running"
        else
          echo "✗ nix-serve: Stopped"
          exit 1
        fi

        # Check nginx (if TLS enabled)
        ${optionalString cfg.enableTLS ''
          if systemctl is-active --quiet nginx; then
            echo "✓ nginx: Running"
          else
            echo "✗ nginx: Stopped"
            exit 1
          fi
        ''}

        # Check cache endpoint
        if curl -sf http://127.0.0.1:${toString cfg.port}/nix-cache-info > /dev/null; then
          echo "✓ Cache endpoint: Responding"
        else
          echo "✗ Cache endpoint: Not responding"
          exit 1
        fi

        # Check disk space
        disk_usage=$(df -h /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$disk_usage" -lt 85 ]; then
          echo "✓ Disk space: $disk_usage% used"
        else
          echo "⚠ Disk space: $disk_usage% used (WARNING: >85%)"
        fi

        echo ""
        echo "All checks passed!"
      '';
      mode = "0755";
    };
  };
}
