{
  config,
  pkgs,
  lib,
  ...
}:

# ═══════════════════════════════════════════════════════════════════════════════
# FIREFOX - Declarative Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# Extensions: Install manually from addons.mozilla.org (synced via Firefox account)
# Settings: Managed declaratively via about:config
# ═══════════════════════════════════════════════════════════════════════════════

{
  programs.firefox = {
    enable = true;

    # ─────────────────────────────────────────────────────────────────────────
    # PROFILE: kernelcore (Default)
    # ─────────────────────────────────────────────────────────────────────────
    profiles.kernelcore = {
      isDefault = true;

      # Extensions: Install manually (uBlock Origin, Bitwarden, Privacy Badger, etc.)
      # They will sync via Firefox Sync if you enable it

      # ───────────────────────────────────────────────────────────────────────
      # SETTINGS (about:config)
      # ───────────────────────────────────────────────────────────────────────
      settings = {
        # === PRIVACY & SECURITY ===
        "privacy.resistFingerprinting" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.firstparty.isolate" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # === TELEMETRY OFF ===
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "browser.ping-centre.telemetry" = false;
        "app.normandy.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;

        # === SEARCH & SUGGESTIONS ===
        "browser.search.suggest.enabled" = false;
        "browser.search.suggest.enabled.private" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;

        # === PERFORMANCE (Intel iGPU) ===
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "widget.dmabuf.force-enabled" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.canvas.accelerated" = true;

        # === SESSION MANAGEMENT ===
        "browser.sessionstore.enabled" = true;
        "browser.sessionstore.resume_from_crash" = true;
        "browser.sessionstore.resume_session_once" = true;

        # === UI TWEAKS ===
        "browser.shell.checkDefaultBrowser" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.enabled" = false;
        "browser.startup.page" = 3; # Resume previous session
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "general.smoothScroll" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.use-xdg-desktop-portal.mime-handler" = 1;

        # === NETWORK HARDENING ===
        "network.http.referer.XOriginPolicy" = 2;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "media.peerconnection.enabled" = false; # Disable WebRTC
        "geo.enabled" = false;

        # === DNS OVER HTTPS ===
        "network.trr.mode" = 2; # TRR first, fallback to native
        "network.trr.uri" = "https://dns.quad9.net/dns-query";

        # === UPDATES (Managed by Nix) ===
        "app.update.auto" = false;
        "app.update.enabled" = false;
      };

      # ───────────────────────────────────────────────────────────────────────
      # SEARCH ENGINES
      # ───────────────────────────────────────────────────────────────────────
      search = {
        default = "ddg"; # Use ID instead of name
        force = true;
        engines = {
          "Nix Packages" = {
            urls = [ { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; } ];
            icon = "https://nixos.org/favicon.png";
            definedAliases = [ "@np" ];
          };
          "Nix Options" = {
            urls = [ { template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}"; } ];
            definedAliases = [ "@no" ];
          };
          "GitHub" = {
            urls = [ { template = "https://github.com/search?q={searchTerms}&type=code"; } ];
            definedAliases = [ "@gh" ];
          };
        };
      };

      # ───────────────────────────────────────────────────────────────────────
      # BOOKMARKS (Managed declaratively)
      # ───────────────────────────────────────────────────────────────────────
      bookmarks = {
        force = true; # New format requirement
        settings = [
          {
            name = "DevTools";
            toolbar = true;
            bookmarks = [
              {
                name = "NixOS Search";
                url = "https://search.nixos.org/";
              }
              {
                name = "GitHub";
                url = "https://github.com/";
              }
              {
                name = "GitLab";
                url = "https://gitlab.com/";
              }
            ];
          }
          {
            name = "AI";
            toolbar = true;
            bookmarks = [
              {
                name = "ChatGPT";
                url = "https://chatgpt.com/";
              }
              {
                name = "Claude";
                url = "https://claude.ai/";
              }
            ];
          }
        ];
      };
    };
  };
}
