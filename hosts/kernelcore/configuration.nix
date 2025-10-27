{
  config,
  lib,
  pkgs,
  ...
}:

{

  kernelcore = {
    system = {
      memory.optimizations.enable = true;
      nix.optimizations.enable = true;
      nix.experimental-features.enable = true;
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = true;
      audit.enable = true;

      # HIGH PRIORITY SECURITY ENHANCEMENTS
      # File integrity monitoring - detects unauthorized file modifications
      aide.enable = false;

      # Antivirus scanning for malware detection
      clamav.enable = true;

      # Enhanced SSH security hardening
      ssh.enable = true;

      # Kernel security hardening (sysctl, module blacklist)
      kernel.enable = true;

      # PAM (Pluggable Authentication Modules) hardening
      pam.enable = true;

      # Install security audit and monitoring tools
      packages.enable = true;
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
          gitlab = true; # GitLab CLI and tools
          gitea = true; # Gitea CLI (local git server integration)
        };
        pre-commit = {
          enable = true;
          formatCode = true; # Auto-format code before commits
          runTests = false; # Set to true when you have automated tests
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
    };

    services.github-runner = {
      # OPTIONAL: Enable self-hosted GitHub Actions runner when needed
      # Requires secrets/github.yaml to be configured with registration token
      # Default: use GitHub-hosted runners (more reliable, no local resource usage)
      enable = false; # Set to true to enable self-hosted runner
      useSops = true; # SOPS fixed: now safe to enable when needed
      runnerName = "nixos-self-hosted";
      repoUrl = "https://github.com/marcosfpina"; # Organization-level runner
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

    # MEDIUM PRIORITY: Standardized ML model storage
    ml.models-storage = {
      enable = true;
      baseDirectory = "/var/lib/ml-models";
    };

    # Centralized ML/GPU user and group management
    system.ml-gpu-users.enable = true;
  };

  services = {
    gnome.core-shell.enable = true;
    gnome.core-apps.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "br";
        variant = "";
      };
    };

    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    llamacpp = {
      enable = true;
      model = "/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
      port = 8080;
      n_threads = 40;
      n_gpu_layers = 24; # Reduced from 32 to 24 (~2.5GB VRAM instead of ~5GB)
      n_parallel = 1;
      n_ctx = 2048; # Reduced from 4096 to 2048 (~400MB VRAM for KV cache)
      # Total VRAM usage: ~2.9GB (allows coexistence with other GPU services)
    };

    ollama = {
      enable = true;
      host = "127.0.0.1"; # Security: Bind to localhost only
      port = 11434; # Default port - Docker ollama uses 11435
      acceleration = "cuda";
      # GPU memory management: unload models after 5 minutes of inactivity
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "5m"; # Unload models after 5min idle to free VRAM
      };
      # NOTE: Systemd ollama service uses port 11434
      # Docker ollama in ~/Dev/Docker.Base/sql/docker-compose.yml uses host port 11435
      # To run ollama manually: OLLAMA_HOST=127.0.0.1:11435 ollama serve
    };

    gitea = {
      enable = true;
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

    #chromiumOrg = {
    #enable = true;
    # opcional: use ungoogled-chromium
    # package = pkgs.ungoogled-chromium;

    # flags extra
    #extraArgs = [
    #"--force-dark-mode"
    # "--disable-print-preview"
    #];

    # variáveis de ambiente
    #env = {
    #HTTP_PROXY = "http://proxy.local:3128";
    #HTTPS_PROXY = "http://proxy.local:3128";
    #};

    # regras de organização (mapeadas para policies)
    #rules = {
    #homepage = "https://intranet.sua-orga";
    #homepageIsNewTabPage = false;
    #restoreOnStartup = 4; # abrir URLs específicas
    #startupUrls = [ "https://intranet.sua-orga" "https://docs.sua-orga" ];

    #defaultSearch = {
    # name = "Brave";
    #searchUrl = "https://search.brave.com/search?q={searchTerms}";
    #suggestUrl = "https://search.brave.com/api/suggest?q={searchTerms}";
    #iconUrl = "https://brave.com/static-assets/images/press/brave-icon.png";
    #};

    #safeBrowsing = 1; # 0=off, 1=padrão, 2=avançado
    #passwordManagerEnabled = false;
    #incognitoModeAvailability = 1; # 0=habilitado, 1=desabilitado, 2=forçado
    #browserSignin = 0; # 0=desabilitado, 1=habilitado, 2=forçado
    #syncDisabled = true;

    #urlBlocklist = [ "*://*.rede-social.com/*" ];
    #urlAllowlist = [ "https://docs.sua-orga/*" "https://intranet.sua-orga/*" ];

    #downloadDirectory = "/var/lib/chromium-downloads";
    #promptForDownload = false;

    #showHomeButton = true;
    #defaultBrowserSettingEnabled = false;

    #proxyMode = "fixed_servers";
    #proxyServer = "http=proxy.local:3128;https=proxy.local:3128";

    #printingEnabled = true;
    #};

    # extensões via policy (forcelist / allowlist / blocklist)
    #extensions = {
    #force = [
    #{ id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
    #{ id = "aapocclcgogkmnckokdopfmhonfmgoek"; } # Google Docs Offline
    #];
    #allowlist = [ ];
    #blocklist = [ "cfhdojbkjhnklbpkdaibdccddilifddb" ]; # ex: bloquear Adblock
    #};

    # onde escrever as policies (padrão Chromium)
    #policiesPath = "/etc/chromium/policies/managed";
    #policyFileName = "policies.json";

    # substitui o binário no PATH por um wrapper com flags/ENV
    #replaceSystemChromium = true;
    #};

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
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];

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
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "nvidia"
      "docker"
      "render"
      "qemu-libvirtd"
      "libvirtd"
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";
    packages = with pkgs; [

      obsidian
      sssd
      vscodium
      trezor-suite
      tmux
      starship
      terraform


      awscli2

      gemini-cli
      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm

      gnome-secrets

      libreoffice
      onlyoffice-desktopeditors

      certbot

      python313Packages.groq

      codex
      claude-code

      python313Packages.openai

      alacritty
      xclip

      glab
      gh
      codeberg-cli

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

  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
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
  ];

  system.stateVersion = "25.05";
}
