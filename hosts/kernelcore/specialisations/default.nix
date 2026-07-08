{
  imports = [
    # Niri specialisation temporarily disabled - focus on Hyprland first
    # ./niri.nix

    # Kubernetes specialisations
    #./k8s-lab.nix # K8s lab: kind cluster, relaxed security, dev toolset
    #./k8s-prod.nix # K8s prod: k3s + Cilium + Longhorn, hardened firewall

    # Emergency boot: Trezor hardware auth, diagnostic tools, no heavy workloads
    #./emergency.nix

    # Profissional de cybersecurity: ferramentas ofensivas/defensivas, Docker para labs
    #./cybersecurity.nix

    # Privacy paranoia: Tor, kernel hardening máximo, anti-fingerprinting
    #./privacy-paranoia.nix

    # Development: ambientes de linguagem, Docker, portas de dev abertas
    #./development.nix

    # Stable: kernel padrão, sem containers, hardening base, auto-upgrade
    #./stable.nix
  ];
}
