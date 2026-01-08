{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules # Import all shared modules
  ];

  # ============================================================================
  # SYSTEM BASICS
  # ============================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.kernelcore = {
    isNormalUser = true; # <--- ISSO RESOLVE O ERRO DA ASSERTION 1
    description = "K8s Node Admin";
    extraGroups = [
      "wheel"
      "docker"
    ]; # wheel para sudo, docker para containers
    group = "users"; # <--- ISSO RESOLVE O ERRO DA ASSERTION 2 (Opcional, 'users' é padrão se isNormalUser)
  };
  # Como é um servidor, idealmente use apenas chaves SSH
  #openssh.authorizedKeys.keys = [
  #"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." # Sua chave pública da workstation
  #];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  networking = {
    hostName = "k8s-node-01";
    domain = "cluster.local";

    # Use systemd-resolved
    useNetworkd = true;
    useDHCP = false;

    interfaces.enp0s3 = {
      # Adjust to your interface
      useDHCP = true;
    };

    # GEMINI: Networking configuration for the kubernetes
    # Firewall is handled by modules (k3s-cluster.nix handles ports)
    firewall.enable = true;
  };

  # Set your time zone.
  time.timeZone = "UTC";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # KUBERNETES STACK (K3S)
  # ============================================================================

  services.k3s-cluster = {
    enable = true;
    role = "server";

    # Use centralized SOPS secret
    tokenFile = config.sops.secrets.k3s-token.path;

    disableComponents = [
      "traefik"
      "servicelb"
      "local-storage"
    ];
  };

  # ============================================================================
  # SOPS SECRETS MANAGEMENT
  # ============================================================================

  # Enable centralized Kubernetes secrets
  kernelcore.secrets.k8s.enable = true;

  # ============================================================================
  # GPU SUPPORT (for PHANTOM ML workloads)
  # ============================================================================

  # GEMINI: Install Systemd Daemon NVIDIA device plugin for K8s
  systemd.services.nvidia-device-plugin = {
    description = "NVIDIA Device Plugin for Kubernetes";
    after = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];

    # Only run if k3s is enabled
    enable = config.services.k3s-cluster.enable; # Fixed reference to module option

    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      ${pkgs.kubectl}/bin/kubectl apply -f \
        https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml || true
    '';
  };

  # ============================================================================
  # ADDITIONAL TOOLS & PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # K8s management
    k9s
    stern
    kubectx
    kustomize
    kubernetes-helm
    argocd

    # Container tools
    dive # Image analysis
    skopeo # Image operations
    buildah # Build OCI images

    # Networking tools
    cilium-cli
    hubble

    # Monitoring
    prometheus
    grafana

    # Development
    go
    python313
    nodejs

    # Basics
    vim
    git
    tmux
    htop
    curl
    wget
  ];

  # ============================================================================
  # SYSTEM OPTIMIZATIONS
  # ============================================================================

  # GEMINI: We need to see if is already aplied
  # k3s-cluster.nix handles some, but we add inotify specifically
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # ============================================================================
  # QUICK START HELPERS
  # ============================================================================

  # GEMINI: Helpers for integrate
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
          ;;;

        ui)
          echo "Opening Hubble UI: http://localhost:12000"
          echo "Opening Longhorn UI: http://localhost:8000"
          ;;;

        logs)
          stern -n kube-system "$2"
          ;;;

        top)
          kubectl top nodes
          kubectl top pods -A
          ;;;

        test)
          echo "Deploying test application..."
          # kubectl apply -f /etc/longhorn/test-pvc.yaml
          echo "TODO: Create test PVC yaml"
          ;;;

        *)
          echo "Usage: k8s-quickstart.sh {status|ui|logs|top|test}"
          ;;;
      esac
    '';
    mode = "0755";
  };

  # GEMINI: Aliases for integrate
  environment.shellAliases = {
    k = "kubectl";
    kns = "kubens";
    kctx = "kubectx";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kdp = "kubectl describe pod";
    klf = "kubectl logs -f";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
