# ─────────────────────────────────────────────────────────────────────────────
# voidnxlabs · modules/brave-hardened.nix
#
# Brave Browser – tuning sob medida
# Camadas: enterprise policies · cli flags hardened · VAAPI · Wayland
#          firejail + iptables netfilter · DNS whitelist · RFC1918 drop
#
# Uso:
#   imports = [ ./modules/brave-hardened.nix ];
#   voidnxlabs.brave-hardened = {
#     enable   = true;
#     vaapiDriver = "radeonsi";   # i965 | iHD | nvidia
#     dns.provider = "quad9";
#     networkConfinement.enable = true;
#   };
# ─────────────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.voidnxlabs.brave-hardened;

  # ── DNS presets ─────────────────────────────────────────────────────────────
  dnsPresets = {
    quad9 = {
      servers = [
        "9.9.9.9"
        "149.112.112.112"
      ];
      doh = "https://dns.quad9.net/dns-query";
    };
    cloudflare = {
      servers = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      doh = "https://cloudflare-dns.com/dns-query";
    };
    nextdns = {
      servers = [
        "45.90.28.0"
        "45.90.30.0"
      ];
      doh = "https://dns.nextdns.io/${cfg.dns.nextdnsId}";
    };
    custom = {
      servers = cfg.dns.customServers;
      doh = cfg.dns.customDoH;
    };
  };

  activeDns = dnsPresets.${cfg.dns.provider};
  dns0 = elemAt activeDns.servers 0;
  dns1 = if length activeDns.servers > 1 then elemAt activeDns.servers 1 else dns0;

  # ── Enterprise Policies (/etc/brave/policies/managed/hardened.json) ─────────
  # Políticas gerenciadas: o usuário NÃO pode fazer override via UI
  managedPolicy = {

    # ── Permissions – block by default ──────────────────────────────────────
    DefaultGeolocationSetting = 2; # Block
    DefaultNotificationsSetting = 2; # Block
    DefaultMediaStreamSetting = 2; # Block camera + mic (per-site pode liberar)
    DefaultSensorsSetting = 2; # Block motion/light sensors
    DefaultWebBluetoothGuardSetting = 2; # Block Bluetooth API
    DefaultWebUsbGuardSetting = 2; # Block USB API
    DefaultSerialGuardSetting = 2; # Block Serial API
    DefaultHidGuardSetting = 2; # Block HID API
    DefaultFileSystemReadGuardSetting = 2; # Block File System Access API
    DefaultFileSystemWriteGuardSetting = 2;

    # ── DNS over HTTPS ────────────────────────────────────────────────────────
    DnsOverHttpsMode = "secure"; # força DoH; sem fallback plaintext
    DnsOverHttpsTemplates = activeDns.doh;

    # ── Conta / Sync ──────────────────────────────────────────────────────────
    BrowserSignin = 0; # Desativa signin Brave/Google
    SyncDisabled = true; # Desativa sync de dados

    # ── Telemetria ────────────────────────────────────────────────────────────
    MetricsReportingEnabled = false;
    CloudReportingEnabled = false;
    SafeBrowsingEnabled = false; # remove Google Safe Browsing telemetry
    SafeBrowsingExtendedReportingEnabled = false;

    # ── Rede ──────────────────────────────────────────────────────────────────
    EnableMediaRouter = false; # desativa Google Cast / Media Router
    NetworkPredictionOptions = 2; # 0=always 1=wifi-only 2=never (prefetch off)
    DnsInterceptionChecksEnabled = false; # não consulta servidores de interceptação DNS
    WebRtcIPHandlingPolicy = "disable_non_proxied_udp"; # previne WebRTC IP leak

    # ── HTTPS ─────────────────────────────────────────────────────────────────
    HttpsUpgradesEnabled = true; # upgrade automático http→https

    # ── Cookies ───────────────────────────────────────────────────────────────
    BlockThirdPartyCookies = true;
    # DefaultCookiesSetting = 4;                # 4=session-only — habilite se aceitar logout em cada restart

    # ── Autofill / Passwords ──────────────────────────────────────────────────
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    PasswordManagerEnabled = false; # usa gerenciador externo (Bitwarden, etc.)

    # ── Background ────────────────────────────────────────────────────────────
    BackgroundModeEnabled = false; # impede Brave de rodar em background
  };

  # ── CLI Flags – segurança ────────────────────────────────────────────────────
  securityFlags = [
    # Desativa features que fazem chamadas de rede desnecessárias
    "--disable-background-networking"
    "--disable-client-side-phishing-detection"
    "--disable-default-apps"
    "--disable-hang-monitor"
    "--disable-prompt-on-repost"
    "--disable-translate" # desativa tradução automática (Google API)
    "--metrics-recording-only" # métricas locais sem envio
    "--no-first-run"
    "--no-default-browser-check"
    "--safebrowsing-disable-auto-update"

    # Features: desativa
    "--disable-features=ChromeWhatsNewUI"
    "--disable-features=HappinessTrackingSurveysForDesktop"
    "--disable-features=DialMediaRouteProvider"
    "--disable-features=MediaRouterCastAllowAllIPs"
    "--disable-features=OptimizationHints"
    "--disable-features=OptimizationGuideModelDownloading"
    "--disable-features=AutofillServerCommunication"

    # Features: ativa (hardening)
    "--enable-features=StrictOriginIsolation" # CORS strict
    "--enable-features=NetworkServiceSandbox" # sandbox o serviço de rede
    "--enable-features=BlockInsecurePrivateNetworkRequests" # bloqueia SSRF web→RFC1918

    # Process isolation
    "--site-per-process" # cada site em processo isolado (segurança >> RAM)

    # Renderer limit (RAM vs. exploit surface)
    "--renderer-process-limit=${toString cfg.rendererProcessLimit}"
  ];

  # ── CLI Flags – performance ──────────────────────────────────────────────────
  perfFlags =
    optionals cfg.enableHardwareAcceleration [
      "--enable-features=VaapiVideoDecodeLinuxGL"
      "--enable-features=VaapiVideoEncoder"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--num-raster-threads=${toString cfg.rasterThreads}"
      "--ignore-gpu-blocklist" # força GPU mesmo em lista negra (cuidado com drivers ruins)
      "--enable-oop-rasterization" # rasterização out-of-process (crash isolation)
      "--enable-features=SkiaDeferredImageDecoding"
    ]
    ++ optionals cfg.wayland [
      "--ozone-platform=wayland"
      "--enable-features=WaylandWindowDecorations"
      "--enable-features=UseOzonePlatform"
    ];

  allFlags = concatStringsSep " " (securityFlags ++ perfFlags);

  # ── Netfilter rules (iptables) para firejail ─────────────────────────────────
  # Whitelist mínima: DNS autorizado + HTTPS/HTTP + QUIC opcional
  # Blacklist: RFC1918, CGNAT, link-local, multicast
  netfilterRules = pkgs.writeText "brave-netfilter.iptables" (
    ''
      *filter
      :INPUT DROP [0:0]
      :FORWARD DROP [0:0]
      :OUTPUT DROP [0:0]

      # ── Loopback ────────────────────────────────────────────────────────────
      -A INPUT  -i lo -j ACCEPT
      -A OUTPUT -o lo -j ACCEPT

      # ── Conexões estabelecidas / relacionadas ────────────────────────────────
      -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # ── RFC1918 / CGNAT / link-local → DROP (anti-SSRF local) ───────────────
      -A OUTPUT -d 10.0.0.0/8      -j DROP
      -A OUTPUT -d 172.16.0.0/12   -j DROP
      -A OUTPUT -d 192.168.0.0/16  -j DROP
      -A OUTPUT -d 100.64.0.0/10   -j DROP
      -A OUTPUT -d 169.254.0.0/16  -j DROP

      # ── Multicast / broadcast → DROP ────────────────────────────────────────
      -A OUTPUT -d 224.0.0.0/4     -j DROP
      -A OUTPUT -d 255.255.255.255 -j DROP

      # ── DNS: whitelist dos servidores autorizados, DROP todo o resto ─────────
      -A OUTPUT -p udp --dport 53 -d ${dns0} -j ACCEPT
      -A OUTPUT -p tcp --dport 53 -d ${dns0} -j ACCEPT
    ''
    + optionalString (dns1 != dns0) ''
      -A OUTPUT -p udp --dport 53 -d ${dns1} -j ACCEPT
      -A OUTPUT -p tcp --dport 53 -d ${dns1} -j ACCEPT
    ''
    + ''
      -A OUTPUT -p udp --dport 53 -j DROP
      -A OUTPUT -p tcp --dport 53 -j DROP

      # ── HTTPS (TCP 443) ──────────────────────────────────────────────────────
      -A OUTPUT -p tcp --dport 443 -j ACCEPT

      # ── HTTP (TCP 80) – apenas para redirect → HTTPS ─────────────────────────
      -A OUTPUT -p tcp --dport 80  -j ACCEPT

    ''
    + optionalString cfg.networkConfinement.allowQUIC ''
      # ── QUIC / HTTP3 (UDP 443) ───────────────────────────────────────────────
      -A OUTPUT -p udp --dport 443 -j ACCEPT

    ''
    + ''
      # ── DROP all else ────────────────────────────────────────────────────────
      -A INPUT  -j DROP
      -A OUTPUT -j DROP

      COMMIT
    ''
  );

  # ── Firejail Profile ─────────────────────────────────────────────────────────
  # Foca em network confinement + filesystem hardening
  # NÃO usa "seccomp" do firejail para não conflitar com a sandbox interna do Chromium
  fjProfile = pkgs.writeText "brave-hardened.fjprofile" ''
    # ── Rede ────────────────────────────────────────────────────────────────
    netfilter ${netfilterRules}
    dns ${dns0}
    ${optionalString (dns1 != dns0) "dns ${dns1}"}

    # ── Filesystem ──────────────────────────────────────────────────────────
    private-tmp          # /tmp isolado por sessão
    private-dev          # /dev mínimo

    # ── Capabilities ────────────────────────────────────────────────────────
    caps.drop all        # Chromium gerencia caps internamente

    # ── Misc ────────────────────────────────────────────────────────────────
    noroot               # impede escalada de privilégio
    nodvd
    notv
    no3d
    disable-mnt

    # nosound            # descomente se não precisar de áudio no browser
  '';

  # ── Wrapper script ───────────────────────────────────────────────────────────
  braveHardened = pkgs.writeShellScriptBin "brave" ''
    ${optionalString cfg.enableHardwareAcceleration ''
      # VAAPI driver: radeonsi (AMD) | i965 | iHD (Intel) | nvidia (proprietary)
      export LIBVA_DRIVER_NAME="${cfg.vaapiDriver}"
      export MOZ_DISABLE_RDD_SANDBOX=1   # algumas distros precisam disso para VAAPI
    ''}

    ${
      if cfg.networkConfinement.useFirejail then
        ''
          exec ${pkgs.firejail}/bin/firejail \
            --profile=${fjProfile} \
            --name=brave-hardened \
            ${pkgs.brave}/bin/brave ${allFlags} "$@"
        ''
      else
        ''
          exec ${pkgs.brave}/bin/brave ${allFlags} "$@"
        ''
    }
  '';

  # ── Desktop entry patchado (usa o wrapper) ───────────────────────────────────
  braveDesktopEntry = pkgs.runCommand "brave-desktop-hardened" { } ''
    mkdir -p $out/share/applications
    sed \
      's|Exec=brave-browser\b|Exec=${braveHardened}/bin/brave|g' \
      < ${pkgs.brave}/share/applications/brave-browser.desktop \
      > $out/share/applications/brave-browser.desktop
  '';

