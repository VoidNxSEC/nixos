{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.21.0-nightly.20251211.8c83e1ea9}";

  src = pkgs.fetchurl {
    url = "file://${./storage/gemini-cli-0.21.0-nightly.20251211.8c83e1ea9.tar.gz}";
    sha256 = "f2e2e90635b0fd0ba1b933a27f6c23e107d33e7f48062de3e52e8060df367005";
  };

  # Expected to fail - will be updated after first build
  npmDepsHash = "";

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
