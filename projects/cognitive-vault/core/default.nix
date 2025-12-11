{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "vault-core";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  # Copy header files for use by consumers (Go CLI)
  postInstall = ''
    mkdir -p $out/include
    cp include/*.h $out/include/
  '';

  meta = with lib; {
    description = "Core crypto library for CognitiveVault";
    license = licenses.mit;
  };
}
