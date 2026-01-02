{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.21.0-nightly.20251210.d90356e8a";

  src = pkgs.fetchurl {
    url = "file://${./storage/gemini-cli-0.21.0-nightly.20251210.d90356e8a.tar.gz}";
    sha256 = "a31636666208cbf4d06220dc782c216efcbd7c7c83548f5c603d1682d6712f5e";
  };

  # Expected to fail - will be updated after first build
  npmDepsHash = "sha256-M4Q5/vTzLaxJYP1qdc8EP6VlqcUpeZwyZRGENxfU8mw=";

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
