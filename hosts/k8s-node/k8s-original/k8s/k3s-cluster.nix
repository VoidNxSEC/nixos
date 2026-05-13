{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.k3s-cluster;
in
{
  options.services.k3s-cluster = {
    enable = mkEnableOption "K3s Kubernetes cluster";

    role = mkOption {
      type = types.enum [
        "server"
        "agent"
      ];
      default = "server";
      description = "K3s role: server (control-plane) or agent (worker)";
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Server address for agents to connect (only needed for agent role)";
    };

    clusterCIDR = mkOption {
      type = types.str;
      default = "10.42.0.0/16";
      description = "Pod CIDR range";
    };

    serviceCIDR = mkOption {
      type = types.str;
      default = "10.43.0.0/16";
      description = "Service CIDR range";
    };

    disableComponents = mkOption {
      type = types.listOf types.str;
      default = [
        "traefik"
        "servicelb"
        "local-storage"
      ];
      description = "List of k3s components to disable (we'll use our own)";
    };

    tokenFile = mkOption {
      type = types.path;
      description = "Path to k3s token file (managed by sops-nix)";
      example = "/run/secrets/k3s-token";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional flags to pass to k3s";
    };
  };

  config = mkIf cfg.enable {
    # K3s service configuration
    services.k3s = {
      enable = true;
      role = cfg.role;

      tokenFile = cfg.tokenFile;

      extraFlags = toString (
        [
          # Disable default components
          (concatMapStringsSep " " (comp: "--disable=${comp}") cfg.disableComponents)

          # Security hardening
          "--protect-kernel-defaults"
          "--secrets-encryption=true"

          # Networking - WireGuard native backend
          "--flannel-backend=wireguard-native"

          # Resource limits
          "--kubelet-arg=max-pods=110"
          "--kube-apiserver-arg=max-requests-inflight=400"

          # Cluster configuration
          "--cluster-cidr=${cfg.clusterCIDR}"
          "--service-cidr=${cfg.serviceCIDR}"
        ]
        ++ cfg.extraFlags
        ++ optional (
          cfg.role == "agent" && cfg.serverAddr != null
        ) "--server https://${cfg.serverAddr}:6443"
      );
    };

    # Container runtime - containerd
    virtualisation.containerd = {
      enable = true;
      settings = {
        version = 2;
        plugins."io.containerd.grpc.v1.cri" = {
          # Enable unprivileged ports for containers
          cni.conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d";

          # Device ownership for GPU workloads (PHANTOM)
          device_ownership_from_security_context = true;

          # Registry mirrors (optional - for faster pulls)
          registry.mirrors."docker.io" = {
            endpoint = [ "https://registry-1.docker.io" ];
          };
        };
      };
    };

    # Kernel modules for Kubernetes
    boot.kernelModules = [
      "br_netfilter"
      "overlay"
      "ip_vs"
      "ip_vs_rr"
      "ip_vs_wrr"
      "ip_vs_sh"
      "nf_conntrack"
    ];

    # Sysctl parameters for K8s
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;

      # Network performance tuning
      "net.core.somaxconn" = 32768;
      "net.ipv4.tcp_max_syn_backlog" = 8096;
    };

    # Firewall configuration
    networking.firewall = {
      allowedTCPPorts = mkMerge [
        (mkIf (cfg.role == "server") [
          6443 # K8s API server
          10250 # Kubelet API
          2379 # etcd client
          2380 # etcd peer
        ])
        (mkIf (cfg.role == "agent") [
          10250 # Kubelet API
        ])
      ];

      allowedUDPPorts = [
        8472 # Flannel VXLAN
        51820 # WireGuard
        51821 # WireGuard
      ];

      # Allow pod-to-pod communication
      trustedInterfaces = [ "cni0" ];
    };

    # Essential packages
    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
      k9s # TUI for K8s management
      stern # Multi-pod log tailing
      kubectx # Context switching
      kustomize # Manifest templating
      dive # Container image analysis
    ];

    # Kubectl config symlink for root
    environment.etc."rancher/k3s/k3s.yaml".enable = true;

    # User configuration helpers
    environment.variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };

    # Systemd service hardening
    systemd.services.k3s = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        # Security
        LimitNOFILE = 1048576;
        LimitNPROC = infinity;
        LimitCORE = infinity;
        TasksMax = infinity;
        Delegate = true;
        KillMode = "process";
        OOMScoreAdjust = -999;

        # Auto-restart on failure
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # Log rotation for K8s logs
    services.logrotate.settings.kubernetes = {
      files = "/var/log/pods/*/*.log";
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };

    # Optional: Enable metrics-server (if not using full Prometheus)
    systemd.services.k3s-metrics-server = mkIf (cfg.role == "server") {
      description = "K3s Metrics Server";
      after = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.kubectl}/bin/kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml";
      };

      environment = {
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      };
    };
  };
}
