{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ci;
in
{
  imports = [ ../../ci-cd/buildbot ];

  options.kernelcore.ci = {
    enable = mkEnableOption "Enable local Buildbot orchestration for the CI/CD domain";

    role = mkOption {
      type = types.enum [
        "master"
        "worker"
        "combined"
      ];
      default = "combined";
      description = "Whether this host runs the Buildbot master, worker, or both.";
    };

    title = mkOption {
      type = types.str;
      default = "Kernelcore Local CI";
      description = "Buildbot UI title.";
    };

    titleUrl = mkOption {
      type = types.str;
      default = "https://voidnx.com";
      description = "Buildbot UI title URL.";
    };

    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Logical domain label for Buildbot documentation and future exposure.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address for the Buildbot web UI.";
    };

    port = mkOption {
      type = types.port;
      default = 8010;
      description = "Buildbot web UI port.";
    };

    pbPort = mkOption {
      type = types.port;
      default = 9989;
      description = "Buildbot master port for worker connections.";
    };

    buildbotUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8010/";
      description = "Public URL advertised by Buildbot.";
    };

    worker = {
      name = mkOption {
        type = types.str;
        default = "kernelcore-local";
        description = "Logical Buildbot worker name.";
      };

      systemUser = mkOption {
        type = types.str;
        default = "bbworker";
        description = "System user running the Buildbot worker service.";
      };

      systemGroup = mkOption {
        type = types.str;
        default = "bbworker";
        description = "Primary group of the Buildbot worker service user.";
      };

      password = mkOption {
        type = types.str;
        default = "local-buildbot-pass";
        description = ''
          Local worker password used by Buildbot authentication.
          This is acceptable only for the initial local-only bridge. Move it to
          SOPS before networked or multi-host rollout.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional SOPS-backed password file for the Buildbot worker.";
      };

      masterUrl = mkOption {
        type = types.str;
        default = "127.0.0.1:9989";
        description = "Buildbot master connection string for the local worker.";
      };

      hostMessage = mkOption {
        type = types.nullOr types.str;
        default = "Local Buildbot worker on kernelcore";
        description = "Description exposed by the worker in Buildbot.";
      };

      adminMessage = mkOption {
        type = types.nullOr types.str;
        default = "kernelcore";
        description = "Administrative owner string exposed by the worker.";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra system groups granted to the worker service user.";
      };

      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          bash
          coreutils
          curl
          findutils
          gawk
          git
          gnugrep
          gnused
          jq
          nix
        ];
        description = "Packages available in the Buildbot worker execution PATH.";
      };

      memoryMax = mkOption {
        type = types.str;
        default = "8G";
        description = "Memory limit for the local Buildbot worker service.";
      };

      cpuQuota = mkOption {
        type = types.str;
        default = "400%";
        description = "CPU quota for the local Buildbot worker service.";
      };
    };

    jobs = {
      enableFlakeCheck = mkOption {
        type = types.bool;
        default = true;
        description = "Run `nix flake check --no-build path:.` in the local Buildbot pipeline.";
      };

      suites = mkOption {
        type = types.listOf types.str;
        default = [ "security" ];
        description = ''
          Suite names from `ci-cd/default.nix` executed via
          `nix build -f ./ci-cd/default.nix testSuites.<suite>`.
        '';
      };

      enableTailscaleSmoke = mkOption {
        type = types.bool;
        default = false;
        description = "Run the lightweight `tailscale-service` NixOS test as part of the local pipeline.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.worker.passwordFile == null) {
    warnings = [
      "kernelcore.ci.enable is using an inline local Buildbot worker password. Move it to SOPS before multi-host or networked rollout."
    ];
  };
}
