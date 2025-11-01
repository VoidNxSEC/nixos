{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.sops;
in
{
  options.kernelcore.secrets.sops = {
    enable = mkEnableOption "Enable SOPS secrets management";

    secretsPath = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets";
      description = "Path to secrets directory";
    };

    ageKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to AGE key file";
    };
  };

  config = mkIf cfg.enable {
    # SOPS-nix integration
    # Note: Requires sops-nix flake input

    # Create secrets directory structure
    # Note: 0755 permissions are safe since files are SOPS-encrypted
    # This allows git/nix flake check to read the encrypted files
    systemd.tmpfiles.rules = [
      "d ${cfg.secretsPath} 0755 root root -"
      "d ${cfg.secretsPath}/env 0755 root root -"
      "d ${cfg.secretsPath}/api-keys 0755 root root -"
      "d ${cfg.secretsPath}/certificates 0755 root root -"
      "d ${cfg.secretsPath}/ssh 0755 root root -"
      "d ${cfg.secretsPath}/ssh-keys 0755 root root -"
      "d ${cfg.secretsPath}/vpn 0755 root root -"
      "d ${cfg.secretsPath}/database 0755 root root -"
      "d ${cfg.secretsPath}/docker 0755 root root -"

      # AGE keys directory (keep restricted)
      "d /var/lib/sops-nix 0700 root root -"
    ];

    # Example secrets structure (to be populated by user)
    environment.etc."secrets-template.yaml" = {
      mode = "0600";
      text = ''
        # SOPS Secrets Template
        # Encrypt with: sops -e secrets-template.yaml > secrets/encrypted.yaml
        # Decrypt with: sops -d secrets/encrypted.yaml

        # API Keys
        api_keys:
          github_token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          nordvpn_token: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          anthropic_api_key: "sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          openai_api_key: "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          huggingface_token: "hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

        # VPN Credentials
        vpn:
          nordvpn:
            username: "user@example.com"
            password: "securepassword"

        # Database Credentials
        database:
          postgresql:
            password: "pgpassword"
          mongodb:
            password: "mongopassword"

        # SSH Keys (base64 encoded)
        ssh:
          private_key: "LS0tLS1CRUd...=="
          public_key: "ssh-ed25519 AAAA...=="

        # Docker Registry
        docker:
          registry:
            username: "dockeruser"
            password: "dockerpass"

        # Environment Variables
        env:
          ANTHROPIC_API_KEY: "sk-ant-xxxxxxxxxxxxx"
          DATABASE_URL: "postgresql://user:pass@localhost/db"
      '';
    };

    # SOPS configuration file
    environment.etc."sops.yaml" = {
      mode = "0644";
      text = ''
        # SOPS Configuration
        creation_rules:
          - path_regex: secrets/.*\.yaml$
            age: >-
              age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

          - path_regex: secrets/env/.*
            age: >-
              age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

        # Key groups
        keys:
          - &admin age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          - &system age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      '';
    };

    # Tools for secrets management
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    # Convenience aliases
    environment.shellAliases = {
      sops-edit = "${pkgs.sops}/bin/sops ${cfg.secretsPath}/secrets.yaml";
      sops-encrypt = "${pkgs.sops}/bin/sops -e";
      sops-decrypt = "${pkgs.sops}/bin/sops -d";
      age-keygen = "${pkgs.age}/bin/age-keygen";
    };
  };
}
