# Example workstation configuration
# This is the full NixOS config for a HyperLab workstation
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix # Generate with nixos-generate-config
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel for better hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # HyperLab configuration
  hyperlab = {
    enable = true;
    user = "pina";
    hostname = "hyperlab-workstation";
    profile = "workstation";

    features = {
      securityHardening = true;
      impermanence = false; # Set true for ephemeral root
      distributedBuilds = false;
    };

    # Remote builders (if you have them)
    # builders = [{
    #   hostName = "builder.local";
    #   system = "x86_64-linux";
    #   maxJobs = 8;
    #   speedFactor = 2;
    #   sshUser = "builder";
    #   sshKey = "/root/.ssh/builder_ed25519";
    # }];
  };

  # Docker + Nix magic
  hyperlab.docker = {
    enable = true;
    enableGPU = true;
    nixStoreMount = true;
    btrfsStorage = false; # Set true if using btrfs
  };

  # GPU configuration
  hyperlab.gpu = {
    enable = true;
    vendor = "nvidia";
    cudaVersion = "12";
    enablePrime = false; # Set true for laptops with hybrid graphics

    passthrough = {
      enable = false; # Enable for GPU passthrough to VMs
      # pciIds = [ "10de:1234" "10de:5678" ];
    };
  };

  # AI/ML stack
  hyperlab.ai = {
    enable = true;

    ollama = {
      enable = true;
      acceleration = "cuda";
      models = [
        "llama3.1"
        "codellama"
        "mistral"
        "deepseek-coder"
      ];
      host = "0.0.0.0"; # Allow network access
    };

    openWebUI.enable = true;
    jupyter.enable = true;
    localAI.enable = false;
  };

  # macOS VM support
  hyperlab.macos = {
    enable = true;
    memory = 8192;
    cpus = 4;
    diskSize = 128;
    display = "sdl,gl=on";
  };

  # Monitoring
  hyperlab.monitoring = {
    enable = true;

    prometheus = {
      enable = true;
      retentionDays = 30;
    };

    grafana = {
      enable = true;
      # WARNING: Override this with SOPS secret in production!
      # Use: grafana.adminPassword = lib.mkForce config.sops.secrets.grafana-password.path;
      adminPassword = lib.mkDefault null; # Set via SOPS in production
    };

    exporters = {
      node = true;
      docker = true;
      nvidia = true;
    };

    loki.enable = true;
  };

  # Additional packages
  environment.systemPackages = with pkgs; [
    # Development
    vscode
    neovim
    tmux

    # Browsers
    firefox
    chromium

    # Communication
    discord
    slack

    # Creative
    obs-studio
    gimp

    # System utilities
    gparted
    ventoy-full
  ];

  # Specialisations for different modes
  specialisation = {
    # Gaming mode - Xanmod kernel, optimizations
    gaming.configuration = {
      boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
      programs.steam.enable = true;
      programs.gamemode.enable = true;
    };

    # Secure mode - Extra hardening
    secure.configuration = {
      hyperlab.features.securityHardening = lib.mkForce true;
      services.tor.enable = true;
      networking.firewall.allowedTCPPorts = lib.mkForce [ ];
    };

    # AI mode - Maximize GPU resources
    ai-workstation.configuration = {
      hyperlab.ai.ollama.models = lib.mkForce [
        "llama3.1:70b"
        "codellama:34b"
        "mixtral"
      ];
    };
  };

  # System version - DON'T CHANGE
  system.stateVersion = "24.05";
}
