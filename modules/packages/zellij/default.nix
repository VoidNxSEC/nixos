# Zellij Terminal Multiplexer
#
# Self-contained package - no external dependencies
# Version auto-updated via nvfetcher in ../../_sources/
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.zellij;

  # Source from nvfetcher (auto-updated)
  sources = pkgs.callPackage ../../_sources/generated.nix { };

  # Zellij is a static MUSL binary - just extract and use
  package = pkgs.stdenv.mkDerivation {
    pname = "zellij";
    version = sources.zellij.version;
    src = sources.zellij.src;

    # No build needed - pre-compiled static binary
    dontBuild = true;
    dontFixup = true; # MUSL binary, no patching needed

    unpackPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
    '';

    installPhase = ''
      chmod +x $out/bin/zellij
    '';

    meta = {
      description = "A terminal workspace with batteries included";
      homepage = "https://zellij.dev";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

in
{
  options.kernelcore.packages.zellij = {
    enable = lib.mkEnableOption "Zellij terminal multiplexer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
