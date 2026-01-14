{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
in
{
  options.kernelcore.soc.network.netflow = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile != "minimal";
      description = "Enable netflow collection for network visibility";
    };

    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "any" ];
      description = "Interfaces to collect flows from";
    };

    exportToSiem = mkOption {
      type = types.bool;
      default = cfg.siem.opensearch.enable or false;
      description = "Export flows to SIEM";
    };
  };

  config = mkIf (cfg.enable && cfg.network.netflow.enable) {
    # softflowd for flow generation
    systemd.services.softflowd = {
      description = "Netflow collector";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.softflowd}/bin/softflowd -i ${head cfg.network.netflow.interfaces} -n 127.0.0.1:9997 -v 9 -t maxlife=600";
        Restart = "always";
        RestartSec = "10s";
      };
    };

    # nfdump for flow storage and analysis
    systemd.services.nfcapd = {
      description = "Netflow capture daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.nfdump}/bin/nfcapd -p 9997 -l /var/lib/soc/netflow -P /run/nfcapd.pid -t 60";
        Restart = "always";
        RestartSec = "5s";
        User = "root";
      };
    };

    # Netflow rotation and cleanup
    systemd.services.netflow-cleanup = {
      description = "Clean old netflow data";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "netflow-cleanup" ''
          find /var/lib/soc/netflow -type f -mtime +${toString cfg.retention.days} -delete
        ''}";
      };
    };

    systemd.timers.netflow-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/soc/netflow 0750 root root -"
    ];

    environment.systemPackages = [ pkgs.nfdump ];

    environment.shellAliases = {
      nf-top = "nfdump -R /var/lib/soc/netflow -s srcip/bytes -n 50";
      nf-flows = "nfdump -R /var/lib/soc/netflow -c 50";
    };
  };
}
