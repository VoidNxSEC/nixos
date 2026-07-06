# profiles/k8s-prod.nix
#
# Produção Kubernetes — K3s + Cilium CNI + Longhorn storage.
# Desabilitado por padrão. Ativar via:
#   services.k3s-cluster.enable = true;
#   services.cilium-cni.enable = true;
#   services.longhorn-storage.enable = true;
#
{ ... }:
{
  imports = [
    ../modules/containers/k3s-cluster.nix
    ../modules/network/cilium-cni.nix
    ../modules/containers/longhorn-storage.nix
  ];
}
