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

    # Blacklist insecure/unused protocols and modules
    boot.blacklistedKernelModules = [
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

    # Kernel sysctl hardening (using mkDefault to allow sec/hardening.nix to override)
    boot.kernel.sysctl = {
      ##########################################################################
      # Kernel Hardening
      ##########################################################################
      "kernel.kptr_restrict" = mkDefault 2;
      "kernel.dmesg_restrict" = mkDefault 1;
      "kernel.printk" = mkDefault "3 3 3 3";
      "kernel.unprivileged_bpf_disabled" = mkDefault 1;
      "kernel.yama.ptrace_scope" = mkDefault 2;
      "kernel.kexec_load_disabled" = mkDefault 1;

      # User namespaces: Required for Chromium/Electron sandbox
      # Security note: Disabling this breaks all Electron apps (VSCode, Chromium, etc)
      # Mitigation: Apps are sandboxed via other mechanisms (AppArmor, seccomp)
      "kernel.unprivileged_userns_clone" = mkDefault 1; # Was 0, changed for Electron

      "kernel.perf_event_paranoid" = mkDefault 3;
      "kernel.core_uses_pid" = mkDefault 1;
      "kernel.randomize_va_space" = mkDefault 2;
      "kernel.panic_on_oops" = mkDefault 1;
      "kernel.panic" = mkDefault 60;

      ##########################################################################
      # Network Hardening
      ##########################################################################
      # IP forwarding
      "net.ipv4.ip_forward" = mkDefault 0;

      # Reverse path filtering
      "net.ipv4.conf.all.rp_filter" = mkDefault 1;
      "net.ipv4.conf.default.rp_filter" = mkDefault 1;

      # Disable redirects
      "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.all.secure_redirects" = mkDefault 0;
      "net.ipv4.conf.default.secure_redirects" = mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.all.send_redirects" = mkDefault 0;
      "net.ipv4.conf.default.send_redirects" = mkDefault 0;

      # Source routing
      "net.ipv4.conf.all.accept_source_route" = mkDefault 0;
      "net.ipv4.conf.default.accept_source_route" = mkDefault 0;
      "net.ipv6.conf.all.accept_source_route" = mkDefault 0;
      "net.ipv6.conf.default.accept_source_route" = mkDefault 0;

      # ICMP
      "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = mkDefault 1;
      "net.ipv4.icmp_echo_ignore_all" = mkDefault 1;

      # TCP hardening
      "net.ipv4.tcp_syncookies" = mkDefault 1;
      "net.ipv4.tcp_rfc1337" = mkDefault 1;

      # Logging
      "net.ipv4.conf.all.log_martians" = mkDefault 1;
      "net.ipv4.conf.default.log_martians" = mkDefault 1;

      ##########################################################################
      # File System Hardening
      ##########################################################################
      "fs.protected_hardlinks" = mkDefault 1;
      "fs.protected_symlinks" = mkDefault 1;
      "fs.protected_regular" = mkDefault 2;
      "fs.protected_fifos" = mkDefault 2;
      "fs.suid_dumpable" = mkDefault 0;

      ##########################################################################
      # Memory Protection
      ##########################################################################
      "vm.mmap_rnd_bits" = mkDefault 32;
      "vm.mmap_rnd_compat_bits" = mkDefault 16;
      "vm.mmap_min_addr" = mkDefault 65536;
    };
  };
}
