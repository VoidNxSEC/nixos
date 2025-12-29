# Claude Code - AI Coding Assistant Module
#
# Provides the Claude Code CLI as a system package when enabled
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.claude;

  # Claude Code package definition
  claude-code = pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    version = "2.0.74";

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/anthropic-artifacts/claude-code/linux-x64/claude-2.0.74";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated on first build
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Install binary
      install -Dm755 $src $out/bin/claude

      # Add ripgrep to PATH (required dependency)
      wrapProgram $out/bin/claude \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "Claude Code - AI coding assistant for terminal";
      homepage = "https://claude.com/product/claude-code";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  options.kernelcore.packages.claude = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ claude-code ];
    nixpkgs.config.allowUnfree = true;
  };
}
