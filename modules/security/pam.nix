{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.pam.enable = mkEnableOption "Enable PAM security hardening";
  };

  config = mkIf config.kernelcore.security.pam.enable {
    ##########################################################################
    # 🔐 PAM & Authentication Hardening
    ##########################################################################

    security.pam = {
      sshAgentAuth.enable = true;

      loginLimits = [
        # Disable core dumps
        {
          domain = "*";
          item = "core";
          type = "hard";
          value = "0";
        }
        # Limit simultaneous logins (increased for multiple TTYs + graphical session)
        {
          domain = "*";
          item = "maxlogins";
          type = "hard";
          value = "10";
        }
        # File descriptor limits
        {
          domain = "*";
          item = "nofile";
          type = "soft";
          value = "65536";
        }
        {
          domain = "*";
          item = "nofile";
          type = "hard";
          value = "65536";
        }
      ];

      services = {
        sshd.showMotd = true;
      };
    };

    # Password quality requirements
    security.pam.services.passwd.text = mkDefault ''
      password required pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
    '';

    # System login policies
    security.loginDefs.settings = {
      PASS_MAX_DAYS = 90;
      PASS_MIN_DAYS = 1;
      PASS_WARN_AGE = 14;
      UMASK = "077";
      ENCRYPT_METHOD = "SHA512";
      SHA_CRYPT_MIN_ROUNDS = 5000;
    };

    # GnuPG agent for SSH
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = mkDefault pkgs.pinentry-curses;
    };

    # Immutable users (managed via configuration)
    users.mutableUsers = false;
  };
}
