# Claude Code - Native binary (linux-x64)
#
# Baseado no pattern de sadjow/claude-code-nix.
# dontStrip é crítico: o binário nativo é Bun com trailer próprio — strip corrompe.
#
# Para atualizar:
# 1. Muda `version`
# 2. nix-prefetch-url https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/<version>/linux-x64/claude
# 3. nix hash to-sri --type sha256 <hash>
# 4. Cola em `binaryHash`
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.claude;

  version = "2.1.92";
  binaryHash = "sha256-4iMkUUln/y1en5Hw7jfkZ1v4tt/sJ/r7GcslzFsj/K8=";

  claude-code = pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/linux-x64/claude";
      hash = binaryHash;
    };

    nativeBuildInputs = [
      pkgs.makeBinaryWrapper
      pkgs.autoPatchelfHook
    ];

    # Bun binary has a custom trailer — stripping corrupts it
    dontStrip = true;
    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      install -m755 $src $out/bin/.claude-unwrapped

      makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --set USE_BUILTIN_RIPGREP 0 \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.procps
            pkgs.ripgrep
            pkgs.bubblewrap
            pkgs.socat
          ]
        }
    '';

    meta = {
      description = "Claude Code - AI coding assistant in your terminal";
      homepage = "https://www.anthropic.com/claude-code";
      license = lib.licenses.unfree;
      mainProgram = "claude";
    };
  };

in
{
  options.kernelcore.packages.claude = {
    enable = lib.mkEnableOption "Claude Code (native binary)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ claude-code ];
  };
}
