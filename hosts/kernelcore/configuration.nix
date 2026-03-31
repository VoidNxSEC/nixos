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

  # Chromium/Electron log suppression (GPU/Wayland error spam)
  kernelcore.chromium.logSuppression = {
    enable = true;
    applyGlobally = true;
    enablePerformanceFlags = false; # Keep disabled for stability
  };

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
        enable = false;
        local.enable = false;
        # URL: http://192.168.15.9:5000 (default)
      };
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = true;
      audit.enable = true;
      tls = {
        enable = true;
        email = "sec@voidnxlabs.com";
        dnsProvider = "cloudflare";
        environmentFile =
          if config.sops.secrets ? "certificates/dns-provider-env" then
            config.sops.secrets."certificates/dns-provider-env".path
          else
            null;
        credentialFiles =
          if config.sops.secrets ? "certificates/cloudflare-dns-api-token" then
            {
              "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."certificates/cloudflare-dns-api-token".path;
              "CF_ZONE_API_TOKEN_FILE" = config.sops.secrets."certificates/cloudflare-dns-api-token".path;
            }
          else
            { };
        certs = {
          "gitea.voidnx.com" = {
            extraDomainNames = [ "git.voidnx.com" ];
            reloadServices = [ "nginx.service" ];
          };
          "forgejo.voidnx.com" = {
            reloadServices = [ "nginx.service" ];
          };
        };
      };

      # HIGH PRIORITY SECURITY ENHANCEMENTS
      aide.enable = true;
      clamav.enable = false;
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
        hostname = "kernelcore";
        tailnetDomain = "tailb3b82e.ts.net";
      };

      proxy.nginx-public = {
        enable = true;
        services = {
          gitea = {
            enable = true;
            host = "gitea.voidnx.com";
            upstreamPort = 3000;
            maxBodySize = "200M";
          };
          forgejo = {
            enable = true;
            host = "forgejo.voidnx.com";
            upstreamPort = 3002;
            maxBodySize = "200M";
          };
        };
      };

      vpn.tailscale.hostname = lib.mkForce "kernelcore";

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

    applications.zellij.enable = false;

    packages.claude.enable = false;
    packages.zellij.enable = false;
    packages.lynis.enable = true;
    packages.js.enable = false;
    packages.f5-tts.enable = lib.mkForce false;
    packages.hubstaff.enable = false;

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
        enable = true; # Set to true to enable custom Antigravity build
        profile = "balanced"; # Options: performance, balanced, minimal
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
          gitlab = true;
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
      nixos.enable = true;

      # ML/AI Containers
      ml = {
        enable = false;

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
        enable = false;

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
      enable = false;
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

    # GitLab Runner disabled: token not configured (useSops=false + empty registrationToken)
    # causes 400 Bad Request spam. Re-enable after setting a valid token via SOPS.
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
    secrets.blockchain.enable = true; # Ethereum, IPFS, Arweave secrets
    secrets.k8s.enable = true;
    secrets.grok.enable = true;
    secrets.gitlab.enable = true;
    secrets.api-keys.enable = true; # DeepSeek, Anthropic, Mistral, Gemini

    ml.models-storage = {
      enable = true;
      baseDirectory = "/var/lib/ml-models";
    };

    ml.mcp = {
      enable = true;
      knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
      agents = {
        roo = {
          enable = true;
          projectRoot = "/home/kernelcore/master";
          configPath = "/home/kernelcore/.roo/mcp.json";
    secrets.ci.enable = true;
    secrets.certificates.enable = true;
          user = "kernelcore";
        };

        # -----------------------------------------------------------
        # AGENTES MCP
        # -----------------------------------------------------------
        codex = {
          enable = true;
          projectRoot = "/home/kernelcore/master";
          configPath = "/home/kernelcore/.codex/mcp_config.json";
          user = "kernelcore";
        };

    ci = {
      enable = true;
      role = "combined";
      worker = {
        passwordFile =
          if config.sops.secrets ? "ci/buildbot-worker-password" then
            config.sops.secrets."ci/buildbot-worker-password".path
          else
            null;
        extraGroups = [ "buildbot" ];
      };
      jobs = {
        suites = [ "security" ];
        enableTailscaleSmoke = false;
      };
    };

        gemini = {
          enable = true;
          projectRoot = "/home/kernelcore/master";
          configPath = "/home/kernelcore/.gemini/mcp_config.json";
          user = "kernelcore";
        };

        antigravity = {
          enable = true;
          projectRoot = "/home/kernelcore/master";
          configPath = "/home/kernelcore/.gemini/antigravity/mcp_config.json";
          user = "kernelcore";
        };

        zed-editor = {
          enable = true;
          projectRoot = "/home/kernelcore/master";
          configPath = "/home/kernelcore/.config/zed/mcp_config.json";
          user = "kernelcore";
        };
      };
    };

    # ═══════════════════════════════════════════════════════════
    # AI AGENT HUB - Event-Driven Automation with Speech
    # ═══════════════════════════════════════════════════════════
    ai.agent-hub = {
      # Infrastructure (Nomad orchestrator + Redpanda/Kafka)
      # Disabled: eating too much RAM; re-enable when needed
      infra = {
        enable = false;
        orchestrator = "nomad";
      };

      # Speech Capabilities (F5-TTS + Whisper STT)
      capabilities.speech = {
        enable = true;
        enableTTS = false; # TODO: f5-tts wheel checa deps na instalação, falta propagatedBuildInputs completo
        enableSTT = true; # Whisper speech-to-text

        # Whisper model: tiny, base, small, medium, large
        # base = good balance between speed and accuracy
        whisperModel = "base";

        # Voice cloning reference (opcional - deixar default por enquanto)
        referenceText = "Olá, eu sou o assistente inteligente do Agent Hub.";
      };
    };

    system.ml-gpu-users.enable = true;

    # LlamaSwap - Hot Model Reloading Configuration
    llama-swap = {
      enable = true;

      profiles = {
        coder = {
          modelPath = "/var/lib/ml-models/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
          displayName = "Qwen 2.5 Coder 7B (Q4)";
          gpuLayers = 47;
          contextSize = 8192;
          #n_ctx = 8192;
          #n_batch = 8192;
        };

        reasoning = {
          modelPath = "/var/lib/ml-models/llamacpp/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf";
          displayName = "DeepSeek-R1 8B (Q4)";
          gpuLayers = 42;
          contextSize = 8192;
        };

        thinking = {
          modelPath = "/var/lib/ml-models/llamacpp/models/Llama3.3-8B-Instruct-Thinking-Claude-4.5-Opus-High-Reasoning.i1-Q4_K_M.gguf";
          displayName = "Llama 3.3 Thinking 8B (Q4)";
          gpuLayers = 42;
          contextSize = 8192;
        };

        fast = {
          modelPath = "/var/lib/ml-models/llamacpp/models/qwen3-vl:2b";
          displayName = "Qwen3 VL 2B (Fast)";
          gpuLayers = 999; # Full offload for small model
          contextSize = 4096;
        };
      };

      defaultProfile = "coder";
    };

    # Shell control scripts
    shell = {
      serviceControl.enable = true; # GPU/ML service control & RAM optimization
      llamaSwapControl.enable = true; # LlamaSwap hot model reloading control
    };
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
        workdir = "/home/kernelcore/master";
        environment = "production";
        env = {
          PROJECT_NAME = "NixOS Configuration";
          PROJECT_TYPE = "infrastructure";
        };
      };

      dev = {
        workdir = "/home/kernelcore/master";
        environment = "development";
        env = {
          PROJECT_NAME = "Development";
          PROJECT_TYPE = "general";
        };
      };

      gemini = {
        workdir = "/home/kernelcore/master";
        environment = "development";
        env = {
          PROJECT_NAME = "Gemini Agent";
          PROJECT_TYPE = "ai-agent";
        };
      };

      codex = {
        workdir = "/home/kernelcore/master";
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
      enable = false; # Disabled in favor of llamacpp-swap
      model = "/var/lib/llamacpp/models/Qwen2.5_Coder_7B_Instruct";
      host = "127.0.0.1";
      port = 8080;
      n_threads = 12;
      n_threads_batch = 12;
      n_gpu_layers = 40;
      mainGpu = 1;
      n_parallel = 1;
      n_ctx = 8196;
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

    # LlamaSwap - Hot Model Reloading
    llamacpp-swap = {
      enable = true;
      host = "127.0.0.1";
      port = 8081;
      n_threads = 12;
      n_threads_batch = 12;
      n_gpu_layers = 52;
      mainGpu = 1;
      n_parallel = 1;
      n_ctx = 8192;
      n_batch = 512;
      n_ubatch = 512;
      cudaGraphs = true;
      flashAttention = true;
      mmap = true;
      mlock = true;
      continuousBatching = true;
      speculativeDecoding.enable = false;
      metricsEndpoint = true;
    };

    # TabbyAPI - OpenAI-compatible Inference Server
    #tabbyapi = {
    #enable = false;
    #host = "127.0.0.1";
    #port = 7734;
    #modelsDir = "/var/lib/ml-models";
    #maxSeqLen = 16384;
    #cacheMode = "FP16";
    #gpuSplitAuto = true;
    #openFirewall = false; # Acessível de containers Docker, mas não da internet
    #};

    # Open-WebUI - Self-hosted AI Chat Interface (ML Hardcore Mode)
    # Open-WebUI - upstream NixOS module (simple config)
    open-webui = {
      enable = false;
      host = "127.0.0.1";
      port = 3000;
      openFirewall = false;

      # Configuração via environment variables
      environment = {
        # Backend: TabbyAPI
        OPENAI_API_BASE_URL = "http://127.0.0.1:7734/v1";
        OPENAI_API_KEY = "not-needed";
        ENABLE_OPENAI_API = "true";
        ENABLE_OLLAMA_API = "false";

        # Disable analytics
        SCARF_NO_ANALYTICS = "true";
        DO_NOT_TRACK = "true";
        ANONYMIZED_TELEMETRY = "false";

        # Features
        ENABLE_SIGNUP = "false";
        DEFAULT_USER_ROLE = "user";
        ENABLE_IMAGE_GENERATION = "false";
      };
    };

    gitea-showcase = {
      enable = true;
      domain = "gitea.voidnx.com";
      rootUrl = "https://gitea.voidnx.com/";
      listenAddress = "127.0.0.1";
      httpPort = 3000;
      showcaseProjectsPath = "/home/kernelcore/dev/projects";
      gitea = {
        adminTokenFile = "/run/secrets/gitea-admin-token";
        autoInitRepos = false;
      };
      autoMirror = {
        enable = false;
        interval = "hourly";
      };
    };

    forgejo = {
      enable = true;
      settings = {
        DEFAULT.APP_NAME = "Forgejo";
        server = {
          DOMAIN = "forgejo.voidnx.com";
          ROOT_URL = "https://forgejo.voidnx.com/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3002;
          PROTOCOL = "http";
          DISABLE_SSH = true;
          SSH_PORT = 22;
        };
        service = {
          DISABLE_REGISTRATION = true;
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
          DEFAULT_ORG_VISIBILITY = "private";
        };
        session.COOKIE_SECURE = true;
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
        #"--enable-gpu-rasterization"
        # REMOVED: --enable-zero-copy (incompatível com NVIDIA+Wayland+GBM)
        # Causa EGL_BAD_MATCH errors (0x3009) ao tentar criar EGLImages
        "--ozone-platform-hint=auto"
        # NVIDIA+Wayland specific fixes para EGL errors
        "--use-gl=egl"
        "--disable-gpu-driver-bug-workarounds"
        "--no-first-run"
        "--disable-sync"
      ];
    };

    udisks2.enable = true;
    gvfs.enable = true;
    tailscale.enable = true;
    config-auditor.enable = true;
    i915-governor.enable = false;

    # ═══════════════════════════════════════════════════════════
    # SPOOKNIX - Privacy-first STT Engine (Docker container)
    # ═══════════════════════════════════════════════════════════
    spooknix = {
      enable = true;
      model = "large-v3";
      device = "cuda";
      port = 8000;
    };
  }; # FIM DO BLOCO SERVICES

  programs.niri.enable = false;

  imports = [ ./specialisations ];

  #kernelcore.hyprland.performance = {
  #enable = config.services.hyprland-desktop.enable;
  #mode = "balanced";
  #};

  systemd.tmpfiles.rules = [
    "d /var/lib/mcp-knowledge 0755 kernelcore users -"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
  kernelcore.hardware.intel.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true; # <--- Critical: Enables UWSM wrapper and integration
  };

  # xdg.portal is managed by services.hyprland-desktop module
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   extraPortals = [
  #     pkgs.xdg-desktop-portal-hyprland
  #     pkgs.xdg-desktop-portal-gtk
  #   ];
  #   config.common.default = "*";
  # };
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  console.keyMap = "br-abnt2";
  security.rtkit.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  modules.audio.production.enable = true;

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
      "input"
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
      glab
      waybackurls
      hakrawler
      python313Packages.pyyaml
      python313Packages.langchain
      python313Packages.huggingface-hub_0
      python313Packages.numpy
      awscli
      cemu
      onlyoffice-desktopeditors
      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm
      kind
      git-lfs
      certbot
      flameshot
      claude-code
      codex
      # vllm # FIXME: upstream nixpkgs broken patch for llama-cpp-python (406)
      koboldcpp
      alacritty
      opencode
      xclip
      glab
      gh
      wrangler
      codeberg-cli

      # Custom wrapper for brev to work with read-only .ssh/config
      (pkgs.writeShellScriptBin "brev" ''
        #!/usr/bin/env bash

        # Original brev binary path
        BREV_BIN="${pkgs.brev-cli}/bin/brev"

        # Real paths
        REAL_HOME="$HOME"
        BREV_HOME="$REAL_HOME/.brev"
        NIX_BREV_CONFIG="$REAL_HOME/.ssh/brev_config"

        # Determine if we're running a command that needs config updates
        NEEDS_REFRESH=false
        if [[ "$1" == "refresh" ]] || [[ "$1" == "login" ]] || [[ "$1" == "start" ]] || [[ "$1" == "open" ]] || [[ "$1" == "shell" ]]; then
            NEEDS_REFRESH=true
        fi

        if [ "$NEEDS_REFRESH" = true ]; then
            # Create a fake home environment for SSH config checking
            FAKE_HOME="/tmp/brev_fake_home_$$"
            mkdir -p "$FAKE_HOME/.ssh"

            # Brev needs to see this exact line or it will try to write to it and fail
            echo 'Include "/home/kernelcore/.brev/ssh_config"' > "$FAKE_HOME/.ssh/config"
            chmod 600 "$FAKE_HOME/.ssh/config"

            # Symlink the real .brev directory so we don't lose session data
            ln -s "$BREV_HOME" "$FAKE_HOME/.brev"

            # Run the actual command with the fake HOME
            HOME="$FAKE_HOME" "$BREV_BIN" "$@" || EXIT_CODE=$?

            # Cleanup
            rm -rf "$FAKE_HOME"

            echo "Syncing Brev SSH configuration for NixOS..."
            # Wait a moment to ensure Brev finishes writing
            sleep 1

            if [ -f "$BREV_HOME/ssh_config" ]; then
                # Replace the fake home path with the real home path in the config
                sed "s|$FAKE_HOME|$REAL_HOME|g" "$BREV_HOME/ssh_config" > "$NIX_BREV_CONFIG"
                # Ensure correct permissions
                chmod 600 "$NIX_BREV_CONFIG"
            fi

            exit ''${EXIT_CODE:-0}
        else
            # For pure read commands, just run normally
            exec "$BREV_BIN" "$@"
        fi
      '')

      slack
      zoom
      gnome-console
      zed-editor
      code-cursor
      rust-analyzer
      rustup
      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault
      anytype
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
      enableGitLabDuo = true;
      extensions = with pkgs.vscode-extensions; [
        rooveterinaryinc.roo-cline
      ];
    };
    brave-secure.enable = false;
    firefox-privacy.enable = true;
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
    # ffmpeg # TEMPORARILY DISABLED: Build broken in current nixpkgs
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
    # antigravity # Replaced by custom build
  ];

  kernelcore.shell.cli-helpers = {
    enable = true;
    flakePath = "/etc/nixos";
    hostName = "kernelcore";
  };

  kernelcore.shell.nix-ops.enable = true;

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

  # Enable Remote SSH extension for VSCode-like editors
  programs.vscode-remote-ssh = {
    enable = true;
    installFor = [
      "vscode"
      "cursor"
      "windsurf"
    ];
  };

  system.stateVersion = "26.05";
}
