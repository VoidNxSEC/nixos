{
  config,
  lib,
  pkgs,
  ...
}:

{

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
      # sudo-claude-code.enable = true; # REMOVED: Insecure module moved to knowledge/

      # Local binary cache - uses offload-server's nix-serve
      binary-cache = {
        enable = true;
        local.enable = false;
        # URL: http://192.168.15.9:5000 (default)
      };
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = false;
      audit.enable = true;

      # HIGH PRIORITY SECURITY ENHANCEMENTS
      # File integrity monitoring - detects unauthorized file modifications
      aide.enable = true;

      # Antivirus scanning for malware detection
      # Note: ClamAV consumes ~2.7GB RAM + swap during full scans
      # Configured with optimizations in modules/security/clamav.nix:
      # - Weekly scans (not continuous)
      # - Low priority (Nice=19, IOSchedulingClass=idle)
      # - Home directory only (excludes /nix/store, /proc, /sys)
      clamav.enable = true;

      # Enhanced SSH security hardening
      ssh.enable = true;

      # Kernel security hardening (sysctl, module blacklist)
      kernel.enable = true;

      # PAM (Pluggable Authentication Modules) hardening
      pam.enable = true;

      # Install security audit and monitoring tools
      packages.enable = true;

      # OS Keyring - gnome-keyring for Secret Service API
      keyring = {
        enable = true;
        enableGUI = true; # Seahorse for managing credentials
        enableKeePassXCIntegration = true; # KeePassXC Secret Service integration
        autoUnlock = true; # Auto-unlock keyring on login
      };
    };

    network = {
      dns-resolver = {
        enable = true;
        # DNSSEC desabilitado temporariamente - muitos domínios não têm DNSSEC configurado
        # Causa "DNSSEC validation failed: no-signature" em domínios populares (anthropic.com, npmjs.org, etc)
        # Para reabilitar: descomente a linha abaixo e faça rebuild
        # enableDNSSEC = true;
        enableDNSSEC = false; # Necessario mais desenvolvimento e estrategia para implementar o dnsec.
        enableDNSCrypt = false; # OPÇÃO A: DNS sem criptografia (mais simples)
        preferredServers = [
          "1.1.1.1" # Cloudflare Primary
          "1.0.0.1" # Cloudflare Secondary
          "9.9.9.9" # Quad9 Primary (Privacy-focused, DNSSEC)
          "149.112.112.112" # Quad9 Secondary
          "8.8.8.8" # Google Primary
          "8.8.4.4" # Google Secondary
        ];
        cacheTTL = 3600;
      };

      bridge = {
        enable = true; # Ensure br0 exists via NetworkManager; uplink auto-detected if unset
        # uplinkInterface = ""; # set explicitly if auto-detect picks wrong device
        ipv6.enable = false;
      };

      vpn.nordvpn = {
        # Não entrega muito
        enable = false; # Habilite se quiser usar VPN
        autoConnect = false;
        overrideDNS = false; # IMPORTANTE: deixar systemd-resolved gerenciar DNS
      };

      # Reverse proxy for Tailscale services (NGINX)
      proxy.nginx-tailscale = {
        enable = true; # Set to true to enable NGINX reverse proxy
        tailnetDomain = "tail-scale.ts.net";
      };

      # nftables-based firewall zones
      # CAUTION: This replaces iptables firewall entirely
      security.firewall-zones = {
        enable = false; # Review nftables rules before enabling
      };
    };

    # SSH client configuration - declarative multi-identity management
    ssh = {
      enable = true;
    };

    # Security Operations Center (SOC) - IDS/IPS, SIEM, monitoring
    soc = {
      enable = false;
      profile = "minimal"; # minimal | standard | enterprise
      retention.days = 30;

      # Explicitly disable Suricata for now
      ids.suricata.enable = false;

      # Alert configuration
      alerting = {
        enable = true;
        minSeverity = "medium";
      };
    };

    nvidia = {
      enable = true;
      cudaSupport = true;
    };

    # Bluetooth support
    bluetooth = {
      enable = true;
    };

    # Applications
    applications.zellij = {
      enable = true;
      autoCleanup = true;
      cleanupInterval = "daily";
      maxCacheSizeMB = 5;
    };

    # Packages - isolated per-package architecture
    packages.zellij.enable = true;
    packages.lynis.enable = true;
    packages.hyprland.enable = true; # Hyprland v0.53.0
    #packages.claude.enable = true;
    packages.gemini-cli.enable = true;

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
          nix.enable = true; # ADDED: Nix kernel for Jupyter notebooks
        };
        extensions.enable = true;
      };

      # MEDIUM PRIORITY: CI/CD and code quality tools
      cicd = {
        enable = true;
        platforms = {
          github = true; # GitHub CLI and tools
          gitlab = false; # Use GitHub Actions instead of local GitLab runners
          gitea = false; # Offload automation to GitHub hosted runners
        };
        pre-commit = {
          enable = true; # ENABLED: For auto-commit hooks
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
        enable = false; # Set to true to use Podman instead of/alongside Docker
        dockerCompat = false; # Enable Docker CLI compatibility (creates docker -> podman alias)
        enableNvidia = true; # NVIDIA GPU support for containers
      };
      nixos.enable = false;
    };

    virtualization = {
      enable = true;
      virt-manager = true;
      libvirtdGroup = [ "kernelcore" ];
      virtiofs.enable = true;
      # Centralized VM registry (managed by modules/virtualization/vms.nix)
      vmBaseDir = "/srv/vms/images";
      sourceImageDir = "/var/lib/vm-images";

      # macOS KVM - Virtual macOS for iOS development and CI/CD
      # Commands: mvm, mfetch, mssh, msnap, mbench
      # See: ~/Downloads/standalone-mac/MASTERPLAN.md
      macos-kvm = {
        enable = false;
        autoDetectResources = true; # Uses 50% of host CPU/RAM
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
        # GPU Passthrough (uncomment when needed)
        # passthrough.enable = true;
        # passthrough.gpuIds = [ "10de:xxxx" ];
      };

      vms = {
        wazuh = {
          enable = false;
          # Resolve under sourceImageDir unless absolute
          sourceImage = "wazuh.qcow2";
          # Final image location (symlink created if missing)
          imageFile = null; # defaults to vmBaseDir/wazuh.qcow2
          memoryMiB = 4096;
          vcpus = 2;
          network = "nat"; # NAT networking via libvirt default network
          bridgeName = "br0";
          enableClipboard = true; # Enable SPICE clipboard sharing
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
          sourceImage = "voidnx.qcow2"; # Will auto-discover in /var/lib/libvirt/images
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
      # Self-hosted GitHub Actions runner
      # Requires secrets/github.yaml to be configured with registration token
      enable = true;
      useSops = true; # SOPS for secure token management
      runnerName = "nixos-self-hosted";
      repoUrl = "https://github.com/VoidNxSEC/nixos"; # Repository URL
      extraLabels = [
        "nixos"
        "nix"
        "linux"
      ];
    };

    # Mosh server for mobile shell connections (Blink Shell iOS)
    services.mosh = {
      enable = true;
      openFirewall = true; # Automatically open UDP ports 60000-61000
      enableMotd = true; # Display welcome message
    };

    # Mobile workspace - Isolated environment for iPhone/tablet access
    services.mobile-workspace = {
      enable = true;
      username = "mobile";
      workspaceDir = "/srv/mobile-workspace";
      enableGitAccess = true; # Allow git with SSH agent forwarding

      # iPhone SSH key (moved from kernelcore user)
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
      url = "https://gitlab.com"; # Or your self-hosted GitLab instance
      executor = "shell"; # Options: shell, docker, docker+machine, kubernetes
      tags = [
        "nixos"
        "nix"
        "linux"
      ];
      concurrent = 4;
    };

    # MEDIUM PRIORITY: Standardized secrets management
    secrets.sops = {
      enable = true;
      secretsPath = "/etc/nixos/secrets";
      ageKeyFile = "/var/lib/sops-nix/key.txt";
    };

    secrets.api-keys.enable = true; # Load decrypted API keys
    secrets.aws-bedrock.enable = true; # Load AWS Bedrock credentials for Claude Code

    # MEDIUM PRIORITY: Standardized ML model storage
    ml.models-storage = {
      enable = true;
      baseDirectory = "/var/lib/ml-models";
    };

    # MCP (Model Context Protocol) - Centralized configuration for AI agents
    # PROJECT_ROOT points to ~/dev/ for all agents (HOME-based development)
    ml.mcp = {
      enable = true;
      # Shared knowledge DB path (enforced via tmpfiles + mcp-shared group)
      knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
      agents = {
        # Roo/Claude Code - USER workspace (HOME-based ~/dev/)
        roo = {
          enable = false;
          projectRoot = "/home/kernelcore/dev";
          configPath = "/home/kernelcore/.roo/mcp.json";
          user = "kernelcore";
        };

        # Codex Agent - Isolated workspace with bwrap (already stable)
        codex = {
          enable = true;
          projectRoot = "/var/lib/codex/dev";
          configPath = "/var/lib/codex/.codex/mcp.json";
          user = "kernelcore";
        };

        # Gemini Agent - Isolated workspace (needs bwrap isolation)
        gemini = {
          enable = true;
          projectRoot = "/var/lib/gemini-agent/dev";
          configPath = "/var/lib/gemini-agent/.gemini/mcp.json";
          user = "kernelcore";
        };

        # Antigravity - User's local editor (needs access to shared knowledge)
        # API keys loaded from SOPS at runtime via /run/secrets/
        antigravity = {
          enable = true;
          projectRoot = "/etc/nixos";
          configPath = "/home/kernelcore/.gemini/antigravity/mcp_config.json";
          user = "kernelcore";
          # extraEnv removed - API keys now read from /run/secrets/ (SOPS)
          # Use: source /etc/load-api-keys.sh to load into shell
        };
      };
    };

    # Centralized ML/GPU user and group management
    system.ml-gpu-users.enable = true;
  };

  # ═══════════════════════════════════════════════════════════
  # FEATURE FLAGS - Service Configuration (migrated from flake.nix)
  # ═══════════════════════════════════════════════════════════

  # SecureLLM MCP Server
  services.securellm-mcp = {
    enable = true;
    daemon.enable = true;
    daemon.logLevel = "INFO";
  };

  # Tools Suite
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
  };

  # Swissknife Debug Tools
  kernelcore.swissknife.enable = true;

  # ═══════════════════════════════════════════════════════════
  # ADDITIONAL SERVICES
  # ═══════════════════════════════════════════════════════════

  # Enable the configuration auditor tool
  services.config-auditor.enable = true;

  services = {

    # ============================================
    # XSERVER - Minimal for NVIDIA drivers only
    # ============================================
    xserver = {
      enable = true; # Required for NVIDIA drivers on NixOS
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "br";
        variant = "";
      };

    };

    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
        # Auto-suspend disabled (causes issues with NVIDIA)
        autoSuspend = false;
      };
      # Disable SDDM
      sddm.enable = false;
      # Default session is Hyprland
      defaultSession = "hyprland";
    };

    # ============================================
    # HYPRLAND DESKTOP - PRIMARY COMPOSITOR
    # ============================================
    # Pure Wayland Hyprland environment with glassmorphism
    hyprland-desktop = {
      enable = true;
      nvidia = true; # Enable NVIDIA optimizations
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Offload build server - DISABLED (this is the laptop, not the desktop)
    # Desktop server is at 192.168.15.7 - connects via Tailscale
    offload-server = {
      enable = false; # Changed from true - this is laptop client, not server
      cachePort = 5000; # nix-serve porta
      builderUser = "nix-builder";
      cacheKeyPath = "/var/cache-priv-key.pem";
      enableNFS = true; # Pode habilitar se quiser compartilhar /nix/store via NFS
    };

    # ============================================
    # LLAMA.CPP TURBO - High-Performance Inference
    # ============================================
    # - CUDA Graphs (~1.2x speedup)
    # - Flash Attention (lower VRAM, faster long context)
    # - Speculative Decoding (1.5-3x speedup)
    # - Continuous Batching (concurrent requests)
    llamacpp-turbo = {
      enable = true;
      model = "/var/lib/llamacpp/models/Qwen2.5_Coder_7B_Instruct";
      host = "127.0.0.1";
      port = 8080;

      # Threading (use physical cores)
      n_threads = 12;
      n_threads_batch = 12;

      # GPU configuration (~4GB VRAM for 8B Q4)
      n_gpu_layers = 35;
      mainGpu = 1;

      # Context & batching
      n_parallel = 1; # Dedicated server - give full context to 1 slot
      n_ctx = 8192; # 8K context window
      n_batch = 2048;
      n_ubatch = 512;

      # Performance optimizations
      cudaGraphs = true; # CUDA Graphs enabled
      flashAttention = true; # Flash Attention enabled
      mmap = true; # Memory-mapped I/O
      mlock = true; # Lock in RAM
      continuousBatching = true;

      # Speculative Decoding (optional - enable when you have a draft model)
      speculativeDecoding = {
        enable = false; # Enable when you download a draft model
        # draftModel = "/var/lib/ml-models/llama-cpp/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf";
        # draftMax = 16;
        # draftMin = 1;
      };

      # API settings
      metricsEndpoint = false; # Prometheus metrics at /metrics
    };

    gitea = {
      enable = false; # Disabled - causing systemd loops during rebuild
      settings = {
        server = {
          DOMAIN = "git.voidnxlabs";
          ROOT_URL = "https://git.voidnxlabs:3443/";
          HTTP_PORT = 3000; # HTTP redirect port
          PROTOCOL = "https";
          HTTPS_PORT = 3443;
          CERT_FILE = "/var/lib/gitea/custom/https/localhost.crt";
          KEY_FILE = "/var/lib/gitea/custom/https/localhost.key";
        };
        service = {
          DISABLE_REGISTRATION = false;
        };
        database = {
          DB_TYPE = "sqlite3";
          HOST = "localhost";
          NAME = "gitea";
          USER = "kernelcore";
        };
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
        "--ozone-platform-hint=auto" # Wayland nativo para o Hyprland
        "--disable-reading-from-canvas"
        "--no-first-run"
        "--disable-sync"
      ];
    };

  };

  # Copy SSL certificates to Gitea directory
  systemd.tmpfiles.rules = [
    "d /var/lib/gitea/custom/https 0750 gitea gitea -"
    "L+ /var/lib/gitea/custom/https/localhost.crt - - - - /home/kernelcore/localhost.crt"
    "L+ /var/lib/gitea/custom/https/localhost.key - - - - /home/kernelcore/localhost.key"

    # MCP Knowledge Database directory
    "d /var/lib/mcp-knowledge 0755 kernelcore users -"
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];

  kernelcore.hardware.intel = {
    enable = true;
  };

  # Yazi configuration moved to home-manager: hosts/kernelcore/home/yazi.nix

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

  #hardware.nvidia.datacenter.enable = true; # Conflicting with xserver drivers

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.tailscale.enable = true;

  # Video Production with OBS, NVIDIA, and mic jack fix
  modules.audio.videoProduction = {
    enable = true;
    enableNVENC = true;
    fixHeadphoneMute = true; # Fix para mic P2 mutando speaker
    lowLatency = true;
  };

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
  '';

  users.users.kernelcore = {
    isNormalUser = true;
    description = "kernel";
    shell = pkgs.zsh; # Set zsh as default shell
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
      "mcp-shared" # For shared MCP knowledge DB access
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";

    # SSH keys for remote access
    openssh.authorizedKeys.keys = [
      # iPhone (Blink Shell) - ECDSA key - Full system access
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG5StF4nUzkEsUei88BstktP/Q/g8BvlHeWnEDD+ii/jB7Fs4v4imG05tJU/jC8/ax2FFRSwoBRt7tH6RDp4Dys= user@iphone"
    ];

    packages = with pkgs; [

      obsidian
      sssd
      vscodium
      gphoto2
      mtpfs
      libimobiledevice # Provides afc support
      devenv # Added for development environments
      tailscale # Added for VPN connectivity
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

      invidious

      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm
      git-lfs
      promptfoo

      certbot

      flameshot

      claude-code

      alacritty
      xclip

      glab
      gh
      codeberg-cli
      brev-cli

      gnome-console

      yt-dlg
      tts

      antigravity
      zed-editor
      rust-analyzer
      rustup

      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault

    ];
  };

  # Guest user removed for security hardening

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

    # CognitiveVault - Secure Password Manager
    cognitive-vault.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.nvidia.acceptLicense = true;

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
    bat # Syntax highlighting for cat (used in debugging scripts)

    # Debugging and profiling tools
    gdb # GNU Debugger
    lldb # LLVM Debugger
    strace # System call tracer
    ltrace # Library call tracer
    valgrind # Memory debugger and profiler
    perf # Performance analysis (kernel perf)
    heaptrack # Heap memory profiler
    hotspot # GUI for perf data
    sysstat # System performance tools (sar, iostat, mpstat)
    bpftrace # High-level tracing language for eBPF
    iotop # I/O monitor
    nethogs # Network bandwidth monitor per process
    iftop # Network bandwidth monitor
    nmon # Performance monitor
    atop # Advanced system & process monitor
    lsof # List open files
    tcpdump # Network packet analyzer
    wireshark # Network protocol analyzer (GUI)
    tshark # Network protocol analyzer (CLI)

    # CLI helper scripts moved to modules/shell/cli-helpers.nix
  ];

  # Enable CLI helper scripts (rebuild, dbg, nix-debug, audit-system, lynis-report)
  kernelcore.shell.cli-helpers = {
    enable = true;
    flakePath = "/etc/nixos";
    hostName = "kernelcore";
  };

  #kernelcore.ml.offload.enable = false;
  #kernelcore.ml.offload.api.enable = false;

  programs.vscodium-secure = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      rooveterinaryinc.roo-cline
    ];
  };

  programs.brave-secure = {
    enable = true;
  };

  # Firefox is now managed by home-manager with self-hosted extensions
  # See: hosts/kernelcore/home/firefox.nix
  programs.firefox-privacy = {
    enable = false; # Disabled - using home-manager firefox.nix instead
  };

  programs.git.lfs = {
    enable = true;
  };

  programs.nemo = {
    enable = true;
  };

  # TODO: This issue need fix with more analysis
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
          # Copie o seu arquivo compilado para dentro da estrutura que o Kernel espera
          cp ${./acpi-fix/dsdt.aml} $out/kernel/firmware/acpi/dsdt.aml

          # Cria o arquivo CPIO
          find $out -print0 | cpio -o -H newc --reproducible -0 > $out/acpi_override.cpio
        ''
    }/acpi_override.cpio"
  ];

  services.i915-governor.enable = false; # WARNING: This service need to be documented

  # OBS Studio configuration moved to modules/audio/video-production.nix
  # Enable with: modules.audio.videoProduction.enable = true;

  programs.vmctl = {
    enable = false;
    vms = {
      wazuh = {
        image = "/var/lib/vm-images/wazuh.qcow2";
        memory = "4G";
        cpus = 2;
      };
    };
  };

  system.stateVersion = "26.05";
}
