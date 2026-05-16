{ pkgs, inputs }:

let
  inherit (pkgs) lib;

  src = lib.cleanSourceWith {
    src = inputs.securellm-mcp.outPath;
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      !(builtins.elem base [
        ".claude"
        ".codex"
        ".env"
        ".git"
        "build"
        "node_modules"
        "result"
      ]);
  };

  spiderNixPkg = inputs.spider-nix.packages.${pkgs.system}.default;
in
pkgs.buildNpmPackage {
  pname = "securellm-mcp";
  version = "2.1.0";

  inherit src;

  env = {
    PUPPETEER_SKIP_DOWNLOAD = "1";
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "1";
  };

  npmDepsHash = "sha256-fLf5Ri20e9LTQ/QILEkAYJELrtsQdxY850Doz39m3G4=";

  buildPhase = ''
    npm run build
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server

    cp -r build $out/lib/mcp-server/
    cp package.json $out/lib/mcp-server/
    cp -r node_modules $out/lib/mcp-server/

    cat > $out/bin/securellm-mcp <<EOF
    #!${pkgs.bash}/bin/bash
    export PUPPETEER_EXECUTABLE_PATH="${pkgs.chromium}/bin/chromium"
    export PUPPETEER_SKIP_DOWNLOAD="1"
    export SPIDER_NIX_BIN="${spiderNixPkg}/bin/spider-nix"

    exec ${pkgs.nodejs}/bin/node $out/lib/mcp-server/build/src/index.js "\$@"
    EOF
    chmod +x $out/bin/securellm-mcp
  '';

  meta = with lib; {
    description = "MCP server for SecureLLM Bridge IDE integration";
    license = licenses.mit;
    maintainers = [ "kernelcore" ];
  };
}
