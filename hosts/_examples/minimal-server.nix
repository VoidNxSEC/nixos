{ lib, ... }:

# ============================================================
# Example: Minimal Server
# ============================================================
# Headless server: security hardening, networking, SSH, secrets.
# No desktop, no audio, no GPU.
# ============================================================

{
  imports = [
    ../../modules/system
    ../../modules/hardware
    ../../modules/security
    ../../modules/network
    ../../modules/services
    ../../modules/secrets
    ../../modules/shell
  ];

  networking.hostName = "change-me";
  system.user.username = "change-me";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "24.11";
}
