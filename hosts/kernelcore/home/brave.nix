{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    commandLineArgs = [
      "--force-dark-mode"
      "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,ParallelDownloading"
      "--ignore-gpu-blocklist"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--ozone-platform-hint=auto"
      "--disable-reading-from-canvas"
      "--no-first-run"
      "--disable-sync"
      "--password-store=gnome-libsecret"
    ];
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    ];
  };

  # Make sure Brave is the default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };
}
