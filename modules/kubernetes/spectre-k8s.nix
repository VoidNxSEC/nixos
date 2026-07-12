{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

{
  imports = [
    ./k3s-cluster.nix
  ];

  options.kernelcore.kubernetes.spectre = {
    enable = mkEnableOption "SPECTRE Kubernetes Hybrid Infrastructure";
  };

  config = mkIf config.kernelcore.kubernetes.spectre.enable {
    # Base Cluster Settings
    kernelcore.kubernetes.k3s = {
      enable = true;
      role = "server";

      # We assume SOPS has a token file, or we provide a dummy path for now until it's provisioned
      tokenFile = "/var/lib/rancher/k3s/server/token";

      disableComponents = [
        "traefik"
        "servicelb"
        "local-storage"
      ];
    };

    # Passthrough GPU for workloads
    virtualisation.containerd = {
      enable = true;
      settings = {
        version = 2;
        plugins."io.containerd.grpc.v1.cri" = {
          device_ownership_from_security_context = true;
        };
      };
    };

    # System Packages required for GitOps and K8s Management
    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
      kustomize
      fluxcd
      argocd
    ];
  };
}
