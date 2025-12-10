{
  description = "Full-Featured NixOS Cache Server with Monitoring";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixtrap.url = "github:yourusername/nixtrap";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixtrap,
    }:
    {
      nixosConfigurations.cache-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import all nixtrap modules
          nixtrap.nixosModules.default

          {
            # Import your hardware configuration
            imports = [ ./hardware-configuration.nix ];

            # Cache server configuration
            services.nixos-cache-server = {
              enable = true;
              hostName = "cache.example.com";
              enableTLS = true;
              enableMonitoring = true;
              priority = 40;

              workers = 4; # Adjust based on CPU cores

              storage = {
                maxSize = "100G";
                gcKeepOutputs = true;
                gcKeepDerivations = true;
                autoOptimise = true;
              };
            };

            # API server for metrics
            services.nixos-cache-api = {
              enable = true;
              port = 8080;
              openFirewall = false; # Keep internal
            };

            # Monitoring stack
            services.nixos-cache-monitoring = {
              enable = true;
              enablePrometheus = true;
              enableNodeExporter = true;
              enableNginxExporter = true;
              enableGrafana = true;

              prometheus = {
                port = 9090;
                retention = "30d";
                scrapeInterval = "15s";
              };

              grafana = {
                port = 3000;
                domain = "grafana.example.com";
                adminPassword = "CHANGE_ME_IN_PRODUCTION";
              };

              openFirewall = false; # Use VPN or SSH tunnel
            };

            # Basic system configuration
            boot.loader.grub = {
              enable = true;
              device = "/dev/sda";
            };

            networking = {
              hostName = "nixos-cache";
              firewall = {
                enable = true;
                # Only HTTPS is exposed publicly
                allowedTCPPorts = [
                  443
                  22
                ];
              };
            };

            time.timeZone = "America/New_York";

            # User configuration
            users.users.admin = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh.authorizedKeys.keys = [
                # Add your SSH public keys here
                "ssh-ed25519 AAAAC3... user@host"
              ];
            };

            # SSH configuration
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "no";
                PasswordAuthentication = false;
              };
            };

            # Automatic updates (optional)
            system.autoUpgrade = {
              enable = true;
              flake = "/etc/nixos";
              dates = "weekly";
            };

            # Nix configuration
            nix = {
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                ];

                # Allow remote builds
                trusted-users = [
                  "root"
                  "@wheel"
                ];
              };

              # Use nixpkgs from flake
              registry.nixpkgs.flake = nixpkgs;
            };

            system.stateVersion = "24.11";
          }
        ];
      };
    };
}
