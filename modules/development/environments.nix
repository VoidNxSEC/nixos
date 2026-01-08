{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.development = {
      rust.enable = mkEnableOption "Enable Rust development environment";
      go.enable = mkEnableOption "Enable Go development environment";
      python.enable = mkEnableOption "Enable Python development environment";
      nodejs.enable = mkEnableOption "Enable Node.js development environment";
      nix.enable = mkEnableOption "Enable Nix development tools";
    };
  };

  config = mkMerge [
    (mkIf config.kernelcore.development.rust.enable {
      environment.systemPackages = with pkgs; [
        rustc
        cargo
        rustfmt
        rust-analyzer
        clippy
      ];
    })

    (mkIf config.kernelcore.development.go.enable {
      environment.systemPackages = with pkgs; [
        go
        gopls
        golangci-lint
      ];
    })

    (mkIf config.kernelcore.development.python.enable {
      environment.systemPackages = with pkgs; [
        python313
        python313Packages.pip
        python313Packages.virtualenv
        python313Packages.uv
        poetry
        ruff
        black
      ];
    })

    (mkIf config.kernelcore.development.nodejs.enable {
      environment.systemPackages = with pkgs; [
        nodejs_24
        nodePackages.npm
        nodePackages.pnpm
        nodePackages.yarn
        nodePackages.typescript
        nodePackages.eslint
      ];
    })

    (mkIf config.kernelcore.development.nix.enable {
      environment.systemPackages = with pkgs; [
        nixfmt
        nil
        nixd
        nix-tree
        nix-output-monitor
        nvd
      ];
    })
  ];
}
