# Gemini CLI - Google AI Agent for Terminal
#
# Self-contained package - FOD from npm registry
# Monorepo workspace não funciona com buildNpmPackage, FOD resolve
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.gemini-cli;
  version = "0.1.25";

  # FOD: Fixed Output Derivation - permite network, hasheia output
  gemini-npm = pkgs.stdenvNoCC.mkDerivation {
    pname = "gemini-cli-npm";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = with pkgs; [
      nodejs
      cacert
    ];

    buildPhase = ''
      export HOME=$PWD
      export npm_config_cache=$PWD/.npm
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      npm install -g @google/gemini-cli@${version} --prefix=$out
    '';

    dontInstall = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = lib.fakeHash; # Build 1x, pega hash do erro, cola aqui
  };

  package = pkgs.symlinkJoin {
    name = "gemini-cli-${version}";
    paths = [ gemini-npm ];
    buildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm -f $out/bin/gemini
      makeBinaryWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
        --add-flags "$out/lib/node_modules/@google/gemini-cli/dist/index.js" \
        --set NODE_PATH "$out/lib/node_modules" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libsecret ]} \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.git
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.xdg-utils
          ]
        }
    '';
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
