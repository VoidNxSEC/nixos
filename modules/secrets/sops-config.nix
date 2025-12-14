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

        # API Keys (replace with your encrypted values)
        api_keys:
          github_token: "<YOUR_GITHUB_TOKEN>"
          nordvpn_token: "<YOUR_NORDVPN_TOKEN>"
          anthropic_api_key: "<YOUR_ANTHROPIC_API_KEY>"
          openai_api_key: "<YOUR_OPENAI_API_KEY>"
          huggingface_token: "<YOUR_HUGGINGFACE_TOKEN>"

        # VPN Credentials
        vpn:
          nordvpn:
            username: "<YOUR_VPN_USERNAME>"
            password: "<YOUR_VPN_PASSWORD>"

        # Database Credentials
        database:
          postgresql:
            password: "<YOUR_POSTGRES_PASSWORD>"
          mongodb:
            password: "<YOUR_MONGO_PASSWORD>"

        # SSH Keys (base64 encoded)
        ssh:
          private_key: "<YOUR_PRIVATE_KEY_BASE64>"
          public_key: "<YOUR_PUBLIC_KEY>"

        # Docker Registry
        docker:
          registry:
            username: "<YOUR_DOCKER_USERNAME>"
            password: "<YOUR_DOCKER_PASSWORD>"

        # Environment Variables
        env:
          ANTHROPIC_API_KEY: "<YOUR_ANTHROPIC_API_KEY>"
          DATABASE_URL: "<YOUR_DATABASE_URL>"
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
