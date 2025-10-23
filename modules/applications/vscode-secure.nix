{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.vscode-secure;
in
{
  options.programs.vscode-secure = {
    enable = mkEnableOption "Enable VSCode with Firejail sandboxing";

    enableHardening = mkOption {
      type = types.bool;
      default = true;
      description = "Enable additional security hardening via Firejail";
    };

    allowNetworking = mkOption {
      type = types.bool;
      default = true;
      description = "Allow network access (required for extensions and remote development)";
    };

    niceLevel = mkOption {
      type = types.int;
      default = 10;
      description = "Nice level for VSCode process (0-19, higher = lower priority)";
    };

    ioSchedulingClass = mkOption {
      type = types.enum [
        "idle"
        "best-effort"
        "realtime"
      ];
      default = "best-effort";
      description = "IO scheduling class for VSCode";
    };

    ioSchedulingPriority = mkOption {
      type = types.int;
      default = 4;
      description = "IO scheduling priority (0-7, lower = higher priority)";
    };

    memoryLimit = mkOption {
      type = types.str;
      default = "8G";
      description = "Memory limit for VSCode process";
    };

    cpuQuota = mkOption {
      type = types.str;
      default = "80%";
      description = "CPU quota for VSCode (percentage or absolute value)";
    };

    allowedPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "\${HOME}/projects"
        "\${HOME}/Documents"
        "\${HOME}/Downloads"
      ];
      description = "List of paths that VSCode can access";
    };

    enableMicrosoftTelemetry = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Microsoft telemetry (disabled by default for privacy)";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of VSCode extensions to install";
      example = literalExpression ''
        with pkgs.vscode-extensions; [
          ms-python.python
          rust-lang.rust-analyzer
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install VSCode and Firejail
    environment.systemPackages = with pkgs; [
      (vscode.override {
        commandLineArgs = [
          "--disable-crash-reporter"
          "--disable-update-check"
        ]
        ++ optional (!cfg.enableMicrosoftTelemetry) "--disable-telemetry";
      })
      firejail
    ];

    # Firejail profile for VSCode
    environment.etc."firejail/vscode.local".text = ''
      # VSCode Firejail security profile

      # Networking - can be disabled if not needed
      ${if cfg.allowNetworking then "# net none" else "net none"}
      ${if cfg.allowNetworking then "netfilter" else ""}

      # Filesystem restrictions
      private-dev
      private-tmp

      # User restrictions
      noroot
      nogroups

      # Seccomp filter for syscall restrictions
      seccomp

      # AppArmor support
      apparmor

      # Allow VSCode config and data
      noblacklist ''${HOME}/.config/Code
      noblacklist ''${HOME}/.vscode
      noblacklist ''${HOME}/.local/share/code-oss

      # Allow specified work directories
      ${concatMapStringsSep "\n" (path: "noblacklist ${path}") cfg.allowedPaths}

      # Whitelist essential directories
      whitelist ''${HOME}/.config/Code
      whitelist ''${HOME}/.vscode
      whitelist ''${HOME}/.local/share/code-oss
      ${concatMapStringsSep "\n" (path: "whitelist ${path}") cfg.allowedPaths}

      # Read-only system directories
      read-only /opt
      read-only /srv
      read-only /media
      read-only /mnt

      # Blacklist sensitive system paths
      blacklist /root
      blacklist /boot
      blacklist /selinux
      blacklist /proc/kcore
      blacklist /proc/kallsyms

      # Memory and resource limits
      rlimit-as ${cfg.memoryLimit}
      rlimit-cpu 600
      rlimit-fsize 10G
      rlimit-nofile 1024

      # Process priority (nice level)
      nice ${toString cfg.niceLevel}

      # Disable unnecessary features
      nodvd
      noprinters
      notv
      nou2f

      # Process restrictions
      caps.drop all
      nonewprivs
      noexec ''${HOME}
      noexec /tmp

      # X11 restrictions
      x11 xorg

      # Disable 3D acceleration (can be enabled if needed)
      # nodbus
      # no3d
    '';

    # Create wrapper script for VSCode
    environment.etc."vscode-wrapper.sh" = mkIf cfg.enableHardening {
      mode = "0755";
      text = ''
        #!/bin/sh
        # VSCode wrapper with Firejail sandboxing and resource control

        # Create systemd scope for resource management
        SCOPE_NAME="vscode-$$"

        # Launch with systemd-run for cgroup-based resource control
        exec ${pkgs.systemd}/bin/systemd-run \
          --user \
          --scope \
          --unit="$SCOPE_NAME" \
          --property="MemoryMax=${cfg.memoryLimit}" \
          --property="CPUQuota=${cfg.cpuQuota}" \
          --property="Nice=${toString cfg.niceLevel}" \
          --property="IOSchedulingClass=${cfg.ioSchedulingClass}" \
          --property="IOSchedulingPriority=${toString cfg.ioSchedulingPriority}" \
          ${pkgs.firejail}/bin/firejail \
            --profile=/etc/firejail/vscode.local \
            --private-etc=alternatives,fonts,ssl,pki,crypto-policies,resolv.conf,hostname,localtime \
            ${pkgs.vscode}/bin/code \
            --disable-crash-reporter \
            --disable-update-check \
            ${optionalString (!cfg.enableMicrosoftTelemetry) "--disable-telemetry"} \
            "$@"
      '';
    };

    # Create desktop entry for sandboxed VSCode
    environment.etc."applications/vscode-secure.desktop".text = mkIf cfg.enableHardening ''
      [Desktop Entry]
      Version=1.0
      Name=Visual Studio Code (Secure/Sandboxed)
      GenericName=Text Editor
      Comment=Code Editing with Firejail sandbox
      Exec=/etc/vscode-wrapper.sh %F
      Icon=vscode
      Terminal=false
      Type=Application
      MimeType=text/plain;inode/directory;
      Categories=Development;IDE;TextEditor;
      Keywords=vscode;editor;ide;development;
      StartupNotify=true
      StartupWMClass=Code
      Actions=new-empty-window;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=/etc/vscode-wrapper.sh --new-window %F
      Icon=vscode
    '';

    # VSCode user settings with privacy/security focus
    environment.etc."vscode/user-settings.json".text = builtins.toJSON {
      # Telemetry settings
      "telemetry.telemetryLevel" = if cfg.enableMicrosoftTelemetry then "all" else "off";
      "telemetry.enableCrashReporter" = cfg.enableMicrosoftTelemetry;
      "telemetry.enableTelemetry" = cfg.enableMicrosoftTelemetry;

      # Update settings
      "update.mode" = "none";
      "update.showReleaseNotes" = false;
      "extensions.autoCheckUpdates" = false;
      "extensions.autoUpdate" = false;

      # Privacy settings
      "workbench.enableExperiments" = false;
      "workbench.settings.enableNaturalLanguageSearch" = false;
      "npm.fetchOnlinePackageInfo" = false;

      # Security
      "security.workspace.trust.enabled" = true;
      "security.workspace.trust.startupPrompt" = "always";
      "security.workspace.trust.emptyWindow" = false;

      # Git settings
      "git.autofetch" = false;
      "git.confirmSync" = true;

      # Editor settings
      "editor.formatOnSave" = false;
      "files.autoSave" = "off";

      # Microsoft-specific settings
      "extensions.ignoreRecommendations" = !cfg.enableMicrosoftTelemetry;
      "workbench.welcomePage.walkthroughs.openOnInstall" = cfg.enableMicrosoftTelemetry;
    };

    # System-wide environment variables
    environment.sessionVariables = mkMerge [
      {
        DISABLE_UPDATE_CHECK = "1";
      }
      (mkIf (!cfg.enableMicrosoftTelemetry) {
        VSCODE_TELEMETRY_OPTOUT = "1";
      })
    ];

    # Install extensions if specified
    home-manager.users = mkIf (cfg.extensions != [ ]) {
      kernelcore = {
        programs.vscode = {
          extensions = cfg.extensions;
        };
      };
    };

    # Warning message for users
    warnings = mkIf cfg.enableMicrosoftTelemetry [
      "VSCode telemetry is enabled. This sends data to Microsoft. Consider disabling with programs.vscode-secure.enableMicrosoftTelemetry = false;"
    ];
  };
}
