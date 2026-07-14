{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.kernel.enable = mkEnableOption "Enable kernel security hardening";
  };

  config = mkIf config.kernelcore.security.kernel.enable {
    ##########################################################################
    # 🛡️ Kernel Security Hardening
    ##########################################################################

    # Kernel parameters
    boot.kernelParams = [
      "lockdown=confidentiality"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
      "slab_nomerge"
      "pti=on"
      "oops=panic"
      "module.sig_enforce=1"
    ];

    # Pre-load modules at boot so they are available before
    # kernel.modules_disabled locks out further module loading.
    #   nf_tables  - firewall (iptables-nft backend)
    #   af_packet  - AF_PACKET raw sockets for wpa_supplicant (EAPOL/L2) and DHCP.
    #                NOTE: af_packet is NOT the Copy Fail (CVE-2026-31431) vector;
    #                that is algif_aead (AF_ALG), blacklisted below.
    boot.kernelModules = [
      # Netfilter / firewall (iptables-nft backend)
      "nf_tables"
      "xt_tcpudp" # -p tcp / -p udp matching
      "xt_conntrack" # -m conntrack (stateful rules)
      "xt_state" # -m state (legacy syntax used by hardening rules)
      "xt_recent" # -m recent (port-scan / rate-limit rules in modules/security/hardening.nix)
      "xt_limit" # -m limit
      "xt_multiport" # -m multiport
      "xt_LOG" # -j LOG target
      "nf_log_syslog" # LOG implementation for kernel 6.x (replaces nf_log_ipv4)
      # Docker / NAT
      "xt_addrtype" # --dst-type LOCAL (Docker bridge NAT)
      "xt_MASQUERADE" # MASQUERADE target (Docker outbound NAT)
      # Network sockets
      "af_packet" # raw sockets: wpa_supplicant EAPOL + DHCP
      # Crypto
      "cmac" # 802.11w PMF (WPA2 em WiFi 6) + Bluetooth secure pairing
    ];

    # Blacklist insecure/unused protocols and modules
    boot.blacklistedKernelModules = [
      # ⚠️ Mitigação do Copy Fail (CVE-2026-31431)
      "algif_aead"

      # Obscure network protocols
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "n-hdlc"
      "ax25"
      "netrom"
      "x25"
      "rose"
      "decnet"
      "econet"
      "af_802154"
      "ipx"
      "appletalk"
      "psnap"
      "p8023"
      "llc"
      "p8022"

      # Uncomment if not needed:
      # "bluetooth"  # Responsável: hardware.bluetooth module (modules/hardware/bluetooth.nix ou system config)
      # "btusb"
      # "uvcvideo"
    ];

    # Kernel sysctl hardening — mkForce para garantir prioridade sobre defaults do nixpkgs
    boot.kernel.sysctl = {
      ##########################################################################
      # Kernel Hardening
      ##########################################################################
      "kernel.kptr_restrict" = mkForce 2;
      "kernel.dmesg_restrict" = mkForce 1;
      "kernel.printk" = mkForce "3 3 3 3";
      "kernel.unprivileged_bpf_disabled" = mkForce 1;
      "kernel.yama.ptrace_scope" = mkForce 2;
      "kernel.kexec_load_disabled" = mkForce 1;

      # ⚠️ Hardening Máximo: Desativa o carregamento automático de QUALQUER módulo pós-boot.
      # Impede que exploits invoquem chamadas de socket que forcem o Kernel a carregar módulos ocultos.
      # ATENÇÃO OPERACIONAL: aplica imediatamente via activation script no próximo nixos-rebuild switch.
      # Após aplicado, nenhum módulo novo carrega até o próximo reboot — hotplug de hardware quebra.
      # Para desabilitar: setar mkForce 0 em modules/security/hardening.nix.
      "kernel.modules_disabled" = mkForce 0;

      # kernel.unprivileged_userns_clone: removido — sysctl não existe no kernel 6.18+
      # (era do patch Debian/Ubuntu; upstream sempre usou kernel.unprivileged_userns_clone=1)
      # No kernel 6.18 user namespaces são controlados via unprivileged_userns no kernel config.

      "kernel.perf_event_paranoid" = mkForce 3;

      # Fixar sample rate máximo do perf para evitar cascata de auto-throttle.
      # O kernel reduz automaticamente quando interrupts demoram >N μs, podendo chegar
      # a valores tão baixos quanto 32000 após ~1h de uso. 50000 é um valor conservador
      # que mantém fidelidade de profiling sem sobrecarregar o interrupt handler.
      "kernel.perf_event_max_sample_rate" = mkForce 50000;
      "kernel.core_uses_pid" = mkForce 1;
      "kernel.randomize_va_space" = mkForce 2;
      "kernel.panic_on_oops" = mkForce 1;
      "kernel.panic" = mkForce 60;

      ##########################################################################
      # Network Hardening
      ##########################################################################
      # IP forwarding
      "net.ipv4.ip_forward" = mkDefault 0;

      # Reverse path filtering
      "net.ipv4.conf.all.rp_filter" = mkForce 1;
      "net.ipv4.conf.default.rp_filter" = mkForce 1;

      # Disable redirects
      "net.ipv4.conf.all.accept_redirects" = mkForce 0;
      "net.ipv4.conf.default.accept_redirects" = mkForce 0;
      "net.ipv4.conf.all.secure_redirects" = mkForce 0;
      "net.ipv4.conf.default.secure_redirects" = mkForce 0;
      "net.ipv6.conf.all.accept_redirects" = mkForce 0;
      "net.ipv6.conf.default.accept_redirects" = mkForce 0;
      "net.ipv4.conf.all.send_redirects" = mkForce 0;
      "net.ipv4.conf.default.send_redirects" = mkForce 0;

      # Source routing
      "net.ipv4.conf.all.accept_source_route" = mkForce 0;
      "net.ipv4.conf.default.accept_source_route" = mkForce 0;
      "net.ipv6.conf.all.accept_source_route" = mkForce 0;
      "net.ipv6.conf.default.accept_source_route" = mkForce 0;

      # ICMP
      "net.ipv4.icmp_echo_ignore_broadcasts" = mkForce 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = mkForce 1;
      "net.ipv4.icmp_echo_ignore_all" = mkDefault 1; # k8s-lab sobrescreve para 0 (necessário para pods)

      # TCP hardening
      "net.ipv4.tcp_syncookies" = mkForce 1;
      "net.ipv4.tcp_rfc1337" = mkForce 1;

      # Logging
      "net.ipv4.conf.all.log_martians" = mkForce 1;
      "net.ipv4.conf.default.log_martians" = mkForce 1;

      ##########################################################################
      # File System Hardening
      ##########################################################################
      "fs.protected_hardlinks" = mkForce 1;
      "fs.protected_symlinks" = mkForce 1;
      "fs.protected_regular" = mkForce 2;
      "fs.protected_fifos" = mkForce 2;
      "fs.suid_dumpable" = mkForce 0;

      ##########################################################################
      # Memory Protection
      ##########################################################################
      "vm.mmap_rnd_bits" = mkForce 32;
      "vm.mmap_rnd_compat_bits" = mkForce 16;
      "vm.mmap_min_addr" = mkForce 65536;
    };
  };
}
