{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkDefault;
  cfg = config.kernelcore.security.kernel;

  # TODO(human): Defina os grupos de módulos do kernel aqui como let-bindings nomeados.
  # Cada grupo deve ser uma lista de strings representando os módulos a pré-carregar.
  # Exemplo de estrutura esperada:
  #   firewallModules = [ "nf_tables" "xt_tcpudp" ... ];
  #   natModules      = [ "xt_addrtype" "xt_MASQUERADE" ];
  #   socketModules   = [ "af_packet" ];  # NOT CVE-2026-31431 vector (é algif_aead)
  #   cryptoModules   = [ "cmac" ];
  # Os módulos completos disponíveis estão comentados abaixo em boot.kernelModules.
in
{
  options.kernelcore.security.kernel = {
    enable = mkEnableOption "kernel security hardening";
  };

  config = mkIf cfg.enable {
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

    # Pre-loaded before kernel.modules_disabled locks further loading
    # TODO(human): substitua esta lista por: firewallModules ++ natModules ++ socketModules ++ cryptoModules
    boot.kernelModules = [
      "nf_tables"
      "xt_tcpudp" # -p tcp / -p udp matching
      "xt_conntrack" # -m conntrack (stateful rules)
      "xt_state" # -m state (legacy syntax used by hardening rules)
      "xt_recent" # -m recent (port-scan / rate-limit rules in modules/security/profiles/hardened.nix)
      "xt_limit" # -m limit
      "xt_multiport" # -m multiport
      "xt_LOG" # -j LOG target
      "nf_log_syslog" # LOG implementation for kernel 6.x (replaces nf_log_ipv4)
      "xt_addrtype" # --dst-type LOCAL (Docker bridge NAT)
      "xt_MASQUERADE" # MASQUERADE target (Docker outbound NAT)
      "af_packet" # raw sockets: wpa_supplicant EAPOL + DHCP
      "cmac" # 802.11w PMF (WPA2 WiFi 6) + Bluetooth secure pairing
    ];

    # CVE-2026-31431 (Copy Fail): algif_aead é o vetor, não af_packet
    boot.blacklistedKernelModules = [
      "algif_aead"
      # obscure/unused network protocols
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
      "bluetooth" # controlled by hardware.bluetooth module
      "uvcvideo"
    ];

    boot.kernel.sysctl = {
      # kernel hardening
      "kernel.kptr_restrict" = lib.mkForce 2;
      "kernel.dmesg_restrict" = mkDefault 1;
      "kernel.printk" = lib.mkForce "3 3 3 3";
      "kernel.unprivileged_bpf_disabled" = mkDefault 1;
      "kernel.yama.ptrace_scope" = mkDefault 2;
      "kernel.kexec_load_disabled" = mkDefault 1;
      # modules_disabled=1 bloqueia hotplug pós-boot — setar mkForce 1 em modules/security/profiles/hardened.nix para ativar
      "kernel.modules_disabled" = mkDefault 0;
      "kernel.perf_event_paranoid" = mkDefault 3;
      # 50000 previne cascata de auto-throttle que degrada para ~32000 após ~1h de uso do perf
      "kernel.perf_event_max_sample_rate" = mkDefault 50000;
      "kernel.core_uses_pid" = mkDefault 1;
      "kernel.randomize_va_space" = mkDefault 2;
      "kernel.panic_on_oops" = mkDefault 1;
      "kernel.panic" = mkDefault 60;

      # network hardening
      "net.ipv4.ip_forward" = mkDefault 0;
      "net.ipv4.conf.all.rp_filter" = mkDefault 1;
      "net.ipv4.conf.default.rp_filter" = mkDefault 1;
      "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.all.secure_redirects" = mkDefault 0;
      "net.ipv4.conf.default.secure_redirects" = mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.all.send_redirects" = mkDefault 0;
      "net.ipv4.conf.default.send_redirects" = mkDefault 0;
      "net.ipv4.conf.all.accept_source_route" = mkDefault 0;
      "net.ipv4.conf.default.accept_source_route" = mkDefault 0;
      "net.ipv6.conf.all.accept_source_route" = mkDefault 0;
      "net.ipv6.conf.default.accept_source_route" = mkDefault 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = mkDefault 1;
      "net.ipv4.icmp_echo_ignore_all" = mkDefault 1;
      "net.ipv4.tcp_syncookies" = mkDefault 1;
      "net.ipv4.tcp_rfc1337" = mkDefault 1;
      "net.ipv4.conf.all.log_martians" = mkDefault 1;
      "net.ipv4.conf.default.log_martians" = mkDefault 1;

      # filesystem hardening
      "fs.protected_hardlinks" = mkDefault 1;
      "fs.protected_symlinks" = mkDefault 1;
      "fs.protected_regular" = mkDefault 2;
      "fs.protected_fifos" = mkDefault 2;
      "fs.suid_dumpable" = mkDefault 0;

      # memory protection
      "vm.mmap_rnd_bits" = mkDefault 32;
      "vm.mmap_rnd_compat_bits" = mkDefault 16;
      "vm.mmap_min_addr" = mkDefault 65536;
    };
  };
}
