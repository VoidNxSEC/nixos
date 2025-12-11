{ lib, buildGoModule, vaultCore, pkg-config }:

buildGoModule {
  pname = "cvault";
  version = "0.1.0";

  src = ./.;

  # First run will fail, providing the correct hash
  vendorHash = "sha256-9jK3jKbFp+5WSQfMbNzwIB55bC5KScZOaFHItffTF00=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ vaultCore ];

  # Configure CGO to use the library from vaultCore
  preBuild = ''
    export CGO_CFLAGS="-I${vaultCore}/include"
    export CGO_LDFLAGS="-L${vaultCore}/lib -lvault_core"
    export CGO_ENABLED=1
  '';
  
  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "CognitiveVault CLI";
    license = licenses.mit;
    mainProgram = "cvault";
  };
}
