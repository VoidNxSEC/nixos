{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  runnerVersion = "2.329.0";
  runnerArchive = "actions-runner-linux-x64-${runnerVersion}.tar.gz";
  runnerUrl = "https://github.com/actions/runner/releases/download/v${runnerVersion}/${runnerArchive}";

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

    runnerName = mkOption {
      type = types.str;
      default = "nixos-self-hosted";
      description = "Name for the GitHub Actions runner";
    };

    repoUrl = mkOption {
      type = types.str;
      default = "https://github.com/VoidNxSEC/nixos";
      description = "GitHub repository URL";
    };

    extraLabels = mkOption {
      type = types.listOf types.str;
      default = [
        "nixos"
        "nix"
      ];
      description = "Additional labels for the runner";
    };
  };

  config = mkIf cfg.enable {
    # Create a dedicated system user
    users.users.actions = {
      isSystemUser = true;
      group = "actions";
      createHome = true;
      home = "/var/lib/actions-runner";
      description = "GitHub Actions Runner user";
      extraGroups = [ "wheel" ]; # Add "docker" if Docker access needed
    };

    users.groups.actions = { };

    # SOPS secret for runner token
    sops.secrets = mkIf cfg.useSops {
      "github/runner/token" = {
        sopsFile = ../../../secrets/github.yaml;
        owner = "actions";
        group = "actions";
        mode = "0400";
        restartUnits = [ "actions-runner.service" ];
      };
    };

    # Environment file for runner configuration
    # Non-sensitive values are here, sensitive token comes from SOPS
    environment.etc."github-runner.env" = {
      mode = "0644";
      text = ''
        RUNNER_URL="${cfg.repoUrl}"
        RUNNER_NAME="${cfg.runnerName}"
        RUNNER_WORK_DIR="/var/lib/actions-runner/_work"
        RUNNER_LABELS="self-hosted,Linux,X64,${concatStringsSep "," cfg.extraLabels}"
      '';
    };

    systemd.services.actions-runner = {
      description = "GitHub Actions Runner (managed by NixOS)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ] ++ (optional cfg.useSops "sops-nix.service");
      wants = [ "network-online.target" ];

      serviceConfig = {
        User = "actions";
        Group = "actions";
        WorkingDirectory = "/var/lib/actions-runner";
        Restart = "always";
        RestartSec = "10s";

        # Load non-sensitive environment variables
        EnvironmentFile = [
          "/etc/github-runner.env"
        ];
      };

      # Download, extract, and configure runner
      preStart = ''
        set -euo pipefail

        # Download and extract runner if not present
        if [ ! -x /var/lib/actions-runner/run.sh ]; then
          echo "Downloading GitHub Actions runner v${runnerVersion}..."
          mkdir -p /var/lib/actions-runner
          ${pkgs.curl}/bin/curl -fsSLo /tmp/${runnerArchive} "${runnerUrl}"
          ${pkgs.gnutar}/bin/tar xzf /tmp/${runnerArchive} -C /var/lib/actions-runner
          rm /tmp/${runnerArchive}
          chown -R actions:actions /var/lib/actions-runner
          echo "Runner extracted successfully"
        fi

        # Configure runner if not already configured
        if [ ! -f /var/lib/actions-runner/.runner ]; then
          echo "Configuring runner..."

          ${
            if cfg.useSops then
              let
                tokenPath = config.sops.secrets."github/runner/token".path;
              in
              ''
                # Read token from SOPS secret
                if [ ! -f "${tokenPath}" ]; then
                  echo "ERROR: SOPS secret not found at ${tokenPath}"
                  echo "Please ensure secrets/github.yaml is encrypted and contains github.runner.token"
                  exit 1
                fi
                RUNNER_TOKEN=$(cat "${tokenPath}")
              ''
            else
              ''
                # Manual token configuration (not recommended)
                echo "WARNING: Using manual token configuration. Consider enabling SOPS."
                if [ -z "''${RUNNER_TOKEN:-}" ]; then
                  echo "ERROR: RUNNER_TOKEN environment variable not set"
                  echo "Set it manually: echo 'RUNNER_TOKEN=your-token' >> /etc/github-runner.env"
                  exit 1
                fi
              ''
          }

          if [ -z "''${RUNNER_URL:-}" ]; then
            echo "ERROR: RUNNER_URL not set"
            exit 1
          fi

          cd /var/lib/actions-runner
          ./config.sh \
            --unattended \
            --url "$RUNNER_URL" \
            --token "$RUNNER_TOKEN" \
            --name "$RUNNER_NAME" \
            --work "$RUNNER_WORK_DIR" \
            --labels "$RUNNER_LABELS"

          echo "Runner configured successfully as: $RUNNER_NAME"
        else
          echo "Runner already configured"
        fi
      '';

      script = ''
        cd /var/lib/actions-runner
        exec ./run.sh
      '';

      # Cleanup on stop
      postStop = ''
        echo "Runner service stopped"
      '';
    };

    # Helpful packages for CI/CD
    environment.systemPackages = with pkgs; [
      git
      curl
      jq
      nix
      cachix
    ];
  };
}
