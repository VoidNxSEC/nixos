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

    cloudflare = {
      enable = mkEnableOption "Automatic Cloudflare DNS configuration";

      zoneId = mkOption {
        type = types.str;
        default = "";
        description = "Cloudflare Zone ID for domain";
        example = "abc123def456...";
      };

      apiTokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Cloudflare API token (use sops-nix)";
        example = "/run/secrets/cloudflare-api-token";
      };

      updateInterval = mkOption {
        type = types.str;
        default = "hourly";
        description = "How often to check and update DNS record";
      };
    };

    gitea = {
      adminTokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Gitea admin API token (use sops-nix)";
        example = "/run/secrets/gitea-admin-token";
      };

      autoInitRepos = mkEnableOption "Automatically create repositories on first boot";
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

    # SSL certificates setup - Copy certs with proper permissions
    systemd.services.gitea-setup-certs = {
      description = "Setup Gitea SSL certificates";
      before = [ "gitea.service" ];
      wantedBy = [ "gitea.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        mkdir -p /var/lib/gitea/custom/https
        chown gitea:gitea /var/lib/gitea/custom/https
        chmod 0750 /var/lib/gitea/custom/https

        # Copy certificates with proper permissions
        cp /home/kernelcore/localhost.crt /var/lib/gitea/custom/https/localhost.crt
        cp /home/kernelcore/localhost.key /var/lib/gitea/custom/https/localhost.key

        chown gitea:gitea /var/lib/gitea/custom/https/localhost.crt
        chown gitea:gitea /var/lib/gitea/custom/https/localhost.key
        chmod 0640 /var/lib/gitea/custom/https/localhost.crt
        chmod 0640 /var/lib/gitea/custom/https/localhost.key

        echo "✓ Gitea SSL certificates configured"
      '';
    };

    # Cloudflare DNS sync service (declarative)
    systemd.services.gitea-cloudflare-dns = mkIf cfg.cloudflare.enable {
      description = "Sync Gitea DNS record to Cloudflare";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        LoadCredential = mkIf (
          cfg.cloudflare.apiTokenFile != null
        ) "cloudflare-api-token:${cfg.cloudflare.apiTokenFile}";
      };

      script = ''
        set -euo pipefail

        # Load credentials
        if [ -z "${cfg.cloudflare.zoneId}" ]; then
          echo "⚠️  Cloudflare Zone ID not configured"
          exit 1
        fi

        if [ ! -f "$CREDENTIALS_DIRECTORY/cloudflare-api-token" ]; then
          echo "⚠️  Cloudflare API token not found in credentials"
          exit 1
        fi

        API_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/cloudflare-api-token")
        ZONE_ID="${cfg.cloudflare.zoneId}"

        # Detect public IP
        PUBLIC_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org 2>/dev/null || echo "")
        if [ -z "$PUBLIC_IP" ]; then
          echo "❌ Could not detect public IP"
          exit 1
        fi

        echo "🔍 Public IP: $PUBLIC_IP"

        # Check if DNS record exists
        EXISTING=$(${pkgs.curl}/bin/curl -s -X GET \
          "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=${cfg.domain}" \
          -H "Authorization: Bearer $API_TOKEN" \
          -H "Content-Type: application/json" | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')

        if [ -n "$EXISTING" ]; then
          # Update existing record
          echo "🔧 Updating DNS record: ${cfg.domain} → $PUBLIC_IP"
          RESULT=$(${pkgs.curl}/bin/curl -s -X PUT \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{
              \"type\": \"A\",
              \"name\": \"${cfg.domain}\",
              \"content\": \"$PUBLIC_IP\",
              \"ttl\": 1,
              \"proxied\": false
            }")
        else
          # Create new record
          echo "✨ Creating DNS record: ${cfg.domain} → $PUBLIC_IP"
          RESULT=$(${pkgs.curl}/bin/curl -s -X POST \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{
              \"type\": \"A\",
              \"name\": \"${cfg.domain}\",
              \"content\": \"$PUBLIC_IP\",
              \"ttl\": 1,
              \"proxied\": false
            }")
        fi

        # Check result
        SUCCESS=$(echo "$RESULT" | ${pkgs.jq}/bin/jq -r '.success // false')
        if [ "$SUCCESS" = "true" ]; then
          echo "✅ DNS record synced successfully"
        else
          echo "❌ Failed to sync DNS record:"
          echo "$RESULT" | ${pkgs.jq}/bin/jq -r '.errors[]?.message // "Unknown error"'
          exit 1
        fi
      '';
    };

    # Cloudflare DNS sync timer (declarative)
    systemd.timers.gitea-cloudflare-dns = mkIf cfg.cloudflare.enable {
      description = "Periodic Gitea Cloudflare DNS sync";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "5min";
        OnCalendar = cfg.cloudflare.updateInterval;
        Persistent = true;
        RandomizedDelaySec = "2m";
      };
    };

    # Gitea repository initialization (declarative, runs once)
    systemd.services.gitea-init-repos = mkIf cfg.gitea.autoInitRepos {
      description = "Initialize Gitea repositories";
      after = [ "gitea.service" ];
      requires = [ "gitea.service" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionPathExists = "!/var/lib/gitea/.repos-initialized";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "gitea";
        Group = "gitea";
        LoadCredential = mkIf (
          cfg.gitea.adminTokenFile != null
        ) "gitea-admin-token:${cfg.gitea.adminTokenFile}";
      };

      script = ''
        set -euo pipefail

        GITEA_URL="https://${cfg.domain}:${toString cfg.httpsPort}"

        if [ ! -f "$CREDENTIALS_DIRECTORY/gitea-admin-token" ]; then
          echo "⚠️  Gitea admin token not found in credentials"
          exit 1
        fi

        GITEA_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/gitea-admin-token")

        echo "🏗️  Initializing Gitea repositories..."

        ${concatMapStringsSep "\n" (project: ''
          echo "→ ${project}"
          ${pkgs.curl}/bin/curl -k -X POST "$GITEA_URL/api/v1/user/repos" \
            -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "${project}",
              "description": "Showcase project: ${project}",
              "private": false,
              "default_branch": "main"
            }' 2>&1 | ${pkgs.jq}/bin/jq -r 'if .id then "  ✓ Created" else "  ⚠️  " + (.message // "Already exists") end'
        '') cfg.projects}

        # Mark as initialized
        touch /var/lib/gitea/.repos-initialized
        echo "✅ Repository initialization complete!"
      '';
    };

    # Auto-mirror service (declarative)
    systemd.services.gitea-mirror-showcases = mkIf cfg.autoMirror.enable {
      description = "Mirror showcase projects to Gitea";
      after = [ "gitea-init-repos.service" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root"; # Needs access to user project directories
        LoadCredential = mkIf (
          cfg.gitea.adminTokenFile != null
        ) "gitea-admin-token:${cfg.gitea.adminTokenFile}";
      };

      script = ''
        set -euo pipefail

        GITEA_URL="https://${cfg.domain}:${toString cfg.httpsPort}"

        if [ ! -f "$CREDENTIALS_DIRECTORY/gitea-admin-token" ]; then
          echo "⚠️  Gitea admin token not found in credentials"
          exit 1
        fi

        GITEA_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/gitea-admin-token")

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
            git push gitea --all --tags 2>&1 || echo "  ⚠️  Push failed"
          else
            echo "  → Adding gitea remote"
            git remote add gitea "https://gitea:$GITEA_TOKEN@${cfg.domain}:${toString cfg.httpsPort}/${project}.git" 2>&1 || echo "  ⚠️  Remote add failed"
            git push gitea --all --tags 2>&1 || echo "  ⚠️  Push failed"
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
        OnBootSec = "10min";
        OnCalendar = cfg.autoMirror.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Helper command to check Gitea Showcase status
    environment.systemPackages =
      with pkgs;
      [
        curl
        jq

        (writeScriptBin "gitea-status" ''
          #!${pkgs.bash}/bin/bash

          echo "🎯 Gitea Showcase - Status"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
          echo "📍 Access: https://${cfg.domain}:${toString cfg.httpsPort}"
          echo ""

          # Gitea service
          echo "🔧 Services:"
          systemctl is-active --quiet gitea.service && echo "  ✓ gitea.service (running)" || echo "  ✗ gitea.service (stopped)"

          ${optionalString cfg.cloudflare.enable ''
            systemctl is-active --quiet gitea-cloudflare-dns.timer && echo "  ✓ gitea-cloudflare-dns.timer (active)" || echo "  ✗ gitea-cloudflare-dns.timer (inactive)"
          ''}

          ${optionalString cfg.gitea.autoInitRepos ''
            systemctl is-active --quiet gitea-init-repos.service && echo "  ✓ gitea-init-repos.service (done)" || echo "  ⏳ gitea-init-repos.service (pending)"
          ''}

          ${optionalString cfg.autoMirror.enable ''
            systemctl is-active --quiet gitea-mirror-showcases.timer && echo "  ✓ gitea-mirror-showcases.timer (active)" || echo "  ✗ gitea-mirror-showcases.timer (inactive)"
          ''}

          echo ""
          echo "📊 Quick actions:"
          echo "  gitea-logs         - View Gitea logs"
          ${optionalString cfg.cloudflare.enable ''
            echo "  gitea-dns-sync     - Trigger DNS sync now"
          ''}
          ${optionalString cfg.autoMirror.enable ''
            echo "  gitea-mirror       - Trigger mirror sync now"
          ''}
          echo "  gitea-help         - Full documentation"
          echo ""
        '')

        (writeScriptBin "gitea-logs" ''
          #!${pkgs.bash}/bin/bash
          journalctl -u gitea.service -f
        '')

        (writeScriptBin "gitea-help" ''
                  #!${pkgs.bash}/bin/bash
                  cat << 'HELP'
          ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          🎯 Gitea Showcase - Full Documentation
          ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

          📍 Access URL:
             https://${cfg.domain}:${toString cfg.httpsPort}

          🔐 First Time Setup:
             1. Access the URL above
             2. Create admin account (first user = admin)
             3. Settings > Applications > Generate Token
             4. Add token to: /etc/nixos/secrets/gitea.yaml
                → sops /etc/nixos/secrets/gitea.yaml
                → Replace gitea-admin-token: PLACEHOLDER with real token
             5. Restart services:
                → sudo systemctl restart gitea-init-repos.service
                → sudo systemctl restart gitea-mirror-showcases.service

          📊 Monitoring:
             gitea-status       - Quick status check
             gitea-logs         - View Gitea logs
             gitea-dns-sync     - Manual DNS sync (Cloudflare)
             gitea-mirror       - Manual project mirror sync

          🔧 Systemd Services:
             systemctl status gitea.service
             ${optionalString cfg.cloudflare.enable "systemctl status gitea-cloudflare-dns.timer"}
             ${optionalString cfg.gitea.autoInitRepos "systemctl status gitea-init-repos.service"}
             ${optionalString cfg.autoMirror.enable "systemctl status gitea-mirror-showcases.timer"}

          📖 Full Guide:
             /etc/nixos/docs/GITEA-SHOWCASE-DECLARATIVE-SETUP.md

          ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          HELP
        '')
      ]
      ++ lib.optionals cfg.cloudflare.enable [
        (writeScriptBin "gitea-dns-sync" ''
          #!${pkgs.bash}/bin/bash
          echo "🔄 Triggering Cloudflare DNS sync..."
          sudo systemctl start gitea-cloudflare-dns.service
          echo "📊 Watching logs (Ctrl+C to exit):"
          sudo journalctl -u gitea-cloudflare-dns.service -f
        '')
      ]
      ++ lib.optionals cfg.autoMirror.enable [
        (writeScriptBin "gitea-mirror" ''
          #!${pkgs.bash}/bin/bash
          echo "🔄 Triggering project mirror sync..."
          sudo systemctl start gitea-mirror-showcases.service
          echo "📊 Watching logs (Ctrl+C to exit):"
          sudo journalctl -u gitea-mirror-showcases.service -f
        '')
      ];

    # Firewall rules
    networking.firewall.allowedTCPPorts = [
      cfg.httpsPort
      3000
    ];

    # Local DNS resolution (for local-only access)
    networking.hosts = {
      "127.0.0.1" = [ cfg.domain ];
    };

    # Simple activation message
    system.activationScripts.gitea-showcase-setup = stringAfter [ "users" ] ''
      echo "✓ Gitea Showcase configured - Run 'gitea-status' for info"
    '';
  };
}
