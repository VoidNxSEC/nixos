{ pkgs, sops-nix, ... }:

let
  # Pacotes comuns a todos os ambientes
  commonPackages = with pkgs; [
    sops
    age
    jq
    yq-go
  ];

  # Factory function para criar shells
  mkEnvShell =
    {
      name,
      tfVersion ? pkgs.terraform,
      extraPackages ? [ ],
      secrets ? null,
    }:
    pkgs.mkShell {
      packages = commonPackages ++ [ tfVersion ] ++ extraPackages;

      shellHook = ''
        export ENV_NAME="${name}"
        export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
        ${
          if secrets != null then
            ''
              export TF_VAR_secrets_file="${secrets}"
            ''
          else
            ""
        }

        echo "🔐 Environment: ${name}"
        echo "📦 Terraform: $(terraform version -json | jq -r .terraform_version)"

        # Aliases úteis por ambiente
        alias tf='terraform'
        alias tfa='terraform apply'
        alias tfp='terraform plan'
        ${
          if name == "prod" then
            ''
              echo "⚠️  PRODUCTION - Tenha cuidado!"
              alias tfa='echo "Use: terraform apply -auto-approve=false"; terraform apply'
            ''
          else
            ""
        }
      '';
    };

in
{
  # Shell padrão (desenvolvimento local)
  default = mkEnvShell {
    name = "dev";
    extraPackages = with pkgs; [
      kubectl
      # awscli2  # TEMP DISABLED: nixpkgs hash mismatch (prompt-toolkit) - re-enable after upstream fix
      docker-compose
    ];
  };

  # Produção
  prod = mkEnvShell {
    name = "prod";
    tfVersion = pkgs.terraform; # versão específica se quiser
    secrets = ./secrets/prod.yaml;
    extraPackages = with pkgs; [
      # awscli2  # TEMP DISABLED: nixpkgs hash mismatch (prompt-toolkit) - re-enable after upstream fix
      kubectl
    ];
  };

  # Staging
  staging = mkEnvShell {
    name = "staging";
    secrets = ./secrets/staging.yaml;
    extraPackages = with pkgs; [
      # awscli2  # TEMP DISABLED: nixpkgs hash mismatch (prompt-toolkit) - re-enable after upstream fix
      kubectl
    ];
  };

  # Sandbox/Testing
  sandbox = mkEnvShell {
    name = "sandbox";
    extraPackages = with pkgs; [
      terraform-docs
      tflint
      trivy # security scanning
    ];
  };

  imports = [ sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ./secrets/prod.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets.db_password = {
      owner = "postgres";
    };
  };
}
