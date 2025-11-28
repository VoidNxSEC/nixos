{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Yazi configuration moved to home-manager: hosts/kernelcore/home/yazi.nix

    # 🚀 Tailscale VPN - Auto-configured for laptop (client mode)
    ../../modules/network/vpn/tailscale-laptop.nix
  ];

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
      sudo-claude-code.enable = true; # Passwordless sudo for Claude Code operations
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = false;
      audit.enable = true;

      # HIGH PRIORITY SECURITY ENHANCEMENTS
      # File integrity monitoring - detects unauthorized file modifications
      aide.enable = false;

      # Antivirus scanning for malware detection
      # DISABLED: ClamAV consumes 2.7GB RAM + 1.2GB swap (causes system slowdown)
      # See REFATORACAO-ARQUITETURA-2025.md for optimized configuration
      clamav.enable = false;

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
      maxCacheSizeMB = 50;
    };

    # Package managers for binaries not in nixpkgs or testing upstream
    # NOTE: deb-packages has a bug with list/null validation - investigating
    packages.deb = {
      enable = false; # DISABLED: validation error - "expected a list but found null"
      packages = import ../../modules/packages/deb-packages/packages/protonvpn.nix;
    };

    packages.tar = {
      enable = true;
      packages = lib.mkMerge [
        (import ../../modules/packages/tar-packages/packages/codex.nix)
        (import ../../modules/packages/tar-packages/packages/zellij.nix)
        (import ../../modules/packages/tar-packages/packages/lynis.nix)
      ];
    };

    packages.js = {
      enable = true;
    };

    packages.gemini-cli = {
      enable = true;
    };

    #services = {
    #users."codex-agent" = lib.mkIf (config.kernelcore.packages.tar.resolvedPackages ? codex) {
    #package = config.kernelcore.packages.tar.resolvedPackages.codex;
    #};
    #};

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
        enable = false;
        platforms = {
          github = false; # GitHub CLI and tools
          gitlab = false; # Use GitHub Actions instead of local GitLab runners
          gitea = false; # Offload automation to GitHub hosted runners
        };
        pre-commit = {
          enable = false;
          formatCode = true; # Auto-format code before commits
          runTests = false; # Set to true when you have automated tests
          flakeCheckOnPush = false; # Offload validation to GitHub-hosted Actions
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
      nixos.enable = true;
    };

    virtualization = {
      enable = true;
      virt-manager = true;
      libvirtdGroup = [ "kernelcore" ];
      virtiofs.enable = true;
      # Centralized VM registry (managed by modules/virtualization/vms.nix)
      vmBaseDir = "/srv/vms/images";
      sourceImageDir = "/var/lib/vm-images";
      vms = {
        wazuh = {
          enable = false;
          # Resolve under sourceImageDir unless absolute
          sourceImage = "wazuh-4.14.0.qcow2";
          # Final image location (symlink created if missing)
          imageFile = null; # defaults to vmBaseDir/wazuh.qcow2
          memoryMiB = 4096;
          vcpus = 2;
          network = "nat"; # NAT networking via libvirt default network
          bridgeName = "br0";
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
          extraVirtInstallArgs = [
            "--graphics type=vnc,listen=0.0.0.0"
          ];
        };
      };
    };

    services.github-runner = {
      # Self-hosted GitHub Actions runner
      # Requires secrets/github.yaml to be configured with registration token
      enable = false; # ❌ DISABLED - CI/CD disabled as requested
      useSops = true; # SOPS for secure token management
      runnerName = "nixos-self-hosted";
      repoUrl = "https://github.com/VoidNxSEC/nixos"; # Repository URL
      extraLabels = [
        "nixos"
        "nix"
        "linux"
      ];
    };

    services.gpu-orchestration = {
      enable = true;
      defaultMode = "docker"; # Docker containers get GPU priority by default
    };

    services.users.gemini-agent = {
      enable = true;
    };

    services.gitlab-runner = {
      enable = false; # Set to true to enable GitLab CI/CD runner
      useSops = false; # Enable when you have secrets/gitlab.yaml configured
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
      agents = {
        # Roo/Claude Code - USER workspace (HOME-based ~/dev/)
        roo = {
          enable = true;
          projectRoot = "/home/kernelcore/dev";
          configPath = "/home/kernelcore/.config/Claude/.mcp.json";
          user = "kernelcore";
        };

        # Codex Agent - Isolated workspace with bwrap (already stable)
        codex = {
          enable = true;
          projectRoot = "/var/lib/codex/dev";
          configPath = "/var/lib/codex/.codex/mcp.json";
          user = "codex";
        };

        # Gemini Agent - Isolated workspace (needs bwrap isolation)
        gemini = {
          enable = true;
          projectRoot = "/var/lib/gemini-agent/dev";
          configPath = "/var/lib/gemini-agent/.gemini/mcp.json";
          user = "gemini-agent";
        };
      };
    };

    # Centralized ML/GPU user and group management
    system.ml-gpu-users.enable = true;
  };

  services = {
    gnome.core-shell.enable = false;
    gnome.core-apps.enable = false;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "br";
        variant = "";
      };
    };

    desktopManager.plasma6.enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      #sessionPackages = [ pkgs.sway ];
      sddm.enable = false;
    };

    # Hyprland desktop environment
    hyprland-desktop.enable = true;

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    # Offload build server - permite laptop buildar remotamente neste desktop
    offload-server = {
      enable = true;
      cachePort = 5000; # nix-serve porta
      builderUser = "nix-builder";
      cacheKeyPath = "/var/cache-priv-key.pem";
      enableNFS = false; # Pode habilitar se quiser compartilhar /nix/store via NFS
    };

    llamacpp = {
      enable = true;
      model = "/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
      port = 8080;
      n_threads = 40;
      n_gpu_layers = 32; # Reduced from 32 to 24 (~2.5GB VRAM instead of ~5GB)
      n_parallel = 1;
      n_ctx = 4096; # Reduced from 4096 to 2048 (~400MB VRAM for KV cache)
      # Total VRAM usage: ~2.9GB (allows coexistence with other GPU services)
    };

    ollama = {
      enable = true;
      host = "127.0.0.1"; # Security: Bind to localhost only
      port = 11434; # Default port - Docker ollama uses 11435
      acceleration = "cuda";
      # GPU memory management: unload models after 5 minutes of inactivity
      environmentVariables = {
        #OLLAMA_KEEP_ALIVE = "5m"; # Unload models after 5min idle to free VRAM
      };
      # NOTE: Systemd ollama service uses port 11434
      # Docker ollama in ~/Dev/Docker.Base/sql/docker-compose.yml uses host port 11435
      # To run ollama manually: OLLAMA_HOST=127.0.0.1:11435 ollama serve
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
      enable = true;
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
  # hardware.nvidia-container-toolkit.enable moved to modules/hardware/nvidia.nix
  #hardware.nvidia.datacenter.enable = true; # Conflicting with xserver drivers

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
  '';

  users.users.kernelcore = {
    isNormalUser = true;
    description = "kernel";
    shell = pkgs.zsh;  # Set zsh as default shell
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
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILI2hXXo4noD779+oYXGTw7vCHZQhkAy0eAEvja1luE0 cypher@nixos"
    ];
    packages = with pkgs; [

      obsidian
      sssd
      vscodium
      trezor-suite
      tmux
      starship
      terraform
      ghidra
      awscli  # AWS CLI v1 (estável) - Para comandos aws bedrock, s3, etc

      invidious

      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm

      libreoffice
      onlyoffice-desktopeditors

      certbot

      python313Packages.groq
      flameshot

      claude-code
      qwen-code

      python313Packages.openai

      alacritty
      xclip

      glab
      gh
      codeberg-cli
      brev-cli

      gnome-console

      yt-dlg
      tts
      spotify
      spotifyd

      antigravity
      zed-editor
      rust-analyzer
      rustup

      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault

      gnomeExtensions.gtile
      gnomeExtensions.awesome-tiles
    ];
  };

  # Guest user with nvidia group access for testing
  users.users.guest = {
    isNormalUser = true;
    description = "Guest User";
    extraGroups = [
      "video"
      "audio"
      "nvidia"
      "render"
    ];
    # Guest user with a simple password (change this!)
    initialPassword = "guest";
  };

  users.extraGroups.docker.members = [ "kernelcore" ];


  programs.nemo = {
    enable = true;
    setDefaultFileManager = true;

    # Já vem tudo habilitado por padrão, mas você pode desabilitar:
    # plugins.preview = false;
    # plugins.compare = false;
    # plugins.terminal = false;
    # plugins.admin = false;
  };


  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
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
    ollama
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

    # Colored wrappers and debugging helpers
    (writeShellScriptBin "rebuild" ''
      #!/usr/bin/env bash
      # Colored nixos-rebuild wrapper - Compatible with bash and zsh

      # Colors
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      MAGENTA='\033[0;35m'
      CYAN='\033[0;36m'
      WHITE='\033[1;37m'
      BOLD='\033[1m'
      NC='\033[0m' # No Color

      # Use printf instead of echo -e for better shell compatibility
      printf "%b" "''${CYAN}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
      printf "%b" "''${CYAN}''${BOLD}║           NixOS Rebuild - Colored Output Mode            ║''${NC}\n"
      printf "%b" "''${CYAN}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
      printf "\n"

      ACTION="''${1:-switch}"
      shift || true

      printf "%b" "''${BLUE}→ Action:''${NC} ''${BOLD}$ACTION''${NC}\n"
      printf "%b" "''${BLUE}→ Flake:''${NC} ''${BOLD}/etc/nixos#kernelcore''${NC}\n"
      printf "\n"

      # Run nixos-rebuild with colored output
      sudo nixos-rebuild "$ACTION" --flake /etc/nixos#kernelcore "$@" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ^error:|ERROR|Error ]]; then
          printf "%b" "''${RED}''${BOLD}✗''${NC} ''${RED}$line''${NC}\n"
        elif [[ "$line" =~ ^warning:|WARNING|Warning ]]; then
          printf "%b" "''${YELLOW}''${BOLD}⚠''${NC} ''${YELLOW}$line''${NC}\n"
        elif [[ "$line" =~ ^building|^copying|^unpacking ]]; then
          printf "%b" "''${CYAN}⚙''${NC} $line\n"
        elif [[ "$line" =~ ^these|^will\ be\ |^evaluating ]]; then
          printf "%b" "''${BLUE}ℹ''${NC} $line\n"
        elif [[ "$line" =~ activation|^restarting|^starting|^stopping ]]; then
          printf "%b" "''${MAGENTA}⟳''${NC} $line\n"
        elif [[ "$line" =~ succeed|success|Success|✓ ]]; then
          printf "%b" "''${GREEN}''${BOLD}✓''${NC} ''${GREEN}$line''${NC}\n"
        else
          printf "%s\n" "$line"
        fi
      done

      EXIT_CODE=''${PIPESTATUS[0]}

      printf "\n"
      if [ $EXIT_CODE -eq 0 ]; then
        printf "%b" "''${GREEN}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
        printf "%b" "''${GREEN}''${BOLD}║                  ✓ Rebuild Successful!                   ║''${NC}\n"
        printf "%b" "''${GREEN}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
      else
        printf "%b" "''${RED}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
        printf "%b" "''${RED}''${BOLD}║                   ✗ Rebuild Failed!                      ║''${NC}\n"
        printf "%b" "''${RED}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
        printf "%b" "''${RED}Exit code: $EXIT_CODE''${NC}\n"
      fi

      exit $EXIT_CODE
    '')

    (writeShellScriptBin "dbg" ''
      #!/usr/bin/env bash
      # Quick debugging helper

      # Colors
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      CYAN='\033[0;36m'
      BOLD='\033[1m'
      NC='\033[0m'

      if [ $# -eq 0 ]; then
        echo -e "''${CYAN}''${BOLD}Debug Tools Quick Menu''${NC}"
        echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo -e "''${GREEN}Usage:''${NC} dbg <tool> <target> [args]"
        echo ""
        echo -e "''${YELLOW}Available tools:''${NC}"
        echo -e "  ''${BOLD}gdb''${NC}        - GNU Debugger"
        echo -e "  ''${BOLD}lldb''${NC}       - LLVM Debugger"
        echo -e "  ''${BOLD}strace''${NC}     - System call tracer"
        echo -e "  ''${BOLD}ltrace''${NC}     - Library call tracer"
        echo -e "  ''${BOLD}valgrind''${NC}   - Memory leak detector"
        echo -e "  ''${BOLD}perf''${NC}       - Performance profiler"
        echo -e "  ''${BOLD}heaptrack''${NC}  - Heap memory profiler"
        echo -e "  ''${BOLD}bpftrace''${NC}   - eBPF tracer"
        echo ""
        echo -e "''${YELLOW}System debugging:''${NC}"
        echo -e "  ''${BOLD}logs''${NC}       - Show recent system logs (journalctl)"
        echo -e "  ''${BOLD}processes''${NC}  - List all processes with details"
        echo -e "  ''${BOLD}network''${NC}    - Network connections and traffic"
        echo -e "  ''${BOLD}disk''${NC}       - Disk I/O and usage"
        echo -e "  ''${BOLD}memory''${NC}     - Memory usage analysis"
        echo -e "  ''${BOLD}ports''${NC}      - Show listening ports"
        echo ""
        echo -e "''${YELLOW}Examples:''${NC}"
        echo -e "  dbg gdb ./myprogram"
        echo -e "  dbg strace ls -la"
        echo -e "  dbg valgrind ./myprogram"
        echo -e "  dbg logs -u docker"
        exit 0
      fi

      TOOL="$1"
      shift

      case "$TOOL" in
        gdb)
          echo -e "''${GREEN}→ Launching GDB debugger...''${NC}"
          gdb "$@"
          ;;
        lldb)
          echo -e "''${GREEN}→ Launching LLDB debugger...''${NC}"
          lldb "$@"
          ;;
        strace)
          echo -e "''${GREEN}→ Tracing system calls...''${NC}"
          strace -f -tt -T "$@"
          ;;
        ltrace)
          echo -e "''${GREEN}→ Tracing library calls...''${NC}"
          ltrace -f -tt -T "$@"
          ;;
        valgrind)
          echo -e "''${GREEN}→ Running Valgrind memory check...''${NC}"
          valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes "$@"
          ;;
        perf)
          echo -e "''${GREEN}→ Running performance profiler...''${NC}"
          sudo perf record -g "$@"
          echo -e "''${YELLOW}→ Use 'perf report' to view results''${NC}"
          ;;
        heaptrack)
          echo -e "''${GREEN}→ Running heap profiler...''${NC}"
          heaptrack "$@"
          ;;
        bpftrace)
          echo -e "''${GREEN}→ Running eBPF tracer...''${NC}"
          sudo bpftrace "$@"
          ;;
        logs)
          echo -e "''${GREEN}→ System logs (last 50 lines):''${NC}"
          sudo journalctl -n 50 -e "$@" | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          ;;
        processes)
          echo -e "''${GREEN}→ Process list:''${NC}"
          ps auxf --sort=-%mem | head -30 | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          ;;
        network)
          echo -e "''${GREEN}→ Network connections:''${NC}"
          echo -e "''${CYAN}Active connections:''${NC}"
          ss -tunap | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          echo ""
          echo -e "''${CYAN}Network traffic (5 seconds):''${NC}"
          timeout 5 sudo iftop -t -s 5 2>/dev/null || echo "Use Ctrl+C to stop iftop"
          ;;
        disk)
          echo -e "''${GREEN}→ Disk I/O:''${NC}"
          sudo iotop -b -n 3 | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          ;;
        memory)
          echo -e "''${GREEN}→ Memory usage:''${NC}"
          free -h
          echo ""
          echo -e "''${CYAN}Top memory consumers:''${NC}"
          ps aux --sort=-%mem | head -11 | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          ;;
        ports)
          echo -e "''${GREEN}→ Listening ports:''${NC}"
          sudo ss -tulpn | grep LISTEN | ${pkgs.bat}/bin/bat --paging=never --color=always -l log
          ;;
        *)
          echo -e "''${RED}Unknown tool: $TOOL''${NC}"
          echo -e "''${YELLOW}Run 'dbg' without arguments to see available tools''${NC}"
          exit 1
          ;;
      esac
    '')

    (writeShellScriptBin "nix-debug" ''
      #!/usr/bin/env bash
      # Nix-specific debugging helper

      # Colors
      CYAN='\033[0;36m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BOLD='\033[1m'
      NC='\033[0m'

      echo -e "''${CYAN}''${BOLD}Nix Debugging Tools''${NC}"
      echo -e "''${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"

      if [ $# -eq 0 ]; then
        echo -e "''${GREEN}Usage:''${NC} nix-debug <command>"
        echo ""
        echo "Commands:"
        echo "  show-trace     - Show full error trace for last build"
        echo "  eval <expr>    - Evaluate Nix expression"
        echo "  why <path>     - Why is this path in closure?"
        echo "  tree <drv>     - Show derivation dependency tree"
        echo "  diff           - Diff current config with last generation"
        echo "  gc-roots       - Show what's preventing GC"
        exit 0
      fi

      case "$1" in
        show-trace)
          echo -e "''${GREEN}→ Building with full trace...''${NC}"
          nix build --show-trace "$@"
          ;;
        eval)
          shift
          echo -e "''${GREEN}→ Evaluating expression: $*''${NC}"
          nix eval --expr "$@"
          ;;
        why)
          shift
          echo -e "''${GREEN}→ Analyzing closure for: $1''${NC}"
          nix-store --query --roots "$1"
          ;;
        tree)
          shift
          echo -e "''${GREEN}→ Dependency tree:''${NC}"
          nix-store -q --tree "$1"
          ;;
        diff)
          echo -e "''${GREEN}→ Configuration diff:''${NC}"
          sudo nix profile diff-closures --profile /nix/var/nix/profiles/system
          ;;
        gc-roots)
          echo -e "''${GREEN}→ GC roots:''${NC}"
          nix-store --gc --print-roots
          ;;
        *)
          echo -e "''${YELLOW}Unknown command. Run without arguments for help.''${NC}"
          ;;
      esac
    '')
  ];

  #kernelcore.ml.offload.enable = false;
  #kernelcore.ml.offload.api.enable = false;

  # ===== DISTRIBUTED BUILDS CONFIGURATION =====
  # Offload heavy builds to desktop (192.168.15.7)
  nix.buildMachines = [{
    hostName = "192.168.15.7";
    sshUser = "nix-builder";
    sshKey = "/home/kernelcore/.ssh/id_ed25519";  # SSH key for remote builds
    system = "x86_64-linux";
    maxJobs = 8;              # Desktop has more cores
    speedFactor = 2;          # Desktop is 2x faster
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];

  nix.distributedBuilds = true;

  nix.settings = {
    builders-use-substitutes = true;  # Try desktop cache first
    max-jobs = 4;                      # Allow local builds for small packages
    cores = 0;                         # Use all available cores
    fallback = true;                   # Build locally if desktop unavailable
  };

  programs.vscodium-secure = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      rooveterinaryinc.roo-cline
    ];
  };

  # Proton Pass - Secure password manager
  programs.protonpass.enable = true;

  # ═══════════════════════════════════════════════════════════════════
  # Tailscale Configuration - Using new modular system
  # Config: modules/network/vpn/tailscale-laptop.nix (imported above)
  # ═══════════════════════════════════════════════════════════════════
  # OLD system disabled (was conflicting):
  # kernelcore.network.proxy.tailscale-services.enable = true;
  # kernelcore.network.monitoring.tailscale.enable = true;

  # Monitor still works via new system
  kernelcore.network.monitoring.tailscale.enable = true;

  # Optional: Enable firewall zones
  kernelcore.network.security.firewall-zones.enable = true;

  # ═══════════════════════════════════════════════════════════════════
  # SSH Configuration - Declarative SSH client setup
  # ═══════════════════════════════════════════════════════════════════
  kernelcore.ssh.enable = true;



  system.stateVersion = "26.05";
}
