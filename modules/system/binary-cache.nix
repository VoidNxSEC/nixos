{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.kernelcore.system.binary-cache = {
    enable = mkEnableOption "Enable custom binary cache configuration";

    local = {
      enable = mkEnableOption "Enable local binary cache server";
      url = mkOption {
        type = types.str;
        default = "http://192.168.15.6:5000";
        description = "URL of the local binary cache server";
      };
      priority = mkOption {
        type = types.int;
        default = 40;
        description = "Priority of the local cache (lower = higher priority)";
      };
      requireConnectivity = mkOption {
        type = types.bool;
        default = false;
        description = "Only enable cache if server is reachable (useful for optional LAN cache)";
      };
    };

    remote = {
      enable = mkEnableOption "Enable remote/custom binary caches";
      substituers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional binary cache URLs";
        example = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
      };
      trustedPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Public keys for verifying binary cache signatures";
        example = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };
    };
  };

  config = mkIf config.kernelcore.system.binary-cache.enable {
    nix.settings = {
      # Add local cache if enabled
      substituters = mkMerge [
        (mkIf config.kernelcore.system.binary-cache.local.enable [
          config.kernelcore.system.binary-cache.local.url
        ])
        (mkIf config.kernelcore.system.binary-cache.remote.enable config.kernelcore.system.binary-cache.remote.substituers)
      ];

      # Add trusted public keys for remote caches
      trusted-public-keys = mkIf config.kernelcore.system.binary-cache.remote.enable config.kernelcore.system.binary-cache.remote.trustedPublicKeys;

      # Allow extra binary caches (needed for non-root users)
      trusted-substituters = mkMerge [
        (mkIf config.kernelcore.system.binary-cache.local.enable [
          config.kernelcore.system.binary-cache.local.url
        ])
        (mkIf config.kernelcore.system.binary-cache.remote.enable config.kernelcore.system.binary-cache.remote.substituers)
      ];

      # Optimization: Make cache failures non-blocking
      connect-timeout = mkDefault 2; # Reduced from 5 to 2 seconds
      http-connections = mkDefault 25; # Limit parallel connections to avoid overwhelming cache
      fallback = mkDefault true; # Always allow fallback to next cache
      narinfo-cache-negative-ttl = mkDefault 3600; # Cache negative lookups for 1h
    };

    # Optional: Set up local cache server using nix-serve
    services.nix-serve = mkIf config.kernelcore.system.binary-cache.local.enable {
      enable = mkDefault false; # Only enable if you want to RUN the server on this machine
      port = 5000;
      bindAddress = "0.0.0.0";
      secretKeyFile = "/var/cache-priv-key.pem";
      # To generate key: nix-store --generate-binary-cache-key cache-name /var/cache-priv-key.pem /var/cache-pub-key.pem
    };

    # Diagnostic script for cache status
    environment.systemPackages = mkIf config.kernelcore.system.binary-cache.enable [
      (pkgs.writeShellScriptBin "cache-status" ''
        echo "🗄️  Binary Cache Status"
        echo "======================="
        echo

        ${optionalString config.kernelcore.system.binary-cache.local.enable ''
          echo "📡 Local Cache: ${config.kernelcore.system.binary-cache.local.url}"

          # Extract host and port from URL
          CACHE_URL="${config.kernelcore.system.binary-cache.local.url}"
          CACHE_HOST=$(echo "$CACHE_URL" | sed -E 's|^https?://([^:/]+).*|\1|')
          CACHE_PORT=$(echo "$CACHE_URL" | sed -E 's|^https?://[^:]+:([0-9]+).*|\1|')

          # Test connectivity
          if timeout 2 bash -c "echo > /dev/tcp/$CACHE_HOST/$CACHE_PORT" 2>/dev/null; then
            echo "  ✅ Server reachable"

            # Test HTTP
            if curl -sf --max-time 2 "$CACHE_URL/nix-cache-info" >/dev/null 2>&1; then
              echo "  ✅ HTTP responding"
              echo "  Priority: ${toString config.kernelcore.system.binary-cache.local.priority}"
            else
              echo "  ⚠️  HTTP error (may be overloaded)"
            fi
          else
            echo "  ❌ Server unreachable"
            echo "  💡 Nix will fallback to public caches"
          fi
          echo
        ''}

        echo "⚙️  Nix Configuration:"
        echo "  Connect timeout: $(nix show-config | grep '^connect-timeout' | awk '{print $3}')s"
        echo "  Fallback enabled: $(nix show-config | grep '^fallback' | awk '{print $3}')"
        echo "  HTTP connections: $(nix show-config | grep '^http-connections' | awk '{print $3}')"
        echo

        echo "📋 Active Substituters:"
        nix show-config | grep '^substituters' | cut -d= -f2- | tr ' ' '\n' | grep -v '^$' | nl
        echo

        echo "💡 To test cache performance:"
        echo "  nix-build '<nixpkgs>' -A hello --option substitute true --option max-jobs 0"
      '')
    ];
  };
}
