{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.clamav.enable = mkEnableOption "Enable ClamAV antivirus scanning";
  };

  config = mkIf config.kernelcore.security.clamav.enable {
    ##########################################################################
    # 🦠 ClamAV Antivirus
    ##########################################################################

    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
      updater.interval = "hourly";
      updater.frequency = 24;
    };

    # ClamAV directories
    systemd.tmpfiles.rules = [
      "d /var/log/clamav 0755 clamav clamav -"
      "d /var/lib/clamav 0755 clamav clamav -"
    ];

    # Allow users in wheel group to run freshclam and clamscan
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${pkgs.clamav}/bin/freshclam";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.clamav}/bin/clamscan";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Wrapper scripts for user-friendly ClamAV access
    environment.systemPackages = with pkgs; [
      clamav
      (pkgs.writeScriptBin "freshclam-update" ''
        #!${pkgs.bash}/bin/bash
        # Wrapper for freshclam with sudo
        exec ${pkgs.sudo}/bin/sudo ${pkgs.clamav}/bin/freshclam "$@"
      '')
    ];

    # ClamAV scan service
    systemd.services.clamav-scan = {
      description = "ClamAV system scan";
      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";
        ExecStart = ''
          ${pkgs.clamav}/bin/clamscan \
            --recursive \
            --infected \
            --log=/var/log/clamav/scan.log \
            --exclude-dir="^/sys" \
            --exclude-dir="^/proc" \
            --exclude-dir="^/dev" \
            --exclude-dir="^/run" \
            --exclude-dir="^/nix/store" \
            --max-filesize=100M \
            --max-scansize=300M \
            /home
        '';
      };
    };

    # Weekly ClamAV scan timer
    systemd.timers.clamav-scan = {
      description = "Weekly ClamAV scan";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        #RandomizedDelaySec = "2h";
        Persistent = true;
      };
    };

    # Systemd hardening for ClamAV daemon
    systemd.services."clamav-daemon".serviceConfig = {
      PrivateTmp = mkForce true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "/var/lib/clamav"
        "/var/log/clamav"
      ];
    };
  };
}
