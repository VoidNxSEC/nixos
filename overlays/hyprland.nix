# Hyprland v0.52.2 Custom Overlay
#
# This overlay provides a custom build of Hyprland v0.52.2, overriding the
# version currently in nixpkgs (v0.51.1). This is a temporary solution until
# nixpkgs upstream updates to v0.52.2.
#
# WHY THIS OVERLAY:
# - v0.52.2 introduces new features and bug fixes we need
# - Maintains compatibility with existing nixpkgs infrastructure
# - Allows testing the new version before it reaches nixpkgs stable
#
# BREAKING CHANGES FROM v0.51.1:
# - Updated Aquamarine dependency requirements
# - New hyprgraphics library dependency
# - Modified Meson build flags (hyprpm disabled by default)
# - Improved XWayland integration
#
# CHANGELOG v0.52.2:
# - Additional bug fixes and stability improvements from v0.52.0
#
# TODO: Replace hash with actual hash after first build attempt
# The build will fail with the correct hash that should be used here.

final: prev: {
  hyprland = prev.hyprland.overrideAttrs (oldAttrs: {
    version = "0.52.2";

    # Source configuration
    # fetchSubmodules is critical for hyprland-protocols and other submodules
    src = final.fetchFromGitHub {
      owner = "hyprwm";
      repo = "Hyprland";
      rev = "v0.52.2";
      fetchSubmodules = true;
      hash = "sha256-R2Hm7XbW8CTLEIeYCAlSQ3U5bFhn76FC17hEy/ws8EM=";
    };

    # Runtime and build dependencies - extend with v0.52.0 requirements
    buildInputs =
      (oldAttrs.buildInputs or [ ])
      ++ (with final; [
        # New dependency in v0.52.0
        hyprgraphics # Graphics utilities (NEW in v0.52.0)
      ]);

    # Meson build configuration
    mesonFlags = [
      "-Dhyprpm=disabled" # Package manager disabled (security/simplicity)
      "-Dsystemd=enabled" # Enable systemd integration
      "-Duwsm=disabled" # Universal Wayland Session Manager disabled
      "-Dxwayland=enabled" # Enable XWayland support
      "-Db_pch=false" # Disable precompiled headers (build reliability)
      "-Dtracy_enable=false" # Disable Tracy profiler
    ];

    # Package metadata
    meta = oldAttrs.meta // {
      longDescription = ''
        Hyprland is a highly customizable dynamic tiling Wayland compositor
        that doesn't sacrifice on its looks. It provides an extensive plugin
        system, beautiful animations, and powerful configuration options.

        This is version 0.52.2, which includes:
        - Updated Aquamarine backend
        - New hyprgraphics library integration
        - Improved XWayland support
        - Additional stability improvements and bug fixes from v0.52.0
      '';
    };
  });
}
