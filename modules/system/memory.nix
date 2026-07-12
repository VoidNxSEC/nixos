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
      zram = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable ZRAM compressed swap";
        };
        memoryPercent = mkOption {
          type = types.int;
          default = 50;
          description = "Percentual da RAM física usado pelo ZRAM (zstd).";
        };
        priority = mkOption {
          type = types.int;
          default = 10;
          description = "Prioridade do swap ZRAM (maior = usado primeiro).";
        };
      };
    };
  };

  # ZRAM independe de optimizations.enable (gate próprio)
  config = mkMerge [
    (mkIf config.kernelcore.system.memory.zram.enable {
      zramSwap = {
        enable = true;
        algorithm = "zstd"; # Best compression/speed balance
        memoryPercent = config.kernelcore.system.memory.zram.memoryPercent;
        priority = config.kernelcore.system.memory.zram.priority;
      };
    })
    (mkIf config.kernelcore.system.memory.optimizations.enable {
    # ============================================
    # KERNEL MEMORY MANAGEMENT - Cgroup v2 optimized
    # ============================================
    boot.kernel.sysctl = {
      # Prevent kernel panics
      "vm.panic_on_oom" = 0;
      "vm.oom_kill_allocating_task" = 1;

      # Memory optimization - OPTIMIZED for Electron apps + builds
      "vm.swappiness" = 30; # Prioritize RAM over SWAP
      "vm.vfs_cache_pressure" = 50; # Keep cache longer

      "vm.dirty_ratio" = 20; # Larger buffer for 16GB RAM

      "vm.dirty_background_ratio" = 10; # Background writes at 3GB

      # Overcommit: 1=always (never reject malloc). Safer than 0 for dev machines
      # because Node/Chrome/JVM/LLM allocate huge virtual arenas. OOM protection
      # delegated to systemd-oomd (80% threshold, nix-daemon+dbus protected).
      "vm.overcommit_memory" = 1;

      # Additional build optimizations
      "vm.min_free_kbytes" = 262144; # Keep 256MB free for emergencies
      "vm.watermark_scale_factor" = 100; # Moderate reclaim, avoid premature swap
      "vm.admin_reserve_kbytes" = 131072; # 128MB reserved for admin recovery

      # inotify - dev tools and monorepos can exhaust the default watcher limits.
      # Calibrated for heavy monorepo development (Zed, multiple IDEs, build watchers).
      # Each watch ≈1KB unswappable kernel memory (~2GB max at 2M watches).
      "fs.inotify.max_user_watches" = 2097152; # 2M (was 1M) - extreme monorepo headroom
      "fs.inotify.max_user_instances" = 2048; # 2K (was 1K) - more concurrent inotify fds
      "fs.inotify.max_queued_events" = 65536; # 64K (was 32K) - absorb burst event storms

      # MGLRU - Multi-Gen LRU, better reclaim decisions (kernel 6.1+)
      "vm.mglru.enabled" = 1;

      # CPU optimizations
      "kernel.sched_migration_cost_ns" = 5000000;
      "kernel.sched_autogroup_enabled" = 1;

      # PID pool - prevent exhaustion from zombie buildup
      "kernel.pid_max" = 131072; # 128K (default 32K)

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
        MemoryMax = "8G"; # Hard limit
        MemoryHigh = "6G"; # Soft limit
        MemoryLow = "1G"; # Minimum protection during build
        CPUQuota = "300%"; # Allow 3 cores max
        IOWeight = 50; # Lower I/O priority than interactive
      };
    };

    # AI/ML slice - GPU workloads
    systemd.slices.ml = {
      description = "Machine learning and GPU workloads";
      sliceConfig = {
        MemoryMax = "12G"; # Balanced for 16GB RAM
        MemoryHigh = "12G";
        CPUWeight = 80; # Slightly lower than default
      };
    };

    # ============================================
    # SYSTEMD-OOMD - Modern Userspace OOM Killer
    # ============================================
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
      settings.OOM = {
        DefaultMemoryPressureLimit = "80%";
        DefaultMemoryPressureDurationSec = "30";
      };
    };

    # Disable EarlyOOM (superseded by systemd-oomd)
    services.earlyoom.enable = false;

    # Configure OOMD policies for top-level slices
    systemd.slices."system".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };

    systemd.slices."user".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };

    # Protect critical services from OOM kill
    systemd.services.nix-daemon.serviceConfig.ManagedOOMPreference = "avoid";
    systemd.services.dbus.serviceConfig.ManagedOOMPreference = "avoid";
    systemd.services."nix-daemon".serviceConfig = {
      CPUWeight = 50;
      IOWeight = 50;
    };

    # ============================================
    # PROCESS HYGIENE - No orphans, no zombies
    # ============================================

    # Kill all user processes on logout (no Node/Chrome orphans)
    services.logind.settings.Login.KillUserProcesses = true;

    # Subreaper: systemd --user adopts orphaned child processes
    systemd.services."user@".serviceConfig.Subreaper = true;

    # ZRAM swap: ver bloco próprio acima (gate kernelcore.system.memory.zram.enable)

    # Swap disabled
    swapDevices = [ ];

    # Aggressive log rotation to prevent I/O bottleneck
    services.journald.extraConfig = ''
      SystemMaxUse=2G
      SystemMaxFileSize=200M
      MaxRetentionSec=1month
      MaxFileSec=1week
    '';

    # I/O scheduler
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
    '';

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

    # Timer: periodic zombie reaping (SIGCHLD to negligent parents)
    systemd.services.reap-zombies = {
      description = "Reap forgotten zombie processes (Node, Chrome orphans)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "reap-zombies" ''
          zombies=$(${pkgs.procps}/bin/ps aux --no-headers | ${pkgs.gawk}/bin/awk '$8 ~ /Z/ {print $2}')
          if [ -n "$zombies" ]; then
            echo "Found zombies: $zombies"
            for zpid in $zombies; do
              ppid=$(${pkgs.procps}/bin/ps -o ppid= -p "$zpid" 2>/dev/null | tr -d ' ')
              if [ -n "$ppid" ] && [ "$ppid" != "1" ]; then
                ${pkgs.util-linux}/bin/kill -SIGCHLD "$ppid" 2>/dev/null || true
              fi
            done
            echo "Sent SIGCHLD to zombie parents"
          else
            echo "No zombies found"
          fi
        '';
      };
    };

    systemd.timers.reap-zombies = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Unit = "reap-zombies.service";
      };
    };

    })
  ];
}
