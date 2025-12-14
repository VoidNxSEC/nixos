{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.chromiumOrg;

  # Build the managed policy JSON by combining high-level "rules" with any raw overrides
  computedPolicies =
    let
      # Build ExtensionInstallForcelist entries like "<id>;<update_url>"
      extForceList = builtins.concatLists (
        map (
          e:
          let
            update =
              if e.updateUrl != null then e.updateUrl else "https://clients2.google.com/service/update2/crx";
          in
          if e ? id then [ "${e.id};${update}" ] else [ ]
        ) cfg.extensions.force
      );

      # Extension block/allow lists come directly from options
      extBlocklist = cfg.extensions.blocklist;
      extAllowlist = cfg.extensions.allowlist;

      # High-level organizational rules mapped to Chromium policies
      rulePolicies = lib.filterAttrs (n: v: v != null) {
        HomepageLocation = if (cfg.rules.homepage != null) then cfg.rules.homepage else null;
        HomepageIsNewTabPage =
          if (cfg.rules.homepageIsNewTabPage != null) then cfg.rules.homepageIsNewTabPage else null;
        RestoreOnStartup =
          if (cfg.rules.restoreOnStartup != null) then cfg.rules.restoreOnStartup else null; # 1 = HOMEPAGE, 4 = URLS
        RestoreOnStartupURLs = if (cfg.rules.startupUrls != [ ]) then cfg.rules.startupUrls else null;

        DefaultSearchProviderEnabled = if (cfg.rules.defaultSearch != null) then true else null;
        DefaultSearchProviderName =
          if (cfg.rules.defaultSearch != null) then cfg.rules.defaultSearch.name else null;
        DefaultSearchProviderSearchURL =
          if (cfg.rules.defaultSearch != null) then cfg.rules.defaultSearch.searchUrl else null;
        DefaultSearchProviderSuggestURL =
          if (cfg.rules.defaultSearch != null && cfg.rules.defaultSearch.suggestUrl != null) then
            cfg.rules.defaultSearch.suggestUrl
          else
            null;
        DefaultSearchProviderIconURL =
          if (cfg.rules.defaultSearch != null && cfg.rules.defaultSearch.iconUrl != null) then
            cfg.rules.defaultSearch.iconUrl
          else
            null;

        # Privacy & safety
        SafeBrowsingProtectionLevel =
          if (cfg.rules.safeBrowsing != null) then cfg.rules.safeBrowsing else null; # 0=off,1=standard,2=enhanced
        PasswordManagerEnabled =
          if (cfg.rules.passwordManagerEnabled != null) then cfg.rules.passwordManagerEnabled else null;
        IncognitoModeAvailability =
          if (cfg.rules.incognitoModeAvailability != null) then
            cfg.rules.incognitoModeAvailability
          else
            null; # 0=enabled,1=disabled,2=forced
        BrowserSignin = if (cfg.rules.browserSignin != null) then cfg.rules.browserSignin else null; # 0=disabled,1=enabled,2=forced
        SyncDisabled = if (cfg.rules.syncDisabled != null) then cfg.rules.syncDisabled else null;
        UrlBlocklist = if (cfg.rules.urlBlocklist != [ ]) then cfg.rules.urlBlocklist else null;
        UrlAllowlist = if (cfg.rules.urlAllowlist != [ ]) then cfg.rules.urlAllowlist else null;
        PopupsAllowedForUrls =
          if (cfg.rules.popupsAllowedForUrls != [ ]) then cfg.rules.popupsAllowedForUrls else null;
        AutoSelectCertificateForUrls =
          if (cfg.rules.autoSelectCertForUrls != [ ]) then cfg.rules.autoSelectCertForUrls else null;

        # Downloads
        DownloadDirectory =
          if (cfg.rules.downloadDirectory != null) then cfg.rules.downloadDirectory else null;
        PromptForDownload =
          if (cfg.rules.promptForDownload != null) then cfg.rules.promptForDownload else null;

        # Extensions
        ExtensionInstallForcelist = if (extForceList != [ ]) then extForceList else null;
        ExtensionInstallBlocklist = if (extBlocklist != [ ]) then extBlocklist else null;
        ExtensionInstallAllowlist = if (extAllowlist != [ ]) then extAllowlist else null;

        # UI/UX
        ShowHomeButton = if (cfg.rules.showHomeButton != null) then cfg.rules.showHomeButton else null;
        DefaultBrowserSettingEnabled =
          if (cfg.rules.defaultBrowserSettingEnabled != null) then
            cfg.rules.defaultBrowserSettingEnabled
          else
            null;

        # Certificates / proxies / networking (optional simple hooks)
        ProxyMode = if (cfg.rules.proxyMode != null) then cfg.rules.proxyMode else null; # "direct"|"auto_detect"|"pac_script"|"fixed_servers"|"system"
        ProxyServer = if (cfg.rules.proxyServer != null) then cfg.rules.proxyServer else null;
        ProxyPacUrl = if (cfg.rules.proxyPacUrl != null) then cfg.rules.proxyPacUrl else null;

        # Printing
        PrintingEnabled = if (cfg.rules.printingEnabled != null) then cfg.rules.printingEnabled else null;
      };
    in
    lib.recursiveUpdate rulePolicies cfg.policies;

  # Build a wrapped Chromium that injects env vars and flags for org use
  wrappedChromium = pkgs.runCommand "chromium-org" { buildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${cfg.package}/bin/chromium $out/bin/chromium \
      ${lib.concatStringsSep " " (map (a: "--add-flags ${lib.escapeShellArg a}") cfg.extraArgs)} \
      ${lib.concatStringsSep " " (
        map (
          n:
          let
            v = cfg.env.${n};
          in
          "--set ${n} ${lib.escapeShellArg v}"
        ) (lib.attrNames cfg.env)
      )}
  '';

in
{
  options.services.chromiumOrg = {
    enable = mkEnableOption "Managed Chromium with organization rules";

    package = mkOption {
      type = types.package;
      default = pkgs.chromium;
      description = "Chromium package to wrap (e.g., pkgs.chromium, pkgs.ungoogled-chromium).";
    };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "--force-dark-mode"
        "--disable-print-preview"
      ];
      description = "Extra command line flags appended to Chromium invocations.";
    };

    env = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = {
        HTTP_PROXY = "http://proxy.local:3128";
      };
      description = "Environment variables set for Chromium via wrapper.";
    };

    # High-level organization rules that map to common Chromium policies
    rules = {
      homepage = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      homepageIsNewTabPage = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      restoreOnStartup = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "1=Homepage, 4=Open specific URLs";
      };
      startupUrls = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      defaultSearch = mkOption {
        type = types.nullOr (
          types.submodule (
            { ... }:
            {
              options = {
                name = mkOption { type = types.str; };
                searchUrl = mkOption { type = types.str; };
                suggestUrl = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                iconUrl = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
              };
            }
          )
        );
        default = null;
      };

      safeBrowsing = mkOption {
        type = types.nullOr types.int;
        default = null;
      }; # 0/1/2
      passwordManagerEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      incognitoModeAvailability = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      browserSignin = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      syncDisabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      urlBlocklist = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      urlAllowlist = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      popupsAllowedForUrls = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      autoSelectCertForUrls = mkOption {
        type = with types; listOf (attrsOf str);
        default = [ ];
      };

      downloadDirectory = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      promptForDownload = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };

      showHomeButton = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      defaultBrowserSettingEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };

      proxyMode = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      proxyServer = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      proxyPacUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      printingEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
    };

    # Raw Chromium policies (merged after rules). Use this to set anything not modeled in `rules`.
    policies = mkOption {
      type = with types; attrs;
      default = { };
      description = "Raw Chromium policy map merged with computed rules. Keys must match Chromium enterprise policy names.";
    };

    extensions = {
      force = mkOption {
        type =
          with types;
          listOf (
            submodule (
              { ... }:
              {
                options = {
                  id = mkOption {
                    type = types.str;
                    description = "Chrome Web Store extension ID";
                  };
                  updateUrl = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Update URL; default is Chrome Web Store";
                  };
                };
              }
            )
          );
        default = [ ];
        description = "Extensions to force-install via policy.";
      };
      blocklist = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      allowlist = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
    };

    # Where to write managed policy JSON (Chromium uses this path; Chrome uses google/chrome)
    policiesPath = mkOption {
      type = types.str;
      default = "/etc/chromium/policies/managed";
      description = "Directory for managed policies JSON files.";
    };

    # Name of the JSON file we manage. You can add additional files via environment.etc yourself if needed.
    policyFileName = mkOption {
      type = types.str;
      default = "policies.json";
    };

    # Control whether to replace the chromium binary in PATH with the wrapped one
    replaceSystemChromium = mkOption {
      type = types.bool;
      default = true;
      description = "If true, exposes the wrapped chromium in PATH. If false, wrapper is installed as chromium-org.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "services.chromiumOrg.package must be set.";
      }
    ];

    # Managed policy file
    environment.etc."${cfg.policiesPath}/${cfg.policyFileName}".text = builtins.toJSON computedPolicies;

    # Provide a wrapped chromium
    environment.systemPackages = [
      (
        if cfg.replaceSystemChromium then
          wrappedChromium
        else
          pkgs.writeShellScriptBin "chromium-org" ''
            exec ${cfg.package}/bin/chromium ${lib.escapeShellArgs cfg.extraArgs} "$@"
          ''
      )
    ];

    # Nice to have: ensure the policies directory exists at build time for clarity
    systemd.tmpfiles.rules = [ "d ${cfg.policiesPath} 0755 root root -" ];
  };
}
