{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.19.0-nightly.20251123.dadd606c0";

  src = pkgs.fetchurl {
    url = "file://${./modules/packages/js-packages/storage/gemini-cli-v0.19.0-nightly.20251123.dadd606c0.tar.gz}";
    sha256 = "755a131a48e58822ceae8eb88954ada8a280af96bfc2004c5d9ef3637b559aef";
  };

  # Expected to fail
  npmDepsHash = "sha256-q8LMBpKL5GEgObqUl8U2wtfdraYWorwCFZylrekwGVM=";

  nodeLinker = "pnpm";

  nativeBuildInputs = with pkgs; [
    pkg-config
    python3
  ];

  buildInputs = with pkgs; [
    libsecret
  ];

  npmFlags = [ "--legacy-peer-deps" ];

  dontCheckNoBrokenSymlinks = true;
}
