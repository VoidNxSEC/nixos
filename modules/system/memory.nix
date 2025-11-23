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
    # Kernel memory management - Optimized for heavy build workloads
    boot.kernel.sysctl = {
      # Prevent kernel panics
      "vm.panic_on_oom" = 0;
      "vm.oom_kill_allocating_task" = 1;

      # Memory optimization for compilation workloads
      "vm.swappiness" = 100; # Aggressive swap for build processes (was 80)
      "vm.vfs_cache_pressure" = 200; # Release file cache quickly
      "vm.dirty_ratio" = 10; # Flush dirty pages early
      "vm.dirty_background_ratio" = 5; # Start background flush sooner
      "vm.overcommit_memory" = 2; # Don't overcommit
      "vm.overcommit_ratio" = 80; # Conservative overcommit

      # Additional build optimizations
      "vm.min_free_kbytes" = 65536; # Keep 64MB free for emergencies
      "vm.watermark_scale_factor" = 200; # More aggressive reclaim
    };

    # Early OOM killer
    services.earlyoom = {
      enable = true;
      freeMemThreshold = 8;
      freeSwapThreshold = 20;
      enableNotifications = true;
    };

    # ZRAM swap - Enhanced for heavy compilation (50% compression ratio)
    zramSwap = mkIf config.kernelcore.system.memory.zram.enable {
      enable = true;
      algorithm = "zstd"; # Best compression/speed balance
      memoryPercent = 50; # Use 50% of RAM for compressed swap (was 25%)
      priority = 10; # Higher priority than disk swap
    };

    # Traditional swap file
    swapDevices = [
      {
        device = "/swapfile";
        size = 16096;
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
  };
}
