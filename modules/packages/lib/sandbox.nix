{ lib, ... }:

with lib;

rec {
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
        map (
          hwType: map (dev: "--dev-bind-try /dev/null ${dev}") (hardwareDevices.${hwType} or [ ])
        ) blockList
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

  # Generate full bwrap arguments from a configuration
  mkSandboxArgs =
    {
      pkgs,
      enable ? false,
      blockHardware ? [ ],
      allowedPaths ? [ ],
      extraArgs ? "",
    }:
    if !enable then
      ""
    else
      let
        blockArgs = mkHardwareBlockArgs blockHardware;
        allowArgs = mkPathAllowArgs allowedPaths;
      in
      ''
        exec ${pkgs.bubblewrap}/bin/bwrap \
          --ro-bind /nix /nix \
          --tmpfs /tmp \
          --tmpfs /run \
          --proc /proc \
          --dev /dev \
          ${blockArgs} \
          ${allowArgs} \
          --unshare-all \
          --share-net \
          --die-with-parent \
          ${extraArgs}
      '';
}
