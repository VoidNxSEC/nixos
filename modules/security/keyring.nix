{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.security.keyring;
in
{
  options.kernelcore.security.keyring = {
    enable = mkEnableOption "OS keyring support with gnome-keyring and KeePassXC integration";

    enableGUI = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Seahorse GUI for keyring management";
    };

    enableKeePassXCIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable KeePassXC Secret Service API integration";
    };

    autoUnlock = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically unlock keyring on login using PAM";
    };
  };

  config = mkIf cfg.enable {
    # ========================================================================
    # GNOME KEYRING - Secret Service API Provider
    # ========================================================================
    # gnome-keyring provides:
    # - Secret Service API (D-Bus interface for credential storage)
    # - SSH agent integration
    # - GPG agent integration (optional)
    # - Automatic unlocking via PAM
    # ========================================================================

    services.gnome.gnome-keyring.enable = true;

    # ========================================================================
    # PAM INTEGRATION - Auto-unlock keyring on login
    # ========================================================================
    # When enabled, keyring is unlocked using your login password
    # Security: Keyring password = login password
    # ========================================================================

    security.pam.services = mkIf cfg.autoUnlock {
      login.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      lightdm.enableGnomeKeyring = true;
      # For any display manager
      greetd.enableGnomeKeyring = true;
    };

    # ========================================================================
    # SYSTEM PACKAGES
    # ========================================================================

    environment.systemPackages = with pkgs; [
      # Core keyring
      gnome-keyring
      libsecret # Library for Secret Service API
      libgnome-keyring # Legacy compatibility

      # GUI management tool
      (mkIf cfg.enableGUI seahorse)

      # KeePassXC with Secret Service support
      keepassxc
    ];

    # ========================================================================
    # SYSTEMD USER SERVICE - Auto-start gnome-keyring-daemon
    # ========================================================================
    # This ensures gnome-keyring starts with your Hyprland session
    # ========================================================================

    systemd.user.services.gnome-keyring = {
      description = "GNOME Keyring daemon";
      documentation = [ "man:gnome-keyring-daemon(1)" ];

      # Start after graphical session prerequisites
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session-pre.target" ];

      partOf = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;

        # Start gnome-keyring-daemon with all components
        ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh";

        # Environment
        Environment = [
          "SSH_AUTH_SOCK=%t/keyring/ssh"
        ];
      };
    };

    # ========================================================================
    # ENVIRONMENT VARIABLES
    # ========================================================================
    # These ensure applications can find the Secret Service API
    # ========================================================================

    # environment.sessionVariables = {
    # Secret Service API location
    # GNOME_KEYRING_CONTROL = "/run/user/$UID/keyring";

    # SSH agent socket (gnome-keyring provides SSH agent)
    # Note: If you prefer gpg-agent for SSH, comment this out
    # SSH_AUTH_SOCK = "/run/user/$UID/keyring/ssh";
    # };

    # ========================================================================
    # KEEPASSXC CONFIGURATION
    # ========================================================================
    # Instructions for enabling Secret Service API in KeePassXC:
    #
    # 1. Open KeePassXC
    # 2. Go to Tools -> Settings -> Secret Service Integration
    # 3. Enable "Enable KeePassXC Freedesktop.org Secret Service integration"
    # 4. Select which database to expose via Secret Service
    # 5. Configure which groups to expose (recommended: create a separate group)
    #
    # Benefits:
    # - Applications can store credentials in your KeePassXC database
    # - Credentials are encrypted in KeePassXC database
    # - No separate keyring password needed
    # - All credentials in one place
    #
    # Security Note:
    # - Only enable for trusted applications
    # - Review access requests carefully
    # - Keep KeePassXC database password strong
    # ========================================================================

    # ========================================================================
    # DBUS SERVICES
    # ========================================================================
    # Enable D-Bus services for Secret Service API
    # ========================================================================

    services.dbus.packages = [ pkgs.gnome-keyring ];

    # ========================================================================
    # XDG AUTOSTART
    # ========================================================================
    # Backup method: Use XDG autostart for gnome-keyring
    # This provides additional compatibility with some applications
    # ========================================================================

    environment.etc."xdg/autostart/gnome-keyring-secrets.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=GNOME Keyring: Secret Service
      Exec=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets
      OnlyShowIn=GNOME;Unity;MATE;Hyprland;
      NoDisplay=true
      X-GNOME-Autostart-Phase=Initialization
      X-GNOME-AutoRestart=true
      X-GNOME-Autostart-Notify=true
    '';

    environment.etc."xdg/autostart/gnome-keyring-ssh.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=GNOME Keyring: SSH Agent
      Exec=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=ssh
      OnlyShowIn=GNOME;Unity;MATE;Hyprland;
      NoDisplay=true
      X-GNOME-Autostart-Phase=PreDisplayServer
      X-GNOME-AutoRestart=true
      X-GNOME-Autostart-Notify=true
    '';
  };
}
