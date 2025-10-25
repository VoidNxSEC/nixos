{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.ssh = {
      enable = mkEnableOption "Enable SSH security hardening";

      enable2FA = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Google Authenticator 2FA for SSH (requires manual setup per user)";
      };
    };
  };

  config = mkIf config.kernelcore.security.ssh.enable {
    ##########################################################################
    # 🔑 OpenSSH Security Hardening
    ##########################################################################

    services.openssh = {
      enable = true;

      settings = {
        # Authentication
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = mkDefault false;
        PubkeyAuthentication = true;
        PermitEmptyPasswords = false;
        UsePAM = true;
        StrictModes = true;
        IgnoreRhosts = true;

        # Security limits
        MaxAuthTries = 3;
        MaxSessions = 2;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;

        # Disable risky features
        X11Forwarding = false;
      };

      extraConfig = ''
        # Cryptographic hardening
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
        HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

        # Logging
        LogLevel VERBOSE
        SyslogFacility AUTH

        # Banner
        Banner /etc/ssh/banner
      '';
    };

    # SSH banner
    environment.etc."ssh/banner".text = ''
      #################################################################
      #                      AUTHORIZED ACCESS ONLY                   #
      # Unauthorized access to this system is strictly prohibited.    #
      # All access attempts are logged and monitored.                #
      #################################################################
    '';

    # Systemd hardening for SSH daemon
    systemd.services.sshd.serviceConfig = {
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      PrivateMounts = true;
      SystemCallFilter = "@system-service";
      SystemCallErrorNumber = "EPERM";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE CAP_DAC_READ_SEARCH";
      AmbientCapabilities = "";
    };

    ##########################################################################
    # 🔐 Google Authenticator 2FA (Optional)
    ##########################################################################

    # Install Google Authenticator
    environment.systemPackages = mkIf config.kernelcore.security.ssh.enable2FA [
      pkgs.google-authenticator
    ];

    # Configure PAM for SSH with 2FA
    security.pam.services.sshd = mkIf config.kernelcore.security.ssh.enable2FA {
      googleAuthenticator = {
        enable = true;
      };

      # Additional PAM settings for 2FA
      text = mkDefault ''
        # Account management
        account required pam_unix.so

        # Authentication with Google Authenticator
        # Required: both password/key AND TOTP code
        auth required pam_google_authenticator.so nullok secret=/home/\''${USER}/.google_authenticator
        auth required pam_unix.so try_first_pass

        # Password management
        password required pam_unix.so

        # Session management
        session required pam_unix.so
        session required pam_env.so
      '';
    };

    # Instructions file for users
    environment.etc."ssh/2fa-setup-instructions.txt" = mkIf config.kernelcore.security.ssh.enable2FA {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║        SSH Two-Factor Authentication Setup Instructions        ║
        ╚════════════════════════════════════════════════════════════════╝

        Google Authenticator 2FA is now ENABLED for SSH access.

        ## SETUP REQUIRED FOR EACH USER:

        1. Login to your account locally or via existing SSH session

        2. Run the setup command:
           $ google-authenticator

        3. Answer the questions:
           - "Do you want authentication tokens to be time-based?" → YES
           - Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)
           - Save the emergency scratch codes in a SAFE PLACE
           - "Do you want me to update your ~/.google_authenticator file?" → YES
           - "Do you want to disallow multiple uses of the same token?" → YES
           - "Do you want to increase the time skew window?" → NO (unless needed)
           - "Do you want to enable rate-limiting?" → YES

        4. Test the configuration:
           - Keep your current session OPEN
           - Open a NEW SSH connection
           - You will be prompted for:
             a) Your SSH key passphrase (if using key auth)
             b) Your verification code from the authenticator app

        ## EMERGENCY ACCESS:

        If you lose access to your authenticator:
        - Use one of the emergency scratch codes saved during setup
        - OR login via local console (physical access)
        - OR have an administrator with root access reset your ~/.google_authenticator file

        ## IMPORTANT NOTES:

        - Keep your emergency scratch codes SAFE and OFFLINE
        - Each scratch code can only be used ONCE
        - Time synchronization is CRITICAL (ensure your phone time is accurate)
        - The 'nullok' option allows SSH without 2FA if .google_authenticator doesn't exist
          (this is for backwards compatibility during rollout)

        ## TROUBLESHOOTING:

        - "Invalid verification code" → Check phone time sync
        - "Permission denied" → Check ~/.google_authenticator file permissions (should be 600)
        - Locked out → Use emergency scratch codes or local console access

        For more information: man google-authenticator
      '';
      mode = "0644";
    };
  };
}
