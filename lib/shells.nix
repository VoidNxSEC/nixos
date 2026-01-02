{ pkgs }:

let
  mk = pkgs.mkShell;

  # Gera um trecho que carrega secrets via sops para o "envName" (pode ser "dev" ou "$NIX_DEV_ENV").
  loadSecretsHook = envName: ''
    # Carrega secrets de SOPS se existir secrets/${envName}.env.enc
    if [ -f "secrets/${envName}.env.enc" ]; then
      echo "Loading secrets from secrets/${envName}.env.enc"
      eval "$(${pkgs.sops}/bin/sops --decrypt --output-type dotenv secrets/${envName}.env.enc)"
    fi
  '';

  commonPkgs = with pkgs; [
    direnv
    nix-direnv
    git
    gh
    sops
    age
    jq
    yq
    bashInteractive
  ];

  mkScript =
    name: text:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.sops
        pkgs.bash
      ];
      text = text;
    };

  scripts = {
    # secrets-edit [env] (default: dev)
    secrets-edit = mkScript "secrets-edit" ''
      set -euo pipefail
      envname="''${1:-dev}"
      file="secrets/''${envname}.env.enc"
      mkdir -p secrets
      ${pkgs.sops}/bin/sops "$file"
    '';

    # dev-test [cmd] -> roda o cmd, padrão "echo ok"
    dev-test = mkScript "dev-test" ''
      set -euo pipefail
      # Use non-login shell to avoid sourcing user profiles (hermetic)
      ${pkgs.bash}/bin/bash -c "''${1:-echo ok}"
    '';

    # nginx-dev start|stop [backend_port]
    # Cria cert local com mkcert e sobe Nginx como reverse-proxy em https://localhost:8443 -> 127.0.0.1:backend_port
    nginx-dev = pkgs.writeShellApplication {
      name = "nginx-dev";
      runtimeInputs = [
        pkgs.nginx
        pkgs.mkcert
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.procps
      ];
      text = ''
        set -euo pipefail
        action="''${1:-start}"
        backend_port="''${2:-8000}"
        base=".dev/nginx"
        mkdir -p "$base"
        pidfile="$base/nginx.pid"
        ssl_crt="$base/localhost.crt"
        ssl_key="$base/localhost.key"
        conf="$base/nginx.conf"

        if [ "$action" = "start" ]; then
          # Cert local
          if [ ! -f "$ssl_crt" ] || [ ! -f "$ssl_key" ]; then
            echo "[nginx-dev] generating TLS cert via mkcert..."
            (cd "$base" && ${pkgs.mkcert}/bin/mkcert -key-file localhost.key -cert-file localhost.crt localhost 127.0.0.1 ::1)
          fi
          # Config
          cat > "$conf" <<EOF
          worker_processes  1;
          events { worker_connections  1024; }
          http {
            sendfile on;
            # Rate limit básica: 10 req/s com burst 20
            limit_req_zone \$binary_remote_addr zone=req_limit:10m rate=10r/s;
            # TLS moderno
            ssl_protocols TLSv1.2 TLSv1.3;
            ssl_prefer_server_ciphers on;

            server {
              listen 8443 ssl;
              server_name localhost;

              ssl_certificate     $ssl_crt;
              ssl_certificate_key $ssl_key;

              # Cabeçalhos de segurança básicos
              add_header X-Content-Type-Options nosniff always;
              add_header X-Frame-Options DENY always;
              add_header Referrer-Policy no-referrer-when-downgrade always;
              add_header Content-Security-Policy "default-src 'self' https: http: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

              location / {
                limit_req zone=req_limit burst=20 nodelay;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto https;
                proxy_pass http://127.0.0.1:${"$"}{backend_port};
              }
            }
          }
          EOF

          echo "[nginx-dev] starting https://localhost:8443 -> 127.0.0.1:$backend_port"
          ${pkgs.nginx}/bin/nginx -p "$(pwd)" -c "$conf" -g "pid $pidfile;"
          echo "[nginx-dev] PID: $(cat "$pidfile")"
        elif [ "$action" = "stop" ]; then
          if [ -f "$pidfile" ]; then
            kill "$(cat "$pidfile")" || true
            rm -f "$pidfile"
            echo "[nginx-dev] stopped"
          else
            echo "[nginx-dev] not running"
          fi
        else
          echo "usage: nginx-dev start|stop [backend_port]"
          exit 1
        fi
      '';
    };
  };
  # Seleciona python 3.13 (custom ML build) se existir no seu canal; senão cai pra 3.12.
  py =
    if pkgs ? python313_ml then
      pkgs.python313_ml
    else
      (if pkgs ? python313 then pkgs.python313 else pkgs.python312);

