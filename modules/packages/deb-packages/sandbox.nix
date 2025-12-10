{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.packages.deb;
  sandboxLib = import ../lib/sandbox.nix { inherit lib; };
in
{
  options.kernelcore.packages.deb.sandboxProfiles = mkOption {
    type = types.attrsOf types.attrs;
    default = {
      inherit (sandboxLib) baseSandboxProfile strictSandboxProfile devSandboxProfile;
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
