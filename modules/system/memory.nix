{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.system.memory = {
      optimizations.enable = mkEnableOption "Enable memory optimizations and OOM protection";
      zram.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ZRAM compressed swap";
      };
    };
  };

  config = mkIf config.kernelcore.system.memory.optimizations.enable {
    # ============================================
    # KERNEL MEMORY MANAGEMENT - Cgroup v2 optimized
    # ============================================
    boot.kernel.sysctl = {
      # Prevent kernel panics
      "vm.panic_on_oom" = 0;
      "vm.oom_kill_allocating_task" = 1;

      # Memory optimization - OPTIMIZED for Electron apps + builds
      "vm.swappiness" = 10; # Prioritize RAM over SWAP
      "vm.vfs_cache_pressure" = 50; # Keep cache longer
      "vm.dirty_ratio" = 30; # Larger buffer for 16GB RAM
      "vm.dirty_background_ratio" = 20; # Background writes at 3GB

      # Overcommit: 0=heuristic (safer than strict=2, allows flexibility)
      "vm.overcommit_memory" = 0;

      # Additional build optimizations
      "vm.min_free_kbytes" = 131072; # Keep 128MB free for emergencies
      "vm.watermark_scale_factor" = 200; # More aggressive reclaim
      "vm.admin_reserve_kbytes" = 131072; # 128MB reserved for admin recovery
    };

    # ============================================
    # CGROUP V2 SLICES - Workload isolation
    # ============================================

    # Browser slice - isolate Electron/Chromium memory hogs
    systemd.slices.browser = {
      description = "Browser and Electron apps memory isolation";
      sliceConfig = {
        MemoryMax = "8G"; # Hard limit
        MemoryHigh = "6G"; # Soft limit - triggers reclaim
        MemoryLow = "512M"; # Minimum protection
        MemoryZSwapMax = "2G"; # Limit ZRAM consumption
        CPUWeight = 100; # Normal priority
      };
    };

    # Build tools slice - compilation isolation
    systemd.slices.build = {
      description = "Compilation and build tools isolation";
      sliceConfig = {
        MemoryMax = "12G"; # Hard limit
        MemoryHigh = "10G"; # Soft limit
        MemoryLow = "1G"; # Minimum protection during build
        CPUQuota = "300%"; # Allow 3 cores max
        IOWeight = 50; # Lower I/O priority than interactive
      };
    };

    # AI/ML slice - GPU workloads
    systemd.slices.ml = {
      description = "Machine learning and GPU workloads";
      sliceConfig = {
        MemoryMax = "14G"; # Allow most of RAM
        MemoryHigh = "12G";
        CPUWeight = 80; # Slightly lower than default
      };
    };

    # Early OOM killer - TUNED for heavy workloads
    services.earlyoom = {
      enable = true;
      freeMemThreshold = 3; # Kill processes when <3% RAM free
      freeSwapThreshold = 5; # Kill when <5% swap free
      enableNotifications = true;
      extraArgs = [
        "-g" # Kill entire process group
        "--prefer"
        "(cc1|rustc|ld|cargo|nix-build)" # Prefer killing build processes
        "--avoid"
        "(X|plasma|gnome|firefox|chrome|hyprland|waybar)" # Avoid killing desktop
      ];
    };

    # ZRAM swap - Enhanced for heavy compilation
    zramSwap = mkIf config.kernelcore.system.memory.zram.enable {
      enable = true;
      algorithm = "zstd"; # Best compression/speed balance
      memoryPercent = 50; # Use 50% of RAM for compressed swap
      priority = 10; # Higher priority than disk swap
    };

    # Traditional swap file
    swapDevices = [
      {
        device = "/swapfile";
        size = 32768;
        priority = 5;
      }
    ];

    # Aggressive log rotation to prevent I/O bottleneck
    services.journald.extraConfig = ''
      SystemMaxUse=2G
      SystemMaxFileSize=200M
      MaxRetentionSec=1month
      MaxFileSec=1week
    '';

    # Systemd service for automatic memory pressure relief
    systemd.services.memory-pressure-relief = {
      description = "Automatic Memory Pressure Relief";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "memory-relief" ''
          # Get current memory usage percentage
          mem_used=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')

          # If memory > 90%, take action
          if [ "$mem_used" -gt 90 ]; then
            echo "High memory usage detected: $mem_used%"

            # Drop caches
            echo 3 > /proc/sys/vm/drop_caches

            # Compact memory
            echo 1 > /proc/sys/vm/compact_memory || true

            echo "Memory pressure relief completed"
          else
            echo "Memory usage OK: $mem_used%"
          fi
        '';
      };
    };

    # Timer to run memory pressure relief every 5 minutes
    systemd.timers.memory-pressure-relief = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
        Unit = "memory-pressure-relief.service";
      };
    };

    # Aggressive log cleanup service (runs daily)
    systemd.services.log-cleanup = {
      description = "Aggressive Log Cleanup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "log-cleanup" ''
          echo "Starting aggressive log cleanup..."

          # Clean journald logs older than 1 month
          ${pkgs.systemd}/bin/journalctl --vacuum-time=30d

          # Clean old journal files larger than 2GB total
          ${pkgs.systemd}/bin/journalctl --vacuum-size=2G

          # Find and remove large log files in /var/log
          ${pkgs.findutils}/bin/find /var/log -type f -size +100M -mtime +7 -delete || true

          # Compress old logs
          ${pkgs.findutils}/bin/find /var/log -type f -name "*.log" -mtime +3 -exec ${pkgs.gzip}/bin/gzip {} \; || true

          # Report final size
          du -sh /var/log 2>/dev/null || true

          echo "Log cleanup completed"
        '';
      };
    };

    # Timer for daily log cleanup at 3 AM
    systemd.timers.log-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        OnBootSec = "10min";
        Persistent = true;
        Unit = "log-cleanup.service";
      };
    };

    # Swap cleanup service - Clear residual swap when RAM is available
    systemd.services.swap-cleanup = {
      description = "Clear residual swap when RAM is available";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "swap-cleanup" ''
          # Only run if we have >4GB free RAM and >1GB used swap
          free_ram=$(${pkgs.procps}/bin/free -m | ${pkgs.gawk}/bin/awk '/^Mem:/{print $7}')
          used_swap=$(${pkgs.procps}/bin/free -m | ${pkgs.gawk}/bin/awk '/^Swap:/{print $3}')

          if [ "$free_ram" -gt 4096 ] && [ "$used_swap" -gt 1024 ]; then
            echo "Clearing swap: $used_swap MB in use, $free_ram MB free RAM"
            ${pkgs.util-linux}/bin/swapoff -a && ${pkgs.util-linux}/bin/swapon -a
            echo "Swap cleared successfully"
          else
            echo "Swap cleanup not needed: $free_ram MB free RAM, $used_swap MB swap used"
          fi
        '';
      };
    };

    systemd.timers.swap-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "30min";
        Unit = "swap-cleanup.service";
      };
    };
  };
}
