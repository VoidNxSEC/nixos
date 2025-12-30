{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.gitea-showcase;
in
{
  options.services.gitea-showcase = {
    enable = mkEnableOption "Gitea with automatic showcase projects mirroring";

    domain = mkOption {
      type = types.str;
      default = "git.local";
      description = "Domain for Gitea server";
    };

    httpsPort = mkOption {
      type = types.int;
      default = 3443;
      description = "HTTPS port for Gitea";
    };

    showcaseProjectsPath = mkOption {
      type = types.str;
      default = "/home/kernelcore/dev/projects";
      description = "Path to showcase projects directory";
    };

    projects = mkOption {
      type = types.listOf types.str;
      default = [
        "ml-offload-api"
        "securellm-mcp"
        "securellm-bridge"
        "cognitive-vault"
        "vmctl"
        "spider-nix"
        "i915-governor"
        "swissknife"
        "arch-analyzer"
        "docker-hub"
        "notion-exporter"
        "nixos-hyperlab"
        "shadow-debug-pipeline"
        "ai-agent-os"
        "phantom"
        "O.W.A.S.A.K.A."
      ];
      description = "List of showcase projects to mirror";
    };

    autoMirror = {
      enable = mkEnableOption "Automatic mirroring of showcase projects";

      interval = mkOption {
        type = types.str;
        default = "hourly";
        description = "Systemd timer interval for auto-mirror (hourly, daily, weekly)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Gitea service
    services.gitea = {
      enable = true;

      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}:${toString cfg.httpsPort}/";
          HTTP_PORT = 3000;
          PROTOCOL = "https";
          HTTPS_PORT = cfg.httpsPort;
          CERT_FILE = "/var/lib/gitea/custom/https/localhost.crt";
          KEY_FILE = "/var/lib/gitea/custom/https/localhost.key";
        };

        service = {
          DISABLE_REGISTRATION = false;
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
          DEFAULT_ORG_VISIBILITY = "private";
        };

        database = {
          DB_TYPE = "sqlite3";
          HOST = "localhost";
          NAME = "gitea";
        };

        repository = {
          ROOT = "/var/lib/gitea/repositories";
          DEFAULT_BRANCH = "main";
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
        };

        # Optimize for rate limiting
        api = {
          ENABLE_SWAGGER = true;
          MAX_RESPONSE_ITEMS = 100;
        };
      };
    };

    # SSL certificates setup
    systemd.tmpfiles.rules = [
      "d /var/lib/gitea/custom/https 0750 gitea gitea -"
      "L+ /var/lib/gitea/custom/https/localhost.crt - - - - /home/kernelcore/localhost.crt"
      "L+ /var/lib/gitea/custom/https/localhost.key - - - - /home/kernelcore/localhost.key"
    ];

    # Auto-mirror script
    systemd.services.gitea-mirror-showcases = mkIf cfg.autoMirror.enable {
      description = "Mirror showcase projects to Gitea";

      serviceConfig = {
        Type = "oneshot";
        User = "gitea";
        Group = "gitea";
      };

      script = ''
        set -euo pipefail

        GITEA_URL="https://${cfg.domain}:${toString cfg.httpsPort}"
        GITEA_TOKEN_FILE="/var/lib/gitea/api-token"

        # Check if token exists, if not, print instructions
        if [ ! -f "$GITEA_TOKEN_FILE" ]; then
          echo "⚠️  Gitea API token not found!"
          echo "   Create token in Gitea UI: Settings > Applications > Generate Token"
          echo "   Save to: $GITEA_TOKEN_FILE (owned by gitea:gitea, mode 600)"
          exit 1
        fi

        GITEA_TOKEN=$(cat "$GITEA_TOKEN_FILE")

        echo "🔄 Starting showcase projects mirror..."

        ${concatMapStringsSep "\n" (project: ''
          echo "→ Processing: ${project}"

          PROJECT_PATH="${cfg.showcaseProjectsPath}/${project}"

          if [ ! -d "$PROJECT_PATH" ]; then
            echo "  ⚠️  Directory not found, skipping"
            continue
          fi

          cd "$PROJECT_PATH"

          # Check if git repo
          if [ ! -d ".git" ]; then
            echo "  ⚠️  Not a git repository, skipping"
            continue
          fi

          # Check if gitea remote exists
          if git remote get-url gitea >/dev/null 2>&1; then
            echo "  ✓ Gitea remote exists, pushing..."
            git push gitea --all --tags 2>&1 || echo "  ⚠️  Push failed (repo may not exist in Gitea yet)"
          else
            echo "  → Adding gitea remote: $GITEA_URL/${project}.git"
            git remote add gitea "https://gitea:$GITEA_TOKEN@${cfg.domain}:${toString cfg.httpsPort}/${project}.git" 2>&1 || echo "  ⚠️  Remote already exists"
            git push gitea --all --tags 2>&1 || echo "  ⚠️  Push failed (create repo in Gitea first)"
          fi
        '') cfg.projects}

        echo "✅ Mirror sync completed!"
      '';
    };

    # Timer for auto-mirror
    systemd.timers.gitea-mirror-showcases = mkIf cfg.autoMirror.enable {
      description = "Timer for Gitea showcase mirrors";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.autoMirror.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Helper script for manual mirror
    environment.systemPackages = [
      (pkgs.writeScriptBin "gitea-mirror-now" ''
        #!${pkgs.bash}/bin/bash
        echo "🚀 Triggering manual Gitea mirror..."
        sudo systemctl start gitea-mirror-showcases.service
        sudo journalctl -u gitea-mirror-showcases.service -f
      '')

      (pkgs.writeScriptBin "gitea-setup-repos" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        echo "🏗️  Gitea Setup Helper"
        echo ""
        echo "This script helps you create repositories in Gitea for all showcase projects."
        echo ""
        echo "Prerequisites:"
        echo " 1. Gitea must be running: systemctl status gitea"
        echo " 2. You need a Gitea admin account"
        echo " 3. You need an API token (Settings > Applications > Generate Token)"
        echo ""

        read -p "Enter Gitea URL (default: https://${cfg.domain}:${toString cfg.httpsPort}): " GITEA_URL
        GITEA_URL=''${GITEA_URL:-"https://${cfg.domain}:${toString cfg.httpsPort}"}

        read -p "Enter Gitea API token: " GITEA_TOKEN

        if [ -z "$GITEA_TOKEN" ]; then
          echo "❌ Token required!"
          exit 1
        fi

        # Save token for later use
        echo "$GITEA_TOKEN" | sudo tee /var/lib/gitea/api-token >/dev/null
        sudo chown gitea:gitea /var/lib/gitea/api-token
        sudo chmod 600 /var/lib/gitea/api-token

        echo ""
        echo "Creating repositories..."

        ${concatMapStringsSep "\n" (project: ''
          echo "→ ${project}"
          curl -k -X POST "$GITEA_URL/api/v1/user/repos" \
            -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "${project}",
              "description": "Showcase project: ${project}",
              "private": false,
              "default_branch": "main"
            }' 2>&1 | grep -q '"id"' && echo "  ✓ Created" || echo "  (already exists)"
        '') cfg.projects}

        echo ""
        echo "✅ Setup complete!"
        echo "   Run 'gitea-mirror-now' to sync projects"
      '')
    ];

    # Firewall rules
    networking.firewall.allowedTCPPorts = [
      cfg.httpsPort
      3000
    ];

    # Instructions on first activation
    system.activationScripts.gitea-showcase-setup = stringAfter [ "users" ] ''
      cat <<EOF

      ═══════════════════════════════════════════════════════════════
      🎯 Gitea Showcase Mirror - First Time Setup
      ═══════════════════════════════════════════════════════════════

      1. Access Gitea: https://${cfg.domain}:${toString cfg.httpsPort}
      2. Create admin account (first user becomes admin)
      3. Run: gitea-setup-repos
      4. Enable auto-mirror: gitea-mirror-now

      ═══════════════════════════════════════════════════════════════
      EOF
    '';
  };
}
