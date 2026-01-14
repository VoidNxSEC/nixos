{ ... }:

# ============================================================
# Kubernetes Cluster Management Aliases
# ============================================================
# Purpose: Aliases for k8s-setup.sh orchestration script
# Script location: /etc/nixos/scripts/k8s-setup.sh
# ============================================================

{
  environment.shellAliases = {
    # ══════════════════════════════════════════════════════
    # K8S CLUSTER ORCHESTRATION
    # ══════════════════════════════════════════════════════

    # Setup operations
    k8s-init = "sudo bash /etc/nixos/scripts/k8s-setup.sh init";
    k8s-deploy = "sudo bash /etc/nixos/scripts/k8s-setup.sh deploy";
    k8s-verify = "sudo bash /etc/nixos/scripts/k8s-setup.sh verify";
    k8s-sample = "sudo bash /etc/nixos/scripts/k8s-setup.sh sample";
    k8s-destroy = "sudo bash /etc/nixos/scripts/k8s-setup.sh destroy";
    k8s-help = "bash /etc/nixos/scripts/k8s-setup.sh help";

    # Quick access to cluster status
    k8s-status = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get nodes -o wide && echo && kubectl get pods -A";
    k8s-nodes = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get nodes -o wide";
    k8s-pods = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get pods -A";
    k8s-services = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get services -A";

    # Storage operations
    k8s-storage = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get storageclass && echo && kubectl get pv && echo && kubectl get pvc -A";
    k8s-longhorn = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl -n longhorn-system get pods";
    k8s-longhorn-ui = "echo 'Longhorn UI: http://localhost:8000'";

    # Network operations
    k8s-cilium = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && cilium status";
    k8s-hubble = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && hubble status";
    k8s-hubble-ui = "echo 'Hubble UI: http://localhost:12000'";

    # Logs and debugging
    k8s-logs-cilium = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && stern -n kube-system cilium";
    k8s-logs-longhorn = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && stern -n longhorn-system longhorn";
    k8s-logs-k3s = "journalctl -u k3s.service -f";

    # Full cluster setup (init + deploy + verify)
    k8s-full-setup = "sudo bash /etc/nixos/scripts/k8s-setup.sh init && sudo bash /etc/nixos/scripts/k8s-setup.sh deploy && sudo bash /etc/nixos/scripts/k8s-setup.sh verify";

    # Quick cluster info
    k8s-info = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl cluster-info && echo && echo 'Dashboards:' && echo '  Hubble UI:   http://localhost:12000' && echo '  Longhorn UI: http://localhost:8000'";
  };
}
