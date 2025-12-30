{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.security.dev-directory;
  userName = "kernelcore";
  devPath = "/home/${userName}/dev";
in
{
  options.kernelcore.security.dev-directory = {
    enable = mkEnableOption "Security hardening for ~/dev/ directory";

    user = mkOption {
      type = types.str;
      default = userName;
      description = "User that owns the dev directory";
    };

    path = mkOption {
      type = types.str;
      default = devPath;
      description = "Path to development directory";
    };

    enableEncryption = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable eCryptfs encryption for dev directory.
        WARNING: Requires manual setup and password on login.
      '';
    };

    enableAudit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable audit logging for dev directory access";
    };

    enableBackup = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automated encrypted backups";
    };

    backupInterval = mkOption {
      type = types.str;
      default = "daily";
      description = "Backup frequency (daily, weekly, hourly)";
    };

    allowedProcesses = mkOption {
      type = types.listOf types.str;
      default = [
        # Development tools
        "cargo"
        "rustc"
        "node"
        "npm"
        "git"
        "nix"
        "nix-build"
        "nix-shell"

        # Editors
        "code"
        "codium"
        "nvim"
        "vim"

        # Shell
        "bash"
        "zsh"
        "fish"
      ];
      description = "Processes allowed to access dev directory (for AppArmor)";
    };
  };

  config = mkIf cfg.enable {

    # ========================================
    # Layer 1: Filesystem Permissions
    # ========================================

    systemd.tmpfiles.rules = [
      # Main dev directory - strict permissions
      "d ${cfg.path} 0700 ${cfg.user} ${cfg.user} -"

      # Project directories
      "d ${cfg.path}/securellm-bridge 0700 ${cfg.user} ${cfg.user} -"
      "d ${cfg.path}/ml-offload-api 0700 ${cfg.user} ${cfg.user} -"

      # Secrets directory (for development secrets)
      "d ${cfg.path}/.secrets 0700 ${cfg.user} ${cfg.user} -"

      # Backup staging
      "d ${cfg.path}/.backup-staging 0700 ${cfg.user} ${cfg.user} -"
    ];

    # ========================================
    # Layer 2: Encryption (Optional)
    # ========================================

    # eCryptfs support (manual setup required)
    # Consolidated system packages for dev directory security
    environment.systemPackages = [
      # File integrity and encryption tools
      pkgs.aide
      pkgs.git-crypt

      # Emergency lockdown script
      (pkgs.writeScriptBin "dev-lockdown" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        echo "🚨 LOCKING DOWN ~/dev DIRECTORY..."

        # Remove all permissions except for owner
        chmod -R go-rwx ${cfg.path}

        # Kill all processes accessing dev directory
        ${pkgs.lsof}/bin/lsof +D ${cfg.path} | ${pkgs.gawk}/bin/awk 'NR>1 {print $2}' | xargs -r kill -9

        # Create emergency backup
        EMERGENCY_BACKUP="/backup/emergency-dev-$(date +%Y%m%d-%H%M%S).tar.gz.gpg"
        ${pkgs.gnutar}/bin/tar -czf - -C "$(dirname ${cfg.path})" "$(basename ${cfg.path})" \
          | ${pkgs.gnupg}/bin/gpg --encrypt --recipient ${cfg.user}@localhost \
          --output "$EMERGENCY_BACKUP"

        # Log incident
        logger -t dev-security -p security.crit "EMERGENCY LOCKDOWN ACTIVATED"

        echo "✅ Lockdown complete. Emergency backup: $EMERGENCY_BACKUP"
      '')
    ]
    ++ (optionals cfg.enableEncryption [
      # Optional: eCryptfs encryption
      pkgs.ecryptfs
      pkgs.ecryptfs-helper
    ]);

    # Note: eCryptfs setup must be done manually:
    # $ ecryptfs-setup-private --nopwcheck --noautomount
    # $ mv ~/Private ~/dev
    # Then mount on login

    # ========================================
    # Layer 3: Audit Logging
    # ========================================

    security.auditd.enable = mkIf cfg.enableAudit true;

    # Audit rules for dev directory
    security.audit.rules = mkIf cfg.enableAudit [
      # Log all access to dev directory (read/write/execute/attribute changes)
      "-w ${cfg.path} -p rwxa -k dev-access"

      # Log secret access specifically
      "-w ${cfg.path}/.secrets -p rwxa -k dev-secrets-access"

      # Log git operations (potential credential exposure)
      "-w ${cfg.path} -p wa -k dev-git-ops -F path~.git"

      # Log cargo builds (potential supply chain issues)
      "-w ${cfg.path} -p wa -k dev-cargo-build -F exe=/usr/bin/cargo"
    ];

    # ========================================
    # Layer 4: File Integrity Monitoring
    # ========================================

    # AIDE configuration
    environment.etc."aide.conf".text = ''
      # AIDE configuration for ~/dev monitoring
      database=file:/var/lib/aide/aide.db
      database_out=file:/var/lib/aide/aide.db.new

      # Monitor dev directory
      ${cfg.path} p+i+n+u+g+s+b+m+c+md5+sha256

      # Exclude build artifacts (too noisy)
      !${cfg.path}/.*/target
      !${cfg.path}/.*/node_modules
      !${cfg.path}/.*/build
      !${cfg.path}/.*/.git/objects
    '';

    # Daily AIDE check
    systemd.services.aide-check = {
      description = "AIDE File Integrity Check for ~/dev";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.aide}/bin/aide --check";
        User = "root";
      };
    };

    systemd.timers.aide-check = {
      description = "Daily AIDE Check Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # ========================================
    # Layer 5: Automated Backups
    # ========================================

    systemd.services.dev-backup = mkIf cfg.enableBackup {
      description = "Encrypted backup of ~/dev directory";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;

        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [
          "${cfg.path}/.backup-staging"
          "/backup"
        ];
        NoNewPrivileges = true;
      };

      script = ''
        set -euo pipefail

        BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
        BACKUP_STAGING="${cfg.path}/.backup-staging"
        BACKUP_DEST="/backup/dev-backups"

        echo "Starting encrypted backup of ${cfg.path}..."

        # Create backup destination
        mkdir -p "$BACKUP_DEST"

        # Tar + GPG encryption (requires GPG key setup)
        ${pkgs.gnutar}/bin/tar -czf - \
          --exclude='*/target' \
          --exclude='*/node_modules' \
          --exclude='*/build' \
          --exclude='*/.git/objects' \
          --exclude='*.db' \
          --exclude='*.db-*' \
          -C "$(dirname ${cfg.path})" \
          "$(basename ${cfg.path})" \
        | ${pkgs.gnupg}/bin/gpg --encrypt --recipient ${cfg.user}@localhost \
          --output "$BACKUP_DEST/dev-backup-$BACKUP_DATE.tar.gz.gpg"

        # Verify backup was created
        if [ -f "$BACKUP_DEST/dev-backup-$BACKUP_DATE.tar.gz.gpg" ]; then
          SIZE=$(du -h "$BACKUP_DEST/dev-backup-$BACKUP_DATE.tar.gz.gpg" | cut -f1)
          echo "Backup completed: $SIZE"

          # Cleanup old backups (keep last 30)
          cd "$BACKUP_DEST"
          ls -t dev-backup-*.tar.gz.gpg | tail -n +31 | xargs -r rm --

          # Log to journal
          logger -t dev-backup "Encrypted backup completed: $SIZE"
        else
          echo "ERROR: Backup failed!"
          logger -t dev-backup -p user.err "Backup failed"
          exit 1
        fi
      '';
    };

    systemd.timers.dev-backup = mkIf cfg.enableBackup {
      description = "Dev Directory Backup Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.backupInterval;
        Persistent = true;
        RandomizedDelaySec = "30min";
      };
    };

    # ========================================
    # Layer 6: Access Monitoring
    # ========================================

    # Monitor suspicious access patterns
    systemd.services.dev-access-monitor = {
      description = "Monitor unusual access to ~/dev";

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
        User = "root";

        # Security
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };

      script = ''
        set -euo pipefail

        echo "Starting dev directory access monitoring..."

        # Monitor audit log for suspicious patterns
        ${pkgs.coreutils}/bin/tail -F /var/log/audit/audit.log 2>/dev/null | while read -r line; do
          # Check for dev-access events
          if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "key=\"dev-access\""; then

            # Extract process info
            PROC=$(echo "$line" | ${pkgs.gnused}/bin/sed -n 's/.*exe="\([^"]*\)".*/\1/p')

            # Alert on unusual processes
            if ! echo "${toString cfg.allowedProcesses}" | ${pkgs.gnugrep}/bin/grep -qw "$(basename "$PROC")"; then
              logger -t dev-security -p security.warning \
                "Unusual process accessing ~/dev: $PROC"

              # Optionally send notification (requires notification daemon)
              # notify-send "Security Alert" "Unusual access to ~/dev by: $PROC"
            fi
          fi

          # Alert on secret access
          if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "key=\"dev-secrets-access\""; then
            logger -t dev-security -p security.info \
              "Secret directory accessed: $(date)"
          fi
        done || true
      '';
    };

    # Auto-start monitoring
    systemd.services.dev-access-monitor.wantedBy = [ "multi-user.target" ];

    # ========================================
    # Layer 7: Git Security
    # ========================================

    # Git credential helper (encrypted storage)
    environment.variables = {
      # Use git-credential-cache with timeout
      GIT_CREDENTIAL_HELPER = "cache --timeout=3600";
    };

    # Shell aliases for secure git operations
    environment.shellAliases = {
      # Git with GPG signing enforced
      git-dev = "${pkgs.git}/bin/git -c commit.gpgsign=true -c tag.gpgsign=true";

      # Check for secrets before commit
      git-commit-safe = ''
        ${pkgs.git}/bin/git diff --cached --name-only | ${pkgs.gnugrep}/bin/grep -E '\.(env|key|pem|p12|pfx)$' && echo "WARNING: Potential secrets in commit!" || ${pkgs.git}/bin/git commit
      '';
    };

    # ========================================
    # Layer 8: Emergency Response
    # ========================================

    # Note: dev-lockdown script defined in systemPackages above

    # ========================================
    # Documentation
    # ========================================

    # Security documentation
    environment.etc."nixos/dev-security-guide.md".text = ''
      # ~/dev Directory Security Guide

      ## Enabled Features
      ${optionalString cfg.enableAudit "✅ Audit logging: /var/log/audit/audit.log"}
      ${optionalString cfg.enableBackup "✅ Automated backups: ${cfg.backupInterval}"}
      ${optionalString cfg.enableEncryption "✅ eCryptfs encryption (manual setup required)"}
      ✅ File integrity monitoring (AIDE)
      ✅ Access monitoring
      ✅ Strict filesystem permissions (0700)

      ## Security Commands

      ### Check audit logs
      sudo ausearch -k dev-access
      sudo ausearch -k dev-secrets-access

      ### Manual backup
      sudo systemctl start dev-backup

      ### Check file integrity
      sudo aide --check

      ### Emergency lockdown
      sudo dev-lockdown

      ### View backup status
      systemctl status dev-backup
      ls -lh /backup/dev-backups/

      ### Restore from backup
      gpg --decrypt /backup/dev-backups/dev-backup-YYYYMMDD.tar.gz.gpg \
        | tar -xzf - -C /tmp/restore/

      ## Best Practices

      1. **Never commit secrets**: Use .gitignore, git-crypt, or SOPS
      2. **Sign commits**: Use GPG signing (git-dev alias)
      3. **Review before commit**: Check git diff before push
      4. **Use SSH keys**: Not HTTPS tokens
      5. **Regular backups**: Verify backups periodically
      6. **Monitor logs**: Check audit logs weekly

      ## Encryption Setup (Optional)

      To enable eCryptfs encryption:

      1. Install: Already installed via this module
      2. Setup: ecryptfs-setup-private
      3. Mount: ecryptfs-mount-private
      4. Unmount: ecryptfs-umount-private

      ## Incident Response

      If suspicious activity detected:
      1. Run: sudo dev-lockdown
      2. Check: sudo ausearch -k dev-access -i
      3. Review: Emergency backup location
      4. Investigate: Process that triggered alert
    '';
  };

  meta.maintainers = with lib.maintainers; [ marcosfpina ];
}