in
{

  # ── Options ───────────────────────────────────────────────────────────────────
  options.voidnxlabs.brave-hardened = {

    enable = mkEnableOption "Brave Browser hardened (voidnxlabs)";

    # ── Performance ──────────────────────────────────────────────────────────
    enableHardwareAcceleration = mkOption {
      type = types.bool;
      default = true;
      description = "Habilita VAAPI + GPU rasterization. Exige drivers Mesa/VA-API.";
    };

    vaapiDriver = mkOption {
      type = types.str;
      default = "radeonsi";
      description = "VAAPI driver: radeonsi (AMD) | i965 | iHD (Intel) | nvidia";
      example = "i965";
    };

    rasterThreads = mkOption {
      type = types.int;
      default = 4;
      description = "--num-raster-threads: threads de rasterização GPU.";
    };

    rendererProcessLimit = mkOption {
      type = types.int;
      default = 4;
      description = "Limite de processos renderer (segurança × RAM). Default=4.";
    };

    wayland = mkOption {
      type = types.bool;
      default = true;
      description = "Suporte nativo Wayland via ozone. Desative em X11 puro.";
    };

    # ── DNS ──────────────────────────────────────────────────────────────────
    dns = {
      provider = mkOption {
        type = types.enum [
          "quad9"
          "cloudflare"
          "nextdns"
          "custom"
        ];
        default = "quad9";
        description = "Provider DoH usado em políticas e nas regras netfilter.";
      };
      nextdnsId = mkOption {
        type = types.str;
        default = "";
        description = "ID do perfil NextDNS (obrigatório se provider=nextdns).";
        example = "abc123";
      };
      customServers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "IPs dos servidores DNS custom (obrigatório se provider=custom).";
        example = [
          "94.140.14.14"
          "94.140.15.15"
        ];
      };
      customDoH = mkOption {
        type = types.str;
        default = "";
        description = "Template DoH custom (obrigatório se provider=custom).";
        example = "https://dns.adguard-dns.com/dns-query";
      };
    };

    # ── Network Confinement ───────────────────────────────────────────────────
    networkConfinement = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Ativa confinamento de rede (firejail + iptables netfilter).";
      };
      useFirejail = mkOption {
        type = types.bool;
        default = true;
        description = "Lança Brave dentro de um sandbox firejail com netfilter.";
      };
      allowQUIC = mkOption {
        type = types.bool;
        default = true;
        description = "Permite UDP 443 (QUIC/HTTP3). Desative se quiser só TCP.";
      };
    };
  };

  # ── Config ────────────────────────────────────────────────────────────────────
  config = mkIf cfg.enable {

    # ── Pacotes ───────────────────────────────────────────────────────────────
    environment.systemPackages = [
      pkgs.brave
      braveHardened
      braveDesktopEntry
    ]
    ++ optionals cfg.networkConfinement.useFirejail [
      pkgs.firejail
      pkgs.iptables # firejail usa iptables; necessário em sistemas com nftables puro
    ]
    ++ optionals cfg.enableHardwareAcceleration [
      pkgs.libva-utils # vainfo – diagnóstico VAAPI
      pkgs.vaapiVdpau
      pkgs.libvdpau-va-gl
    ];

    # ── Enterprise Policies ───────────────────────────────────────────────────
    environment.etc."brave/policies/managed/hardened.json".text = builtins.toJSON managedPolicy;

    # ── Firejail local override ───────────────────────────────────────────────
    # Firejail lê /etc/firejail/<profile>.local após o .profile padrão
    environment.etc."firejail/brave.local".text = mkIf cfg.networkConfinement.useFirejail ''
      # voidnxlabs override – aplica netfilter e DNS forçado
      netfilter ${netfilterRules}
      dns ${dns0}
      ${optionalString (dns1 != dns0) "dns ${dns1}"}
    '';

    # ── Hardware video acceleration ───────────────────────────────────────────
    # NixOS ≥ 24.05: hardware.graphics substitui hardware.opengl
    hardware.graphics = mkIf cfg.enableHardwareAcceleration {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # ── Wrapper tem prioridade no PATH ────────────────────────────────────────
    environment.shellInit = ''
      export PATH="${braveHardened}/bin:$PATH"
    '';

    # ── Assertions ────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = !(cfg.networkConfinement.useFirejail && !cfg.networkConfinement.enable);
        message = "voidnxlabs.brave-hardened: useFirejail = true requer networkConfinement.enable = true";
      }
      {
        assertion = cfg.dns.provider != "nextdns" || cfg.dns.nextdnsId != "";
        message = "voidnxlabs.brave-hardened: dns.provider = nextdns requer dns.nextdnsId";
      }
      {
        assertion =
          cfg.dns.provider != "custom" || (cfg.dns.customServers != [ ] && cfg.dns.customDoH != "");
        message = "voidnxlabs.brave-hardened: dns.provider = custom requer dns.customServers e dns.customDoH";
      }
    ];
  };
}
