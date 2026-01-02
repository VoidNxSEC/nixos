# Example NixOS Configuration with Complete K8s Stack
# Location: /etc/nixos/hosts/k8s-node/configuration.nix
#
# This demonstrates a production-ready K8s setup integrated with your existing NixOS infrastructure

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Your existing modules (from ARCHITECTURE-REPORT.json)
    ./hardware-configuration.nix
    ../../modules/system/base.nix
    ../../modules/security/hardening.nix

    # New K8s stack modules
    ../../modules/containers/k3s-cluster.nix
    ../../modules/network/cilium-cni.nix
    ../../modules/containers/longhorn-storage.nix

    # SOPS for secrets management
    ../../modules/security/sops.nix
  ];

  # ============================================================================
  # KUBERNETES CLUSTER CONFIGURATION
  # ============================================================================

  services.k3s-cluster = {
    enable = true;
    role = "server"; # Change to "agent" for worker nodes

    # Use SOPS-managed token
    tokenFile = config.sops.secrets.k3s-token.path;

    # Cluster networking
    clusterCIDR = "10.42.0.0/16";
    serviceCIDR = "10.43.0.0/16";

    # Disable default components (we'll use our own)
    disableComponents = [
      "traefik" # Using custom Traefik setup
      "servicelb" # Using MetalLB or cloud LB
      "local-storage" # Using Longhorn
    ];

    extraFlags = [
      # Enable metrics server
      "--kube-apiserver-arg=enable-aggregator-routing=true"

      # Audit logging for security
      "--kube-apiserver-arg=audit-log-path=/var/log/kubernetes/audit.log"
      "--kube-apiserver-arg=audit-log-maxage=30"

      # For multi-node setup (uncomment if needed)
      # "--tls-san=k8s.your-domain.com"
    ];
  };

  # ============================================================================
  # NETWORKING: CILIUM CNI
  # ============================================================================

  services.cilium-cni = {
    enable = true;

    # API server configuration
    apiServerHost = "127.0.0.1"; # localhost for server, IP for agents
    apiServerPort = 6443;

    clusterCIDR = "10.42.0.0/16"; # Match k3s clusterCIDR

    # Transparent encryption between pods
    encryption = {
      enable = true;
      type = "wireguard"; # WireGuard > IPsec for performance
    };

    # Network observability with Hubble
    hubble = {
      enable = true;
      relay = true;
      ui = true; # Access at http://node-ip:12000
    };

    # Enforce NetworkPolicies from the start
    policyEnforcementMode = "default";

    # Optional: Runtime security (Tetragon)
    securityFeatures.runtimeSecurity = false; # Enable after basic setup works

    # Prometheus metrics
    prometheus.serviceMonitor = true;
  };

  # ============================================================================
  # STORAGE: LONGHORN
  # ============================================================================

  services.longhorn-storage = {
    enable = true;

    # Make it the default storage class
    defaultStorageClass = true;

    # High availability with 3 replicas
    defaultReplicas = 3;

    # Reclaim policy
    reclaimPolicy = "Delete"; # or "Retain" for production

    # Storage provisioning
    overProvisioningPercentage = 200;
    minimalAvailablePercentage = 25;

    # Auto-salvage failed volumes
    autoSalvage = true;

    # Backup configuration (example with S3)
    backup = {
      target = ""; # "s3://my-bucket@us-east-1/" when configured
      credential = null; # Secret name with AWS credentials
    };

    # Snapshot features
    snapshot = {
      enable = true;
      dataIntegrity = "fast-check";
      immediateCheck = false;
    };

    # Optional: Ingress for Longhorn UI
    ingress = {
      enable = false; # Using port-forward initially
      host = "longhorn.k8s.local";
      tls = false;
      ingressClassName = "traefik";
    };

    # Resource limits
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

    # Data path on nodes
    dataPath = "/var/lib/longhorn";
  };

  # ============================================================================
  # SOPS SECRETS MANAGEMENT
  # ============================================================================

  sops.secrets = {
    # K3s cluster token
    k3s-token = {
      sopsFile = ./secrets.yaml;
      restartUnits = [ "k3s.service" ];
    };

    # Grafana admin password (for observability stack)
    grafana-password = {
      sopsFile = ./secrets.yaml;
      owner = "root";
    };

    # Example: AWS credentials for Longhorn backups
    # aws-credentials = {
    #   sopsFile = ./secrets.yaml;
    # };
  };

  # ============================================================================
  # GPU SUPPORT (for PHANTOM ML workloads)
  # ============================================================================

  # Uncomment if you have NVIDIA GPUs
  # hardware.nvidia-container-toolkit.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];

  # Install NVIDIA device plugin for K8s
  # systemd.services.nvidia-device-plugin = {
  #   description = "NVIDIA Device Plugin for Kubernetes";
  #   after = [ "k3s.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #
  #   script = ''
  #     export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  #     ${pkgs.kubectl}/bin/kubectl apply -f \
  #       https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml
  #   '';
  # };

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
    python311
    nodejs

    # Your existing tools
    vim
    git
    tmux
    htop
  ];

  # ============================================================================
  # SYSTEM OPTIMIZATIONS
  # ============================================================================

  # Increase inotify limits for K8s
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # Swap configuration (disable for production K8s)
  swapDevices = [ ]; # K8s prefers no swap

  # Journal size limits
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=7day
  '';

  # ============================================================================
  # NETWORKING CONFIGURATION
  # ============================================================================

  networking = {
    hostName = "k8s-node-01";
    domain = "cluster.local";

    # Use systemd-resolved
    useNetworkd = true;
    useDHCP = false;

    interfaces.enp0s3 = {
      # Adjust to your interface
      useDHCP = true;
      # Or static IP:
      # ipv4.addresses = [{
      #   address = "192.168.1.100";
      #   prefixLength = 24;
      # }];
    };

    # DNS
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Firewall is handled by modules
    firewall.enable = true;
  };

  # ============================================================================
  # SERVICES
  # ============================================================================

  services = {
    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Time sync
    timesyncd.enable = true;
  };

  # ============================================================================
  # USERS
  # ============================================================================

  users.users.pina = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # ============================================================================
  # QUICK START HELPERS
  # ============================================================================

  # Create a helper script for common K8s operations
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

  # Alias for convenience
  environment.shellAliases = {
    k = "kubectl";
    kns = "kubens";
    kctx = "kubectx";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kdp = "kubectl describe pod";
    klf = "kubectl logs -f";
  };

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  system.stateVersion = "24.05"; # Match your NixOS version
}
