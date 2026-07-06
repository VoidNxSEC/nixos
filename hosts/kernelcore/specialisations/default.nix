{
  imports = [
    # Niri specialisation temporarily disabled - focus on Hyprland first
    # ./niri.nix

    # Kubernetes specialisations
    ./k8s-lab.nix # K8s lab: kind cluster, relaxed security, dev toolset
    ./k8s-prod.nix # K8s prod: k3s + Cilium + Longhorn, hardened firewall

    # Emergency boot: Trezor hardware auth, diagnostic tools, no heavy workloads
    ./emergency.nix
  ];
}
