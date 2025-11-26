{ pkgs, self }:

let
  mkLd = pkgs.lib.makeLibraryPath;
in
{
  # VM and ISO builds
  vm-image = self.nixosConfigurations.kernelcore.config.system.build.vm;
  iso = self.nixosConfigurations.kernelcore-iso.config.system.build.isoImage;

  # MCP Server - SecureLLM Bridge
  securellm-mcp = pkgs.buildNpmPackage rec {
    pname = "securellm-bridge-mcp";
    version = "2.0.0";

    src = ../modules/ml/integrations/mcp/server;

    npmDepsHash = "sha256-u0xDEW8vlMcyJtnMEPuVDhJv/piK6lUHKPlkAU5H6+8=";

    # Native build dependencies for better-sqlite3 and other native modules
    nativeBuildInputs = with pkgs; [
      python3
      nodePackages.node-gyp
    ];

    buildInputs = with pkgs; [
      sqlite
    ];

    # Environment variables to skip Puppeteer Chrome download
    PUPPETEER_SKIP_DOWNLOAD = "1";
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "1";

    # Allow npm to write to cache during install
    makeCacheWritable = true;

    # Skip TypeScript build - use pre-compiled files from build directory
    dontNpmBuild = true;

    # Skip scripts to avoid network access and use legacy peer deps
    npmFlags = [ "--legacy-peer-deps" ];

    # Install phase - create wrapper script
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/node_modules/securellm-bridge-mcp
      cp -r build node_modules package.json $out/lib/node_modules/securellm-bridge-mcp/

      mkdir -p $out/bin
      cat > $out/bin/securellm-mcp <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/securellm-bridge-mcp/build/src/index.js "\$@"
      EOF
      chmod +x $out/bin/securellm-mcp

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "MCP server for SecureLLM Bridge with Knowledge Management";
      homepage = "https://github.com/kernelcore/nixos";
      license = licenses.mit;
      maintainers = [ ];
      platforms = platforms.linux;
    };
  };

  # Docker images - exposed as individual packages
  image-app = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/app";
    tag = "dev";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        pkgs.bash
        pkgs.coreutils
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [ "PATH=/bin" ];
      Cmd = [
        "bash"
        "-lc"
        "echo hello-from-app"
      ];
    };
  };

  # imagem base com runtime CUDA a partir do closure Nix (sem puxar ubuntu)
  image-cuda-runtime = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/cuda-runtime";
    tag = "cuda-12";
    copyToRoot = pkgs.buildEnv {
      name = "cuda-image-root";
      paths = with pkgs; [
        bash
        coreutils
        cudatoolkit
        cudaPackages.cudnn
        cudaPackages.nccl
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [
        "LD_LIBRARY_PATH=${
          mkLd [
            pkgs.cudatoolkit
            pkgs.stdenv.cc.cc.lib
          ]
        }"
        "PATH=/bin"
      ];
      Cmd = [ "bash" ];
    };
  };
}
