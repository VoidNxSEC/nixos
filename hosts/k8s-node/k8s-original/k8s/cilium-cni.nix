{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.cilium-cni;

  ciliumValues = pkgs.writeText "cilium-values.yaml" ''
    # Cluster configuration
    cluster:
      name: ${config.networking.hostName}
      id: 1

    # IPAM configuration
    ipam:
      mode: kubernetes

    # Replace kube-proxy entirely with eBPF
    kubeProxyReplacement: strict
    k8sServiceHost: ${cfg.apiServerHost}
    k8sServicePort: ${toString cfg.apiServerPort}

    # Networking
    routingMode: native
    ipv4NativeRoutingCIDR: ${cfg.clusterCIDR}
    autoDirectNodeRoutes: true

    # Encryption - WireGuard transparent encryption
    encryption:
      enabled: ${if cfg.encryption.enable then "true" else "false"}
      type: ${cfg.encryption.type}
      ${optionalString cfg.encryption.ipsec.enable ''
        ipsec:
          keyFile: ${cfg.encryption.ipsec.keyFile}
      ''}

    # Hubble - Network observability
    hubble:
      enabled: ${if cfg.hubble.enable then "true" else "false"}
      relay:
        enabled: ${if cfg.hubble.relay then "true" else "false"}
      ui:
        enabled: ${if cfg.hubble.ui then "true" else "false"}
      metrics:
        enabled:
          - dns:query;ignoreAAAA
          - drop
          - tcp
          - flow
          - icmp
          - http

    # Network Policy enforcement
    policyEnforcementMode: ${cfg.policyEnforcementMode}

    # Security features
    ${optionalString cfg.securityFeatures.runtimeSecurity ''
      enableRuntimeSecurity: true
    ''} 

    # BGP Control Plane (for advanced routing)
    bgpControlPlane:
      enabled: ${if cfg.bgp.enable then "true" else "false"}

    # Prometheus metrics
    prometheus:
      enabled: true
      serviceMonitor:
        enabled: ${if cfg.prometheus.serviceMonitor then "true" else "false"}

    # Resource limits
    resources:
      limits:
        cpu: ${cfg.resources.limits.cpu}
        memory: ${cfg.resources.limits.memory}
      requests:
        cpu: ${cfg.resources.requests.cpu}
        memory: ${cfg.resources.requests.memory}

    # Node selector (if you want Cilium only on specific nodes)
    ${optionalString (cfg.nodeSelector != { }) ''
      nodeSelector:
        ${concatStringsSep "\n  " (mapAttrsToList (k: v: "${k}: ${v}") cfg.nodeSelector)}
    ''}
  '';

in
{
  options.services.cilium-cni = {
    enable = mkEnableOption "Cilium CNI with eBPF networking";

    apiServerHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Kubernetes API server host";
    };

    apiServerPort = mkOption {
      type = types.int;
      default = 6443;
      description = "Kubernetes API server port";
    };

    clusterCIDR = mkOption {
      type = types.str;
      default = "10.42.0.0/16";
      description = "Cluster CIDR for native routing";
    };

    encryption = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable transparent pod-to-pod encryption";
      };

      type = mkOption {
        type = types.enum [
          "wireguard"
          "ipsec"
        ];
        default = "wireguard";
        description = "Encryption type";
      };

      ipsec = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable IPsec encryption (if type is ipsec)";
        };

        keyFile = mkOption {
          type = types.path;
          default = "/run/secrets/cilium-ipsec-key";
          description = "IPsec key file path";
        };
      };
    };

    hubble = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Hubble network observability";
      };

      relay = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Hubble Relay";
      };

      ui = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Hubble UI";
      };
    };

    policyEnforcementMode = mkOption {
      type = types.enum [
        "default"
        "always"
        "never"
      ];
      default = "default";
      description = "Network policy enforcement mode";
    };

    securityFeatures = {
      runtimeSecurity = mkOption {
        type = types.bool;
        default = false;
        description = "Enable runtime security features (Tetragon)";
      };
    };

    bgp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable BGP control plane for advanced routing";
      };
    };

    prometheus = {
      serviceMonitor = mkOption {
        type = types.bool;
        default = true;
        description = "Create ServiceMonitor for Prometheus Operator";
      };
    };

    resources = {
      limits = {
        cpu = mkOption {
          type = types.str;
          default = "4000m";
          description = "CPU limit";
        };
        memory = mkOption {
          type = types.str;
          default = "4Gi";
          description = "Memory limit";
        };
      };
      requests = {
        cpu = mkOption {
          type = types.str;
          default = "100m";
          description = "CPU request";
        };
        memory = mkOption {
          type = types.str;
          default = "512Mi";
          description = "Memory request";
        };
      };
    };

    nodeSelector = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Node selector for Cilium pods";
      example = {
        "node-role.kubernetes.io/control-plane" = "true";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install Cilium CLI and tools
    environment.systemPackages = with pkgs; [
      cilium-cli
      hubble
    ];

    # Kernel modules for eBPF
    boot.kernelModules = [
      "tun"
      "veth"
      "vxlan"
    ];

    # Install Cilium via Helm
    systemd.services.cilium-install = {
      description = "Install Cilium CNI";
      after = [ "k3s.service" ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Wait for K8s API to be ready
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.kubectl}/bin/kubectl get nodes; do sleep 2; done'";
      };

      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Add Cilium Helm repo
        ${pkgs.kubernetes-helm}/bin/helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
        ${pkgs.kubernetes-helm}/bin/helm repo update

        # Install or upgrade Cilium
        ${pkgs.kubernetes-helm}/bin/helm upgrade --install cilium cilium/cilium \
          --version 1.15.0 \
          --namespace kube-system \
          --values ${ciliumValues} \
          --wait \
          --timeout 10m

        echo "Cilium CNI installed successfully"
      '';

      # Auto-restart on failure
      unitConfig = {
        ConditionPathExists = "/etc/rancher/k3s/k3s.yaml";
      };
    };

    # Enable Hubble UI port-forward service (optional)
    systemd.services.hubble-ui-forward = mkIf cfg.hubble.ui {
      description = "Hubble UI Port Forward";
      after = [ "cilium-install.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10";
      };

      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        ${pkgs.kubectl}/bin/kubectl port-forward -n kube-system \
          svc/hubble-ui --address 0.0.0.0 12000:80
      '';
    };

    # Firewall rules for Hubble UI
    networking.firewall.allowedTCPPorts = mkIf cfg.hubble.ui [ 12000 ];

    # Post-install verification script
    environment.etc."cilium/verify.sh" = {
      text = ''
        #!/usr/bin/env bash
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        echo "=== Cilium Status ==="
        ${pkgs.cilium-cli}/bin/cilium status

        echo -e "\n=== Cilium Connectivity Test ==="
        ${pkgs.cilium-cli}/bin/cilium connectivity test

        ${optionalString cfg.hubble.enable ''
          echo -e "\n=== Hubble Status ==="
          ${pkgs.hubble}/bin/hubble status
        ''}
      '';
      mode = "0755";
    };
  };
}
