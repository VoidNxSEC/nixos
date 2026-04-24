# profiles/k8s-lab.nix
#
# Sobrescreve regras de hardening de rede do sec/hardening.nix para uso local
# com Kubernetes (kind, minikube, k3s, kubeadm).
#
# ATENÇÃO: Este perfil relaxa intencionalmente regras de segurança.
# Use apenas em ambientes de lab/desenvolvimento — NUNCA em produção.
#
# Para ativar, importe este arquivo em hosts/kernelcore/configuration.nix:
#   imports = [ ... ./../../profiles/k8s-lab.nix ];
#
{ lib, ... }:

{
  # ──────────────────────────────────────────────────────────────
  # Firewall — portas necessárias para k8s local
  # ──────────────────────────────────────────────────────────────
  networking.firewall = {
    # Permite ping (health checks de pods e CNI plugins usam ICMP)
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
      # NodePort range padrão do Kubernetes
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

    # CNI plugins (flannel, calico, cilium) precisam de encaminhamento;
    # desabilitar rejectPackets evita drops silenciosos durante setup.
    rejectPackets = lib.mkForce false;

    # Mantém log de recusas para depuração, mas sem log de reverse-path
    # (rp_filter relaxado abaixo quebra esse log de forma ruidosa)
    logReversePathDrops = lib.mkForce false;
  };

  # ──────────────────────────────────────────────────────────────
  # sysctl — parâmetros críticos para redes de pods
  # ──────────────────────────────────────────────────────────────
  boot.kernel.sysctl = {
    # CRÍTICO: encaminhamento de IP é obrigatório para roteamento entre pods
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.conf.all.forwarding" = lib.mkForce 1;

    # CNI plugins VXLAN/geneve precisam que rp_filter seja 0 ou 2;
    # valor 1 (strict) descarta pacotes encapsulados legítimos.
    "net.ipv4.conf.all.rp_filter" = lib.mkForce 0;
    "net.ipv4.conf.default.rp_filter" = lib.mkForce 0;

    # Permite ping para health checks (liveness/readiness probes via ICMP)
    "net.ipv4.icmp_echo_ignore_all" = lib.mkForce 0;

    # Namespaces de usuário não-privilegiados — necessário para containerd
    # rootless e para o runtime de alguns operadores.
    "kernel.unprivileged_userns_clone" = lib.mkForce 1;

    # Aumenta o limite de mapeamentos de memória; Elasticsearch, JVM e
    # algumas imagens de ML exigem valores acima de 262144.
    "vm.max_map_count" = lib.mkForce 524288;

    # Conntrack — clusters com muitos pods esgotam o valor padrão rapidamente
    "net.netfilter.nf_conntrack_max" = lib.mkForce 524288;
    "net.nf_conntrack_max" = lib.mkForce 524288;
  };

  # ──────────────────────────────────────────────────────────────
  # Módulos de kernel blacklistados no hardening que o k8s precisa
  # ──────────────────────────────────────────────────────────────
  # O hardening bloqueia módulos de rede raramente usados. Nenhum deles
  # é necessário para k8s padrão, então não sobrescrevemos a lista aqui.
  # Se um CNI específico falhar por módulo ausente, adicione abaixo:
  #
  # boot.blacklistedKernelModules = lib.mkForce
  #   (lib.filter (m: m != "sctp") config.boot.blacklistedKernelModules);

  # ──────────────────────────────────────────────────────────────
  # AppArmor — não matar processos não-confinados em lab
  # ──────────────────────────────────────────────────────────────
  # containerd e o runtime de pods podem iniciar processos sem perfil
  # AppArmor definido; killUnconfinedConfinables = true os encerraria.
  security.apparmor.killUnconfinedConfinables = lib.mkForce false;
}
