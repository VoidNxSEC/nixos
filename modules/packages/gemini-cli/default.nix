# Google Gemini CLI
#
# Self-contained package - no external dependencies
# Using official nightly release tarball
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;

  package = pkgs.buildNpmPackage {
    pname = "gemini-cli";
    version = "0.21.0-nightly.20251216";

    src = pkgs.fetchzip {
      url = "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.21.0-nightly.20251216.bb0c0d8ee.tar.gz";
      hash = "sha256-JUTjHd914dcNjnWS1AjXDASt0PVFNVtXAHgpiNIwZMU=";
    };

    npmDepsHash = "sha256-EQRAeVC9xJRoztl89g0QINMd10I4zSITISQpdkSMEuY=";

    # Native dependencies for keytar
    nativeBuildInputs = with pkgs; [
      pkg-config
      python3
      git
    ];
    buildInputs = with pkgs; [ libsecret ];

    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmInstall = true; # Skip default install, use custom

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gemini-cli $out/bin

      # Copy monorepo workspace packages (needed for symlinks to work)
      cp -r packages $out/lib/gemini-cli/

      # Copy node_modules
      cp -rL node_modules $out/lib/gemini-cli/ || cp -r node_modules $out/lib/gemini-cli/

      # Create executable wrapper
      cat > $out/bin/gemini << EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.nodejs}/bin/node $out/lib/gemini-cli/packages/cli/dist/index.js "\$@"
      EOF
      chmod +x $out/bin/gemini

      runHook postInstall
    '';

    # Skip broken symlink check - monorepo has internal workspace links
    dontCheckNoBrokenSymlinks = true;

    meta = {
      description = "CLI tool for Google's Gemini Generative AI API";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = lib.licenses.asl20;
      platforms = lib.platforms.all;
    };
  };

in
{
  options.kernelcore.packages.gemini-cli = {
    enable = lib.mkEnableOption "Google Gemini CLI";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
