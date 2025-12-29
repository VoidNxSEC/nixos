{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.github-runner;
in
{
  options.kernelcore.services.github-runner = {
    enable = mkEnableOption "Enable GitHub Actions self-hosted runner";

    useSops = mkOption {
      type = types.bool;
      default = true;
      description = "Use SOPS for secret management (recommended)";
    };

    runnerType = mkOption {
      type = types.enum [
        "self-hosted"
        "organization"
        "repository"
      ];
      default = "repository";
      description = ''
        Type of runner registration:
        - repository: Register runner for a specific repository
        - organization: Register runner for entire organization
        - self-hosted: Use custom configuration
      '';
    };

    runnerName = mkOption {
      type = types.str;
      default = "nixos-self-hosted";
      description = "Name for the GitHub Actions runner";
    };

    repoUrl = mkOption {
      type = types.str;
      default = "https://github.com/VoidNxSEC/nixos";
      description = ''
        GitHub repository or organization URL:
        - Repository: https://github.com/owner/repo
        - Organization: https://github.com/organization
      '';
    };

    extraLabels = mkOption {
      type = types.listOf types.str;
      default = [
        "nixos"
        "nix"
      ];
      description = "Additional labels for the runner";
    };

    rotateRunner = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable runner rotation (remove and re-register on each start).
        Useful for ephemeral runners or testing.
        Requires fresh token on each start.
      '';
    };

    ephemeral = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run as ephemeral runner (automatically removed after each job).
        Runner will be deleted from GitHub after completing one job.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Use official NixOS GitHub Runner service
    services.github-runners."${cfg.runnerName}" = {
      enable = true;
      url = cfg.repoUrl;

      # Token from SOPS
      tokenFile =
        if cfg.useSops then config.sops.secrets."github_runner_token".path else "/etc/github-runner-token";

      name = cfg.runnerName;

      extraLabels = cfg.extraLabels;

      # Ephemeral mode
      ephemeral = cfg.ephemeral;

      # Runner package with all dependencies
      package = pkgs.github-runner;

      # Extra packages available to runner
      extraPackages = with pkgs; [
        git
        nix
        cachix
        jq
        curl
        bash
        coreutils
        git-lfs
        inetutils # hostname
        procps # free, ps, top
        gnugrep
        gnused
        gawk
        findutils
        sops # for secrets decryption
        yq-go # for YAML parsing
        nixfmt-rfc-style # for nix fmt
        age # for SOPS AGE encryption
      ];

      # Relax systemd hardening to allow Nix daemon access
      # DynamicUser + PrivateUsers blocks socket access to /nix/var/nix/daemon-socket/socket
      serviceOverrides = {
        # Allow access to Nix daemon socket
        PrivateUsers = false;
        # Allow access to /nix filesystem
        ReadWritePaths = [
          "/nix/var/nix/daemon-socket"
          "/nix/store"
        ];
        # Required for nix to work properly
        BindReadOnlyPaths = [
          "/etc/nix"
          "/nix/var/nix/db"
          "/nix/var/nix/profiles"
        ];
      };
    };

    # SOPS secret for runner token
    sops.secrets = mkIf cfg.useSops {
      "github_runner_token" = {
        sopsFile = ../../../secrets/github.yaml;
        mode = "0400";
        restartUnits = [ "github-runner-${cfg.runnerName}.service" ];
      };
    };

    # Helpful packages for CI/CD (available system-wide)
    environment.systemPackages = with pkgs; [
      git
      curl
      jq
      nix
      cachix
      gh # GitHub CLI
    ];
  };
}
