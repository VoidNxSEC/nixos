# Centralized Configuration Template for hosts/kernelcore/configurations.nix
# This file demonstrates the intended structure for enable/disable toggles

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM CONFIGURATION TOGGLES
  # ═══════════════════════════════════════════════════════════════════════════

  kernelcore = {
    # ───────────────────────────────────────────────────────────────────────
    # System Optimizations
    # ───────────────────────────────────────────────────────────────────────
    system = {
      memory.optimizations.enable = true;
      nix.optimizations.enable = true;
      nix.experimental-features.enable = true;
    };

    # ───────────────────────────────────────────────────────────────────────
    # Security
    # ───────────────────────────────────────────────────────────────────────
    security = {
      hardening.enable = true;
      sandbox-fallback = true;
      apparmor.enable = true;
      auditd.enable = true;
    };

    # ───────────────────────────────────────────────────────────────────────
    # Hardware
    # ───────────────────────────────────────────────────────────────────────
    nvidia = {
      enable = true;
      cudaSupport = true;
      container-toolkit.enable = true;
    };

    # ───────────────────────────────────────────────────────────────────────
    # Development Environments
    # ───────────────────────────────────────────────────────────────────────
    development = {
      rust.enable = true;
      go.enable = true;
      python.enable = true;
      nodejs.enable = true;
      nix.enable = true;

      jupyter = {
        enable = true;
        kernels = {
          python.enable = true;
          rust.enable = true;
          nodejs.enable = true;
        };
        extensions.enable = true;
      };

      cicd = {
        enable = false; # Enable when needed
        github-actions.enable = false;
        gitlab-ci.enable = false;
      };
    };

    # ───────────────────────────────────────────────────────────────────────
    # Containers & Virtualization
    # ───────────────────────────────────────────────────────────────────────
    containers = {
      docker.enable = true;
      nixos.enable = true;
    };

    virtualization = {
      enable = true;
      virt-manager = true;
      libvirtdGroup = [ "kernelcore" ];
      virtiofs.enable = true;
    };

    # ───────────────────────────────────────────────────────────────────────
    # Machine Learning Services
    # ───────────────────────────────────────────────────────────────────────
    ml = {
      models-storage.enable = true;

      llamacpp = {
        enable = true;
        model = "/var/lib/ml-models/llamacpp/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
        port = 8080;
        n_threads = 16;
        n_gpu_layers = 35;
      };

      #  enable = true;
      #  acceleration = "cuda";
      #  gpu-manager.enable = true; # Auto-offload on idle
      #};
    };

    # ───────────────────────────────────────────────────────────────────────
    # Services
    # ───────────────────────────────────────────────────────────────────────
    services = {
      # Service Users
      users = {
        claude-code.enable = true;
      };

      # ML Services
      ml = {
        llama.enable = true;
      };

      # Container Services
      containers = {
        docker-pull.enable = true;
      };

      # Development Services
      development = {
        jupyter.enable = true;
      };

      # Monitoring
      monitoring = {
        prometheus.enable = true;
        grafana.enable = true;
        node-exporter.enable = true;
      };

      # Security Services
      security = {
        clamav.enable = true;
        credentials.enable = true;
        sshd-hardening.enable = true;
      };

      # Database Services
      databases = {
        postgresql.enable = true;
        etcd.enable = true;
      };

      # Git Services
      gitea = {
        enable = true;
        domain = "git.voidnxlabs";
        port = 3000;
      };
    };

    # ───────────────────────────────────────────────────────────────────────
    # Network Configuration
    # ───────────────────────────────────────────────────────────────────────
    network = {
      dns-resolver = {
        enable = true;
        enableDNSSEC = true;
        enableDNSCrypt = false;
      };

      vpn = {
        nordvpn = {
          enable = false; # Enable manually when needed
          autoConnect = false;
          preferredCountry = "United_States";
          protocol = "nordlynx";
        };
      };

      firewall = {
        enable = true;
        strictMode = true;
      };
    };

    # ───────────────────────────────────────────────────────────────────────
    # Applications
    # ───────────────────────────────────────────────────────────────────────
    applications = {
      brave-secure = {
        enable = true;
        gpuMemoryLimit = "4G";
        enableHardening = true;
      };

      firefox-privacy = {
        enable = true;
        enableGoogleAuthenticator = true;
        enableHardening = true;
        enableContainers = true;
      };

      vscode = {
        enable = false;
        extensions.enable = false;
      };
    };

    # ───────────────────────────────────────────────────────────────────────
    # Secrets Management
    # ───────────────────────────────────────────────────────────────────────
    secrets = {
      sops = {
        enable = true;
        secretsPath = "/etc/nixos/secrets";
      };

      age.enable = true;
    };

    # ───────────────────────────────────────────────────────────────────────
    # Desktop Environment
    # ───────────────────────────────────────────────────────────────────────
    desktop = {
      gnome = {
        enable = true;
        extensions.enable = true;
      };

      wayland.enable = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM-LEVEL SERVICES (Non-Kernelcore namespace)
  # ═══════════════════════════════════════════════════════════════════════════

  services = {
    xserver.enable = true;
    xserver.videoDrivers = [ "nvidia" ];

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    pulseaudio.enable = false;
    pipewire.enable = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # USAGE NOTES
  # ═══════════════════════════════════════════════════════════════════════════

  # This template demonstrates the intended structure for centralized configuration.
  #
  # Benefits:
  # - Single source of truth for all feature toggles
  # - Easy to enable/disable entire subsystems
  # - Clear hierarchy and organization
  # - Self-documenting configuration
  # - Consistent naming convention
  #
  # To implement:
  # 1. Create corresponding option definitions in modules
  # 2. Use mkEnableOption for boolean toggles
  # 3. Use mkOption for configurable parameters
  # 4. Follow the kernelcore.* namespace for custom modules
  # 5. Use standard NixOS namespaces (services.*, programs.*) where appropriate

}
