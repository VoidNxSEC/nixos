# GitLab Duo Nix Module
# Provides declarative configuration for GitLab Duo

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.gitlabDuo;

  # Convert YAML config to environment variables
  configToEnv =
    settings:
    let
      flatten =
        prefix: obj:
        if isAttrs obj then
          concatMapAttrs (k: v: flatten "${prefix}_${toUpper k}" v) obj
        else if isList obj then
          { "${prefix}" = concatStringsSep "," (map toString obj); }
        else
          { "${prefix}" = toString obj; };
    in
    flatten "GITLAB_DUO" settings;

in
{
  options.services.gitlabDuo = {
    enable = mkEnableOption "GitLab Duo service";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "GitLab Duo configuration settings";
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing GitLab Duo API key";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to YAML configuration file";
    };

    logLevel = mkOption {
      type = types.enum [
        "debug"
        "info"
        "warning"
        "error"
      ];
      default = "info";
      description = "Log level for GitLab Duo";
    };

    cacheEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Enable caching for GitLab Duo responses";
    };

    cacheTtl = mkOption {
      type = types.int;
      default = 3600;
      description = "Cache TTL in seconds";
    };
  };

  config = mkIf cfg.enable {
    # Install dependencies
    environment.systemPackages = with pkgs; [
      yq
      jq
      (writeShellScriptBin "validate-gitlab-duo" (builtins.readFile ./validate.sh))
      (writeShellScriptBin "load-gitlab-duo-settings" ''
        #!/usr/bin/env bash
        set -euo pipefail

        CONFIG_FILE="''${GITLAB_DUO_CONFIG_FILE:-/etc/gitlab-duo/settings.yaml}"

        if [ ! -f "$CONFIG_FILE" ]; then
          echo "Error: Configuration file not found: $CONFIG_FILE" >&2
          exit 1
        fi

        # Convert YAML to environment variables
        if command -v yq &> /dev/null; then
          yq eval -o=json "$CONFIG_FILE" | jq -r 'to_entries[] | "\(.key)=\(.value)"'
        else
          echo "Error: yq is required to load settings" >&2
          exit 1
        fi
      '')
    ];

    # Place settings file
    environment.etc."gitlab-duo/settings.yaml".source = ./settings.yaml;

    # Environment variables
    environment.variables = {
      GITLAB_DUO_ENABLED = "true";
      GITLAB_DUO_ENDPOINT = "https://gitlab.com/api/v4";
      GITLAB_DUO_CONFIG_FILE = "/etc/gitlab-duo/settings.yaml";
      GITLAB_DUO_LOG_LEVEL = cfg.logLevel;
      GITLAB_DUO_CACHE_ENABLED = toString cfg.cacheEnabled;
      GITLAB_DUO_CACHE_TTL = toString cfg.cacheTtl;
    }
    // (optionalAttrs (cfg.configFile != null) {
      GITLAB_DUO_CONFIG_FILE = cfg.configFile;
    })
    // (optionalAttrs (cfg.apiKeyFile != null) {
      GITLAB_DUO_API_KEY_FILE = cfg.apiKeyFile;
    });

    # Assertions
    assertions = [
      {
        # We only warn or require at runtime, but can check if a file path is provided
        assertion = true;
        message = "GitLab Duo configuration initialized";
      }
    ];
  };
}
