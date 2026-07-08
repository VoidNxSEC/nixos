{
  imports = [
    ./k8s-lab.nix
    ./k8s-prod.nix
    ./emergency.nix
    ./cybersecurity.nix
    ./privacy-paranoia.nix
    ./development.nix
    ./stable.nix

    # Niri: aguardando migração do Hyprland
    # ./niri.nix
  ];
}
