{ ... }:

# ═══════════════════════════════════════════════════════════════
# KUBERNETES MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: All Kubernetes-related NixOS modules in one place
# Activation: via specialisations (k8s-lab, k8s-prod)
#             or by enabling individual service options
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    ./k3s-cluster.nix # K3s lightweight Kubernetes (server + agent roles)
    ./kind.nix # Kind lab cluster + CKA/CKAD/CKS toolset
    ./longhorn-storage.nix # Longhorn distributed block storage
    ./cilium-cni.nix # Cilium CNI (eBPF-based networking + policy)
  ];
}
