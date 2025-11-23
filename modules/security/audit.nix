{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.audit.enable = mkEnableOption "Enable security auditing and logging";
  };

  config = mkIf config.kernelcore.security.audit.enable {
    ##########################################################################
    # 📋 Security Auditing & Logging
    ##########################################################################

    # Increase audit backlog to prevent kauditd queue overflow during boot
    boot.kernelParams = [
      "audit=1"
      "audit_backlog_limit=8192" # Increased from default 1024 to handle boot-time events
    ];

    # Linux audit daemon
    security.auditd.enable = true;
    security.audit = {
      enable = true;
      rules = [
        # Monitor execve syscalls
        "-a exit,always -F arch=b64 -S execve"

        # Monitor critical file changes
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        "-w /etc/sudoers -p wa -k sudoers_changes"

        # Monitor login attempts
        "-w /var/log/lastlog -p wa -k logins"
        "-w /var/run/faillock -p wa -k logins"

        # Monitor unauthorized access attempts
        "-a always,exit -F arch=b64 -S open -F dir=/etc -F success=0 -k unauthed_access"

        # Monitor file deletions
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete"
      ];
    };

    # AppArmor for application confinement
    security.apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
      packages = with pkgs; [ apparmor-profiles ];
    };

    # Journald configuration
    services.journald = {
      extraConfig = ''
        Storage=persistent
        Compress=yes
        SplitMode=uid
        RateLimitInterval=30s
        RateLimitBurst=1000
        SystemMaxUse=1G
        MaxRetentionSec=1month
        ForwardToSyslog=yes
      '';
    };

    # Rsyslog configuration moved to sec/hardening.nix to avoid duplication
    # (was causing 3x log entries in /var/log/messages)

    # Credential storage setup
    systemd.services."setup-system-credentials" = {
      description = "Setup system credential storage";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /etc/credstore && ${pkgs.coreutils}/bin/chmod 700 /etc/credstore'";
      };
    };
  };
}
