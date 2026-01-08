# ============================================
# Development Container Kits Module
# ============================================
# Purpose: Declarative NixOS containers for development workloads
# Inspired by: ~/dev/low-level/docker-hub/ml-clusters/kits/
# Containers: Dev-ML, Chat-UI, Proxy, Code Server
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.containers.dev;

  # Network configuration for dev containers
  devNetworkBase = "192.168.210";
  hostBaseIP = "${devNetworkBase}.10";

  # Helper to generate sequential IPs
  mkContainerIP = offset: "${devNetworkBase}.${toString (10 + offset)}";

  # Common packages for development containers
  devCommonPackages = with pkgs; [
    git
    curl
    wget
    vim
    neovim
    htop
    ripgrep
    fd
    jq
    tmux
  ];
in
{
  options.kernelcore.containers.dev = {
    enable = mkEnableOption "Enable development container infrastructure";

    # Development ML environment
    dev-ml = {
      enable = mkEnableOption "Development ML container with full tooling";
      port = mkOption {
        type = types.port;
        default = 8889;
        description = "Dev-ML Jupyter port";
      };
      workspacePath = mkOption {
        type = types.str;
        default = "/home/kernelcore/dev/workspace";
        description = "Host path for development workspace";
      };
    };

    # Chat UI container
    chat-ui = {
      enable = mkEnableOption "Chat UI container for LLM interaction";
      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Chat UI web interface port";
      };
    };

    # Code Server (VS Code in browser)
    code-server = {
      enable = mkEnableOption "Code Server container (VS Code in browser)";
      port = mkOption {
        type = types.port;
        default = 8443;
        description = "Code Server port";
      };
      workspacePath = mkOption {
        type = types.str;
        default = "/home/kernelcore/dev";
        description = "Host path for code workspace";
      };
    };

    # Proxy container (Caddy/nginx)
    proxy = {
      enable = mkEnableOption "Reverse proxy container for routing";
      httpPort = mkOption {
        type = types.port;
        default = 80;
        description = "HTTP port";
      };
      httpsPort = mkOption {
        type = types.port;
        default = 443;
        description = "HTTPS port";
      };
    };

    # PostgreSQL development database
    postgres = {
      enable = mkEnableOption "PostgreSQL development database container";
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port";
      };
      dataPath = mkOption {
        type = types.str;
        default = "/var/lib/postgres-dev";
        description = "Host path for PostgreSQL data";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure container networking is enabled
    boot.enableContainers = true;

    # Network configuration for dev containers
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-dev-+" ];
      externalInterface = "wlp62s0";
    };

    networking.firewall = {
      trustedInterfaces = [ "ve-dev-+" ];
      allowedTCPPorts =
        [ ]
        ++ optional cfg.dev-ml.enable cfg.dev-ml.port
        ++ optional cfg.chat-ui.enable cfg.chat-ui.port
        ++ optional cfg.code-server.enable cfg.code-server.port
        ++ optionals cfg.proxy.enable [
          cfg.proxy.httpPort
          cfg.proxy.httpsPort
        ]
        ++ optional cfg.postgres.enable cfg.postgres.port;
    };

    # ═══════════════════════════════════════════════════════════
    # DEV-ML CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.dev-ml = mkIf cfg.dev-ml.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 1;

      bindMounts = {
        "${cfg.dev-ml.workspacePath}" = {
          hostPath = cfg.dev-ml.workspacePath;
          isReadOnly = false;
        };
      };

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.dev-ml.port ];
            };
          };

          nixpkgs.config.allowUnfree = true;

          environment.systemPackages =
            devCommonPackages
            ++ (with pkgs; [
              python313
              python313Packages.pip
              python313Packages.virtualenv
              python313Packages.uv
              python313Packages.poetry-core
              python313Packages.jupyterlab
              python313Packages.ipython
              python313Packages.numpy
              python313Packages.pandas
              python313Packages.scikit-learn
              nodejs_22
              nodePackages.npm
              go
              rustc
              cargo
              gcc
              gnumake
            ]);

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # CHAT-UI CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.dev-chat-ui = mkIf cfg.chat-ui.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 2;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.chat-ui.port ];
            };
          };

          nixpkgs.config.allowUnfree = true;

          environment.systemPackages =
            devCommonPackages
            ++ (with pkgs; [
              nodejs_22
              nodePackages.npm
              nodePackages.pnpm
              git
            ]);

          systemd.tmpfiles.rules = [ "d /opt/chat-ui 0755 root root -" ];

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # CODE-SERVER CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.dev-code-server = mkIf cfg.code-server.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 3;

      bindMounts = {
        "${cfg.code-server.workspacePath}" = {
          hostPath = cfg.code-server.workspacePath;
          isReadOnly = false;
        };
      };

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.code-server.port ];
            };
          };

          nixpkgs.config.allowUnfree = true;

          services.code-server = {
            enable = true;
            host = "0.0.0.0";
            port = cfg.code-server.port;
            auth = "password";
            hashedPassword = "$argon2i$v=19$m=4096,t=3,p=1$wst5qhbgk0tbviziesbzj5e1$q5fjdwvdjqn+awlrg9iyxopvldxvejnzmxnmhwp1boh5h0s";
          };

          environment.systemPackages =
            devCommonPackages
            ++ (with pkgs; [
              python313
              nodejs_22
              go
              rustc
              cargo
            ]);

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # PROXY CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.dev-proxy = mkIf cfg.proxy.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 4;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [
                cfg.proxy.httpPort
                cfg.proxy.httpsPort
              ];
            };
          };

          services.caddy = {
            enable = true;
            virtualHosts = {
              "localhost:${toString cfg.proxy.httpPort}" = {
                extraConfig = ''
                  respond "Caddy Proxy Running"
                '';
              };
            };
          };

          environment.systemPackages = devCommonPackages;

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # POSTGRES CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.dev-postgres = mkIf cfg.postgres.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 5;

      bindMounts = {
        "${cfg.postgres.dataPath}" = {
          hostPath = cfg.postgres.dataPath;
          isReadOnly = false;
        };
      };

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.postgres.port ];
            };
          };

          services.postgresql = {
            enable = true;
            package = pkgs.postgresql_16;
            port = cfg.postgres.port;
            enableTCPIP = true;
            authentication = pkgs.lib.mkOverride 10 ''
              #type database  DBuser  auth-method
              local all       all     trust
              host  all       all     192.168.210.0/24 trust
              host  all       all     ::1/128          trust
            '';
            initialScript = pkgs.writeText "init.sql" ''
              CREATE DATABASE devdb;
              CREATE USER devuser WITH PASSWORD 'devpass';
              GRANT ALL PRIVILEGES ON DATABASE devdb TO devuser;
            '';
          };

          environment.systemPackages = devCommonPackages ++ [ pkgs.postgresql_16 ];

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # SHELL ALIASES FOR DEV CONTAINERS
    # ═══════════════════════════════════════════════════════════
    environment.shellAliases = {
      # Dev-ML shortcuts
      dev-ml-enter = "nixos-container root-login dev-ml";
      dev-ml-status = "nixos-container status dev-ml";
      dev-ml-start = "nixos-container start dev-ml";
      dev-ml-stop = "nixos-container stop dev-ml";

      # Chat-UI shortcuts
      dev-chat-enter = "nixos-container root-login dev-chat-ui";
      dev-chat-status = "nixos-container status dev-chat-ui";
      dev-chat-start = "nixos-container start dev-chat-ui";
      dev-chat-stop = "nixos-container stop dev-chat-ui";

      # Code-Server shortcuts
      dev-code-enter = "nixos-container root-login dev-code-server";
      dev-code-status = "nixos-container status dev-code-server";
      dev-code-start = "nixos-container start dev-code-server";
      dev-code-stop = "nixos-container stop dev-code-server";

      # Proxy shortcuts
      dev-proxy-enter = "nixos-container root-login dev-proxy";
      dev-proxy-status = "nixos-container status dev-proxy";
      dev-proxy-start = "nixos-container start dev-proxy";
      dev-proxy-stop = "nixos-container stop dev-proxy";

      # Postgres shortcuts
      dev-pg-enter = "nixos-container root-login dev-postgres";
      dev-pg-status = "nixos-container status dev-postgres";
      dev-pg-start = "nixos-container start dev-postgres";
      dev-pg-stop = "nixos-container stop dev-postgres";
      dev-pg-psql = "nixos-container run dev-postgres -- sudo -u postgres psql";

      # Bulk operations
      dev-status-all = "nixos-container list | grep '^dev-' | xargs -I {} nixos-container status {}";
      dev-stop-all = "nixos-container list | grep '^dev-' | xargs -I {} nixos-container stop {}";
      dev-start-all = "nixos-container list | grep '^dev-' | xargs -I {} nixos-container start {}";
    };
  };
}
