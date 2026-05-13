{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.gitlab-runner;
in
{
  options.kernelcore.services.gitlab-runner = {
    enable = mkEnableOption "Enable GitLab Runner service";

    useSops = mkOption {
      type = types.bool;
      default = true;
      description = "Use SOPS for secret management (recommended)";
    };

    registrationToken = mkOption {
      type = types.str;
      default = "";
      description = "GitLab Runner registration token (if not using SOPS)";
    };

    url = mkOption {
      type = types.str;
      default = "https://gitlab.com";
      description = "GitLab instance URL";
    };

    runnerName = mkOption {
      type = types.str;
      default = "nixos-gitlab-runner";
      description = "Name for the GitLab Runner";
    };

    executor = mkOption {
      type = types.enum [
        "shell"
        "docker"
        "docker+machine"
        "kubernetes"
      ];
      default = "shell";
      description = "GitLab Runner executor type";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [
        "nixos"
        "nix"
        "linux"
      ];
      description = "Tags for the GitLab Runner";
    };

    concurrent = mkOption {
      type = types.int;
      default = 4;
      description = "Maximum number of concurrent jobs";
    };

    dockerImage = mkOption {
      type = types.str;
      default = "nixos/nix:latest";
      description = "Default Docker image for Docker executor";
    };
  };

  config = mkIf cfg.enable {
    # GitLab Runner service
    services.gitlab-runner = {
      enable = true;

      settings = {
        concurrent = cfg.concurrent;
        check_interval = 3;

        runners = [
          {
            name = cfg.runnerName;
            url = cfg.url;
            token = if cfg.useSops then "$GITLAB_RUNNER_TOKEN" else cfg.registrationToken;
            executor = cfg.executor;

            # Tags for job matching
            tag_list = cfg.tags;

            # Don't run untagged jobs by default (safer)
            run_untagged = false;

            # Docker executor configuration
            docker = mkIf (cfg.executor == "docker" || cfg.executor == "docker+machine") {
              image = cfg.dockerImage;
              privileged = false;
              disable_cache = false;
              volumes = [ "/cache" ];
              shm_size = 0;
            };

            # Shell executor configuration
            shell = mkIf (cfg.executor == "shell") "bash";
          }
        ];
      };
    };

    # SOPS secret for runner token
    sops.secrets = mkIf cfg.useSops {
      "gitlab/runner/token" = {
        sopsFile = ../../../secrets/gitlab.yaml;
        owner = "gitlab-runner";
        group = "gitlab-runner";
        mode = "0400";
        restartUnits = [ "gitlab-runner.service" ];
      };
    };

    # Environment file for runner
    systemd.services.gitlab-runner = {
      serviceConfig = {
        EnvironmentFile = mkIf cfg.useSops [
          (pkgs.writeText "gitlab-runner.env" ''
            GITLAB_RUNNER_TOKEN=$(cat ${
              if cfg.useSops then
                let
                  tokenPath = config.sops.secrets."gitlab/runner/token".path;
                in
                tokenPath
              else
                "/dev/null"
            })
          '')
        ];
      };
    };

    # Useful packages for CI/CD in shell executor
    environment.systemPackages = with pkgs; [
      git
      git-lfs
      curl
      jq
      nix
      cachix
      docker # For Docker executor
    ];

    # Add gitlab-runner user to docker group if using docker executor
    users.users.gitlab-runner = mkIf (cfg.executor == "docker" || cfg.executor == "docker+machine") {
      extraGroups = [ "docker" ];
    };
  };
}
