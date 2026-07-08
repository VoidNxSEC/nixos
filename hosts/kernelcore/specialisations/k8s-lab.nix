{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.k8s-lab.configuration = {
    system.nixos.tags = [ "K8s-Lab" ];

    # ──────────────────────────────────────────────────────────────
    # Kubernetes modules activation
    # ──────────────────────────────────────────────────────────────
    services.k3s-cluster.enable = lib.mkForce false; # Use kind for lab
    services.cilium-cni.enable = lib.mkForce false; # Not needed for kind
    services.longhorn-storage.enable = lib.mkForce false;

    # ──────────────────────────────────────────────────────────────
    # Firewall — portas necessárias para k8s local
    # ──────────────────────────────────────────────────────────────
    networking.firewall = {
      allowPing = lib.mkForce true;

      allowedTCPPorts = lib.mkForce [
        22 # SSH
        6443 # kube-apiserver
        2379 # etcd client
        2380 # etcd peer
        10250 # kubelet API
        10251 # kube-scheduler (legado)
        10252 # kube-controller-manager (legado)
        10257 # kube-controller-manager (seguro)
        10259 # kube-scheduler (seguro)
        10255 # kubelet read-only (opcional)
      ];

      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];

      allowedUDPPorts = lib.mkForce [
        8472 # flannel VXLAN
        4789 # Calico / OVN VXLAN
        51820 # WireGuard (Cilium WireGuard mode)
      ];

      trustedInterfaces = [
        "docker0"
        "tailscale0"
        "br+"
        "kind+"
      ];

      extraCommands = lib.mkAfter ''
        iptables -I FORWARD -s 172.16.0.0/12 -j ACCEPT
        iptables -I FORWARD -d 172.16.0.0/12 -j ACCEPT
        iptables -t nat -A POSTROUTING -s 172.16.0.0/12 ! -o docker0 -j MASQUERADE
      '';

      rejectPackets = lib.mkForce false;
      logReversePathDrops = lib.mkForce false;
    };

    # ──────────────────────────────────────────────────────────────
    # sysctl — parâmetros críticos para redes de pods
    # ──────────────────────────────────────────────────────────────
    boot.kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_all" = lib.mkForce 0;
      #"kernel.unprivileged_userns_clone" = lib.mkForce 1;
      "net.bridge.bridge-nf-call-iptables" = lib.mkForce 1;
      "net.bridge.bridge-nf-call-ip6tables" = lib.mkForce 1;
      "vm.max_map_count" = lib.mkForce 524288;
      "net.netfilter.nf_conntrack_max" = lib.mkForce 524288;
      "net.nf_conntrack_max" = lib.mkForce 524288;
    };

    environment.systemPackages = with pkgs; [
      kind
      kubectl
      kubernetes-helm
      k9s
      kubectx
    ];

    boot.kernelModules = [
      "veth"
      "br_netfilter"
      "overlay"
    ];

    # AppArmor desabilitado: containerd/k3s criam processos sem perfil definido
    security.apparmor.enable = lib.mkForce false;
  };
}
