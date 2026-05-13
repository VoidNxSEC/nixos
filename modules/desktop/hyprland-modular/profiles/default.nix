# ============================================
# Hyprland Modular - Profile System
# ============================================
# Usage profiles that optimize for:
# - Gaming (minimal latency)
# - Work (productivity focus)
# - Minimal (resource conservation)
# - Presentation (elegant, smooth)
# - Development (balanced)
# - Streaming (OBS-friendly)
# ============================================
{
  lib,
  pkgs,
  hyprLib,
  cfg,
}:

let
  inherit (hyprLib) animationPresets;

in
{
  # ==========================================
  # DEFAULT - Balanced configuration
  # ==========================================
  default = {
    name = "default";
    description = "Balanced configuration for everyday use";
    settings = {
      # Uses theme defaults
    };
  };

  # ==========================================
  # GAMING - Maximum performance, minimal latency
  # ==========================================
  gaming = {
    name = "gaming";
    description = "Optimized for gaming: minimal latency, reduced effects";
    settings = {
      # Minimal animations for responsiveness
      animations = {
        enabled = true;
        bezier = animationPresets.minimal.bezier;
        animation = animationPresets.minimal.animation;
      };

      # Reduced decoration overhead
      decoration = {
        blur = {
          enabled = false; # Disable blur for performance
        };
        shadow.enabled = false;
        dim_inactive = false;
        rounding = 4; # Minimal rounding
        active_opacity = 1.0;
        inactive_opacity = 1.0;
      };

      # Reduce gaps for more screen real estate
      general = {
        gaps_in = 2;
        gaps_out = 4;
        allow_tearing = true; # Allow tearing for lower latency
      };

      # Performance misc settings
      misc = {
        vfr = false; # Disable VFR for consistent frame timing
        vrr = 2; # Fullscreen only VRR
        no_direct_scanout = false;
      };

      # Render optimizations
      render = {
        # explicit_sync = true;  # Removed in newer Hyprland
      };
    };
  };

  # ==========================================
  # WORK - Productivity focused
  # ==========================================
  work = {
    name = "work";
    description = "Productivity-focused: clear visuals, functional";
    settings = {
      # Smooth but not distracting animations
      animations = {
        enabled = true;
        bezier = [
          "work, 0.4, 0, 0.2, 1"
        ];
        animation = [
          "windowsIn, 1, 3, work, slide"
          "windowsOut, 1, 2, work, slide"
          "windowsMove, 1, 3, work"
          "fadeIn, 1, 2, work"
          "fadeOut, 1, 2, work"
          "workspaces, 1, 3, work, slide"
          "layers, 1, 2, work, fade"
        ];
      };

      # Clean, professional appearance
      decoration = {
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 10;
          render_power = 2;
        };
        dim_inactive = true;
        dim_strength = 0.2; # More pronounced to focus attention
        rounding = 8;
        active_opacity = 0.98;
        inactive_opacity = 0.92;
      };

      # Comfortable gaps
      general = {
        gaps_in = 6;
        gaps_out = 12;
      };

      # Focus management
      misc = {
        focus_on_activate = true;
        layers_hog_keyboard_focus = true;
      };
    };
  };

  # ==========================================
  # MINIMAL - Resource conservation
  # ==========================================
  minimal = {
    name = "minimal";
    description = "Resource-saving: no effects, minimal overhead";
    settings = {
      animations.enabled = false;

      decoration = {
        blur.enabled = false;
        shadow.enabled = false;
        dim_inactive = false;
        rounding = 0;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
      };

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
      };

      misc = {
        vfr = true; # Save power when idle
        vrr = 0; # No VRR
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
      };
    };
  };

  # ==========================================
  # PRESENTATION - Elegant, professional
  # ==========================================
  presentation = {
    name = "presentation";
    description = "Elegant animations for presentations and demos";
    settings = {
      animations = {
        enabled = true;
        bezier = animationPresets.elegant.bezier;
        animation = animationPresets.elegant.animation;
      };

      decoration = {
        blur = {
          enabled = true;
          size = 12;
          passes = 4;
          vibrancy = 0.3;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 4;
        };
        dim_inactive = true;
        dim_strength = 0.25;
        rounding = 16;
        active_opacity = 0.95;
        inactive_opacity = 0.85;
      };

      general = {
        gaps_in = 12;
        gaps_out = 24;
        border_size = 2;
      };
    };
  };

  # ==========================================
  # DEVELOPMENT - Balanced for coding
  # ==========================================
  development = {
    name = "development";
    description = "Balanced for development work: clear, efficient";
    settings = {
      animations = {
        enabled = true;
        bezier = [
          "dev, 0.2, 0.8, 0.2, 1"
          "devGentle, 0.4, 0.14, 0.3, 1"
        ];
        animation = [
          "windowsIn, 1, 3, dev, slide"
          "windowsOut, 1, 2, dev, slide"
          "windowsMove, 1, 3, dev"
          "fadeIn, 1, 2, devGentle"
          "fadeOut, 1, 2, devGentle"
          "workspaces, 1, 4, dev, slide"
          "layers, 1, 2, dev, fade"
        ];
      };

      decoration = {
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 15;
          render_power = 2;
        };
        dim_inactive = true;
        dim_strength = 0.12;
        rounding = 10;
        active_opacity = 0.94;
        inactive_opacity = 0.88;
      };

      general = {
        gaps_in = 6;
        gaps_out = 12;
      };

      # Dev-friendly misc
      misc = {
        focus_on_activate = true;
        enable_swallow = true;
      };
    };
  };

  # ==========================================
  # STREAMING - OBS-optimized
  # ==========================================
  streaming = {
    name = "streaming";
    description = "Optimized for streaming: OBS-friendly, clean capture";
    settings = {
      # Moderate animations (smooth on stream)
      animations = {
        enabled = true;
        bezier = [
          "stream, 0.3, 0, 0.2, 1"
        ];
        animation = [
          "windowsIn, 1, 4, stream, slide"
          "windowsOut, 1, 3, stream, slide"
          "windowsMove, 1, 4, stream"
          "fadeIn, 1, 3, stream"
          "fadeOut, 1, 3, stream"
          "workspaces, 1, 4, stream, slide"
          "layers, 1, 3, stream, fade"
        ];
      };

      decoration = {
        # Moderate blur (doesn't kill encoding performance)
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 15;
          render_power = 2;
        };
        dim_inactive = false; # Keep all windows visible for stream
        rounding = 10;
        active_opacity = 0.98;
        inactive_opacity = 0.95; # Keep inactive windows visible
      };

      general = {
        gaps_in = 8;
        gaps_out = 16;
      };

      misc = {
        vrr = 0; # Disable VRR for consistent capture
        vfr = false; # Consistent frame timing for OBS
      };
    };
  };
}
