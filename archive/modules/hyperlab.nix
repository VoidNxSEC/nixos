# HyperLab Core Module
# The central configuration hub for the entire hyperlab ecosystem
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.hyperlab;
in
{
  options.hyperlab = {
    enable = mkEnableOption "NixOS HyperLab";

    user = mkOption {
      type = types.str;
      default = "pina";
      description = "Primary user for HyperLab";
    };

    hostname = mkOption {
      type = types.str;
      default = "hyperlab";
      description = "System hostname";
    };

    profile = mkOption {
      type = types.enum [
        "workstation"
        "server"
        "minimal"
      ];
      default = "workstation";
      description = "HyperLab profile type";
    };

    # Feature flags
    features = {
      impermanence = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ephemeral root filesystem";
      };

      securityHardening = mkOption {
        type = types.bool;
        default = true;
        description = "Enable security hardening";
      };

      distributedBuilds = mkOption {
        type = types.bool;
        default = false;
        description = "Enable distributed Nix builds";
      };
    };

    # Remote builders
    builders = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            hostName = mkOption { type = types.str; };
            system = mkOption {
              type = types.str;
              default = "x86_64-linux";
            };
            maxJobs = mkOption {
              type = types.int;
              default = 4;
            };
            speedFactor = mkOption {
              type = types.int;
              default = 1;
            };
            sshUser = mkOption {
              type = types.str;
              default = "builder";
            };
            sshKey = mkOption { type = types.str; };
          };
        }
      );
      default = [ ];
      description = "Remote build machines";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Core system configuration
    {
      networking.hostName = cfg.hostname;

      # Nix settings
      nix = {
        settings = {
          # Enable flakes
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Optimization
          auto-optimise-store = true;

          # Binary caches
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://devenv.cachix.org"
            "https://cuda-maintainers.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          ];

          # Trust
          trusted-users = [
            "root"
            "@wheel"
            cfg.user
          ];
        };

        # Garbage collection
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };

      # Base packages
      environment.systemPackages = with pkgs; [
        # Essentials
        git
        vim
        curl
        wget
        htop
        btop
        tree
        ripgrep
        fd
        jq
        yq

        # Nix tools
        nix-tree
        nix-diff
        nix-prefetch-git
        nixpkgs-fmt
        nh # Nix helper

        # System monitoring
        lsof
        iotop
        nethogs

        # Development
        direnv
        nix-direnv
      ];

      # Programs
      programs = {
        git.enable = true;

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        zsh = {
          enable = true;
          autosuggestions.enable = true;
          syntaxHighlighting.enable = true;
        };
      };

      # User configuration
      users.users.${cfg.user} = {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
        ];
      };

      # Timezone and locale
      time.timeZone = "America/Sao_Paulo";
      i18n.defaultLocale = "en_US.UTF-8";
    }

    # Workstation profile
    (mkIf (cfg.profile == "workstation") {
      # Desktop environment
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      # Audio
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      # Bluetooth
      hardware.bluetooth.enable = true;

      # Printing
      services.printing.enable = true;

      # Extra packages for workstation
      environment.systemPackages = with pkgs; [
        firefox
        vscode
        alacritty
        kitty
      ];
    })

    # Server profile
    (mkIf (cfg.profile == "server") {
      # SSH
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      # Fail2ban
      services.fail2ban.enable = true;
    })

    # Security hardening
    (mkIf cfg.features.securityHardening {
      # Kernel hardening
      boot.kernelParams = [
        "slab_nomerge"
        "init_on_alloc=1"
        "init_on_free=1"
        "page_alloc.shuffle=1"
        "randomize_kstack_offset=on"
      ];

      # Sysctl hardening
      boot.kernel.sysctl = {
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.perf_event_paranoid" = 3;
        "kernel.yama.ptrace_scope" = 2;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.tcp_syncookies" = 1;
      };

      # Firewall
      networking.firewall.enable = true;

      # AppArmor
      security.apparmor.enable = true;
    })

    # Distributed builds
    (mkIf cfg.features.distributedBuilds {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;

      nix.buildMachines = map (b: {
        inherit (b)
          hostName
          system
          maxJobs
          speedFactor
          sshUser
          sshKey
          ;
        supportedFeatures = [
          "nixos-test"
          "big-parallel"
          "kvm"
        ];
      }) cfg.builders;
    })

    # Impermanence (ephemeral root)
    (mkIf cfg.features.impermanence {
      # This requires impermanence module to be imported
      # environment.persistence."/persistent" = {
      #   hideMounts = true;
      #   directories = [
      #     "/var/log"
      #     "/var/lib/docker"
      #     "/var/lib/containers"
      #     "/var/lib/ollama"
      #     "/etc/nixos"
      #   ];
      #   files = [
      #     "/etc/machine-id"
      #     "/etc/ssh/ssh_host_ed25519_key"
      #     "/etc/ssh/ssh_host_ed25519_key.pub"
      #   ];
      #   users.${cfg.user} = {
      #     directories = [
      #       ".ssh"
      #       ".gnupg"
      #       ".local/share"
      #       ".config"
      #       "projects"
      #       "Documents"
      #       ".hyperlab"
      #     ];
      #   };
      # };
    })
  ]);
}
