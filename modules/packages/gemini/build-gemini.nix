{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.24.0-nightly.20251231.05049b5ab";

  src = pkgs.fetchurl {
    url = "file://${./storage/gemini-cli-0.24.0-nightly.20251231.05049b5ab.tar.gz}";
    sha256 = "CZQRDxV8omFWZ+RY7MEFXGohsoN8z1iiW//PxXgOr9E=";
  };

  # Expected to fail - will be updated after first build
  npmDepsHash = "sha256-XMUqYNZGwnCYF80dz0fH0rZ0j44GVqpXfrGRJf9WCRI=";

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
