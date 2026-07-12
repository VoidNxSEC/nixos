{ lib, pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# PACOTES — systemPackages, pacotes custom kernelcore, nixpkgs config
# ═══════════════════════════════════════════════════════════

{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
  nixpkgs.config.nvidia.acceptLicense = true;
  nixpkgs.config.packageOverrides = pkgs: {
    ltrace = pkgs.ltrace.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  # ── Pacotes custom kernelcore ──
  kernelcore.packages = {
    claude.enable = true;
    zellij.enable = false;
    lynis.enable = true;
    "brev-cli".enable = true;
    js.enable = false;
    f5-tts.enable = lib.mkForce false;
    hubstaff.enable = false;

    # Custom individual packaging for Gemini/Antigravity
    custom = {
      gemini = {
        enable = false; # Set to true to enable custom Gemini build
        sandbox = false;
        allowedPaths = [
          "$HOME/.gemini"
          "/etc/nixos"
          "$HOME/dev"
        ];
        blockHardware = [
          "camera"
          "bluetooth"
        ];
      };

      antigravity = {
        enable = false; # Set to true to enable custom Antigravity build
        profile = "balanced"; # Options: performance, balanced, minimal
        enableCache = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    ninja
    cudatoolkit
    cmake
    gcc
    # ffmpeg # TEMPORARILY DISABLED: Build broken in current nixpkgs
    yt-dlp
    cri-tools
    docker-compose
    docker-buildx
    docker
    gnumake
    libfido2
    python313Packages.pyudev
    libudev0-shim
    libusb1
    trezord
    trezor-udev-rules
    rust-analyzer
    bat
    gdb
    lldb
    strace
    valgrind
    perf
    heaptrack
    hotspot
    sysstat
    bpftrace
    iotop
    nethogs
    iftop
    nmon
    atop
    lsof
    tcpdump
    # wireshark # hash mismatch upstream — re-enable after nixpkgs fix
    # tshark # same source as wireshark (wireshark-cli) — hash mismatch upstream
    gemini-cli
    sqlite
    #lxc
    incus
    evince
    # antigravity # Replaced by custom build
    pcsx2
    postman
    bruno
  ];
}
