{ lib, pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# APLICAÇÕES — browsers, editores, tuning Electron/Chromium
# ═══════════════════════════════════════════════════════════

{
  kernelcore.applications.electron.enable = false;
  #kernelcore.applications.electron.apps.antigravity = {
  #profile = "performance";
  #configDir = "Antigravity";
  #features.enable = [
  #"VaapiVideoDecodeLinuxGL"
  #"WaylandWindowDecorations"
  #];
  #};

  # Chromium/Electron log suppression (GPU/Wayland error spam)
  kernelcore.applications.chromium.logSuppression = {
    enable = true;
    applyGlobally = true;
    enablePerformanceFlags = false; # Keep disabled for stability
  };

  kernelcore.applications.chromium = {
    enable = true;
    extraArgs = [
      "--force-dark-mode"
      "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,ParallelDownloading"
      "--ignore-gpu-blocklist"
      #"--enable-gpu-rasterization"
      # REMOVED: --enable-zero-copy (incompatível com NVIDIA+Wayland+GBM)
      # Causa EGL_BAD_MATCH errors (0x3009) ao tentar criar EGLImages
      "--ozone-platform-hint=auto"
      # NVIDIA+Wayland specific fixes para EGL errors
      "--use-gl=egl"
      "--disable-gpu-driver-bug-workarounds"
      "--no-first-run"
      "--disable-sync"
    ];
  };

  kernelcore.applications.brave = {
    enable = true;
    profile = "secure";
  };

  kernelcore.applications.firefox.enable = true;
  kernelcore.applications.nemo.enable = true;
  kernelcore.applications.zellij.enable = false;
  kernelcore.applications.cognitive-vault.enable = true;

  kernelcore.applications.vscodium = {
    enable = true;
    enableGitLabDuo = true;
    extensions = with pkgs.vscode-extensions; [
      rooveterinaryinc.roo-cline
    ];
  };

  kernelcore.applications.vscode = {
    enable = true;
  };

  # Enable Remote SSH extension for VSCode-like editors
  kernelcore.applications.vscode-remote-ssh = {
    enable = true;
    installFor = [
      "vscode"
      "cursor"
      "windsurf"
    ];
  };

  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = lib.mkForce false; # PENDENTE: reativar após importar GPG keys
    };
    ssh.startAgent = lib.mkForce false; # gcr-ssh-agent (GNOME keyring) assume o papel
    ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    git.lfs.enable = true;
    zsh.enable = true;
  };
}
