{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.longhorn-storage;

  longhornValues = pkgs.writeText "longhorn-values.yaml" ''
    # Persistence
    persistence:
      defaultClass: ${if cfg.defaultStorageClass then "true" else "false"}
      defaultClassReplicaCount: ${toString cfg.defaultReplicas}
      reclaimPolicy: ${cfg.reclaimPolicy}

    # Default settings
    defaultSettings:
      backupTarget: ${cfg.backup.target}
      ${optionalString (cfg.backup.credential != null) ''
        backupTargetCredentialSecret: ${cfg.backup.credential}
      ''}
      
      # Storage over-provisioning
      storageOverProvisioningPercentage: ${toString cfg.overProvisioningPercentage}
      storageMinimalAvailablePercentage: ${toString cfg.minimalAvailablePercentage}
      
      # Node-level configuration
      defaultReplicaCount: ${toString cfg.defaultReplicas}
      guaranteedEngineManagerCPU: ${toString cfg.engineManagerCPU}
      guaranteedReplicaManagerCPU: ${toString cfg.replicaManagerCPU}
      
      # Auto-salvage
      autoSalvage: ${if cfg.autoSalvage then "true" else "false"}
      
      # Snapshot settings
      ${optionalString cfg.snapshot.enable ''
        snapshotDataIntegrity: ${cfg.snapshot.dataIntegrity}
        snapshotDataIntegrityImmediateCheckAfterSnapshotCreation: ${
          if cfg.snapshot.immediateCheck then "true" else "false"
        }
      ''}

    # UI/UX Configuration
    ingress:
      enabled: ${if cfg.ingress.enable then "true" else "false"}
      ${optionalString cfg.ingress.enable ''
        host: ${cfg.ingress.host}
        tls: ${if cfg.ingress.tls then "true" else "false"}
        ${optionalString (cfg.ingress.ingressClassName != null) ''
          ingressClassName: ${cfg.ingress.ingressClassName}
        ''}
      ''}

    # Resources
    longhornManager:
      resources:
        limits:
          cpu: ${cfg.resources.manager.limits.cpu}
          memory: ${cfg.resources.manager.limits.memory}
        requests:
          cpu: ${cfg.resources.manager.requests.cpu}
          memory: ${cfg.resources.manager.requests.memory}

    longhornDriver:
      resources:
        limits:
          cpu: ${cfg.resources.driver.limits.cpu}
          memory: ${cfg.resources.driver.limits.memory}
        requests:
          cpu: ${cfg.resources.driver.requests.cpu}
          memory: ${cfg.resources.driver.requests.memory}

    # Node selector (optional)
    ${optionalString (cfg.nodeSelector != { }) ''
      nodeSelector:
        ${concatStringsSep "\n  " (mapAttrsToList (k: v: "${k}: ${v}") cfg.nodeSelector)}
    ''}

    # Tolerations (if you have tainted nodes)
    ${optionalString (cfg.tolerations != [ ]) ''
      tolerations:
        ${concatStringsSep "\n  " cfg.tolerations}
    ''}
  '';

in
{
  options.services.longhorn-storage = {
    enable = mkEnableOption "Longhorn distributed block storage";

    defaultStorageClass = mkOption {
      type = types.bool;
      default = true;
      description = "Make Longhorn the default storage class";
    };

    defaultReplicas = mkOption {
      type = types.int;
      default = 3;
      description = "Default number of replicas for volumes";
    };

    reclaimPolicy = mkOption {
      type = types.enum [
        "Retain"
        "Delete"
      ];
      default = "Delete";
      description = "Default reclaim policy for PVs";
    };

    overProvisioningPercentage = mkOption {
      type = types.int;
      default = 200;
      description = "Storage over-provisioning percentage";
    };

    minimalAvailablePercentage = mkOption {
      type = types.int;
      default = 25;
      description = "Minimal available storage percentage";
    };

    autoSalvage = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic volume salvage";
    };

    engineManagerCPU = mkOption {
      type = types.int;
      default = 12;
      description = "Guaranteed CPU percentage for engine manager";
    };

    replicaManagerCPU = mkOption {
      type = types.int;
      default = 12;
      description = "Guaranteed CPU percentage for replica manager";
    };

    backup = {
      target = mkOption {
        type = types.str;
        default = "";
        description = "Backup target (s3://, nfs://)";
        example = "s3://backup-bucket@us-east-1/";
      };

      credential = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Secret name containing backup credentials";
      };
    };

    snapshot = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable snapshot features";
      };

      dataIntegrity = mkOption {
        type = types.enum [
          "disabled"
          "enabled"
          "fast-check"
        ];
        default = "fast-check";
        description = "Snapshot data integrity checking mode";
      };

      immediateCheck = mkOption {
        type = types.bool;
        default = false;
        description = "Immediate integrity check after snapshot creation";
      };
    };

    ingress = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Ingress for Longhorn UI";
      };

      host = mkOption {
        type = types.str;
        default = "longhorn.local";
        description = "Hostname for Longhorn UI";
      };

      tls = mkOption {
        type = types.bool;
        default = false;
        description = "Enable TLS for Ingress";
      };

      ingressClassName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Ingress class name";
        example = "traefik";
      };
    };

    resources = {
      manager = {
        limits = {
          cpu = mkOption {
            type = types.str;
            default = "1000m";
          };
          memory = mkOption {
            type = types.str;
            default = "1Gi";
          };
        };
        requests = {
          cpu = mkOption {
            type = types.str;
            default = "250m";
          };
          memory = mkOption {
            type = types.str;
            default = "512Mi";
          };
        };
      };

      driver = {
        limits = {
          cpu = mkOption {
            type = types.str;
            default = "500m";
          };
          memory = mkOption {
            type = types.str;
            default = "512Mi";
          };
        };
        requests = {
          cpu = mkOption {
            type = types.str;
            default = "100m";
          };
          memory = mkOption {
            type = types.str;
            default = "256Mi";
          };
        };
      };
    };

    nodeSelector = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Node selector for Longhorn components";
    };

    tolerations = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Tolerations for Longhorn components";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/var/lib/longhorn";
      description = "Path where Longhorn stores data on nodes";
    };
  };

  config = mkIf cfg.enable {
    # Prerequisites - iSCSI support
    services.openiscsi = {
      enable = true;
      name = "${config.networking.hostName}-initiator";
    };

    # Kernel modules
    boot.supportedFilesystems = [ "iscsi" ];
    boot.kernelModules = [
      "iscsi_tcp"
      "dm_crypt"
    ];

    # System packages
    environment.systemPackages = with pkgs; [
      nfs-utils # For NFS backup targets
      curl
      wget
    ];

    # Ensure data directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath} 0755 root root -"
    ];

    # Install Longhorn
    systemd.services.longhorn-install = {
      description = "Install Longhorn Storage System";
      after = [
        "k3s.service"
        "cilium-install.service"
      ];
      requires = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Wait for K8s nodes to be ready
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.kubectl}/bin/kubectl get nodes | grep -q Ready; do sleep 5; done'";
      };

      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Add Longhorn Helm repo
        ${pkgs.kubernetes-helm}/bin/helm repo add longhorn https://charts.longhorn.io 2>/dev/null || true
        ${pkgs.kubernetes-helm}/bin/helm repo update

        # Install or upgrade Longhorn
        ${pkgs.kubernetes-helm}/bin/helm upgrade --install longhorn longhorn/longhorn \
          --namespace longhorn-system \
          --create-namespace \
          --values ${longhornValues} \
          --wait \
          --timeout 10m

        echo "Longhorn installed successfully"

        # Show storage classes
        echo -e "\n=== Storage Classes ==="
        ${pkgs.kubectl}/bin/kubectl get storageclass
      '';
    };

    # Optional: Port-forward Longhorn UI
    systemd.services.longhorn-ui-forward = mkIf (!cfg.ingress.enable) {
      description = "Longhorn UI Port Forward";
      after = [ "longhorn-install.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10";
      };

      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
        ${pkgs.kubectl}/bin/kubectl port-forward -n longhorn-system \
          svc/longhorn-frontend --address 0.0.0.0 8000:80
      '';
    };

    # Firewall for UI (if port-forwarding)
    networking.firewall.allowedTCPPorts = mkIf (!cfg.ingress.enable) [ 8000 ];

    # Verification script
    environment.etc."longhorn/verify.sh" = {
      text = ''
        #!/usr/bin/env bash
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        echo "=== Longhorn Status ==="
        ${pkgs.kubectl}/bin/kubectl -n longhorn-system get pods

        echo -e "\n=== Storage Classes ==="
        ${pkgs.kubectl}/bin/kubectl get storageclass

        echo -e "\n=== Persistent Volumes ==="
        ${pkgs.kubectl}/bin/kubectl get pv

        echo -e "\n=== Longhorn Volumes ==="
        ${pkgs.kubectl}/bin/kubectl -n longhorn-system get volumes.longhorn.io

        ${optionalString (!cfg.ingress.enable) ''
          echo -e "\n=== Access Longhorn UI ==="
          echo "http://$(hostname -I | awk '{print $1}'):8000"
        ''}
      '';
      mode = "0755";
    };

    # Sample PVC for testing
    environment.etc."longhorn/test-pvc.yaml" = {
      text = ''
        apiVersion: v1
        kind: PersistentVolumeClaim
        metadata:
          name: longhorn-test-pvc
          namespace: default
        spec:
          accessModes:
            - ReadWriteOnce
          storageClassName: longhorn
          resources:
            requests:
              storage: 1Gi
        ---
        apiVersion: v1
        kind: Pod
        metadata:
          name: longhorn-test-pod
          namespace: default
        spec:
          containers:
          - name: nginx
            image: nginx:alpine
            volumeMounts:
            - name: data
              mountPath: /usr/share/nginx/html
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: longhorn-test-pvc
      '';
    };
  };
}
