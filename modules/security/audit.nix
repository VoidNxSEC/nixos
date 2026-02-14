{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  auditPkg = config.security.audit.package;

  # Workaround: kernel 6.18 breaks AUDIT_SET netlink commands (auditctl -b/-f/-r/-e)
  # due to audit_status struct ABI change. The upstream NixOS rules file uses -b/-f/-r/-e
  # which all fail. We bypass this by loading only the actual watch/syscall rules
  # directly via individual auditctl calls. Backlog limit is already set via
  # boot.kernelParams (audit_backlog_limit=8192).
  auditRulesScript = pkgs.writeShellScript "load-audit-rules" ''
    auditctl="${lib.getExe' auditPkg "auditctl"}"

    # Delete existing rules (AUDIT_DEL works fine on 6.18)
    $auditctl -D

    # Load rules individually, skipping AUDIT_SET commands (-b/-f/-r/-e)
    ${concatMapStringsSep "\n" (rule: "$auditctl ${rule}") config.security.audit.rules}
  '';
in
{
  options = {
    kernelcore.security.audit.enable = mkEnableOption "Enable security auditing and logging";
  };

  config = mkIf config.kernelcore.security.audit.enable {
    ##########################################################################
    # 📋 Security Auditing & Logging
    ##########################################################################

    # Linux audit daemon
    security.auditd.enable = true;
    security.audit = {
      enable = true;

      # backlogLimit sets kernel param audit_backlog_limit= (works)
      # and generates -b in rules file (broken on kernel 6.18).
      # We override the service below to skip the broken -b command.
      backlogLimit = 8192;

      rules = [
        # Monitor critical file changes
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        "-w /etc/sudoers -p wa -k sudoers_changes"

        # Monitor login attempts
        "-w /var/log/lastlog -p wa -k logins"
        "-w /var/run/faillock -p wa -k logins"
        "-w /var/log/audit/ -p wx -k audit_tampering"

        # Monitor unauthorized access attempts (openat for kernel 6.18+ compat)
        "-a always,exit -F arch=b64 -S openat -F dir=/etc -F success=0 -k unauthed_access"

        # Monitor kernel module loading/unloading
        "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules"
      ];
    };

    # Override the upstream audit-rules-nixos service to bypass AUDIT_SET
    # netlink ABI breakage on kernel 6.18 with audit 4.1.x userspace.
    systemd.services.audit-rules-nixos.serviceConfig = {
      ExecStart = mkForce auditRulesScript;
      ExecStopPost = mkForce [
        # Only use -D (AUDIT_DEL), skip -e 0 (AUDIT_SET, broken)
        "${lib.getExe' auditPkg "auditctl"} -D"
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
