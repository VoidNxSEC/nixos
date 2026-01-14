{ pkgs, nix-colors, ... }:

{
  # Import the nix-colors module
  imports = [ nix-colors.homeManagerModules.default ];

  # Configure the color scheme - Catppuccin Macchiato
  colorScheme = nix-colors.colorSchemes.catppuccin-macchiato;

  # Set the GTK theme, icons, and cursor
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Macchiato-Standard-Blue-dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "macchiato";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Catppuccin-Macchiato-Blue";
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      size = 24;
    };
  };

  # Configure Qt styles to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
  };

  # Home Manager packages required for the theme
  home.packages = with pkgs; [
    catppuccin-gtk
    papirus-icon-theme
    catppuccin-cursors.macchiatoBlue
  ];
}
