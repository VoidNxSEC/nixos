{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enhanced cache bucket server with intelligent caching and LAN distribution

  # Systemd service for cache bucket management
  systemd.services.cache-bucket-setup = {
    description = "Setup enhanced cache bucket local server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    script = ''
            # Ensure cache directories exist
            mkdir -p /var/cache/nix-serve
            mkdir -p /var/lib/cache-bucket
            mkdir -p /var/lib/cache-bucket/buckets
            mkdir -p /var/lib/cache-bucket/manifests
            mkdir -p /var/log/cache-bucket
            
            # Generate cache info
            cat > /var/cache/nix-serve/nix-cache-info <<'EOF'
      StoreDir: /nix/store
      WantMassQuery: 1
      Priority: 30
      EOF
            
            # Set permissions
            chmod 644 /var/cache/nix-serve/nix-cache-info
            chown -R nix-serve:nix-serve /var/cache/nix-serve /var/lib/cache-bucket
            
            # Create enhanced cache bucket configuration
            cat > /var/lib/cache-bucket/config.json <<'EOF'
      {
        "cache_url": "https://cache.local",
        "nar_url": "https://nar.local:8443",
        "local_url": "http://localhost:5000",
        "nar_local_url": "http://localhost:8080",
        "ssl_cert": "/etc/nixos/certs/server.crt",
        "ssl_key": "/etc/nixos/certs/server.key",
        "signing_key": "/etc/nixos/cache-keys/cache-priv-key.pem",
        "public_key": "/etc/nixos/cache-keys/cache-pub-key.pem",
        "priority": 30,
        "workers": 4,
        "max_age": 86400,
        "bucket_settings": {
          "max_size_gb": 10,
          "cleanup_threshold": 0.8,
          "compression": "xz",
          "lan_distribution": true,
          "preload_popular": true
        },
        "endpoints": {
          "nix_serve": "http://localhost:5000",
          "nar_server": "http://localhost:8080",
          "cache_ssl": "https://cache.local",
          "nar_ssl": "https://nar.local:8443"
        }
      }
      EOF
            
            echo "Enhanced cache bucket configured:"
            echo "  - Main cache: https://cache.local"
            echo "  - NAR server: https://nar.local:8443"
            echo "  - Local cache: http://localhost:5000"
            echo "  - Local NAR: http://localhost:8080"
            echo "Configuration saved to: /var/lib/cache-bucket/config.json"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };

  networking.hosts."127.0.0.1" = [
    "cache.local"
    "nar.local"
  ];

  # Service to monitor cache server status
  systemd.services.cache-server-monitor = {
    description = "Monitor cache server status";
    wantedBy = [ "multi-user.target" ];
    after = [
      "nix-serve.service"
      "nginx.service"
    ];

    script = ''
      while true; do
        # Check if services are running
        if systemctl is-active --quiet nix-serve && systemctl is-active --quiet nginx; then
          echo "$(date): Cache server is running on https://cache.local"
        else
          echo "$(date): Cache server services not running"
        fi
        sleep 300  # Check every 5 minutes
      done
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10";
      User = "nobody";
    };
  };

  # Nix daemon configuration for using the cache
  nix.extraOptions = ''
    # Binary cache settings
    connect-timeout = 5
    stalled-download-timeout = 30

    # Build settings optimized for cache usage
    builders-use-substitutes = true
    require-sigs = true

    # Fallback settings
    fallback = true
    keep-going = true
  '';

  # Environment variables for cache usage
  environment.variables = {
    NIX_CACHE_URL = "https://cache.local";
    NIX_CACHE_LOCAL_URL = "http://localhost:5000";
  };

  # Create a helper script for cache management - scripts will be added to main configuration
}
