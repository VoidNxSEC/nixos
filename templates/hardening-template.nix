# modules/hardening.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  ##########################################################################
  # 🔒 Hardening Global do Nix Daemon
  ##########################################################################
  nix.settings = {
    sandbox = true;
    sandbox-fallback = false;
    allowed-uris = [
      "https://github.com/"
      "https://gitlab.com/"
      "https://nixos.org/"
      "https://cache.nixos.org/"
    ];
    trusted-users = [ "@wheel" ];
    allowed-users = [ "@users" ];
    build-users-group = "nixbld";
    max-jobs = "auto";
    cores = 0;
    require-sigs = true;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  ##########################################################################
  # 📦 Hardening de Compilação - Flags Fortalecidas
  ##########################################################################
  nixpkgs.config = {
    allowUnfree = false;
    allowBroken = false;
    allowInsecure = false;
  };

  # Habilita todas as flags de hardening globalmente
  nixpkgs.overlays = [
    (self: super: {
      stdenv =
        super.stdenvAdapters.withCFlags
          [
            # FORTIFY_SOURCE=3 - Proteção de buffer overflow (nível máximo)
            "-D_FORTIFY_SOURCE=3"

            # Stack Protector Strong - Proteção contra stack smashing
            "-fstack-protector-strong"

            # PIE (Position Independent Executable) - ASLR para executáveis
            "-fPIE"

            # Format String Protection
            "-Wformat"
            "-Wformat-security"
            "-Werror=format-security"

            # Stack Clash Protection
            "-fstack-clash-protection"

            # Control Flow Integrity
            "-fcf-protection=full"
          ]
          (
            super.stdenvAdapters.withCFlags [
              # Linker flags para PIE e RELRO
              "-pie"
              "-Wl,-z,relro"
              "-Wl,-z,now"
              "-Wl,-z,noexecstack"
            ] super.stdenv
          );
    })
  ];

  # Habilita hardening flags no stdenv
  environment.variables = {
    HARDENING_ENABLE = "fortify stackprotector pic strictoverflow format relro bindnow";
  };

  ##########################################################################
  # 🔐 PAM & Autenticação Hardened
  ##########################################################################
  security.pam = {
    enableSSHAgentAuth = true;
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
        item = "maxsyslogins";
        type = "hard";
        value = "3";
      }
      {
        domain = "*";
        item = "nofile";
        type = "soft";
        value = "65536";
      }
      {
        domain = "*";
        item = "nofile";
        type = "hard";
        value = "65536";
      }
    ];
  };

  ##########################################################################
  # 🛡️ Kernel Hardening
  ##########################################################################
  boot.kernelPackages = pkgs.linuxPackages_hardened;

  boot.kernelParams = [
    # Desabilita mitigações que podem expor informações
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "pti=on"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "module.sig_enforce=1"
    "lockdown=confidentiality"
  ];

  boot.kernel.sysctl = {
    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;

    # Kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.yama.ptrace_scope" = 2;

    # Filesystem hardening
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.suid_dumpable" = 0;
  };

  ##########################################################################
  # 🔒 Security Modules
  ##########################################################################
  security = {
    # Proteção de módulos do kernel
    lockKernelModules = true;
    protectKernelImage = true;

    # AppArmor para confinamento de aplicações
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };

    # Auditd para logs de segurança
    audit = {
      enable = true;
      rules = [
        "-a exit,always -F arch=b64 -S execve"
      ];
    };

    # Políticas de sudo mais restritivas
    sudo = {
      enable = true;
      execWheelOnly = true;
      extraConfig = ''
        Defaults timestamp_timeout=5
        Defaults lecture="always"
        Defaults logfile=/var/log/sudo.log
        Defaults log_input,log_output
      '';
    };
  };

  ##########################################################################
  # 🚫 Restrições Adicionais
  ##########################################################################

  # Remove capacidades desnecessárias
  security.wrappers = { };

  # Previne core dumps
  systemd.coredump.enable = false;

  # Firewall restritivo por padrão
  networking.firewall = {
    enable = true;
    allowPing = false;
    logRefusedConnections = true;
    logRefusedPackets = true;
  };

  ##########################################################################
  # 📋 Logging e Auditoria
  ##########################################################################
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    RuntimeMaxUse=100M
    ForwardToSyslog=yes
    Storage=persistent
  '';

  ##########################################################################
  # 🎯 Hardening de Compilação Específico por Pacote
  ##########################################################################
  nixpkgs.config.packageOverrides = pkgs: {
    # Força hardening máximo para pacotes críticos
    openssh = pkgs.openssh.override {
      withKerberos = false;
      withLdap = false;
    };
  };
}
