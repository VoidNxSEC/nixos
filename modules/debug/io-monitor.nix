{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =================================================================
  # IO MONITORING TOOLS
  # Track IO patterns and identify performance bottlenecks
  # =================================================================

  environment.systemPackages = with pkgs; [
    iotop # Real-time IO monitoring
    iftop # Network IO monitoring
    sysstat # iostat, sar, mpstat
  ];

  # Periodic IO stats collection for analysis
  systemd.services.io-stats-collector = {
    description = "Collect IO statistics for performance analysis";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "collect-io-stats" ''
        STATS_DIR="/var/log/io-stats"
        mkdir -p "$STATS_DIR"

        # Capture current IO statistics
        ${pkgs.sysstat}/bin/iostat -x 1 5 > "$STATS_DIR/iostat-$(date +%Y%m%d-%H%M).log" 2>/dev/null || true

        # Capture per-process IO
        if command -v iotop >/dev/null 2>&1; then
          timeout 5 ${pkgs.iotop}/bin/iotop -b -n 5 -o > "$STATS_DIR/iotop-$(date +%Y%m%d-%H%M).log" 2>/dev/null || true
        fi

        # Keep only last 7 days of logs
        find "$STATS_DIR" -type f -mtime +7 -delete 2>/dev/null || true

        echo "IO stats collected: $(ls -lh $STATS_DIR | wc -l) files"
      '';
    };
  };

  systemd.timers.io-stats-collector = {
    description = "Timer for IO statistics collection";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
      Unit = "io-stats-collector.service";
    };
  };
}
