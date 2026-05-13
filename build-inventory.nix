# build-inventory.nix
# Package inventory for remote build server
# Generated: 2026-01-25
#
# Usage on build server:
# 1. Copy this file to build server
# 2. nix-build build-inventory.nix
# 3. nix copy --to 'http://192.168.15.7:5000' $(readlink result)
# 4. Build server pushes to local cache, laptop downloads

{
  pkgs ? import <nixpkgs> { config.allowUnfree = true; },
}:

let
  # Large/Heavy packages that take long to build
  heavyPackages = with pkgs; [
    # Chromium family (30-90 min each)
    chromium
    brave
    vscodium
    vscode

    # Electron apps (10-30 min each)
    obs-studio

    # CUDA packages (ML/AI workloads)
    cudaPackages.cuda_cccl
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cupti
    cudaPackages.libcublas
    cudaPackages.libcufft
    cudaPackages.libcurand
    cudaPackages.libcusolver
    cudaPackages.libcusparse
    cudaPackages.libnpp

    # Python ML packages (heavy dependencies)
    # python312Packages.vllm  # If available
    python312Packages.torch
    python312Packages.numpy
    python312Packages.transformers

    # Hyprland (compositor)
    hyprland
    xdg-desktop-portal-hyprland

    # Desktop environment
    gnome-shell
    gnome-control-center
  ];

  # System packages (installed via environment.systemPackages)
  systemPackages = with pkgs; [
    # Shells
    zsh
    bash
    fish

    # Development
    git
    neovim
    tmux

    # Nix tools
    nixd
    nil
    pkgs.nixfmt
    nix-tree
    nix-du

    # Security
    age
    sops

    # Networking
    wireguard-tools
    tailscale
    cloudflared

    # Containers
    docker
    docker-compose
    podman

    # Monitoring
    htop
    btop
    glances

    # Browsers
    firefox

    # Communication
    telegram-desktop
    discord

    # Media
    mpv
    vlc

    # Utilities
    curl
    wget
    jq
    yq
    ripgrep
    fd
    fzf
    eza
    bat

    # Python
    python312Full
    python312Packages.pip
    python312Packages.poetry-core
    python312Packages.virtualenv

    # Node.js
    nodejs_22
    nodePackages.npm
    nodePackages.pnpm
    nodePackages.yarn

    # Rust
    rustc
    cargo
    rustfmt
    clippy

    # Go
    go

    # C/C++
    gcc
    clang
    cmake
    gnumake

    # Fonts
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "JetBrainsMono"
      ];
    })
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # All packages combined
  allPackages = heavyPackages ++ systemPackages;

in
{
  # Create a derivation that depends on all packages
  inventory = pkgs.buildEnv {
    name = "nixos-laptop-inventory";
    paths = allPackages;
    pathsToLink = [ "/" ];
  };

  # Individual package sets for selective building
  heavy = pkgs.buildEnv {
    name = "heavy-packages";
    paths = heavyPackages;
  };

  system = pkgs.buildEnv {
    name = "system-packages";
    paths = systemPackages;
  };
}
