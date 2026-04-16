# ============================================================
# GitHub Actions Self-Hosted Runners
# ============================================================
# Description: Declarative multi-repo and org-level GitHub Actions
#              runner management. Token lifecycle handled at runtime:
#              a root oneshot service uses the PAT (github_token) to
#              force-delete stale runners and generate fresh registration
#              tokens before each runner start.
# Dependencies: services.github-runners (nixpkgs), sops-nix
# ============================================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.github-runner;

  # ── PAT secret path (long-lived, stored in SOPS) ──────────────────────────
  patSecretPath = config.sops.secrets."github_token".path;

  # ── Common packages available inside every runner job ──────────────────────
  defaultPackages = with pkgs; [
    git
    git-lfs
    nix
    cachix
    jq
    curl
    bash
    coreutils
    openssh
    inetutils
    procps
    gnugrep
    gnused
    gawk
    findutils
    sops
    yq-go
    nixfmt-rfc-style
    age
    gh
  ];

  # ── Systemd hardening relaxations required for Nix daemon access ───────────
  # NOTE: Environment is set separately via systemd.services.<name>.environment
  # because serviceOverrides.Environment doesn't handle spaces correctly.
  commonServiceOverrides = {
    PrivateUsers = false;
    ReadWritePaths = [
      "/nix/var/nix/daemon-socket"
      "/nix/store"
    ];
    BindReadOnlyPaths = [
      "/etc/nix"
      "/nix/var/nix/db"
      "/nix/var/nix/profiles"
      "/home/kernelcore/.ssh"
    ];
  };

  # ── Token refresh script ──────────────────────────────────────────────────
  # Runs as root via a separate oneshot service before each runner start.
  # Uses the stored PAT to:
  #   1. Delete any existing runner with the same name (idempotent)
  #   2. Request a fresh registration token
  #   3. Write it to /run/github-runner-<name>-regtoken
  mkTokenRefreshScript =
    name: url:
    pkgs.writeShellScript "github-runner-${name}-refresh-token" ''
      set -euo pipefail

      PAT=$(cat "${patSecretPath}")
      TOKEN_FILE="/run/github-runner-${name}-regtoken"

      # ── Derive API base URL from GitHub URL ──────────────────────────────
      PATH_PART=$(echo "${url}" | ${pkgs.gnused}/bin/sed 's|https://github.com/||')
      DEPTH=$(echo "$PATH_PART" | ${pkgs.gawk}/bin/awk -F/ '{print NF}')

      if [ "$DEPTH" -eq 1 ]; then
        API_BASE="https://api.github.com/orgs/$PATH_PART/actions/runners"
      else
        API_BASE="https://api.github.com/repos/$PATH_PART/actions/runners"
      fi

      AUTH_HEADER="Authorization: token $PAT"
      ACCEPT_HEADER="Accept: application/vnd.github+json"

      # ── 1. Force-delete existing runner by name ──────────────────────────
      RUNNER_ID=$(${pkgs.curl}/bin/curl -sf \
        -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" \
        "$API_BASE" \
        | ${pkgs.jq}/bin/jq -r \
          --arg name "${name}" \
          '.runners[] | select(.name == $name) | .id // empty') || true

      if [ -n "''${RUNNER_ID:-}" ]; then
        echo "→ Removing stale runner '${name}' (id=$RUNNER_ID)"
        ${pkgs.curl}/bin/curl -sf -X DELETE \
          -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" \
          "$API_BASE/$RUNNER_ID" || true
        echo "✓ Removed"
      fi

      # ── 2. Get fresh registration token ───────────────────────────────────
      REG_TOKEN=$(${pkgs.curl}/bin/curl -sf -X POST \
        -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" \
        "$API_BASE/registration-token" \
        | ${pkgs.jq}/bin/jq -r '.token')

      if [ -z "''${REG_TOKEN:-}" ] || [ "$REG_TOKEN" = "null" ]; then
        echo "ERROR: Failed to obtain registration token" >&2
        exit 1
      fi

      # ── 3. Write token to runtime file ────────────────────────────────────
      echo -n "$REG_TOKEN" > "$TOKEN_FILE"
      chmod 400 "$TOKEN_FILE"
      echo "✓ Token written to $TOKEN_FILE"
    '';

  # ── Helper: build one services.github-runners entry ───────────────────────
  mkRunnerEntry =
    name:
    {
      url,
      labels ? [ ],
      ephemeral ? false,
    }:
    {
      enable = true;
      inherit url ephemeral;
      name = name;
      tokenFile = "/run/github-runner-${name}-regtoken";
      extraLabels = [
        "nixos"
        "nix"
        "linux"
      ]
      ++ labels;
      package = pkgs.github-runner;
      extraPackages = defaultPackages ++ cfg.extraPackages;
      serviceOverrides = commonServiceOverrides;
    };

  # ── Build github-runners attrsets ─────────────────────────────────────────
  repoRunners = mapAttrs (
    name: r: mkRunnerEntry name { inherit (r) url labels ephemeral; }
  ) cfg.repos;

  orgRunner = optionalAttrs cfg.org.enable {
    ${cfg.org.name} = mkRunnerEntry cfg.org.name {
      url = cfg.org.url;
      labels = cfg.org.labels;
    };
  };

  # ── Token refresh oneshot services ────────────────────────────────────────
  # Separate root service per runner — clean systemd dependency, no + hacks
  mkRefreshService =
    name: url:
    nameValuePair "github-runner-${name}-token-refresh" {
      description = "Refresh GitHub Actions token for runner ${name}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      before = [ "github-runner-${name}.service" ];
      requiredBy = [ "github-runner-${name}.service" ];
      path = with pkgs; [
        coreutils
        curl
        jq
        gnused
        gawk
        bash
      ];
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "15s";
        ExecStart = mkTokenRefreshScript name url;
      };
    };

  repoRefreshServices = listToAttrs (mapAttrsToList (name: r: mkRefreshService name r.url) cfg.repos);

  orgRefreshServices = optionalAttrs cfg.org.enable (listToAttrs [
    (mkRefreshService cfg.org.name cfg.org.url)
  ]);

  # ── Environment overrides (proper quoting via NixOS environment attr) ─────
  mkEnvOverride = name: {
    "github-runner-${name}" = {
      environment.GIT_SSH_COMMAND = "ssh -i /home/kernelcore/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new";
    };
  };

  repoEnvOverrides = foldl' (acc: name: acc // mkEnvOverride name) { } (attrNames cfg.repos);

  orgEnvOverrides = if cfg.org.enable then mkEnvOverride cfg.org.name else { };

  allRunnerNames =
    map (name: "github-runner-${name}") (attrNames cfg.repos)
    ++ optional cfg.org.enable "github-runner-${cfg.org.name}";

in
{
  # ============================================================
  # OPTIONS
  # ============================================================
  options.kernelcore.services.github-runner = {
    enable = mkEnableOption "GitHub Actions self-hosted runners";

    # ── Org runner ────────────────────────────────────────────
    org = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Register a single org-level runner (serves all repos).";
      };

      url = mkOption {
        type = types.str;
        default = "https://github.com/VoidNxSEC";
        description = "Organisation URL (not a repo URL).";
      };

      name = mkOption {
        type = types.str;
        default = "kernelcore-org";
        description = "Runner display name shown in GitHub UI.";
      };

      labels = mkOption {
        type = types.listOf types.str;
        default = [ "gpu" ];
        description = "Extra labels appended to the common set [nixos, nix, linux].";
      };
    };

    # ── Per-repo runners ──────────────────────────────────────
    repos = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            url = mkOption {
              type = types.str;
              description = "Full GitHub repository URL.";
            };

            labels = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra labels beyond [nixos, nix, linux].";
            };

            ephemeral = mkOption {
              type = types.bool;
              default = false;
              description = "Runner removes itself after one job. Disable for a persistent runner.";
            };
          };
        }
      );
      default = { };
      description = ''
        Per-repo runners. Tokens are auto-refreshed via PAT.

        Example:
          spooknix.url = "https://github.com/VoidNxSEC/spooknix";
      '';
    };

    # ── Shared extras ─────────────────────────────────────────
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages available inside every runner job.";
    };
  };

  # ============================================================
  # CONFIGURATION
  # ============================================================
  config = mkIf cfg.enable {

    # 1. Runner services
    services.github-runners = orgRunner // repoRunners;

    # 2. Systemd: token refresh (oneshot) + environment overrides
    systemd.services = orgRefreshServices // repoRefreshServices // orgEnvOverrides // repoEnvOverrides;

    # 3. Nix daemon trust
    nix.settings.trusted-users = allRunnerNames;

    # 4. System packages
    environment.systemPackages = with pkgs; [
      git
      curl
      jq
      nix
      cachix
      gh
    ];

    # 5. Assertions
    assertions = [
      {
        assertion = cfg.org.enable -> (cfg.repos == { });
        message = ''
          kernelcore.services.github-runner: set either org.enable OR repos, not both.
        '';
      }
      {
        assertion = !cfg.org.enable -> (cfg.repos != { });
        message = ''
          kernelcore.services.github-runner: enable is true but no runners configured.
          Set org.enable = true OR add entries to repos = { ... }.
        '';
      }
    ];
  };
}
