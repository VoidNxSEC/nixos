# lib/packages.nix - Exported packages for the flake
# VM, ISO builds and Docker images
{
  pkgs,
  self,
  inputs ? { },
}:

let
  mkLd = pkgs.lib.makeLibraryPath;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # VM and ISO builds
  vm-image = self.nixosConfigurations.kernelcore.config.system.build.vm;
  iso = self.nixosConfigurations.kernelcore-iso.config.system.build.isoImage;

  # SecureLLM MCP - from external flake input
  securellm-mcp = import ../pkgs/securellm-mcp.nix { inherit pkgs inputs; };

  # ── Documentação automática das options kernelcore.* ──
  # Gera Markdown (CommonMark) a partir das declarações de options do
  # módulo-sistema, com nome, tipo, default, descrição e arquivo de origem.
  # Uso: nix build .#options-doc  → result/ contém options.md
  # Consumido pelo workflow docs.yml para publicar no GitHub Pages.
  options-doc =
    let
      eval = self.nixosConfigurations.kernelcore;
      doc = pkgs.nixosOptionsDoc {
        options = eval.options.kernelcore;
        # descrições ausentes viram warning, não erro — o objetivo é
        # documentar o que existe, não travar CI enquanto a Fase 6
        # (documentação inline completa) não termina.
        warningsAreErrors = false;
        transformOptions =
          opt:
          opt
          // {
            # troca o caminho absoluto do nix store pelo caminho relativo
            # do repo, com link para o arquivo no GitHub
            declarations = map (
              d:
              let
                rel = pkgs.lib.removePrefix "${self}/" (toString d);
              in
              {
                name = rel;
                url = "https://github.com/VoidNxSEC/nixos/blob/main/${rel}";
              }
            ) opt.declarations;
          };
      };
    in
    pkgs.runCommand "kernelcore-options-doc" { } ''
      mkdir -p $out
      cp ${doc.optionsCommonMark} $out/options.md
    '';

  #securellm-bridge =
  #  inputs.securellm-bridge.packages.${system}.default
  #    or inputs.securellm-bridge.packages.${system}.securellm-bridge or null;

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

  # imagem base com runtime CUDA a partir do closure Nix
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

  # ============================================
  # ML/AI Docker Images
  # ============================================

  # Ollama image with CUDA support
  image-ollama = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/ollama";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "ollama-root";
      paths = with pkgs; [
        bash
        coreutils
        ollama
        cudatoolkit
      ];
      pathsToLink = [
        "/bin"
        "/lib"
      ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "LD_LIBRARY_PATH=${mkLd [ pkgs.cudatoolkit ]}"
        "OLLAMA_HOST=0.0.0.0:11434"
      ];
      ExposedPorts = {
        "11434/tcp" = { };
      };
      Cmd = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
    };
  };

  # Python ML development image
  image-python-ml = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/python-ml";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "python-ml-root";
      paths = with pkgs; [
        bash
        coreutils
        python313
        python313Packages.pip
        python313Packages.numpy
        python313Packages.pandas
        python313Packages.scikit-learn
        python313Packages.torch
        python313Packages.torchvision
        python313Packages.jupyterlab
        git
        curl
        wget
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "PYTHONUNBUFFERED=1"
      ];
      WorkingDir = "/workspace";
      ExposedPorts = {
        "8888/tcp" = { };
      };
      Cmd = [
        "${pkgs.python313Packages.jupyterlab}/bin/jupyter-lab"
        "--ip=0.0.0.0"
        "--port=8888"
        "--no-browser"
        "--allow-root"
      ];
    };
  };

  # Node.js development image
  image-nodejs-dev = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/nodejs-dev";
    tag = "22";
    copyToRoot = pkgs.buildEnv {
      name = "nodejs-root";
      paths = with pkgs; [
        bash
        coreutils
        nodejs_24
        #nodePackages.npm
        #nodePackages.pnpm
        #nodePackages.yarn
        git
        curl
        wget
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "NODE_ENV=development"
      ];
      WorkingDir = "/app";
      ExposedPorts = {
        "3000/tcp" = { };
      };
      Cmd = [ "bash" ];
    };
  };

  # Go development image
  image-go-dev = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/go-dev";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "go-root";
      paths = with pkgs; [
        bash
        coreutils
        go
        gopls
        golangci-lint
        git
        curl
        wget
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "GOPATH=/go"
      ];
      WorkingDir = "/workspace";
      Cmd = [ "bash" ];
    };
  };

  # PostgreSQL development image
  image-postgres-dev = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/postgres-dev";
    tag = "16";
    copyToRoot = pkgs.buildEnv {
      name = "postgres-root";
      paths = with pkgs; [
        bash
        coreutils
        postgresql_16
        curl
      ];
      pathsToLink = [
        "/bin"
        "/lib"
        "/share"
      ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "PGDATA=/var/lib/postgresql/data"
      ];
      ExposedPorts = {
        "5432/tcp" = { };
      };
      User = "postgres";
      Cmd = [
        "${pkgs.postgresql_16}/bin/postgres"
        "-D"
        "/var/lib/postgresql/data"
      ];
    };
  };

  # Nginx reverse proxy image
  image-nginx-proxy = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/nginx-proxy";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "nginx-root";
      paths = with pkgs; [
        bash
        coreutils
        nginx
        curl
      ];
      pathsToLink = [
        "/bin"
        "/etc"
      ];
    };
    config = {
      Env = [ "PATH=/bin" ];
      ExposedPorts = {
        "80/tcp" = { };
        "443/tcp" = { };
      };
      Cmd = [
        "${pkgs.nginx}/bin/nginx"
        "-g"
        "daemon off;"
      ];
    };
  };

  # Redis cache image
  image-redis = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/redis";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "redis-root";
      paths = with pkgs; [
        bash
        coreutils
        redis
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [ "PATH=/bin" ];
      ExposedPorts = {
        "6379/tcp" = { };
      };
      Cmd = [
        "${pkgs.redis}/bin/redis-server"
        "--bind"
        "0.0.0.0"
      ];
    };
  };
}
