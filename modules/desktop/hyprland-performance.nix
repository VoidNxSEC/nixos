{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.hyprland.performance;
in
{
  options.kernelcore.hyprland.performance = {
    enable = mkEnableOption "Enable Hyprland performance optimizations";

    mode = mkOption {
      type = types.enum [
        "balanced"
        "performance"
        "minimal-latency"
      ];
      default = "balanced";
      description = ''
        Performance mode:
        - balanced: Good balance between security and performance
        - performance: Prioritize performance over some hardening
        - minimal-latency: Maximum performance, relax all hardenings
      '';
    };
  };

  config = mkIf cfg.enable {
    # ============================================
    # KERNEL TUNING - RELAXED FOR COMPOSITOR
    # ============================================
    boot.kernel.sysctl = mkMerge [
      # Always apply (all modes)
      {
        # Reduce latency for desktop compositor
        "kernel.sched_latency_ns" = 4000000; # 4ms (default: 6ms)
        "kernel.sched_min_granularity_ns" = 500000; # 0.5ms (default: 0.75ms)
        "kernel.sched_wakeup_granularity_ns" = 1000000; # 1ms (default: 1ms)
      }

      # Performance and minimal-latency modes
      (mkIf (cfg.mode == "performance" || cfg.mode == "minimal-latency") {
        # Allow userfaultfd (required by some Wayland compositors)
        "kernel.unprivileged_userfaultfd" = mkForce 1;

        # Reduce ptrace restrictions (allows compositor debugging)
        "kernel.yama.ptrace_scope" = mkForce 1;
      })

      # Minimal-latency mode only
      (mkIf (cfg.mode == "minimal-latency") {
        # Maximum performance, minimal security
        "kernel.kptr_restrict" = mkForce 1;
      })
    ];

    # ============================================
    # SYSTEMD SLICE - COMPOSITOR PRIORITY
    # ============================================
    systemd.slices.compositor = {
      description = "Hyprland compositor priority slice";
      sliceConfig = {
        CPUWeight = if cfg.mode == "minimal-latency" then 1000 else 500;
        IOWeight = if cfg.mode == "minimal-latency" then 1000 else 500;
        MemoryLow = "2G"; # Never reclaim compositor memory
        MemoryHigh = "6G"; # Allow generous memory usage
      };
    };

    # ============================================
    # OOM PROTECTION - NEVER KILL COMPOSITOR
    # ============================================
    systemd.user.services.hyprland-oom-protect = {
      description = "Protect Hyprland from OOM killer";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "protect-hyprland" ''
          sleep 2 # Wait for Hyprland to start

          HYPR_PID=$(pgrep -x Hyprland || echo "")

          if [ -n "$HYPR_PID" ]; then
            # -1000 = Never kill this process
            echo -1000 > /proc/$HYPR_PID/oom_score_adj
            echo "Hyprland (PID $HYPR_PID) protected from OOM killer"
          else
            echo "WARNING: Hyprland not running, cannot protect"
          fi
        '';
      };
    };

    # ============================================
    # EARLYOOM TUNING - LESS AGGRESSIVE
    # ============================================
    services.earlyoom = mkIf config.services.earlyoom.enable {
      # Make OOM killer less aggressive when compositor is running
      freeMemThreshold = mkForce 2; # Lower threshold (was 3%)
      extraArgs = mkForce [
        "-g" # Kill entire process group
        "--prefer"
        "(cc1|rustc|ld|cargo|nix-build|electron)"
        "--avoid"
        "(Hyprland|waybar|mako|X|gnome|plasma|firefox|chrome)"
      ];
    };

    # ============================================
    # NVIDIA TWEAKS (if enabled)
    # ============================================
    environment.sessionVariables = mkIf config.services.hyprland-desktop.nvidia {
      # Force GPU to max performance
      __GL_YIELD = "USLEEP";
      __GL_THREADED_OPTIMIZATIONS = "1";

      # Experimental: test both atomic modes
      # Comment out the one that doesn't work for you
      # WLR_DRM_NO_ATOMIC = "0";  # WITH atomic modesetting (try first)
      WLR_DRM_NO_ATOMIC = "1"; # WITHOUT atomic (fallback)
    };

    # ============================================
    # SYSTEMD USER UNIT OVERRIDES
    # ============================================
    # Move Hyprland to compositor slice
    systemd.user.services.hyprland-slice-move = {
      description = "Move Hyprland to high-priority slice";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "move-to-slice" ''
          sleep 2

          HYPR_PID=$(pgrep -x Hyprland || echo "")

          if [ -n "$HYPR_PID" ]; then
            # Move Hyprland to compositor.slice
            ${pkgs.systemd}/bin/systemctl --user set-property \
              user@$(id -u).service \
              Slice=compositor.slice || true
            
            echo "Hyprland moved to compositor.slice"
          fi
        '';
      };
    };

    # ============================================
    # WARNINGS
    # ============================================
    warnings = mkIf (cfg.mode == "minimal-latency") [
      ''
        Hyprland performance mode is set to 'minimal-latency'.
        This relaxes security hardening for maximum performance.
        Only use this if you're experiencing severe stuttering.
      ''
    ];
  };
}
