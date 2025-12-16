# Lynis Security Auditing Tool
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
  cfg = config.kernelcore.packages.lynis;

  # Source from nvfetcher (auto-updated)
  sources = pkgs.callPackage ../../_sources/generated.nix { };

  package = pkgs.stdenv.mkDerivation {
    pname = "lynis";
    version = sources.lynis.version;
    src = sources.lynis.src;

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/share/lynis
      cp -r * $out/share/lynis/

      # Create wrapper script
      cat > $out/bin/lynis << 'EOF'
      #!/bin/sh
      exec /bin/sh $out/share/lynis/lynis "$@"
      EOF
      chmod +x $out/bin/lynis

      # Fix the wrapper to use actual path
      substituteInPlace $out/bin/lynis --replace '$out' "$out"
    '';

    meta = {
      description = "Security auditing tool for Linux, macOS, and UNIX-based systems";
      homepage = "https://cisofy.com/lynis/";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.unix;
    };
  };

in
{
  options.kernelcore.packages.lynis = {
    enable = lib.mkEnableOption "Lynis security auditing tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
