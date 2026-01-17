# Integration Guide for GitLab Duo Nix Configuration

## Como Integrar no Seu Flake Principal

Se você quer integrar a configuração do GitLab Duo no seu `flake.nix` principal, siga estes passos:

### Opção 1: Usar como Input (Recomendado)

```nix
# No seu flake.nix principal
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  flake-utils.url = "github:numtide/flake-utils";
  gitlab-duo.url = "path:./nix";  # Referencia local
};

outputs = { self, nixpkgs, flake-utils, gitlab-duo }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = pkgs.mkShell {
        # Herdar configuração do GitLab Duo
        shellHook = ''
          # GitLab Duo Configuration
          export GITLAB_DUO_ENABLED=true
          export GITLAB_DUO_ENDPOINT="https://gitlab.com/api/v4"
          export GITLAB_DUO_FEATURES_CODE_COMPLETION=true
          export GITLAB_DUO_FEATURES_CODE_REVIEW=true
          export GITLAB_DUO_FEATURES_SECURITY_SCANNING=true
          export GITLAB_DUO_FEATURES_DOCUMENTATION=true
          export GITLAB_DUO_MODEL_CODE_GENERATION="claude-3-5-sonnet"
          export GITLAB_DUO_MODEL_CODE_REVIEW="claude-3-5-sonnet"
          export GITLAB_DUO_MODEL_SECURITY="claude-3-5-sonnet"
          export GITLAB_DUO_RATE_LIMIT_RPM=60
          export GITLAB_DUO_RATE_LIMIT_TPM=90000
          export GITLAB_DUO_CACHE_ENABLED=true
          export GITLAB_DUO_CACHE_TTL=3600
          export GITLAB_DUO_LOG_LEVEL="info"
          export GITLAB_DUO_LOG_FORMAT="json"

          # Load API key
          if [ -f ~/.config/gitlab-duo/api-key ]; then
            export GITLAB_DUO_API_KEY=$(cat ~/.config/gitlab-duo/api-key)
          fi

          mkdir -p ./logs/gitlab-duo
        '';
      };
    }
  );
```

### Opção 2: Usar Módulo Nix

```nix
# No seu flake.nix principal
{
  imports = [ ./nix/gitlab-duo/module.nix ];

  services.gitlabDuo = {
    enable = true;
    logLevel = "info";
    cacheEnabled = true;
    cacheTtl = 3600;
  };
}
```

### Opção 3: Usar Separadamente (Atual)

Manter `nix/` como repositório separado e usar:

```bash
# Entrar no ambiente GitLab Duo
nix develop ./nix

# Ou do seu flake principal
nix develop
```

## Estrutura Recomendada

```
projeto/
├── flake.nix                    # Seu flake principal
├── nix/                         # GitLab Duo (desacoplado)
│   ├── flake.nix
│   ├── gitlab-duo/
│   │   ├── settings.yaml
│   │   ├── module.nix
│   │   └── default.nix
│   ├── modules/
│   │   └── default.nix
│   ├── scripts/
│   │   └── validate-gitlab-duo.sh
│   └── README.md
└── ...
```

## Vantagens da Abordagem Desacoplada

✓ **Independência**: GitLab Duo pode ser versionado separadamente
✓ **Reutilização**: Pode ser usado em múltiplos projetos
✓ **Manutenção**: Atualizações sem afetar o projeto principal
✓ **Clareza**: Separação clara de responsabilidades
✓ **Flexibilidade**: Fácil de ativar/desativar

## Próximos Passos

1. Configurar API key: `mkdir -p ~/.config/gitlab-duo && echo "key" > ~/.config/gitlab-duo/api-key`
2. Testar: `nix develop ./nix`
3. Validar: `bash nix/scripts/validate-gitlab-duo.sh`
4. Integrar no seu flake principal se necessário
