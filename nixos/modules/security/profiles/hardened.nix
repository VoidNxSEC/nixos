# modules/hardening.nix
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

{
  nix.settings = {
    sandbox = true;
    sandbox-fallback = false;

    allowed-uris = [
      "https://cache.nixos.org/"
      "https://cache.nixos-cuda.org"
    ];
    trusted-users = [ "@wheel" ];
    allowed-users = [ "@users" ];
    build-users-group = "nixbld";
    max-jobs = mkDefault 4;
    cores = mkDefault 3;
    require-sigs = true;
    auto-optimise-store = true;
    warn-dirty = false;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowInsecure = false;
    permittedInsecurePackages = [
      /* X */
    ];
  };

  security.pam = {
    sshAgentAuth.enable = true;
    loginLimits = [
      {
        domain = "*";
        item = "core";
        type = "hard";
        value = "0";
      }
      {
        domain = "*";
        item = "maxlogins";
        type = "hard";
        value = "10";
      }
      {
        domain = "*";
        item = "nofile";
        type = "soft";
        value = "65536";
      }
    ];
    services = {
      sshd.showMotd = true;
      # login.enableGnomeKeyring = false;
    };
  };

  security.pam.services.passwd.text = lib.mkDefault ''
    password required pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
  '';

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  systemd.services."setup-system-credentials" = {
    description = "Setup system credential storage";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /etc/credstore && ${pkgs.coreutils}/bin/chmod 700 /etc/credstore'";
    };
  };

  networking.firewall = {
    enable = true;
    allowPing = false;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
    logRefusedConnections = true;
    logRefusedPackets = true;
    logReversePathDrops = true;
    rejectPackets = true;

    extraCommands = ''
      # Silently drop RDP (3389) — stealth over the default REJECT
      iptables -I INPUT -p tcp --dport 3389 -j DROP
      iptables -I INPUT -p udp --dport 3389 -j DROP

      # Rate limiting for SSH
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

      # Drop invalid packets
      iptables -A INPUT -m state --state INVALID -j DROP

      # Prevent port scanning
      iptables -N port-scanning || iptables -F port-scanning
      iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
      iptables -A port-scanning -j DROP
    '';

    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 3389 -j DROP 2>/dev/null || true
      iptables -D INPUT -p udp --dport 3389 -j DROP 2>/dev/null || true
    '';
  };


  boot.kernel.sysctl = {
    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.unprivileged_userns_clone" = 0
    "kernel.perf_event_paranoid" = 3;
    "kernel.core_uses_pid" = 1;

    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.icmp_echo_ignore_all" = 1;

    # File system hardening
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_fifos" = 2;
    "fs.suid_dumpable" = 0;

    # Memory protection
    "kernel.randomize_va_space" = 2;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 10;
    "vm.mmap_min_addr" = 65536;
    "vm.max_map_count" = 262144;
  };

  boot.blacklistedKernelModules = [
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
    "bluetooth"
    #"btusb"
    "uvcvideo"
  ];

  # O ouro
  boot.kernelParams = [
    "lockdown=confidentiality"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "randomize_kstack_offset=on"
    "vsyscall=none"
    "debugfs=off"
  ];

  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
    packages = with pkgs; [ apparmor-profiles ];
  };

  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    consoleMode = "max";
  };

  services.journald = {
    extraConfig = ''
      Storage=persistent
      Compress=yes
      SplitMode=uid
      RateLimitInterval=30s
      RateLimitBurst=1000
      SystemMaxUse=1G
      MaxRetentionSec=1month
      ForwardToSyslog=yes
    '';
  };

  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      # Log authentication messages
      auth,authpriv.* /var/log/auth.log

      # Log kernel messages
      kern.* /var/log/kern.log

      # Log anything of level info or higher
      *.info;mail.none;authpriv.none;cron.none /var/log/messages
    '';
  };

  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
    dates = "04:00";
    flake = "/etc/nixos#kernelcore";
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "--print-build-logs"
      "--show-trace"
    ];
  };

  users.mutableUsers = false;

  security.loginDefs.settings = {
    PASS_MAX_DAYS = 90;
    PASS_MIN_DAYS = 1;
    PASS_WARN_AGE = 14;
    UMASK = "077";
    ENCRYPT_METHOD = "SHA512";
    SHA_CRYPT_MIN_ROUNDS = 5000;
  };

  # 🏠 Home directory encryption
  security.pam.enableEcryptfs = true;

}
