{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.20.0-nightly.20251127.5bed97064";

  src = pkgs.fetchurl {
    url = "file://${./storage/v0.20.0-nightly.20251127.5bed97064.tar.gz}";
    sha256 = "e56b30f34d3215fa93514088ced29d805ac4ceb75736f988e2f9d41b0e31cb8a";
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
