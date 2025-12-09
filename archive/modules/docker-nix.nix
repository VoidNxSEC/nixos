# Docker + Nix Integration Module
# This module provides the magic sauce for Docker/Nix synergy
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.hyperlab.docker;
in
{
  options.hyperlab.docker = {
    enable = mkEnableOption "HyperLab Docker-Nix integration";

    enableGPU = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NVIDIA GPU support for containers";
    };

    registryMirrors = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Docker registry mirrors";
    };

    btrfsStorage = mkOption {
      type = types.bool;
      default = false;
      description = "Use btrfs storage driver";
    };

    nixStoreMount = mkOption {
      type = types.bool;
      default = true;
      description = "Enable /nix/store mount for containers (Arion useHostStore)";
    };
  };

  config = mkIf cfg.enable {
    # Docker daemon
    virtualisation.docker = {
      enable = true;

      # Rootless for security
      rootless = {
        enable = true;
        setSocketVariable = true;
      };

      # Autprune to save space
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--all"
          "--volumes"
        ];
      };

      # Storage driver
      storageDriver = mkIf cfg.btrfsStorage "btrfs";

      # Daemon settings
      daemon.settings = {
        # Registry mirrors
        registry-mirrors = cfg.registryMirrors;

        # Features
        features = {
          buildkit = true;
        };

        # Logging
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };

        # DNS
        dns = [
          "8.8.8.8"
          "8.8.4.4"
        ];
      };
    };

    # Podman as alternative
    virtualisation.podman = {
      enable = true;
      dockerCompat = false; # Don't conflict with Docker
      defaultNetwork.settings.dns_enabled = true;
    };

    # NVIDIA Container Toolkit
    hardware.nvidia-container-toolkit = mkIf cfg.enableGPU {
      enable = true;
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      # Container tools
      docker
      docker-compose
      podman
      podman-compose

      # Image tools
      skopeo
      dive # Image layer explorer
      crane # OCI registry tool

      # Build tools
      buildah

      # Debugging
      ctop # Container top
      lazydocker # TUI for Docker

      # Nix-specific
      # nix2container comes from devshell/flake context
      skopeo
    ];

    # Docker group for user
    users.users.${config.hyperlab.user or "pina"}.extraGroups = [
      "docker"
      "podman"
    ];

    # Systemd services for container management
    systemd.services = {
      # Auto-cleanup old images
      docker-cleanup = {
        description = "Docker cleanup service";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.docker}/bin/docker system prune -af --volumes";
        };
      };
    };

    # Timers
    systemd.timers.docker-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # Environment variables for nix2container
    environment.sessionVariables = {
      # Default registry for nix2container
      CONTAINER_REGISTRY = "ghcr.io";
    };

    # Firewall rules for common container ports
    networking.firewall.allowedTCPPorts = [
      # Development
      3000
      3001
      5000
      8000
      8080
      8888
      # Databases
      5432
      6379
      27017
      # Monitoring
      9090
      9100
      # AI/ML
      11434 # Ollama
    ];
  };
}
