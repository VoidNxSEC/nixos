{
  config,
  lib,
  pkgs,
  ...
}:

let
  baseProfile = {
    system = {
      memory.optimizations.enable = true;
      nix.optimizations.enable = true;
      nix.experimental-features.enable = true;
    };

    /*
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
        ssh.enable = false;

        # Kernel security hardening (sysctl, module blacklist)
        kernel.enable = true;

        # PAM (Pluggable Authentication Modules) hardening
        pam.enable = true;

        # Install security audit and monitoring tools
        packages.enable = true;
      };
    */

    network = {
      dns-resolver = {
        enable = true;
        # DNSSEC desabilitado temporariamente - muitos domínios não têm DNSSEC configurado
        # Causa "DNSSEC validation failed: no-signature" em domínios populares (anthropic.com, npmjs.org, etc)
        # Para reabilitar: descomente a linha abaixo e faça rebuild
        #enableDNSSEC = true;
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
        enable = false; # Ensure br0 exists via NetworkManager; uplink auto-detected if unset
        uplinkInterface = ""; # set explicitly if auto-detect picks wrong device
        ipv6.enable = false;
      };

      # vpn.nordvpn = {
      #   Não entrega muito
      #   enable = false; # Habilite se quiser usar VPN
      #   autoConnect = false;
      #   overrideDNS = false; # IMPORTANTE: deixar systemd-resolved gerenciar DNS
      # };
    };

    #nvidia = {
    # enable = false;
    #cudaSupport = false;
    #};

    #hardware.wifi-optimization.enable = false;

    #development = {
    #rust.enable = true;
    #go.enable = true;
    #python.enable = true;
    #nodejs.enable = true;
    #nix.enable = true;
    #jupyter = {
    #enable = true;
    #kernels = {
    #python.enable = true;
    #rust.enable = true;
    #nodejs.enable = true;
    #nix.enable = true; # ADDED: Nix kernel for Jupyter notebooks
    #};
    #extensions.enable = true;
    #};

    # MEDIUM PRIORITY: CI/CD and code quality tools
    #cicd = {
    #enable = false;
    #platforms = {
    #github = true; # GitHub CLI and tools
    #gitlab = true; # GitLab CLI and tools
    #gitea = true; # Gitea CLI (local git server integration)
    #};
    #pre-commit = {
    #enable = false;
    #formatCode = true; # Auto-format code before commits
    #runTests = false; # Set to true when you have automated tests
    #};
    #};
    #};

    #containers = {
    #docker.enable = false;
    # podman = {
    #   enable = false; # Set to true to use Podman instead of/alongside Docker
    # dockerCompat = false; # Enable Docker CLI compatibility (creates docker -> podman alias)
    # enableNvidia = true; # NVIDIA GPU support for containers
    # };
    #  nixos.enable = false;
    #};

    #virtualization = {
    #enable = false;
    #virt-manager = true;
    #libvirtdGroup = [ "cypher" ];
    #virtiofs.enable = true;
    # Centralized VM registry (managed by modules/virtualization/vms.nix)
    #vmBaseDir = "/srv/vms/images";
    #sourceImageDir = "/var/lib/vm-images";
    #vms = {
    #wazuh = {
    #enable = false;
    # Resolve under sourceImageDir unless absolute
    #sourceImage = "wazuh-4.14.0.qcow2";
    # Final image location (symlink created if missing)
    #imageFile = null; # defaults to vmBaseDir/wazuh.qcow2
    #memoryMiB = 4096;
    #vcpus = 2;
    #network = "nat"; # NAT networking via libvirt default network
    #bridgeName = "br0";
    #sharedDirs = [
    #{
    #path = "/srv/vms/shared";
    #tag = "hostshare";
    #driver = "virtiofs";
    #readonly = false;
    #create = true;
    #}
    #];
    #autostart = false;
    #extraVirtInstallArgs = [
    #"--graphics type=vnc,listen=0.0.0.0"
    #];
    #};
    #};
    #};

    #services.github-runner = {
    # OPTIONAL: Enable self-hosted GitHub Actions runner when needed
    # Requires secrets/github.yaml to be configured with registration token
    # Default: use GitHub-hosted runners (more reliable, no local resource usage)
    #enable = false; # Set to true to enable self-hosted runner
    #useSops = false; # SOPS fixed: now safe to enable when needed
    #runnerName = "nixos-self-hosted";
    #repoUrl = "https://github.com/voidnxSEC"; # Organization-level runner
    #extraLabels = [
    #"nixos"
    #"nix"
    #"linux"
    # ];
    #};

    #services.gpu-orchestration = {
    #enable = false;
    #defaultMode = "docker"; # Docker containers get GPU priority by default
    #};

    #services.gitlab-runner = {
    #enable = false; # Set to true to enable GitLab CI/CD runner
    #useSops = false; # Enable when you have secrets/gitlab.yaml configured
    #runnerName = "nixos-gitlab-runner";
    #url = "https://gitlab.com"; # Or your self-hosted GitLab instance
    #executor = "shell"; # Options: shell, docker, docker+machine, kubernetes
    #tags = [
    #"nixos"
    #"nix"
    #"linux"
    #];
    #concurrent = 4;
    #};

    # MEDIUM PRIORITY: Standardized secrets management
    #secrets.sops = {
    #enable = false;
    #secretsPath = "/etc/nixos/secrets";
    #ageKeyFile = "/var/lib/sops-nix/key.txt";
    #};

    #secrets.api-keys.enable = false; # Load decrypted API keys

    # MEDIUM PRIORITY: Standardized ML model storage
    #ml.models-storage = {
    #enable = false;
    #baseDirectory = "/var/lib/ml-models";
    #};

    # Centralized ML/GPU user and group management
    #system.ml-gpu-users.enable = false;

    # Desktop Cache Server for Laptop Offloading
    #system.binary-cache.enable = true;
    #system.binary-cache.local.enable = true;
  };
  kernelcoreProfile = lib.recursiveUpdate baseProfile {
    desktop.i3.enable = true;
  };
