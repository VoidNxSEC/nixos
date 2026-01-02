
  # ============================================================================
  # SOPS SECRETS MANAGEMENT
  # ============================================================================

  sops.secrets = { # GEMINI: Secrets management for the kubernetes node, critical
    # K3s cluster token
    k3s-token = {
      sopsFile = ./secrets.yaml;
      restartUnits = [ "k3s.service" ];
    };

    # Grafana admin password (for observability stack)
  #grafana-password = {
  #sopsFile = ./secrets.yaml;
  #owner = "root";
  #};

    # Example: AWS credentials for Longhorn backups
    # aws-credentials = {
    #   sopsFile = ./secrets.yaml;
    # };
  #};

  # ============================================================================
  # GPU SUPPORT (for PHANTOM ML workloads)
  # ============================================================================



  # Install NVIDIA device plugin for K8s
  systemd.services.nvidia-device-plugin = { # GEMINI: Install Systemd Daemon NVIDIA device plugin for K8s
  description = "NVIDIA Device Plugin for Kubernetes";
  after = [ "k3s.service" ];
  wantedBy = [ "multi-user.target" ];

     script = ''
       export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
       ${pkgs.kubectl}/bin/kubectl apply -f \
         https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml
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
  boot.kernel.sysctl = { # GEMINI: We need to see if is already aplied
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # ============================================================================
  # NETWORKING CONFIGURATION
  # ============================================================================

  networking = { # GEMINI: Networking configuration for the kubernetes, the problem is how to setup the pod network isolated
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
  # QUICK START HELPERS
  # ============================================================================

  # Create a helper script for common K8s operations # GEMINI: Helpers for integrate
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

  # Alias for convenience # GEMINI: Aliases for integrate
  environment.shellAliases = {
    k = "kubectl";
    kns = "kubens";
    kctx = "kubectx";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kdp = "kubectl describe pod";
    klf = "kubectl logs -f";
  };
