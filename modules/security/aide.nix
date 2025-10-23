{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.aide = {
      enable = mkEnableOption "Enable AIDE (Advanced Intrusion Detection Environment)";

      databasePath = mkOption {
        type = types.str;
        default = "/var/lib/aide/aide.db";
        description = "Path to AIDE database";
      };

      configFile = mkOption {
        type = types.lines;
        default = ''
          # AIDE configuration for NixOS

          # Database locations
          database_in=/var/lib/aide/aide.db
          database_out=/var/lib/aide/aide.db.new
          database_new=/var/lib/aide/aide.db.new

          # Report settings
          report_url=/var/log/aide/aide.log
          report_url=stdout

          # Verbose level (0-255)
          verbose=5

          # Rule definitions
          # p: permissions
          # i: inode
          # n: number of links
          # u: user
          # g: group
          # s: size
          # b: block count
          # m: mtime
          # a: atime
          # c: ctime
          # S: check for growing size
          # md5: md5 checksum
          # sha256: sha256 checksum

          # Custom rules
          FIPSR = p+i+n+u+g+s+m+c+md5+sha256
          NORMAL = p+i+n+u+g+s+m+c+md5+sha256
          DIR = p+i+n+u+g
          PERMS = p+i+u+g
          LOG = >

          # Critical system directories
          /boot FIPSR
          /bin NORMAL
          /sbin NORMAL
          /lib NORMAL
          /lib64 NORMAL
          /usr/bin NORMAL
          /usr/sbin NORMAL
          /usr/lib NORMAL
          /usr/lib64 NORMAL

          # NixOS specific
          /nix/var/nix/profiles/system NORMAL
          /etc NORMAL

          # Configuration files
          !/etc/mtab
          !/etc/resolv.conf
          !/etc/hosts
          !/etc/hostname

          # SSH
          /etc/ssh/sshd_config FIPSR
          /root/.ssh FIPSR

          # User directories (selective monitoring)
          !/home

          # Temporary and variable data (excluded)
          !/tmp
          !/var/tmp
          !/var/cache
          !/var/log
          !/var/spool
          !/var/run
          !/run

          # Process and system information
          !/proc
          !/sys
          !/dev
        '';
        description = "AIDE configuration file content";
      };

      checkSchedule = mkOption {
        type = types.str;
        default = "daily";
        description = "Schedule for AIDE integrity checks (systemd timer format)";
      };

      alertEmail = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "admin@example.com";
        description = "Email address to send AIDE alerts (requires mail system configured)";
      };
    };
  };

  config = mkIf config.kernelcore.security.aide.enable {
    ##########################################################################
    # 🛡️ AIDE - Advanced Intrusion Detection Environment
    ##########################################################################

    # Install AIDE
    environment.systemPackages = [ pkgs.aide ];

    # AIDE configuration file
    environment.etc."aide.conf" = {
      text = config.kernelcore.security.aide.configFile;
      mode = "0600";
    };

    # Create AIDE directories
    systemd.tmpfiles.rules = [
      "d /var/lib/aide 0700 root root -"
      "d /var/log/aide 0700 root root -"
    ];

    # Initial AIDE database creation service
    systemd.services.aide-init = {
      description = "Initialize AIDE database";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/aide /var/log/aide";
        ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -f /var/lib/aide/aide.db ]; then ${pkgs.aide}/bin/aide --config /etc/aide.conf --init && ${pkgs.coreutils}/bin/mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db; fi'";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    # AIDE integrity check service
    systemd.services.aide-check = {
      description = "AIDE integrity check";
      requires = [ "aide-init.service" ];
      after = [ "aide-init.service" ];

      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";

        # Run check and log results
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.aide}/bin/aide --config /etc/aide.conf --check | tee /var/log/aide/aide-check-$(date +%Y%m%d-%H%M%S).log'";

        # Send email if configured
        ExecStartPost =
          mkIf (config.kernelcore.security.aide.alertEmail != null)
            "${pkgs.bash}/bin/bash -c 'if [ -s /var/log/aide/aide-check-*.log ]; then ${pkgs.mailutils}/bin/mail -s \"AIDE Report - $(hostname)\" ${config.kernelcore.security.aide.alertEmail} < /var/log/aide/aide-check-*.log; fi'";
      };
    };

    # AIDE check timer
    systemd.timers.aide-check = {
      description = "AIDE integrity check timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = config.kernelcore.security.aide.checkSchedule;
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };

    # AIDE database update service
    systemd.services.aide-update = {
      description = "Update AIDE database";
      requires = [ "aide-init.service" ];
      after = [ "aide-init.service" ];

      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";

        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.aide}/bin/aide --config /etc/aide.conf --update && ${pkgs.coreutils}/bin/mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db'";
      };
    };

    # Convenient shell aliases for AIDE management
    environment.shellAliases = {
      aide-check = "sudo systemctl start aide-check.service && sudo journalctl -u aide-check.service -n 50";
      aide-update = "sudo systemctl start aide-update.service && sudo journalctl -u aide-update.service -n 50";
      aide-status = "sudo systemctl status aide-check.timer aide-init.service";
      aide-logs = "sudo ls -lah /var/log/aide/ && echo '---' && sudo tail -n 50 /var/log/aide/*.log";
    };

    # AIDE usage instructions
    environment.etc."aide/README.txt" = {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║     AIDE - Advanced Intrusion Detection Environment           ║
        ╚════════════════════════════════════════════════════════════════╝

        AIDE monitors file system integrity and detects unauthorized changes.

        ## QUICK START:

        1. Initial Setup (automatic on first boot):
           - AIDE database is automatically initialized
           - Check status: aide-status

        2. Manual Check:
           $ aide-check

        3. After Legitimate Changes (system updates, configs):
           $ aide-update

        4. View Reports:
           $ aide-logs

        ## WHAT AIDE MONITORS:

        ✓ Critical system files (/boot, /bin, /sbin, /lib, /usr)
        ✓ NixOS system profile
        ✓ Configuration files (/etc)
        ✓ SSH configuration
        ✓ Root SSH keys

        ✗ Excluded: /tmp, /var, /home, /proc, /sys, /dev

        ## INTERPRETING RESULTS:

        - No output = No changes detected (good!)
        - "Added entries" = New files created
        - "Removed entries" = Files deleted
        - "Changed entries" = Files modified

        Common legitimate changes:
        - After nixos-rebuild: NixOS profiles change
        - After package updates: System files change
        - After config edits: /etc files change

        ## SCHEDULED CHECKS:

        - Automatic checks run: ${config.kernelcore.security.aide.checkSchedule}
        - Check timer status: systemctl status aide-check.timer
        - View last check: journalctl -u aide-check.service

        ## IMPORTANT:

        ⚠️  After legitimate system changes, run: aide-update
        ⚠️  Otherwise, next check will show false positives
        ⚠️  Keep AIDE database secure (stored in /var/lib/aide/)

        ## MANUAL COMMANDS:

        Initialize:  aide --config /etc/aide.conf --init
        Check:       aide --config /etc/aide.conf --check
        Update:      aide --config /etc/aide.conf --update

        ## CONFIGURATION:

        Edit: /etc/aide.conf
        Database: ${config.kernelcore.security.aide.databasePath}
        Logs: /var/log/aide/

        For more information: man aide
      '';
      mode = "0644";
    };
  };
}
