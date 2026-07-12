{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.privacy-paranoia.configuration = {
    system.nixos.tags = [ "PrivacyParanoia" ];

    # ── Hardening máximo ──────────────────────────────────────────────────────
    kernelcore.security.hardening.enable = lib.mkForce true;
    kernelcore.security.kernel.enable = lib.mkForce true;
    kernelcore.security.audit.enable = lib.mkForce true;

    # ── Rede: apenas Tor e VPN — sem DNS leaks ────────────────────────────────
    services.tor = {
      enable = true;
      client.enable = true;
      settings = {
        ExitNodes = "{br},{us},{de}";
        StrictNodes = true;
      };
    };

    # DNS via Tor — evita vazamento
    networking.nameservers = lib.mkForce [ "127.0.0.1" ];
    services.resolved.enable = lib.mkForce false;

    # ── Desabilita serviços que expõem dados ──────────────────────────────────
    services.avahi.enable = lib.mkForce false;
    services.printing.enable = lib.mkForce false;
    hardware.bluetooth.enable = lib.mkForce false;

    # ── Kernel: parâmetros anti-fingerprinting ────────────────────────────────
    boot.kernel.sysctl = {
      "net.ipv4.tcp_timestamps" = lib.mkForce 0;
      "kernel.kptr_restrict" = lib.mkForce 2;
      "kernel.dmesg_restrict" = lib.mkForce 1;
      "net.ipv4.conf.all.log_martians" = lib.mkForce 1;
      "net.ipv4.conf.default.log_martians" = lib.mkForce 1;
      "net.ipv4.conf.all.accept_redirects" = lib.mkForce 0;
      "net.ipv4.conf.default.accept_redirects" = lib.mkForce 0;
    };

    # ── Módulos de kernel bloqueados ──────────────────────────────────────────
    boot.blacklistedKernelModules = lib.mkForce [
      # Wireless com histórico de vulnerabilidades
      "firewire-core"
      "firewire-ohci"
      "firewire-sbp2"
      # Filesystems desnecessários
      "cramfs"
      "freevxfs"
      "jffs2"
      "hfs"
      "hfsplus"
      "udf"
      # Protocolos raramente usados e com superfície de ataque
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
      "p8022"
      "can"
      "atm"
      # Hardware não utilizado
      "bluetooth"
      "btusb"
    ];

    # ── Browser: Tor Browser por padrão ──────────────────────────────────────
    environment.systemPackages = with pkgs; [
      tor-browser
      torsocks
      onionshare-gui
      veracrypt
      keepassxc
    ];

    # ── Desabilita telemetria de apps ─────────────────────────────────────────
    environment.variables = {
      DO_NOT_TRACK = "1";
      HOMEBREW_NO_ANALYTICS = "1";
    };

    # ── Firewall: nega tudo por padrão, whitelist explícita ───────────────────
    networking.firewall = {
      enable = lib.mkForce true;
      allowedTCPPorts = lib.mkForce [
        9050
        9150
      ]; # Tor only
      allowedUDPPorts = lib.mkForce [ ];
      logRefusedConnections = true;
    };
  };
}
