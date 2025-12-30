# ⚠️  DEPRECATED - DO NOT USE ⚠️
#
# This overlay is DEPRECATED and should NOT be enabled.
# It builds Hyprland and all dependencies from source, which:
# - Invalidates binary cache (forces local compilation)
# - Takes hours to build on most systems
# - Is unnecessary since we use the official Hyprland flake input
#
# CURRENT APPROACH (RECOMMENDED):
# - Hyprland is provided via official flake input in flake.nix
# - Input: hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1"
# - Applied via: inputs.hyprland.overlays.default
# - Module: inputs.hyprland.nixosModules.default
#
# This file is kept for reference only.
# DO NOT UNCOMMENT in overlays/default.nix
#
# ══════════════════════════════════════════════════════════════════════
# LEGACY DOCUMENTATION (for historical reference)
# ══════════════════════════════════════════════════════════════════════
#
# Hyprland v0.53.0 Custom Overlay (LEGACY - DO NOT USE)
#
# This overlay provided a custom build of Hyprland v0.53.0, overriding the
# version in nixpkgs. This approach is no longer used.
#
# LEGACY BUILD INFO:
# - Built hyprwire v0.2.1 from source
# - Built pugixml, libffi, hyprutils from source
# - Compiled Hyprland v0.53.0 with custom flags
#
# Hash verification: sha256-Y53Vjx/Lc1d3UoN/9DzzP9xGKkzWgVUFw1PS25bnT6Y=

final: prev: {
  # Build pugixml from source (dependency for hyprwire)
  hyprland-pugixml = final.stdenv.mkDerivation rec {
    pname = "pugixml";
    version = "1.15";

    src = final.fetchurl {
      url = "https://github.com/zeux/pugixml/releases/download/v${version}/pugixml-${version}.tar.gz";
      sha256 = "sha256-ZVreV/pwP7QhwuuaARO1BkvdsUXUFd0fiMeTU9kNURo=";
    };

    nativeBuildInputs = with final; [
      cmake
    ];

    doCheck = false;

    meta = with final.lib; {
      description = "Light-weight, simple and fast XML parser for C++";
      homepage = "https://pugixml.org/";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Build libffi from source (dependency for hyprutils)
  hyprland-libffi = final.stdenv.mkDerivation rec {
    pname = "libffi";
    version = "3.5.2";

    src = final.fetchurl {
      url = "https://github.com/libffi/libffi/releases/download/v${version}/libffi-${version}.tar.gz";
      sha256 = "sha256-86MIKiOzfCk6T80QUxR7Nx8v+R+n6hsqUuM1Z2usgtw=";
    };

    nativeBuildInputs = with final; [
      pkg-config
    ];

    doCheck = false;

    meta = with final.lib; {
      description = "Foreign function interface library";
      homepage = "https://sourceware.org/libffi/";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Build hyprutils from source (dependency for hyprwire)
  hyprutils = final.stdenv.mkDerivation rec {
    pname = "hyprutils";
    version = "0.11.0";

    src = final.fetchurl {
      url = "https://github.com/hyprwm/hyprutils/archive/refs/tags/v${version}.tar.gz";
      sha256 = "sha256-Hwl+uZFQgfG5KZc3AWQ7zYWBtGnCQurlRGJ1sSCjsik=";
    };

    nativeBuildInputs = with final; [
      cmake
      pkg-config
    ];

    buildInputs = with final; [
      hyprland-pugixml
      hyprland-libffi
    ];

    doCheck = false;

    meta = with final.lib; {
      description = "Hyprland utilities library";
      homepage = "https://github.com/hyprwm/hyprutils";
      license = licenses.bsd3;
      platforms = platforms.linux;
    };
  };
  # Build hyprwire from source (not yet in nixpkgs)
  hyprwire = final.stdenv.mkDerivation rec {
    pname = "hyprwire";
    version = "0.2.1";

    src = final.fetchurl {
      url = "https://github.com/hyprwm/hyprwire/archive/refs/tags/v${version}.tar.gz";
      sha256 = "sha256-pjcNt3EhP+EOvKWi2nSAcKcDSwkTGEf5c/2l1gtHPBE=";
    };

    nativeBuildInputs = with final; [
      cmake
      pkg-config
    ];

    buildInputs = with final; [
      hyprlang
      hyprland-pugixml # XML parser dependency
      hyprutils # Hyprland utilities (requires libffi)
      hyprland-libffi # Foreign function interface
    ];

    doCheck = false;

    meta = with final.lib; {
      description = "Hyprland Wire - Wayland protocol implementation";
      homepage = "https://github.com/hyprwm/hyprwire";
      license = licenses.bsd3;
      platforms = platforms.linux;
    };
  };

  hyprland = prev.hyprland.overrideAttrs (oldAttrs: {
    version = "0.53.0";

    # Source configuration
    src = final.fetchurl {
      url = "https://github.com/hyprwm/Hyprland/archive/refs/tags/v0.53.0.tar.gz";
      sha256 = "sha256-Y53Vjx/Lc1d3UoN/9DzzP9xGKkzWgVUFw1PS25bnT6Y=";
    };

    # Runtime and build dependencies for v0.53.0
    buildInputs =
      (oldAttrs.buildInputs or [ ])
      ++ (with final; [
        # Dependencies for v0.53.0
        hyprgraphics # Graphics utilities
        hyprutils # Utility library
        hyprcursor # Cursor management
        hyprlang # Configuration language parser
        aquamarine # Wayland backend
        hyprwayland-scanner # Wayland protocol scanner
        hyprwire # NEW: Wire protocol (built from source above)
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

    doCheck = false;

    # Package metadata
    meta = oldAttrs.meta // {
      timeout = 10800; # 3 hours
      longDescription = ''
        Hyprland is a highly customizable dynamic tiling Wayland compositor
        that doesn't sacrifice on its looks. It provides an extensive plugin
        system, beautiful animations, and powerful configuration options.

        This is version 0.53.0, which includes:
        - Updated Aquamarine backend
        - Improved hyprgraphics integration
        - Enhanced XWayland support
        - Performance improvements and bug fixes
        - New hyprwire dependency for protocol handling
      '';
    };
  });
}
