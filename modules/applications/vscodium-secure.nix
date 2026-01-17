{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.vscodium-secure;
in
{
  options.programs.vscodium-secure = {
    enable = mkEnableOption "Enable VSCodium with Firejail sandboxing";

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
      description = "Nice level for VSCodium process (0-19, higher = lower priority)";
    };

    ioSchedulingClass = mkOption {
      type = types.enum [
        "idle"
        "best-effort"
        "realtime"
      ];
      default = "best-effort";
      description = "IO scheduling class for VSCodium";
    };

    ioSchedulingPriority = mkOption {
      type = types.int;
      default = 4;
      description = "IO scheduling priority (0-7, lower = higher priority)";
    };

    memoryLimit = mkOption {
      type = types.str;
      default = "8G";
      description = "Memory limit for VSCodium process";
    };

    cpuQuota = mkOption {
      type = types.str;
      default = "80%";
      description = "CPU quota for VSCodium (percentage or absolute value)";
    };

    allowedPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "\${HOME}/projects"
        "\${HOME}/Documents"
        "\${HOME}/Downloads"
      ];
      description = "List of paths that VSCodium can access";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of VSCodium extensions to install";
      example = literalExpression ''
        with pkgs.vscode-extensions; [
          ms-python.python
          rust-lang.rust-analyzer
        ]
      '';
    };

    enableGitLabDuo = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GitLab Duo integration for VSCodium";
    };
  };

  config = mkIf cfg.enable {
    # Enable GitLab Duo service if requested
    services.gitlabDuo.enable = mkIf cfg.enableGitLabDuo true;

    # Install VSCodium and Firejail
    environment.systemPackages = with pkgs; [
      (vscodium.override {
        commandLineArgs = [
          "--disable-telemetry"
          "--disable-crash-reporter"
          "--disable-update-check"
        ];
      })
      firejail
    ];

    # Firejail profile for VSCodium
    environment.etc."firejail/vscodium.local".text = ''
      # VSCodium Firejail security profile

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

      # Allow VSCodium config and data
      noblacklist ''${HOME}/.config/VSCodium
      noblacklist ''${HOME}/.vscode-oss
      noblacklist ''${HOME}/.local/share/VSCodium

      # Allow specified work directories
      ${concatMapStringsSep "\n" (path: "noblacklist ${path}") cfg.allowedPaths}

      # Whitelist essential directories
      whitelist ''${HOME}/.config/VSCodium
      whitelist ''${HOME}/.vscode-oss
      whitelist ''${HOME}/.local/share/VSCodium
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

    # Create wrapper script for VSCodium
    environment.etc."vscodium-wrapper.sh" = mkIf cfg.enableHardening {
      mode = "0755";
      text = ''
        #!/bin/sh
        # VSCodium wrapper with Firejail sandboxing and resource control

        # Create systemd scope for resource management
        SCOPE_NAME="vscodium-$$"

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
            --profile=/etc/firejail/vscodium.local \
            --private-etc=alternatives,fonts,ssl,pki,crypto-policies,resolv.conf,hostname,localtime \
            ${pkgs.vscodium}/bin/codium \
            --disable-telemetry \
            --disable-crash-reporter \
            --disable-update-check \
            "$@"
      '';
    };

    # Create desktop entry for sandboxed VSCodium
    environment.etc."applications/vscodium-secure.desktop".text = mkIf cfg.enableHardening ''
      [Desktop Entry]
      Version=1.0
      Name=VSCodium (Secure/Sandboxed)
      GenericName=Text Editor
      Comment=Code Editing with Firejail sandbox
      Exec=/etc/vscodium-wrapper.sh %F
      Icon=vscodium
      Terminal=false
      Type=Application
      MimeType=text/plain;inode/directory;
      Categories=Development;IDE;TextEditor;
      Keywords=vscode;editor;ide;development;
      StartupNotify=true
      StartupWMClass=VSCodium
      Actions=new-empty-window;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=/etc/vscodium-wrapper.sh --new-window %F
      Icon=vscodium
    '';

    # VSCodium user settings with privacy/security focus
    environment.etc."vscodium/user-settings.json".text = builtins.toJSON {
      # Telemetry disabled
      "telemetry.telemetryLevel" = "off";
      "telemetry.enableCrashReporter" = false;
      "telemetry.enableTelemetry" = false;

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
      "files.autoSave" = "on";
    };

    # System-wide environment variables
    environment.sessionVariables = {
      # Disable VSCodium telemetry
      VSCODE_TELEMETRY_OPTOUT = "1";
      DISABLE_UPDATE_CHECK = "1";
    };

    # Install extensions if specified
    home-manager.users = mkIf (cfg.extensions != [ ] || cfg.enableGitLabDuo) {
      kernelcore = {
        programs.vscode = {
          profiles = {
            extensions = cfg.extensions ++ (if cfg.enableGitLabDuo then [ pkgs.vscode-extensions.gitlab.gitlab-workflow ] else []);
          };
        };
      };
    };
  };
}
