{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.k8s-prod.configuration = {
    system.nixos.tags = [ "K8s-Prod" ];

    # ──────────────────────────────────────────────────────────────
    # Kubernetes stack activation
    # ──────────────────────────────────────────────────────────────
    services.k3s-cluster.enable = lib.mkForce true;
    services.cilium-cni.enable = lib.mkForce true;
    services.longhorn-storage.enable = lib.mkForce true;

    # ──────────────────────────────────────────────────────────────
    # Firewall — produção mantém regras hardened + portas k8s
    # ──────────────────────────────────────────────────────────────
    networking.firewall = {
      allowedTCPPorts = lib.mkForce [
        22 # SSH
        6443 # kube-apiserver
        2379 # etcd client
        2380 # etcd peer
        10250 # kubelet API
        10257 # kube-controller-manager
        10259 # kube-scheduler
      ];

      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];

      allowedUDPPorts = lib.mkForce [
        8472 # flannel VXLAN
        4789 # Calico VXLAN
        51820 # Cilium WireGuard
      ];

      trustedInterfaces = [
        "tailscale0"
        "br+"
      ];
    };

    # ──────────────────────────────────────────────────────────────
    # sysctl obrigatórios para roteamento de pods
    # ──────────────────────────────────────────────────────────────
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkForce 1;
      "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
      "net.bridge.bridge-nf-call-iptables" = lib.mkForce 1;
      "net.bridge.bridge-nf-call-ip6tables" = lib.mkForce 1;
      "vm.max_map_count" = lib.mkForce 524288;
      "net.netfilter.nf_conntrack_max" = lib.mkForce 524288;
    };

    boot.kernelModules = [
      "veth"
      "br_netfilter"
      "overlay"
    ];

    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      k9s
      kubectx
      cilium-cli
      kubeseal
    ];
  };
}
