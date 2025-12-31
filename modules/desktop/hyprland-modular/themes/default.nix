# ============================================
# Hyprland Modular - Theme System
# ============================================
# Declarative theme definitions with:
# - Color palettes
# - Opacity settings
# - Blur configurations
# - Animation styles
# - Border styling
# ============================================
{
  lib,
  pkgs,
  hyprLib,
}:

let
  inherit (hyprLib)
    hexToRgba
    gradient
    palettes
    mkBlur
    mkShadow
    animationPresets
    ;

  # Theme factory - creates a complete theme from a palette
  mkTheme =
    {
      name,
      palette,
      opacity ? {
        active = 0.92;
        inactive = 0.88;
        fullscreen = 1.0;
      },
      blur ? {
        size = 10;
        passes = 3;
      },
      rounding ? 12,
      gaps ? {
        inner = 8;
        outer = 16;
      },
      border ? {
        size = 1;
        angle = 45;
      },
      shadow ? {
        range = 20;
        power = 3;
      },
      animations ? "smooth",
      dimStrength ? 0.15,
    }:
    {
      inherit name;
      settings = {
        general = {
          gaps_in = lib.mkDefault gaps.inner;
          gaps_out = lib.mkDefault gaps.outer;
          border_size = lib.mkDefault border.size;
          "col.active_border" = lib.mkDefault (gradient [ palette.primary palette.secondary ] border.angle);
          "col.inactive_border" = lib.mkDefault (hexToRgba palette.surface 0.5);
        };

        decoration = {
          rounding = lib.mkDefault rounding;

          blur = mkBlur {
            enabled = true;
            size = blur.size;
            passes = blur.passes;
            new_optimizations = true;
            ignore_opacity = false;
          };

          active_opacity = lib.mkDefault opacity.active;
          inactive_opacity = lib.mkDefault opacity.inactive;
          fullscreen_opacity = lib.mkDefault opacity.fullscreen;

          shadow = mkShadow {
            enabled = true;
            range = shadow.range;
            renderPower = shadow.power;
            offset = "0 4";
            color = "rgba(00000066)";
            colorInactive = "rgba(00000044)";
          };

          dim_inactive = lib.mkDefault true;
          dim_strength = lib.mkDefault dimStrength;
        };

        animations = {
          enabled = true;
          bezier = animationPresets.${animations}.bezier;
          animation = animationPresets.${animations}.animation;
        };
      };
    };

in
{
  # ==========================================
  # GLASSMORPHISM - Premium frosted glass
  # ==========================================
  glassmorphism = mkTheme {
    name = "glassmorphism";
    palette = palettes.glassmorphism;
    opacity = {
      active = 0.92;
      inactive = 0.88;
      fullscreen = 1.0;
    };
    blur = {
      size = 10;
      passes = 3;
    };
    rounding = 12;
    gaps = {
      inner = 8;
      outer = 16;
    };
    border = {
      size = 1;
      angle = 45;
    };
    shadow = {
      range = 20;
      power = 3;
    };
    animations = "smooth";
    dimStrength = 0.15;
  };

  # ==========================================
  # NORD - Arctic, north-bluish clean aesthetic
  # ==========================================
  nord = mkTheme {
    name = "nord";
    palette = palettes.nord;
    opacity = {
      active = 0.95;
      inactive = 0.90;
      fullscreen = 1.0;
    };
    blur = {
      size = 8;
      passes = 2;
    };
    rounding = 8;
    gaps = {
      inner = 6;
      outer = 12;
    };
    border = {
      size = 2;
      angle = 90;
    };
    shadow = {
      range = 15;
      power = 2;
    };
    animations = "smooth";
    dimStrength = 0.1;
  };

  # ==========================================
  # DRACULA - Dark theme with vibrant colors
  # ==========================================
  dracula = mkTheme {
    name = "dracula";
    palette = palettes.dracula;
    opacity = {
      active = 0.94;
      inactive = 0.89;
      fullscreen = 1.0;
    };
    blur = {
      size = 12;
      passes = 3;
    };
    rounding = 10;
    gaps = {
      inner = 8;
      outer = 16;
    };
    border = {
      size = 2;
      angle = 135;
    };
    shadow = {
      range = 25;
      power = 3;
    };
    animations = "smooth";
    dimStrength = 0.12;
  };

  # ==========================================
  # CATPPUCCIN - Soothing pastel theme
  # ==========================================
  catppuccin = mkTheme {
    name = "catppuccin";
    palette = palettes.catppuccin;
    opacity = {
      active = 0.95;
      inactive = 0.90;
      fullscreen = 1.0;
    };
    blur = {
      size = 10;
      passes = 3;
    };
    rounding = 14;
    gaps = {
      inner = 10;
      outer = 20;
    };
    border = {
      size = 2;
      angle = 60;
    };
    shadow = {
      range = 18;
      power = 3;
    };
    animations = "smooth";
    dimStrength = 0.1;
  };

  # ==========================================
  # GRUVBOX - Retro groove
  # ==========================================
  gruvbox = mkTheme {
    name = "gruvbox";
    palette = palettes.gruvbox;
    opacity = {
      active = 0.96;
      inactive = 0.92;
      fullscreen = 1.0;
    };
    blur = {
      size = 6;
      passes = 2;
    };
    rounding = 6;
    gaps = {
      inner = 6;
      outer = 10;
    };
    border = {
      size = 3;
      angle = 0;
    };
    shadow = {
      range = 12;
      power = 2;
    };
    animations = "smooth";
    dimStrength = 0.08;
  };

  # ==========================================
  # TOKYO NIGHT - A clean, dark theme
  # ==========================================
  tokyonight = mkTheme {
    name = "tokyonight";
    palette = palettes.tokyonight;
    opacity = {
      active = 0.94;
      inactive = 0.88;
      fullscreen = 1.0;
    };
    blur = {
      size = 10;
      passes = 3;
    };
    rounding = 12;
    gaps = {
      inner = 8;
      outer = 16;
    };
    border = {
      size = 1;
      angle = 45;
    };
    shadow = {
      range = 20;
      power = 3;
    };
    animations = "smooth";
    dimStrength = 0.15;
  };

  # ==========================================
  # MINIMAL - No effects, maximum performance
  # ==========================================
  minimal = {
    name = "minimal";
    settings = {
      general = {
        gaps_in = lib.mkDefault 2;
        gaps_out = lib.mkDefault 4;
        border_size = lib.mkDefault 1;
        "col.active_border" = lib.mkDefault "rgba(ffffffff)";
        "col.inactive_border" = lib.mkDefault "rgba(444444ff)";
      };

      decoration = {
        rounding = lib.mkDefault 0;
        blur.enabled = lib.mkDefault false;
        active_opacity = lib.mkDefault 1.0;
        inactive_opacity = lib.mkDefault 1.0;
        fullscreen_opacity = lib.mkDefault 1.0;
        shadow.enabled = lib.mkDefault false;
        dim_inactive = lib.mkDefault false;
      };

      animations.enabled = false;
    };
  };

  # ==========================================
  # CUSTOM - User-defined theme (placeholder)
  # ==========================================
  custom = {
    name = "custom";
    settings = { };
  };
}
