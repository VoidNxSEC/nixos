{ config, ... }:

# ═══════════════════════════════════════════════════════════
# KUBERNETES — k3s, Cilium, Longhorn, kind (todos gated; ativação
# real acontece nas specialisations k8s-lab / k8s-prod)
# ═══════════════════════════════════════════════════════════

{
  # K3S Cluster
  kernelcore.kubernetes.k3s = {
    enable = false;
    role = "server";
    # Secret só existe com kernelcore.secrets.k8s.enable (specialisation k8s-lab);
    # fallback evita erro de eval no host base, onde k3s fica desabilitado.
    tokenFile = config.sops.secrets."k3s-token".path or "/run/secrets/k3s-token";
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

  kernelcore.kubernetes.cilium = {
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

  kernelcore.kubernetes.longhorn = {
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

  # kind (Kubernetes IN Docker) lab — CKA exam prep.
  # Disposable multi-node clusters + full CKA/CKAD/CKS toolset and the
  # kindlab-* helper CLI. Study material: ~/learn/kuber-labs/ and
  # docs/guides/KIND-CKA-EXAM-GUIDE.md. Requires Docker.
  kernelcore.kubernetes.kind = {
    enable = false;
    clusterName = "cka-lab";
    workerCount = 2;
    haControlPlane = false; # set true to practice etcd quorum / multi-master
    ingress.enable = true;
    metricsServer.enable = true;
  };

  # ── Quick start helpers ──
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
}
