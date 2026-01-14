{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.containers.podman.enable = mkEnableOption "Enable Podman container support";

    kernelcore.containers.podman.dockerCompat = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Docker compatibility (creates docker alias to podman)";
    };

    kernelcore.containers.podman.enableNvidia = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NVIDIA GPU support via nvidia-container-toolkit";
    };
  };

  config = mkIf config.kernelcore.containers.podman.enable {
    virtualisation.podman = {
      enable = true;

      # Docker compatibility
      dockerCompat = config.kernelcore.containers.podman.dockerCompat;

      # Enable socket API (required for docker-compose)
      dockerSocket.enable = config.kernelcore.containers.podman.dockerCompat;

      # Create a `docker` alias for podman
      defaultNetwork.settings.dns_enabled = true;

      # Auto-prune images and containers
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    # NVIDIA GPU support
    hardware.nvidia-container-toolkit.enable = mkIf config.kernelcore.containers.podman.enableNvidia true;

    # Useful packages for Podman
    environment.systemPackages = with pkgs; [
      podman-compose # Docker Compose compatibility
      podman-tui # Terminal UI for Podman
      buildah # Container image builder
      skopeo # Work with remote container registries
      conmon # Container monitoring
    ];

    # Enable cgroups v2 (recommended for Podman)
    #systemd.enableUnifiedCgroupHierarchy = mkDefault true;

    # Configure storage
    virtualisation.containers.storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        rootless_storage_path = "$HOME/.local/share/containers/storage";

        options = {
          overlay = {
            # Improve performance
            mountopt = "nodev,metacopy=on";
          };
        };
      };
    };

    # Configure registries (Docker Hub, Quay, GitHub Container Registry)
    virtualisation.containers.registries = {
      search = [
        "docker.io"
        "quay.io"
        "ghcr.io"
      ];

      insecure = [ ]; # Add insecure registries here if needed
      block = [ ]; # Block specific registries if needed
    };

    # Shell aliases for convenience
    environment.shellAliases = mkIf config.kernelcore.containers.podman.enable {
      # Podman aliases
      pod = "${pkgs.podman}/bin/podman";
      pc = "${pkgs.podman-compose}/bin/podman-compose";
      ptui = "${pkgs.podman-tui}/bin/podman-tui";

      # Container management
      pods = "${pkgs.podman}/bin/podman ps -a";
      podi = "${pkgs.podman}/bin/podman images";
      podrm = "${pkgs.podman}/bin/podman rm -f";
      podrmi = "${pkgs.podman}/bin/podman rmi -f";
      podprune = "${pkgs.podman}/bin/podman system prune -af";

      # Build and run
      podbuild = "${pkgs.buildah}/bin/buildah build";
      podrun = "${pkgs.podman}/bin/podman run --rm -it";
    };
  };
}
