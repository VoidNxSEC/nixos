{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.chromiumOrg;

  # Build the managed policy JSON by combining high-level "rules" with any raw overrides
  computedPolicies = let
    # Build ExtensionInstallForcelist entries like "<id>;<update_url>"
    extForceList = builtins.concatLists (
      map (e:
        let update = if e ? updateUrl then e.updateUrl else "https://clients2.google.com/service/update2/crx";
        in if e ? id then [ "${e.id};${update}" ] else []
      ) cfg.extensions.force
    );

    # Extension block/allow lists come directly from options
    extBlocklist = cfg.extensions.blocklist;
    extAllowlist = cfg.extensions.allowlist;

    # High-level organizational rules mapped to Chromium policies
    rulePolicies = {
      HomepageLocation = mkIf (cfg.rules.homepage != null) cfg.rules.homepage;
      HomepageIsNewTabPage = mkIf (cfg.rules.homepageIsNewTabPage != null) cfg.rules.homepageIsNewTabPage;
      RestoreOnStartup = mkIf (cfg.rules.restoreOnStartup != null) cfg.rules.restoreOnStartup; # 1 = HOMEPAGE, 4 = URLS
      RestoreOnStartupURLs = mkIf (cfg.rules.startupUrls != []) cfg.rules.startupUrls;

      DefaultSearchProviderEnabled = mkIf (cfg.rules.defaultSearch != null) true;
      DefaultSearchProviderName = mkIf (cfg.rules.defaultSearch != null) cfg.rules.defaultSearch.name;
      DefaultSearchProviderSearchURL = mkIf (cfg.rules.defaultSearch != null) cfg.rules.defaultSearch.searchUrl;
      DefaultSearchProviderSuggestURL = mkIf (cfg.rules.defaultSearch != null && cfg.rules.defaultSearch ? suggestUrl) cfg.rules.defaultSearch.suggestUrl;
      DefaultSearchProviderIconURL = mkIf (cfg.rules.defaultSearch != null && cfg.rules.defaultSearch ? iconUrl) cfg.rules.defaultSearch.iconUrl;

      # Privacy & safety
      SafeBrowsingProtectionLevel = mkIf (cfg.rules.safeBrowsing != null) cfg.rules.safeBrowsing; # 0=off,1=standard,2=enhanced
      PasswordManagerEnabled = mkIf (cfg.rules.passwordManagerEnabled != null) cfg.rules.passwordManagerEnabled;
      IncognitoModeAvailability = mkIf (cfg.rules.incognitoModeAvailability != null) cfg.rules.incognitoModeAvailability; # 0=enabled,1=disabled,2=forced
      BrowserSignin = mkIf (cfg.rules.browserSignin != null) cfg.rules.browserSignin; # 0=disabled,1=enabled,2=forced
      SyncDisabled = mkIf (cfg.rules.syncDisabled != null) cfg.rules.syncDisabled;
      UrlBlocklist = mkIf (cfg.rules.urlBlocklist != []) cfg.rules.urlBlocklist;
      UrlAllowlist = mkIf (cfg.rules.urlAllowlist != []) cfg.rules.urlAllowlist;
      PopupsAllowedForUrls = mkIf (cfg.rules.popupsAllowedForUrls != []) cfg.rules.popupsAllowedForUrls;
      AutoSelectCertificateForUrls = mkIf (cfg.rules.autoSelectCertForUrls != []) cfg.rules.autoSelectCertForUrls;

      # Downloads
      DownloadDirectory = mkIf (cfg.rules.downloadDirectory != null) cfg.rules.downloadDirectory;
      PromptForDownload = mkIf (cfg.rules.promptForDownload != null) cfg.rules.promptForDownload;

      # Extensions
      ExtensionInstallForcelist = mkIf (extForceList != []) extForceList;
      ExtensionInstallBlocklist = mkIf (extBlocklist != []) extBlocklist;
      ExtensionInstallAllowlist = mkIf (extAllowlist != []) extAllowlist;

      # UI/UX
      ShowHomeButton = mkIf (cfg.rules.showHomeButton != null) cfg.rules.showHomeButton;
      DefaultBrowserSettingEnabled = mkIf (cfg.rules.defaultBrowserSettingEnabled != null) cfg.rules.defaultBrowserSettingEnabled;

      # Certificates / proxies / networking (optional simple hooks)
      ProxyMode = mkIf (cfg.rules.proxyMode != null) cfg.rules.proxyMode; # "direct"|"auto_detect"|"pac_script"|"fixed_servers"|"system"
      ProxyServer = mkIf (cfg.rules.proxyServer != null) cfg.rules.proxyServer;
      ProxyPacUrl = mkIf (cfg.rules.proxyPacUrl != null) cfg.rules.proxyPacUrl;

      # Printing
      PrintingEnabled = mkIf (cfg.rules.printingEnabled != null) cfg.rules.printingEnabled;
    };
  in lib.recursiveUpdate rulePolicies cfg.policies;

  # Build a wrapped Chromium that injects env vars and flags for org use
  wrappedChromium = pkgs.runCommand "chromium-org" { buildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${cfg.package}/bin/chromium $out/bin/chromium \
      ${lib.concatStringsSep " " (map (a: "--add-flags ${lib.escapeShellArg a}") cfg.extraArgs)} \
      ${lib.concatStringsSep " " (map (n: let v = cfg.env.${n}; in "--set ${n} ${lib.escapeShellArg v}") (lib.attrNames cfg.env))}
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
      default = [];
      example = [ "--force-dark-mode" "--disable-print-preview" ];
      description = "Extra command line flags appended to Chromium invocations.";
    };

    env = mkOption {
      type = with types; attrsOf str;
      default = {};
      example = { HTTP_PROXY = "http://proxy.local:3128"; };
      description = "Environment variables set for Chromium via wrapper.";
    };

    # High-level organization rules that map to common Chromium policies
    rules = {
      homepage = mkOption { type = with types; nullOr str; default = null; };
      homepageIsNewTabPage = mkOption { type = types.nullOr types.bool; default = null; };
      restoreOnStartup = mkOption {
        type = types.nullOr types.int; default = null;
        description = "1=Homepage, 4=Open specific URLs";
      };
      startupUrls = mkOption { type = with types; listOf str; default = []; };
      defaultSearch = mkOption {
        type = types.nullOr (types.submodule ({...}: {
          options = {
            name = mkOption { type = types.str; };
            searchUrl = mkOption { type = types.str; };
            suggestUrl = mkOption { type = types.nullOr types.str; default = null; };
            iconUrl = mkOption { type = types.nullOr types.str; default = null; };
          };
        }));
        default = null;
      };

      safeBrowsing = mkOption { type = types.nullOr types.int; default = null; }; # 0/1/2
      passwordManagerEnabled = mkOption { type = types.nullOr types.bool; default = null; };
      incognitoModeAvailability = mkOption { type = types.nullOr types.int; default = null; };
      browserSignin = mkOption { type = types.nullOr types.int; default = null; };
      syncDisabled = mkOption { type = types.nullOr types.bool; default = null; };
      urlBlocklist = mkOption { type = with types; listOf str; default = []; };
      urlAllowlist = mkOption { type = with types; listOf str; default = []; };
      popupsAllowedForUrls = mkOption { type = with types; listOf str; default = []; };
      autoSelectCertForUrls = mkOption { type = with types; listOf (attrsOf str); default = []; };

      downloadDirectory = mkOption { type = types.nullOr types.str; default = null; };
      promptForDownload = mkOption { type = types.nullOr types.bool; default = null; };

      showHomeButton = mkOption { type = types.nullOr types.bool; default = null; };
      defaultBrowserSettingEnabled = mkOption { type = types.nullOr types.bool; default = null; };

      proxyMode = mkOption { type = types.nullOr types.str; default = null; };
      proxyServer = mkOption { type = types.nullOr types.str; default = null; };
      proxyPacUrl = mkOption { type = types.nullOr types.str; default = null; };

      printingEnabled = mkOption { type = types.nullOr types.bool; default = null; };
    };

    # Raw Chromium policies (merged after rules). Use this to set anything not modeled in `rules`.
    policies = mkOption {
      type = with types; attrs;
      default = {};
      description = "Raw Chromium policy map merged with computed rules. Keys must match Chromium enterprise policy names.";
    };

    extensions = {
      force = mkOption {
        type = with types; listOf (submodule ({...}: {
          options = {
            id = mkOption { type = types.str; description = "Chrome Web Store extension ID"; };
            updateUrl = mkOption {
              type = types.nullOr types.str; default = null;
              description = "Update URL; default is Chrome Web Store";
            };
          };
        }));
        default = [];
        description = "Extensions to force-install via policy.";
      };
      blocklist = mkOption { type = with types; listOf str; default = []; };
      allowlist = mkOption { type = with types; listOf str; default = []; };
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
      type = types.bool; default = true;
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
    environment.systemPackages = [ (if cfg.replaceSystemChromium then wrappedChromium else pkgs.writeShellScriptBin "chromium-org" ''
      exec ${cfg.package}/bin/chromium ${lib.escapeShellArgs cfg.extraArgs} "$@"
    '') ];

    # Nice to have: ensure the policies directory exists at build time for clarity
    systemd.tmpfiles.rules = [ "d ${cfg.policiesPath} 0755 root root -" ];
  };
}