in
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  kernelcore = lib.recursiveUpdate kernelcoreProfile {
    services = {
      users = {
        codex = {
          enable = true;
          userName = "codex";
          homeDirectory = "/var/lib/codex";
          sudoNoPasswd = true;
          nixTrusted = true;
        };
      };
    };
  };

  services = {
    #gnome.core-shell.enable = true;
    #gnome.core-apps.enable = true;
    #xserver = {
    #enable = true;
    #videoDrivers = [ "nvidia" ];
    #xkb = {
    #layout = "br";
    #variant = "";
    #};
    #};

    #desktopManager.gnome.enable = true;
    #displayManager.gdm = {
    #enable = true;
    #wayland = true;
    #};

    # Desktop Cache + Offload Server
    nixos-cache-server = {
      enable = true;
      hostName = "cache.kernelcore.local";
      bindAddress = "0.0.0.0";
      enableTLS = false;
      enableMonitoring = true;
      workers = 6;
      resources = {
        memoryMax = "4G";
        memoryHigh = "3.5G";
        cpuQuota = "400%";
        tasksMax = 100;
      };
    };

    nix-builder.enable = true;

    nixos-cache-monitoring = {
      enable = false;
      enablePrometheus = true;
      enableNodeExporter = true;
      openFirewall = true;
    };

    nixos-cache-api = {
      enable = false;
      openFirewall = true;
    };

    openssh = {
      enable = true;
      openFirewall = true;
      ports = [ 22 ];
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }
      ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };

    #llamacpp = {
    #enable = false;
    #model = "/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
    #port = 8080;
    #n_threads = 40;
    #n_gpu_layers = 32; # Reduced from 32 to 24 (~2.5GB VRAM instead of ~5GB)
    #n_parallel = 1;
    #n_ctx = 4096; # Reduced from 4096 to 2048 (~400MB VRAM for KV cache)
    # Total VRAM usage: ~2.9GB (allows coexistence with other GPU services)
    #};

    #ollama = {
    #enable = true;
    #host = "127.0.0.1"; # Security: Bind to localhost only
    #port = 11434; # Default port - Docker ollama uses 11435
    # acceleration = "cuda";
    # GPU memory management: unload models after 5 minutes of inactivity
    # environmentVariables = {
    #   OLLAMA_KEEP_ALIVE = "5m"; # Unload models after 5min idle to free VRAM
    # };
    # NOTE: Systemd ollama service uses port 11434
    # Docker ollama in ~/Dev/Docker.Base/sql/docker-compose.yml uses host port 11435
    # To run ollama manually: OLLAMA_HOST=127.0.0.1:11435 ollama serve
    #};

    gitea = {
      enable = false;
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
          USER = "cypher";
        };
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "cypher" ];
      ensureUsers = [
        {
          name = "cypher";
          ensureDBOwnership = true;
        }
      ];
    };

    # Keep the session awake to avoid hibernation while large downloads run
    logind = {
      settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
        IdleActionSec = "0";
        HandleHibernateKey = "ignore";
        HandleHibernateKeyLongPress = "ignore";
        HibernateDelaySec = "0";
      };
    };

    mcp-server = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 8951;
      roots = [ "/etc/nixos" ];
      logFile = "/var/log/mcp-server/mcp-server.log";
    };

    #etcd = {
    # enable = false;
    #  name = "etc";
    # };

    pulseaudio.enable = true;
    pipewire = {
      enable = false;
      alsa.enable = false;
      alsa.support32Bit = false;
      pulse.enable = true;
    };

    libinput.enable = true;
    printing.enable = true;
  };

  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
    HibernateDelaySec=0
  '';

  # Copy SSL certificates to Gitea directory
  systemd.tmpfiles.rules = [
    "d /var/lib/gitea/custom/https 0750 gitea gitea -"
    "L+ /var/lib/gitea/custom/https/localhost.crt - - - - /home/cypher/localhost.crt"
    "L+ /var/lib/gitea/custom/https/localhost.key - - - - /home/cypher/localhost.key"
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

  console.keyMap = "us";

  security.rtkit.enable = true;
  #hardware.graphics.enable = true;
  #hardware.graphics.enable32Bit = true;
  # hardware.nvidia-container-toolkit.enable moved to modules/hardware/nvidia.nix
  #hardware.nvidia.datacenter.enable = true; # Conflicting with xserver drivers

  #services.xserver.screenSection = ''
  #Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
  #'';

  users.users.cypher = {
    isNormalUser = true;
    description = "server";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      #"nvidia"
      "docker"
      #"render"
      #"libvirtd"
      #"kvm"
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB784LcoYl5UoXxJSbFk60gmPo7WGKn/jmK8gePkkUhw sec@voidnxlabs.com"
    ];
    packages = with pkgs; [

      obsidian
      sssd
      vscodium
      trezor-suite
      tmux
      starship

      awscli2

      gemini-cli

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
      rustup

      terraform-providers.carlpett_sops
    ];
  };

  # Guest user with nvidia group access for testing
  users.users.guest = {
    isNormalUser = true;
    description = "Guest User";
    extraGroups = [
      "video"
      "audio"
    ];
    # Guest user with a simple password (change this!)
    initialPassword = "guest";
  };

  users.extraGroups.docker.members = [ "cypher" ];

  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  #nixpkgs.config.nvidia.acceptLicense = true;

  nix.settings.download-buffer-size = 1024 * 1024 * 512; # 512MiB buffer for slow mirrors

  environment.systemPackages = with pkgs; [
    wget
    curl
    ninja
    #cudatoolkit
    cmake
    xclip
    gcc
    docker-compose
    docker-buildx
    docker
    gnumake
    libfido2
    python313Packages.pyudev
    libudev0-shim
    libusb1
    trezord
    p7zip
  ];

  # DFIR MCP daemon (system-wide)
  systemd.services.dfir-mcp =
    let
      dfirMcpScript = pkgs.writeTextFile {
        name = "dfir-mcp.py";
        executable = true;
        text = ''
          #!/usr/bin/env python3
          import argparse
          import hashlib
          import json
          import os
          import shlex
          import shutil
          import subprocess
          from datetime import datetime
          from http.server import BaseHTTPRequestHandler, HTTPServer


          def hash_file(path):
            h = hashlib.sha256()
            with open(path, "rb") as f:
              for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
            st = os.stat(path)
            return {
              "sha256": h.hexdigest(),
              "size": st.st_size,
              "mtime": datetime.fromtimestamp(st.st_mtime).isoformat(),
              "atime": datetime.fromtimestamp(st.st_atime).isoformat(),
              "ctime": datetime.fromtimestamp(st.st_ctime).isoformat(),
            }


          def run_cmd(cmd):
            proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return {
              "cmd": cmd,
              "returncode": proc.returncode,
              "stdout": proc.stdout,
              "stderr": proc.stderr,
            }


          def exif(path):
            if not shutil.which("exiftool"):
              return {"error": "exiftool not installed"}
            return run_cmd(f"exiftool -json {shlex.quote(path)}")


          def yara_scan(path, rule_dir=None):
            if not shutil.which("yara"):
              return {"error": "yara not installed"}
            rules = rule_dir or os.environ.get("YARA_RULE_DIR")
            if rules:
              return run_cmd(f"yara -r {shlex.quote(rules)} {shlex.quote(path)}")
            return run_cmd(f"yara -s {shlex.quote(path)} {shlex.quote(path)}")


          def binwalk_scan(path):
            if not shutil.which("binwalk"):
              return {"error": "binwalk not installed"}
            return run_cmd(f"binwalk {shlex.quote(path)}")


          def strings_dump(path, max_lines=400):
            if shutil.which("strings"):
              res = run_cmd(f"strings -n 4 {shlex.quote(path)} | head -n {int(max_lines)}")
              return res
            out = []
            with open(path, "rb") as f:
              data = f.read().decode(errors="ignore")
              for line in data.splitlines():
                if any(c.isprintable() for c in line):
                  out.append(line)
                  if len(out) >= max_lines:
                    break
            return {"stdout": "\n".join(out), "returncode": 0, "stderr": ""}


          class Handler(BaseHTTPRequestHandler):
            def _send(self, code, payload):
              body = json.dumps(payload, ensure_ascii=False).encode()
              self.send_response(code)
              self.send_header("Content-Type", "application/json")
              self.send_header("Content-Length", str(len(body)))
              self.end_headers()
              self.wfile.write(body)

            def do_POST(self):
              length = int(self.headers.get("Content-Length", "0"))
              raw = self.rfile.read(length)
              try:
                data = json.loads(raw)
              except Exception as exc:
                self._send(400, {"error": f"invalid json: {exc}"})
                return

              tool = data.get("tool")
              path = data.get("path")
              if tool in {"hash", "exif", "yara", "binwalk", "strings"} and not path:
                self._send(400, {"error": "path is required"})
                return

              if tool == "hash":
                try:
                  self._send(200, hash_file(path))
                except Exception as exc:
                  self._send(500, {"error": str(exc)})
              elif tool == "exif":
                self._send(200, exif(path))
              elif tool == "yara":
                self._send(200, yara_scan(path, data.get("rules")))
              elif tool == "binwalk":
                self._send(200, binwalk_scan(path))
              elif tool == "strings":
                self._send(200, strings_dump(path, data.get("max_lines", 400)))
              else:
                self._send(400, {"error": f"unknown tool {tool}"})

          def main():
            parser = argparse.ArgumentParser(description="DFIR MCP-style server (HTTP JSON, local only).")
            parser.add_argument("--host", default="127.0.0.1")
            parser.add_argument("--port", type=int, default=8950)
            args = parser.parse_args()
            server = HTTPServer((args.host, args.port), Handler)
            print(f"[dfir-mcp] listening on http://{args.host}:{args.port}")
            server.serve_forever()

          if __name__ == "__main__":
            main()
        '';
      };
    in
    {
      description = "DFIR MCP-style HTTP server (local only)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = "cypher";
        Group = "users";
        ExecStart = "${pkgs.python3}/bin/python3 ${dfirMcpScript} --host 127.0.0.1 --port 8950";
        Restart = "on-failure";
        Environment = "YARA_RULE_DIR=/home/cypher/Rules/yara";
      };
    };

  # Sudo passwordless for cypher
  security.sudo.extraRules = [
    {
      users = [ "cypher" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
