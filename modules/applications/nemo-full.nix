{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.nemo;
in
{
  options.programs.nemo = {
    enable = mkEnableOption "Nemo file manager with full features";

    package = mkOption {
      type = types.package;
      default = pkgs.nemo;
      defaultText = literalExpression "pkgs.nemo";
      description = "The Nemo package to use";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        # Core Nemo package already includes basic extensions
        # Additional functionality
        sushi # File previewer (spacebar preview)
      ];
      description = "List of Nemo extensions to install";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        # Thumbnails and previews
        ffmpegthumbnailer # Video thumbnails
        imagemagick # Image processing
        libgsf # ODF thumbnails
        poppler # PDF thumbnails

        # Archive support
        file-roller # GUI archive manager
        p7zip # 7z support
        unrar # RAR support
        unzip # ZIP support
        zip # ZIP creation

        # Media info
        mediainfo # Media file information
        exiftool # EXIF data reading
      ];
      description = "Additional packages to support Nemo features";
    };

    setDefaultFileManager = mkOption {
      type = types.bool;
      default = true;
      description = "Set Nemo as the default file manager";
    };

    plugins = {
      preview = mkEnableOption "Enable file preview (sushi)" // {
        default = true;
      };
      compare = mkEnableOption "Enable file comparison tools" // {
        default = true;
      };
      terminal = mkEnableOption "Enable 'Open in Terminal' action" // {
        default = true;
      };
      admin = mkEnableOption "Enable 'Open as Administrator' action" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ]
    ++ cfg.extensions
    ++ cfg.extraPackages
    ++ optional cfg.plugins.compare pkgs.meld
    ++ optional cfg.plugins.terminal pkgs.gnome-terminal
    ++ optional cfg.plugins.admin pkgs.polkit;

    # GIO modules for proper integration
    services.gvfs = {
      enable = mkDefault true;
      package = mkDefault pkgs.gvfs;
    };

    # Thumbnail generation
    services.tumbler.enable = mkDefault true;

    # Enable polkit for admin actions
    security.polkit.enable = mkIf cfg.plugins.admin true;

    # XDG MIME associations
    xdg.mime = mkIf cfg.setDefaultFileManager {
      enable = true;
      defaultApplications = {
        "inode/directory" = "nemo.desktop";
        "application/x-gnome-saved-search" = "nemo.desktop";
      };
    };

    # DBus service for Nemo
    services.dbus.packages = [ cfg.package ];

    # Environment variables
    environment.sessionVariables = {
      # Ensure Nemo uses correct backend
      GIO_MODULE_DIR = "${pkgs.gvfs}/lib/gio/modules";

      # Enable additional features
      NEMO_ACTION_VERBOSE = "1";
    }
    // optionalAttrs cfg.setDefaultFileManager {
      # Set as default file manager
      XDG_CURRENT_DESKTOP = mkDefault "X-Cinnamon";
    };

    # XDG portal for file picker integration
    xdg.portal = {
      enable = mkDefault true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = mkDefault "gtk";
    };

    # Custom Nemo actions directory
    environment.pathsToLink = [
      "/share/nemo"
      "/share/nemo/actions"
    ];

    # User-level configuration hints (displayed as warning)
    warnings =
      optional (!config.services.xserver.enable && !config.services.displayManager.enable)
        "Nemo works best with a display manager. Consider enabling services.xserver.enable or services.displayManager.enable";
  };

  meta = {
    maintainers = with maintainers; [ ];
  };
}
