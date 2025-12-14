{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.firefox-privacy;
in
{
  options.programs.firefox-privacy = {
    enable = mkEnableOption "Firefox Hardened: Privacy + Intel iGPU Tuning";

    enableGoogleAuthenticator = mkOption {
      type = types.bool;
      default = true;
      description = "Integração PAM com Google Authenticator para autenticação local reforçada.";
    };

    enableHardening = mkOption {
      type = types.bool;
      default = true;
      description = "Ativa scripts de hardening user.js e isolamento via Firejail.";
    };
  };

  config = mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # 1. OTIMIZAÇÃO DE SISTEMA E DRIVERS (Intel iGPU & Hardware Acceleration)
    # -------------------------------------------------------------------------

    # Garante que o subsistema gráfico tenha acesso às bibliotecas de decodificação
    #hardware.graphics = {
    #enable = true;
    #extraPackages = with pkgs; [
    #intel-media-driver   # Driver VA-API moderno para Broadwell+ (iHD)
    #libvdpau-va-gl       # Backend VDPAU para VA-API
    #libva                # Video Acceleration API
    #ffmpeg_6-full        # Backend multimídia completo
    #];
    #};

    # Variáveis de ambiente globais para forçar o Firefox a usar a GPU correta
    environment.sessionVariables = {
      MOZ_DISABLE_RDD_SANDBOX = "1"; # Necessário para VA-API funcionar corretamente em alguns contextos
      #LIBVA_DRIVER_NAME = "iHD";     # Força o driver Intel Media (evita fallback para i965 antigo)
    };

    # Pacotes auxiliares para verificação de aceleração (intel_gpu_top, vainfo)
    environment.systemPackages =
      with pkgs;
      [
        libva-utils
        intel-gpu-tools
        google-authenticator
      ]
      ++ optional cfg.enableGoogleAuthenticator pkgs.linux-pam;

    # -------------------------------------------------------------------------
    # 2. CONFIGURAÇÃO DECLARATIVA DO FIREFOX (Policies & Preferences)
    # -------------------------------------------------------------------------

    programs.firefox = {
      enable = true;

      # Políticas Corporativas (Imutáveis pelo usuário na GUI)
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true; # Remove Sync totalmente (Self-hosted mindset)
        DisableFormHistory = true;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "never";
        DontCheckDefaultBrowser = true;

        # Bloqueio de DNS via HTTPS externo (Força uso do DNS do sistema ou definido abaixo)
        DNSOverHTTPS = {
          Enabled = true;
          ProviderURL = "https://dns.quad9.net/dns-query"; # Quad9 (Privacidade e Segurança)
          Locked = true;
        };

        # Hardening de Extensões
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            # Privacy Badger
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          };
          "skipredirect@sblask" = {
            # Skip Redirect (Evita rastreamento via redirecionamento)
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/skip-redirect/latest.xpi";
          };
        };
      };

      # Preferências Internas (about:config) - O núcleo do Tunning
      preferences = {
        # --- SEÇÃO 1: GPU & PERFORMANCE INTEL (Otimização Chromium-killer) ---
        "gfx.webrender.all" = true; # Força WebRender (Compositor GPU Rust)
        "media.ffmpeg.vaapi.enabled" = true; # Ativa VA-API para decodificação de vídeo
        "media.rdd-ffmpeg.enabled" = true; # Processo RDD para FFmpeg
        "widget.dmabuf.force-enabled" = true; # Força DMA-BUF (Zero-copy texture sharing GPU->Browser)
        "layers.acceleration.force-enabled" = true;
        "gfx.canvas.accelerated" = true; # Aceleração de Canvas 2D na GPU
        "media.av1.enabled" = false; # Desativa AV1 se a iGPU não tiver hardware decode (economiza CPU)

        # --- SEÇÃO 2: PRIVACIDADE & ANTI-FINGERPRINTING (Nível Arkenfox) ---
        "privacy.resistFingerprinting" = true; # Padroniza UserAgent, Timezone e APIs de hardware
        "privacy.fingerprintingProtection" = true; # Proteção adicional contra canvas/font fingerprinting
        "privacy.firstparty.isolate" = true; # Total State Partitioning (Cookies/Cache isolados por domínio)

        # WebGL e WebRTC (Vetores de vazamento de IP e Fingerprinting)
        "webgl.disabled" = true; # Desativa WebGL (Segurança extrema. Se quebrar sites, mude para false)
        "media.peerconnection.enabled" = false; # Mata WebRTC (Impede vazamento de IP local)
        "geo.enabled" = false; # Mata geolocalização

        # --- SEÇÃO 3: REDUÇÃO DE RUÍDO E TELEMETRIA (Air-gapped feel) ---
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "experiments.supported" = false;
        "network.allow-experiments" = false;
        "browser.ping-centre.telemetry" = false;
        "app.normandy.enabled" = false; # Desativa "Shield Studies" (Backdoor de config remota da Mozilla)
        "app.update.auto" = false; # Gerenciado pelo Nix, não pelo Firefox
        "browser.safebrowsing.malware.enabled" = false; # Remove chamadas ao Google Safebrowsing
        "browser.safebrowsing.phishing.enabled" = false;

        # --- SEÇÃO 4: UX & LIMPEZA ---
        "browser.startup.page" = 0; # Página em branco
        "browser.newtabpage.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
      };
    };

    # -------------------------------------------------------------------------
    # 3. SEGURANÇA FÍSICA E ISOLAMENTO DE PROCESSOS
    # -------------------------------------------------------------------------

    # Módulo PAM para Google Authenticator
    security.pam.oath = mkIf cfg.enableGoogleAuthenticator {
      enable = true;
      digits = 6;
      window = 30;
    };

    # Script de injeção direta no profile (user.js) para configurações que o Nix não alcança em runtime
    environment.etc."firefox/harden.sh" = mkIf cfg.enableHardening {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Garante que o profile receba tunning mesmo se criado manualmente
        PROFILE_DIR="$HOME/.mozilla/firefox"
        [ ! -d "$PROFILE_DIR" ] && exit 0

        DEFAULT_PROFILE=$(grep -oP "(?<=Path=).*" "$PROFILE_DIR/profiles.ini" | head -1)
        [ -z "$DEFAULT_PROFILE" ] && exit 0

        echo "Injecting entropy-reduction and hardening prefs into $DEFAULT_PROFILE..."

        cat >> "$PROFILE_DIR/$DEFAULT_PROFILE/user.js" <<'EOF'
        // Hardening de baixo nível
        user_pref("privacy.resistFingerprinting.letterboxing", true); // Adiciona margens para ocultar resolução real
        user_pref("network.http.referer.XOriginPolicy", 2);           // Envia referer apenas para mesmo host
        user_pref("network.http.referer.XOriginTrimmingPolicy", 2);   // Envia apenas esquema/host/porta
        user_pref("dom.event.clipboardevents.enabled", false);        // Impede sites de saberem se você copiou/colou
        user_pref("dom.battery.enabled", false);                      // API Bateria
        user_pref("dom.gamepad.enabled", false);                      // API Controle
        user_pref("dom.vr.enabled", false);                           // API VR
        EOF
      '';
    };

    # Firejail: Isolamento de syscalls e filesystem
    environment.etc."firejail/firefox.local" = mkIf cfg.enableHardening {
      text = ''
        # Perfil restritivo para Firefox
        noblacklist ${"\${HOME}"}/.mozilla
        whitelist ${"\${HOME}"}/.mozilla

        # Bloqueia acesso a diretórios sensíveis
        blacklist /boot
        blacklist /mnt
        blacklist /media

        # Hardening de Kernel
        seccomp
        caps.drop all
        nonewprivs
        noroot
        protocol unix,inet,inet6,netlink
        netfilter

        # Impede execução de binários no /tmp e /home
        noexec /tmp
        noexec ${"\${HOME}"}
      '';
    };
  };
}
