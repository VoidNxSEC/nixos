{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.deb;

  # Hardware device mappings for blocking
  hardwareDevices = {
    gpu = [
      "/dev/nvidia*"
      "/dev/dri"
      "/dev/fb0"
    ];
    audio = [
      "/dev/snd"
      "/dev/audio"
    ];
    usb = [ "/dev/bus/usb" ];
    camera = [
      "/dev/video*"
      "/dev/v4l"
    ];
    bluetooth = [
      "/dev/rfkill"
      "/dev/bluetooth"
    ];
  };

  # Generate bubblewrap arguments for hardware blocking
  mkHardwareBlockArgs =
    blockList:
    concatStringsSep " " (
      flatten (
        map (hwType: map (dev: "--dev-bind-try /dev/null ${dev}") hardwareDevices.${hwType}) blockList
      )
    );

  # Generate bubblewrap arguments for path allowlist
  mkPathAllowArgs = paths: concatStringsSep " " (map (path: "--bind ${path} ${path}") paths);

  # Base sandbox profile - minimal access
  baseSandboxProfile = {
    # Read-only system directories
    ro-bind = [
      "/nix/store"
      "/etc/hosts"
      "/etc/resolv.conf"
      "/etc/ssl"
      "/etc/static/ssl"
    ];

    # Temporary filesystems
    tmpfs = [
      "/tmp"
      "/run"
      "/var/tmp"
    ];

    # Essential pseudo-filesystems
    essential = [
      "--proc /proc"
      "--dev /dev"
      "--tmpfs /tmp"
    ];

    # Namespace isolation
    unshare = [
      "--unshare-user"
      "--unshare-ipc"
      "--unshare-pid"
      "--unshare-uts"
      "--unshare-cgroup"
    ];

    # Network handling (shared by default, can be isolated)
    network = "--share-net";

    # Security options
    security = [
      "--die-with-parent"
      "--new-session"
      "--cap-drop ALL" # Drop all capabilities
    ];
  };

  # Strict sandbox profile - maximum isolation
  strictSandboxProfile = baseSandboxProfile // {
    network = "--unshare-net"; # No network access
    security = baseSandboxProfile.security ++ [
      "--ro-bind-try /sys /sys" # Read-only sysfs
    ];
  };

  # Development sandbox profile - more permissive for development tools
  devSandboxProfile = baseSandboxProfile // {
    ro-bind = baseSandboxProfile.ro-bind ++ [
      "/usr" # Some tools expect /usr
    ];
  };

in
{
  options.kernelcore.packages.deb.sandboxProfiles = mkOption {
    type = types.attrsOf types.attrs;
    default = {
      inherit baseSandboxProfile strictSandboxProfile devSandboxProfile;
    };
    description = "Pre-defined sandbox profiles";
  };

  config = mkIf cfg.enable {
    # Ensure bubblewrap is available system-wide
    environment.systemPackages = [ pkgs.bubblewrap ];

    # Enable user namespaces (required for bubblewrap)
    security.allowUserNamespaces = mkDefault true;

    # Kernel parameters for namespace isolation
    boot.kernel.sysctl = {
      # Allow unprivileged user namespaces (required for bubblewrap)
      "kernel.unprivileged_userns_clone" = mkDefault 1;

      # Restrict access to kernel pointers (security)
      "kernel.kptr_restrict" = mkDefault 2;

      # Restrict dmesg access
      "kernel.dmesg_restrict" = mkDefault 1;
    };

    # Create systemd services for each sandboxed package
    systemd.services = mkMerge (
      mapAttrsToList (
        name: pkg:
        let
          serviceName = "deb-package-${name}";
          resourceLimits = pkg.sandbox.resourceLimits;
        in
        mkIf (pkg.enable && pkg.sandbox.enable) {
          ${serviceName} = {
            description = "Sandboxed .deb package: ${name}";
            after = [ "network.target" ];

            serviceConfig = mkMerge [
              {
                Type = "simple";
                User = "nobody";
                Group = "nogroup";
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadOnlyPaths = [ "/nix/store" ];
              }

              # Resource limits
              (mkIf (resourceLimits.memory != null) { MemoryMax = resourceLimits.memory; })

              (mkIf (resourceLimits.cpu != null) { CPUQuota = "${toString resourceLimits.cpu}%"; })

              (mkIf (resourceLimits.tasks != null) { TasksMax = toString resourceLimits.tasks; })

              # Hardware isolation
              (mkIf (elem "gpu" pkg.sandbox.blockHardware) {
                DeviceAllow = [ "/dev/null rw" ]; # Only allow /dev/null
              })

              # Capabilities
              {
                CapabilityBoundingSet = [ "" ]; # Drop all capabilities
                AmbientCapabilities = [ "" ];
                SecureBits = [
                  "noroot"
                  "noroot-locked"
                ];
              }

              # System call filtering
              {
                SystemCallFilter = [
                  "@system-service"
                  "~@privileged"
                  "~@resources"
                ];
                SystemCallArchitectures = "native";
              }

              # Namespace isolation
              {
                PrivateDevices = mkDefault true;
                PrivateNetwork = mkDefault false; # Allow network by default
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectKernelLogs = true;
                ProtectControlGroups = true;
                ProtectClock = true;
                RestrictNamespaces = true;
                LockPersonality = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                RemoveIPC = true;
              }
            ];

            # Optional: Start on boot (disabled by default)
            wantedBy = mkIf (pkg.audit.enable) [ "multi-user.target" ];
          };
        }
      ) cfg.packages
    );

    # Audit rules for sandboxed binaries
    security.audit.rules =
      let
        enabledPackages = filterAttrs (_: pkg: pkg.enable && pkg.audit.enable) cfg.packages;
      in
      mkIf (enabledPackages != { }) (
        map (name: "-w /var/log/deb-packages/${name}.log -p wa -k deb_package_${name}") (
          attrNames enabledPackages
        )
      );
  };
}
