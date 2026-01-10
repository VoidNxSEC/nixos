{
  config,
  lib,
  pkgs,
  ...
}:

{

  kernelcore.electron.enable = false;
  #kernelcore.electron.apps.antigravity = {
  #profile = "performance";
  #configDir = "Antigravity";
  #features.enable = [
  #"VaapiVideoDecodeLinuxGL"
  #"WaylandWindowDecorations"
  #];
  #};

  # Shell configuration - Training session logger
  shell.trainingLogger = {
    enable = false;
    userLogDirectory = "\${HOME}/.training-logs";
    maxLogSize = "1G";
  };

  kernelcore = {
    system = {
      memory.optimizations.enable = true;
      nix.optimizations.enable = true;
      nix.experimental-features.enable = true;

      # Local binary cache - uses offload-server's nix-serve
      binary-cache = {
        enable = true;
        local.enable = false;
        # URL: http://192.168.15.9:5000 (default)
      };
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = true;
      audit.enable = true;

      # HIGH PRIORITY SECURITY ENHANCEMENTS
      aide.enable = true;
      clamav.enable = true;
      ssh.enable = true;
      kernel.enable = true;
      pam.enable = true;
      packages.enable = true;

      # OS Keyring
      keyring = {
        enable = true;
        enableGUI = true;
        enableKeePassXCIntegration = true;
        autoUnlock = true;
      };
    };

    network = {
      dns-resolver = {
        enable = true;
        enableDNSSEC = false; # Necessario mais desenvolvimento
        enableDNSCrypt = false;
        preferredServers = [
          "1.1.1.1"
          "1.0.0.1" # Cloudflare
          "9.9.9.9"
          "149.112.112.112" # Quad9
          "8.8.8.8"
          "8.8.4.4" # Google
        ];
        cacheTTL = 3600;
      };

      bridge = {
        enable = true;
        ipv6.enable = false;
      };

      vpn.nordvpn = {
        enable = false;
        autoConnect = false;
        overrideDNS = false;
      };

      proxy.nginx-tailscale = {
        enable = true;
        tailnetDomain = "tail-scale.ts.net";
      };

      security.firewall-zones = {
        enable = false;
      };
    };

    ssh.enable = true;

    soc = {
      enable = false;
      profile = "minimal";
      retention.days = 30;
      ids.suricata.enable = false;
      alerting = {
        enable = true;
        minSeverity = "medium";
      };
    };

    nvidia = {
      enable = true;
      cudaSupport = true;
    };

    bluetooth.enable = true;

    applications.zellij = {
      enable = true;
      autoCleanup = true;
      cleanupInterval = "daily";
      maxCacheSizeMB = 5;
    };

    packages.zellij.enable = true;
    packages.lynis.enable = true;
    packages.js.enable = false;

    # Custom individual packaging for Gemini/Antigravity
    packages.custom = {
      gemini = {
        enable = false; # Set to true to enable custom Gemini build
        sandbox = false;
        allowedPaths = [
          "$HOME/.gemini"
          "/etc/nixos"
          "$HOME/dev"
        ];
        blockHardware = [
          "camera"
          "bluetooth"
        ];
      };

      antigravity = {
        enable = false; # Set to true to enable custom Antigravity build
        profile = "performance"; # Options: performance, balanced, minimal
        enableCache = true;
      };
    };

    hardware.wifi-optimization.enable = true;

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
          nix.enable = true;
        };
        extensions.enable = true;
      };

      cicd = {
        enable = true;
        platforms = {
          github = true;
          gitlab = false;
          gitea = false;
        };
        pre-commit = {
          enable = true;
          formatCode = false;
          runTests = false;
          flakeCheckOnPush = false;
          autoCommit = true;
        };
      };
    };

    containers = {
      docker.enable = true;
      podman = {
        enable = false;
        dockerCompat = false;
        enableNvidia = true;
      };
      nixos.enable = false;

      # ML/AI Containers
      ml = {
        enable = true;

        # Ollama with llama.cpp from host
        ollama = {
          enable = true;
          port = 11434;
          modelsPath = "/var/lib/ollama/models";
          bindLlamaCpp = true; # Bind llama.cpp from host
        };

        # Jupyter Lab for ML development
        jupyter = {
          enable = true;
          port = 8888;
          notebooksPath = "/home/kernelcore/dev/notebooks";
        };
      };

      # Development Containers
      dev = {
        enable = true;

        # Reverse proxy (Caddy)
        proxy = {
          enable = true;
          httpPort = 80;
          httpsPort = 443;
        };
      };
    };

    virtualization = {
      enable = true;
      virt-manager = true;
      libvirtdGroup = [ "libvirtd" ];
      virtiofs.enable = true;
      vmBaseDir = "/srv/vms/images";
      sourceImageDir = "/var/lib/vm-images";

      macos-kvm = {
        enable = false;
        autoDetectResources = true;
        maxCores = 8;
        maxMemoryGB = 32;
        diskSizeGB = 256;
        cpuModel = "Cascadelake-Server";
        memoryPrealloc = true;
        sshPort = 10022;
        vncPort = 5900;
        sshUser = "admin";
        display.virtioGl = true;
        enableQmpSocket = true;
        enableMonitorSocket = true;
      };

      vms = {
        wazuh = {
          enable = false;
          sourceImage = "wazuh.qcow2";
          imageFile = null;
          memoryMiB = 4096;
          vcpus = 2;
          network = "nat";
          bridgeName = "br0";
          enableClipboard = true;
          sharedDirs = [
            {
              path = "/srv/vms/shared";
              tag = "hostshare";
              driver = "virtiofs";
              readonly = false;
              create = true;
            }
          ];
          autostart = false;
        };

        nx = {
          enable = false;
          sourceImage = "voidnx.qcow2";
          memoryMiB = 4096;
          vcpus = 2;
          network = "nat";
          bridgeName = "br0";
          autostart = false;
          sharedDirs = [
            {
              path = "/srv/vms/shared";
              tag = "hostshare";
              driver = "virtiofs";
              readonly = false;
              create = true;
            }
          ];
          enableClipboard = true;
        };
      };
    };

    services.github-runner = {
      enable = true;
      useSops = true;
      runnerName = "nixos-self-hosted";
      repoUrl = "https://github.com/VoidNxSEC/nixos";
      extraLabels = [
        "nixos"
        "nix"
        "linux"
      ];
    };

    services.mosh = {
      enable = true;
      openFirewall = true;
      enableMotd = true;
    };

    services.mobile-workspace = {
      enable = true;
      username = "mobile";
      workspaceDir = "/srv/mobile-workspace";
      enableGitAccess = true;
      sshKeys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG5StF4nUzkEsUei88BstktP/Q/g8BvlHeWnEDD+ii/jB7Fs4v4imG05tJU/jC8/ax2FFRSwoBRt7tH6RDp4Dys= user@iphone"
      ];
    };

    services.gpu-orchestration = {
      enable = true;
      defaultMode = "local";
    };

    services.gitlab-runner = {
      enable = false;
      useSops = false;
      runnerName = "nixos-gitlab-runner";
      url = "https://gitlab.com";
      executor = "shell";
      tags = [
        "nixos"
        "nix"
        "linux"
      ];
      concurrent = 4;
    };

    secrets.sops = {
      enable = true;
      secretsPath = "/etc/nixos/secrets";
      ageKeyFile = "/var/lib/sops-nix/key.txt";
    };

    secrets.gcp-ml.enable = true;
    secrets.aws-bedrock.enable = true;
    secrets.k8s.enable = true;
    secrets.grok.enable = true;

    ml.models-storage = {
      enable = true;
      baseDirectory = "/var/lib/ml-models";
    };

    ml.mcp = {
      enable = true;
      knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
      agents = {
        roo = {
          enable = false;
          projectRoot = "/home/kernelcore/dev";
          configPath = "/home/kernelcore/.roo/mcp.json";
          user = "kernelcore";
        };

        # -----------------------------------------------------------
        # AGENTE CODEX (Agora Habilitado)
        # -----------------------------------------------------------
        codex = {
          enable = false;
          projectRoot = "/var/lib/codex/dev";
          configPath = "/var/lib/codex/.codex/mcp.json";
          user = "kernelcore";
        };

        gemini = {
          enable = true;
          projectRoot = "/var/lib/gemini-agent/dev";
          configPath = "/var/lib/gemini-agent/.gemini/mcp.json";
          user = "kernelcore";
        };

        antigravity = {
          enable = true;
          projectRoot = "/etc/nixos";
          configPath = "/home/kernelcore/.gemini/antigravity/mcp_config.json";
          user = "kernelcore";
        };

        zed-editor = {
          enable = true;
          projectRoot = "/etc/nixos";
          configPath = "/home/kernelcore/.config/zed/mcp_config.json";
          user = "kernelcore";
        };
      };
    };

    system.ml-gpu-users.enable = true;
  }; # FIM DO BLOCO KERNELCORE

  # ============================================================================
  # QUICK START HELPERS
  # ============================================================================

  environment.etc."k8s-quickstart.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Quick K8s cluster operations
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      case "$1" in
        status)
          echo "=== Cluster Status ==="
          kubectl get nodes -o wide
          echo -e "\n=== System Pods ==="
          kubectl get pods -A
          ;;
        ui)
          echo "Opening Hubble UI: http://localhost:12000"
          echo "Opening Longhorn UI: http://localhost:8000"
          ;;
        logs)
          stern -n kube-system "$2"
          ;;
        top)
          kubectl top nodes
          kubectl top pods -A
          ;;
        test)
          echo "Deploying test application..."
          kubectl apply -f /etc/longhorn/test-pvc.yaml
          ;;
        *)
          echo "Usage: k8s-quickstart.sh {status|ui|logs|top|test}"
          ;;
      esac
    '';
    mode = "0755";
  };

  environment.shellAliases = {
    k = "kubectl";
    kns = "kubens";
    kctx = "kubectx";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kdp = "kubectl describe pod";
    klf = "kubectl logs -f";
  };

  environment.shellInit = ''
    export PATH="$HOME/.local/bin:$PATH"
    if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
      source ~/.nix-profile/etc/profile.d/nix.sh
    fi
  '';

  # ═══════════════════════════════════════════════════════════
  # FEATURE FLAGS
  # ═══════════════════════════════════════════════════════════

  services.securellm-mcp = {
    enable = true;
    daemon.enable = true;
    daemon.logLevel = "INFO";

    # Dynamic project profiles - switch with: mcp-context profile <name>
    profiles = {
      nixos = {
        workdir = "/etc/nixos";
        environment = "production";
        env = {
          PROJECT_NAME = "NixOS Configuration";
          PROJECT_TYPE = "infrastructure";
        };
      };

      dev = {
        workdir = "/home/kernelcore/dev/Projects/";
        environment = "development";
        env = {
          PROJECT_NAME = "Development";
          PROJECT_TYPE = "general";
        };
      };

      gemini = {
        workdir = "/var/lib/gemini-agent/dev";
        environment = "development";
        env = {
          PROJECT_NAME = "Gemini Agent";
          PROJECT_TYPE = "ai-agent";
        };
      };

      codex = {
        workdir = "/var/lib/codex/dev";
        environment = "development";
        env = {
          PROJECT_NAME = "Codex";
          PROJECT_TYPE = "ai-agent";
        };
      };
    };
  };

  kernelcore.tools = {
    enable = true;
    intel.enable = true;
    secops.enable = true;
    nix-utils.enable = true;
    dev.enable = true;
    secrets.enable = true;
    diagnostics.enable = true;
    llm.enable = true;
    mcp.enable = true;
    arch-analyzer.enable = true;
    #swissknife.enable = true;
  };

  # ═══════════════════════════════════════════════════════════
  # MAIN SERVICES BLOCK
  # ═══════════════════════════════════════════════════════════

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "br";
        variant = "";
      };
    };

    greetd = {
      enable = false;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };
    };

    displayManager = {
      gdm = {
        enable = false;
        wayland = true;
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "hyprland-uwsm";
    };

    hyprland-desktop = {
      enable = true;
      nvidia = true;
    };

    # K3S Cluster
    k3s-cluster = {
      enable = false;
      role = "server";
      tokenFile = config.sops.secrets.k3s-token.path; # Definido em secrets/k8s.nix ou similar
      clusterCIDR = "10.42.0.0/16";
      serviceCIDR = "10.43.0.0/16";
      disableComponents = [
        "traefik"
        "servicelb"
        "local-storage"
      ];
      extraFlags = [
        "--kube-apiserver-arg=enable-aggregator-routing=true"
        "--kube-apiserver-arg=audit-log-path=/var/log/kubernetes/audit.log"
        "--kube-apiserver-arg=audit-log-maxage=30"
      ];
    };

    cilium-cni = {
      enable = false;
      apiServerHost = "127.0.0.1";
      apiServerPort = 6443;
      clusterCIDR = "10.42.0.0/16";
      encryption = {
        enable = true;
        type = "wireguard";
      };
      hubble = {
        enable = true;
        relay = true;
        ui = true;
      };
      policyEnforcementMode = "default";
      securityFeatures.runtimeSecurity = false;
      prometheus.serviceMonitor = true;
    };

    longhorn-storage = {
      enable = false;
      defaultStorageClass = true;
      defaultReplicas = 1;
      reclaimPolicy = "Delete";
      overProvisioningPercentage = 200;
      minimalAvailablePercentage = 25;
      autoSalvage = true;
      backup = {
        target = "";
        credential = null;
      };
      snapshot = {
        enable = true;
        dataIntegrity = "fast-check";
        immediateCheck = false;
      };
      ingress = {
        enable = true;
        host = "longhorn.k8s.local";
        tls = false;
        ingressClassName = "traefik";
      };
      resources = {
        manager = {
          limits = {
            cpu = "1000m";
            memory = "1Gi";
          };
          requests = {
            cpu = "250m";
            memory = "512Mi";
          };
        };
        driver = {
          limits = {
            cpu = "500m";
            memory = "512Mi";
          };
          requests = {
            cpu = "100m";
            memory = "256Mi";
          };
        };
      };
      dataPath = "/var/lib/longhorn";
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    offload-server = {
      enable = false;
      cachePort = 5000;
      builderUser = "nix-builder";
      cacheKeyPath = "/var/cache-priv-key.pem";
      enableNFS = true;
    };

    llamacpp-turbo = {
      enable = true;
      model = "/var/lib/llamacpp/models/Qwen2.5_Coder_7B_Instruct";
      host = "127.0.0.1";
      port = 8080;
      n_threads = 12;
      n_threads_batch = 12;
      n_gpu_layers = 35;
      mainGpu = 1;
      n_parallel = 1;
      n_ctx = 8192;
      n_batch = 2048;
      n_ubatch = 512;
      cudaGraphs = true;
      flashAttention = true;
      mmap = true;
      mlock = true;
      continuousBatching = true;
      speculativeDecoding.enable = false;
      metricsEndpoint = false;
    };

    gitea-showcase = {
      enable = true;
      domain = "git.voidnx.com";
      httpsPort = 3443;
      showcaseProjectsPath = "/home/kernelcore/dev/projects";
      cloudflare = {
        enable = true;
        zoneId = "2e7f7edeb989e58dc7eed3dc4e4b5622";
        apiTokenFile = "/run/secrets/cloudflare-api-token";
        updateInterval = "hourly";
      };
      gitea = {
        adminTokenFile = "/run/secrets/gitea-admin-token";
        autoInitRepos = false;
      };
      autoMirror = {
        enable = true;
        interval = "hourly";
      };
    };

    postgresql = {
      enable = false;
      ensureDatabases = [ "kernelcore" ];
      ensureUsers = [
        {
          name = "kernelcore";
          ensureDBOwnership = true;
        }
      ];
    };

    etcd = {
      enable = false;
      name = "etc";
    };
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    printing.enable = true;

    chromiumOrg = {
      enable = true;
      extraArgs = [
        "--force-dark-mode"
        "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,ParallelDownloading"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--disable-reading-from-canvas"
        "--no-first-run"
        "--disable-sync"
      ];
    };

    udisks2.enable = true;
    gvfs.enable = true;
    tailscale.enable = true;
    config-auditor.enable = true;
    i915-governor.enable = false;
  }; # FIM DO BLOCO SERVICES

  programs.niri.enable = false;

  imports = [ ./specialisations ];

  #kernelcore.hyprland.performance = {
  #enable = config.services.hyprland-desktop.enable;
  #mode = "balanced";
  #};

  systemd.tmpfiles.rules = [
    "d /var/lib/gitea/custom/https 0750 gitea gitea -"
    "L+ /var/lib/gitea/custom/https/localhost.crt - - - - /home/kernelcore/localhost.crt"
    "L+ /var/lib/gitea/custom/https/localhost.key - - - - /home/kernelcore/localhost.key"
    "d /var/lib/mcp-knowledge 0755 kernelcore users -"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
  kernelcore.hardware.intel.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true; # <--- Critical: Enables UWSM wrapper and integration
  };
  time.timeZone = "America/Scoresbysund";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "kl_GL.UTF-8";
    LC_IDENTIFICATION = "kl_GL.UTF-8";
    LC_MEASUREMENT = "kl_GL.UTF-8";
    LC_MONETARY = "kl_GL.UTF-8";
    LC_NAME = "kl_GL.UTF-8";
    LC_NUMERIC = "kl_GL.UTF-8";
    LC_PAPER = "kl_GL.UTF-8";
    LC_TELEPHONE = "kl_GL.UTF-8";
    LC_TIME = "kl_GL.UTF-8";
  };

  console.keyMap = "br-abnt2";
  security.rtkit.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  modules.audio.videoProduction = {
    enable = true;
    enableNVENC = true;
    fixHeadphoneMute = true;
    lowLatency = true;
  };

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
  '';
  users.groups.kernelcore = { };
  users.users.kernelcore = {
    isNormalUser = true;
    description = "kernel";
    shell = pkgs.zsh;
    group = "kernelcore";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "nvidia"
      "docker"
      "render"
      "libvirtd"
      "kvm"
      "mcp-shared"
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG5StF4nUzkEsUei88BstktP/Q/g8BvlHeWnEDD+ii/jB7Fs4v4imG05tJU/jC8/ax2FFRSwoBRt7tH6RDp4Dys= user@iphone"
    ];
    packages = with pkgs; [
      obsidian
      sssd
      vscodium
      gphoto2
      libimobiledevice
      devenv
      tailscale
      trezor-suite
      tmux
      starship
      terraform
      nushell
      ghidra
      waybackurls
      hakrawler
      python313Packages.pyyaml
      python313Packages.langchain
      awscli
      onlyoffice-desktopeditors
      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm
      git-lfs
      certbot
      flameshot
      claude-code
      codex
      alacritty
      xclip
      glab
      gh
      codeberg-cli
      brev-cli
      gnome-console
      #zed-editor
      jetbrains.idea
      rust-analyzer
      rustup
      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault
    ];
  };

  users.extraGroups.docker.members = [
    "kernelcore"
    "nvidia"
  ];

  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    cognitive-vault.enable = true;
    vscodium-secure = {
      enable = false;
      extensions = with pkgs.vscode-extensions; [ rooveterinaryinc.roo-cline ];
    };
    brave-secure.enable = false;
    firefox-privacy.enable = false;
    git.lfs.enable = true;
    nemo.enable = true;

    vmctl = {
      enable = false;
      vms.wazuh = {
        image = "/var/lib/vm-images/wazuh.qcow2";
        memory = "4G";
        cpus = 2;
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  nixpkgs.config.packageOverrides = pkgs: {
    ltrace = pkgs.ltrace.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    ninja
    cudatoolkit
    cmake
    gcc
    ffmpeg
    yt-dlp
    docker-compose
    docker-buildx
    docker
    gnumake
    libfido2
    python313Packages.pyudev
    libudev0-shim
    libusb1
    trezord
    trezor-udev-rules
    rust-analyzer
    bat
    gdb
    lldb
    strace
    valgrind
    perf
    heaptrack
    hotspot
    sysstat
    bpftrace
    iotop
    nethogs
    iftop
    nmon
    atop
    lsof
    tcpdump
    wireshark
    tshark
    gemini-cli
    sqlite
    antigravity
  ];

  kernelcore.shell.cli-helpers = {
    enable = true;
    flakePath = "/etc/nixos";
    hostName = "kernelcore";
  };

  boot.initrd.prepend = [
    "${
      pkgs.runCommand "acpi-override"
        {
          nativeBuildInputs = [
            pkgs.cpio
            pkgs.findutils
          ];
        }
        ''
          mkdir -p $out/kernel/firmware/acpi
          cp ${./acpi-fix/dsdt.aml} $out/kernel/firmware/acpi/dsdt.aml
          find $out -print0 | cpio -o -H newc --reproducible -0 > $out/acpi_override.cpio
        ''
    }/acpi_override.cpio"
  ];

  programs.zsh.enable = true;

  system.stateVersion = "26.05";
}
