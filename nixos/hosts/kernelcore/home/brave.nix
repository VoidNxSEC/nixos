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
      # "--enable-gpu-rasterization"
      # REMOVED: --enable-zero-copy (incompatível com NVIDIA+Wayland+GBM)
      # Causa EGL_BAD_MATCH errors (0x3009) ao tentar criar EGLImages
      "--ozone-platform-hint=auto"
      # NVIDIA+Wayland specific fixes para EGL errors
      "--use-gl=egl"
      # "--disable-gpu-driver-bug-workarounds" # REMOVED: Breaks extensions
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