in
{
  default = mk {
    name = "base";
    packages = commonPkgs ++ [
      scripts.secrets-edit
      scripts.dev-test
      scripts.nginx-dev
    ];
    shellHook = ''
      # Default: dev
      export NIX_DEV_ENV="''${NIX_DEV_ENV:-dev}"
      ${loadSecretsHook "$NIX_DEV_ENV"}
      echo "env=$NIX_DEV_ENV"

      # direnv (não precisa se usar 'use flake' no .envrc)
      eval "$(${pkgs.direnv}/bin/direnv hook bash)" >/dev/null
    '';
  };

  python = mk {
    name = "python";
    packages =
      commonPkgs
      ++ (with pkgs; [
        (py.withPackages (
          ps: with ps; [
            pip
            setuptools
            wheel
            numpy
            pandas
            ipykernel
            requests
            pydantic
            # Pacote OpenAI (se faltar no seu canal, instale via uv/poetry)
            (ps.openai or null)
          ]
        ))
        uv
        pipx
        poetry
        # utilidades extras opcionais
        pre-commit
        ruff
        black
      ])
      ++ [
        scripts.secrets-edit
        scripts.nginx-dev
      ];

    # Isola pipx dentro do projeto e prepara venv via uv/poetry
    shellHook = ''
      # Carrega secrets de "dev" (altere se quiser outro)
      ${loadSecretsHook "dev"}

      # Variáveis para pipx isolado por diretório
      export PIPX_HOME="$PWD/.dev/pipx"
      export PIPX_BIN_DIR="$PWD/.dev/pipx/bin"
      export PATH="$PIPX_BIN_DIR:$PATH"
      mkdir -p "$PIPX_HOME" "$PIPX_BIN_DIR"

      # Venv gerenciado pelo uv (mais rápido), se houver pyproject.toml
      if [ -f pyproject.toml ]; then
        echo "[python] uv sync (desenvolvimento)"
        UV_CACHE_DIR="$PWD/.dev/uv-cache" ${pkgs.uv}/bin/uv sync --all-extras --dev || true
        # Ativa o venv criado pelo uv (.venv por padrão)
        if [ -f .venv/bin/activate ]; then
          . .venv/bin/activate
        fi
      fi

      # CLI’s via pipx (opcional; comenta se preferir pelo Nix)
      ${pkgs.pipx}/bin/pipx ensurepath >/dev/null 2>&1 || true
      for tool in "pre-commit" "ruff" "black"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
          ${pkgs.pipx}/bin/pipx install "$tool" || true
        fi
      done

      echo "[python] ready. OPENAI_API_KEY deve vir do sops (seus secrets)."
    '';
  };

  node = mk {
    name = "node";
    packages =
      commonPkgs
      ++ (with pkgs; [
        nodejs_20
        pnpm
        yarn
        typescript
      ]);
    shellHook = loadSecretsHook "dev";
  };

  rust = mk {
    name = "rust";
    packages =
      commonPkgs
      ++ (with pkgs; [
        rustup
        cargo-nextest
        just
      ]);
    shellHook = loadSecretsHook "dev";
  };

  infra = mk {
    name = "infra";
    packages =
      commonPkgs
      ++ (with pkgs; [
        terraform
        kubectl
        helm
        kustomize
        # awscli2  # TEMP DISABLED: nixpkgs hash mismatch (prompt-toolkit) - re-enable after upstream fix
        sops
        age
        gnupg
      ]);
    shellHook = loadSecretsHook "staging";
  };

  cuda = mk {
    name = "cuda";
    packages =
      commonPkgs
      ++ (with pkgs; [
        cudatoolkit
        cudaPackages.cuda_nvcc
        cudaPackages.cudnn
        cudaPackages.nccl
        vulkan-loader
        vulkan-tools
        nvtopPackages.full
      ]);

    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
      with pkgs;
      [
        cudatoolkit
        stdenv.cc.cc.lib
      ]
    );
    CUDA_PATH = pkgs.cudatoolkit;
    CUDA_HOME = pkgs.cudatoolkit;

    shellHook = ''
      export TORCH_CUDA_ARCH_LIST="''${TORCH_CUDA_ARCH_LIST:-8.6}"
      export CUDA_CACHE_PATH="''${TMPDIR:-/tmp}/cuda-cache"
      export CUDA_CACHE_MAXSIZE="2147483648"
      ${loadSecretsHook "dev"}
    '';
  };
}
