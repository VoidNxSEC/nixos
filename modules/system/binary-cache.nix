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
    };

    # Optional: Set up local cache server using nix-serve
    services.nix-serve = mkIf config.kernelcore.system.binary-cache.local.enable {
      enable = mkDefault false; # Only enable if you want to RUN the server on this machine
      port = 5000;
      bindAddress = "0.0.0.0";
      secretKeyFile = "/var/cache-priv-key.pem";
      # To generate key: nix-store --generate-binary-cache-key cache-name /var/cache-priv-key.pem /var/cache-pub-key.pem
    };
  };
}
