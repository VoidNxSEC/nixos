{ ... }:

# ═══════════════════════════════════════════════════════════════
# KUBERNETES MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: K3s cluster, CNI, storage, lab tools
# Migrated from: modules/containers/ and modules/network/
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    ./k3s-cluster.nix # K3s lightweight Kubernetes
    ./longhorn-storage.nix # Longhorn distributed storage
    ./kind.nix # kind lab cluster + CKA/CKAD/CKS toolset
    ./spectre-k8s.nix # Spectre K8s cluster config
    ./cilium-cni.nix # Cilium CNI networking
  ];
}
