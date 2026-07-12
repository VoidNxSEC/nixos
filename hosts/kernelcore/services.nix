{ pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# SERVIÇOS — SSH, PostgreSQL, forges git, runners, acesso remoto
# ═══════════════════════════════════════════════════════════

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = false;
    ensureDatabases = [ "kernelcore" ];
    ensureUsers = [
      {
        name = "kernelcore";
        ensureDBOwnership = true;
      }
    ];
  };

  services.etcd = {
    enable = false;
    name = "etc";
  };

  # ── Forges git ──
  services.forgejo = {
    enable = false; # PENDENTE: reativar após restaurar secrets forgejo
  };

  # Integração Forgejo (gate = services.forgejo.enable upstream)
  kernelcore.services.forgejo = {
    publicDomain = "forgejo.nx.tailb3b82e.ts.net";
    publicUrl = "http://forgejo.nx.tailb3b82e.ts.net/";
    listenPort = 3002;
    proxy.enable = false;
    tls.enable = false;
    integratedSsh = {
      enable = true;
      port = 22;
      listenPort = 2222;
    };
    database = {
      type = "postgres";
      name = "forgejo";
      user = "forgejo";
      createLocally = true;
    };
  };

  kernelcore.services.gitea-showcase = {
    enable = false;
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

  # ── CI runners ──
  kernelcore.services.github-runner = {
    enable = false;
    org = {
      enable = true;
      # Org-level runner covers all VoidNxSEC repos automatically.
      url = "https://github.com/VoidNxSEC";
      name = "kernelcore-org";
      labels = [
        "linux"
        "gpu"
        "nix"
        "docker"
        "python"
        "node"
        "containers"
        "security"
      ];
    };
    extraPackages = with pkgs; [
      docker
      docker-compose
      docker-buildx
      podman
      podman-compose
      python313
      python313Packages.pip
      nodejs_24
      bun
      syft
      semgrep
    ];
  };

  # GitLab Runner disabled: token not configured (useSops=false + empty registrationToken)
  # causes 400 Bad Request spam. Re-enable after setting a valid token via SOPS.
  kernelcore.services.gitlab-runner = {
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

  kernelcore.ci = {
    enable = false;
    role = "combined";
    title = "Kernelcore CI";
    titleUrl = "https://voidnx.com";
    buildbotUrl = "http://127.0.0.1:8010/";
    listenAddress = "127.0.0.1";
    port = 8010;
    pbPort = 9989;
    jobs.enableFlakeCheck = true;
    jobs.suites = [ ];
    worker.extraGroups = [
      "docker"
      "nix"
    ];
  };

  # ── Acesso remoto ──
  kernelcore.services.mosh = {
    enable = true;
    openFirewall = true;
    enableMotd = true;
  };

  kernelcore.services.mobile-workspace = {
    enable = true;
    username = "mobile";
    workspaceDir = "/srv/mobile-workspace";
    enableGitAccess = true;
    sshKeys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG5StF4nUzkEsUei88BstktP/Q/g8BvlHeWnEDD+ii/jB7Fs4v4imG05tJU/jC8/ax2FFRSwoBRt7tH6RDp4Dys= user@iphone"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBE2jQWzD7N9sMWW+UKBNuxzS5v3Dt5g6UbZ/kd49b7XJugBLma8152DogVrblUxhPqfQfcCVrMHNHFlIkXAB9w= voidnxlabs"
    ];
  };

  # ── Infra auxiliar ──
  kernelcore.services.offload-server = {
    enable = false;
    cachePort = 5000;
    builderUser = "nix-builder";
    cacheKeyPath = "/var/cache-priv-key.pem";
    enableNFS = true;
  };

  kernelcore.services.gpu-orchestration = {
    enable = false;
    defaultMode = "local";
  };

  kernelcore.services.config-auditor.enable = true;
}
