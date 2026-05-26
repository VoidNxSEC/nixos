{ lib, ... }:

# ============================================================
# Example: Kubernetes Node
# ============================================================
# Worker or control-plane node. Includes K3s, container runtime,
# Cilium CNI, Longhorn storage, and baseline security.
# ============================================================

{
  imports = [
    ../../modules/system
    ../../modules/hardware
    ../../modules/security
    ../../modules/network
    ../../modules/containers
    ../../modules/secrets
    ../../modules/shell
  ];

  networking.hostName = "change-me";
  system.user.username = "change-me";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # K8s-specific module imports (adjust per role)
  imports = [
    ../../modules/containers/k3s-cluster.nix
    ../../modules/network/cilium-cni.nix
    ../../modules/containers/longhorn-storage.nix
  ];

  system.stateVersion = "24.11";
}
