# Neoland Checkpoint Storage — ADR filesystem + retention

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.neoland-checkpoints;
in
{
  options.services.neoland-checkpoints = {
    enable = lib.mkEnableOption "Neoland checkpoint ADR storage";

    dir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/neoland/checkpoints";
    };

    retentionDays = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "Dias de retenção dos arquivos ADR JSON";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dir}      0750 neoland neoland -"
      "d ${cfg.dir}/adr  0750 neoland neoland -"
    ];

    systemd.services.neoland-checkpoint-cleanup = {
      description = "Neoland checkpoint retention cleanup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.findutils}/bin/find ${cfg.dir} -name '*.json' -mtime +${toString cfg.retentionDays} -delete";
        User = "neoland";
      };
    };

    systemd.timers.neoland-checkpoint-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
