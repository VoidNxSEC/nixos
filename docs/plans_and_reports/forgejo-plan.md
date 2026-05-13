Adaptar na infra atual

nixos/
├── flake.nix
├── hosts/
│ └── forge/
│ ├── default.nix # Host entry point
│ └── hardware-configuration.nix
└── modules/
└── forgejo/
├── default.nix # Module aggregator
├── service.nix # Core Forgejo service
├── database.nix # PostgreSQL configuration
├── nginx.nix # Reverse proxy + TLS
├── actions-runner.nix # Forgejo Actions runner
├── backup.nix # Automated backups
├── monitoring.nix # Prometheus + Grafana
├── hardening.nix # Security hardening
├── mail.nix # SMTP notification config
└── secrets.nix # SOPS/AGE secret management

flake.nix

{
description = "NixOS — Forgejo Self-Hosted Git Forge";

inputs = {
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
sops-nix = {
url = "github:Mic92/sops-nix";
inputs.nixpkgs.follows = "nixpkgs";
};
disko = {
url = "github:nix-community/disko";
inputs.nixpkgs.follows = "nixpkgs";
};
};

outputs = { self, nixpkgs, sops-nix, disko, ... }:
{
nixosConfigurations.forge = nixpkgs.lib.nixosSystem {
system = "x86_64-linux";
modules = [
./hosts/forge
./modules/forgejo
sops-nix.nixosModules.sops
disko.nixosModules.disko
];
};
};
}

## modules/forgejo/default.nix

Agregador que importa todos os sub-módulos:

{ ... }:
{
imports = [
./service.nix
./database.nix
./nginx.nix
./actions-runner.nix
./backup.nix
./monitoring.nix
./hardening.nix
./mail.nix
./secrets.nix
];
}

## modules/forgejo/secrets.nix

Gerenciamento de secrets com SOPS + AGE:

{ config, ... }:
{
sops = {
defaultSopsFile = ../../secrets/forgejo.yaml;
age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      "forgejo/db-password" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/secret-key" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/internal-token" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/oauth2-jwt-secret" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/lfs-jwt-secret" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/runner-token" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/smtp-password" = {
        owner = "forgejo";
        group = "forgejo";
        mode = "0400";
      };
      "forgejo/restic-password" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

};
}

## modules/forgejo/service.nix

Core do serviço Forgejo:

{ config, lib, pkgs, ... }:

let
cfg = config.services.forgejo;
domain = "git.example.com";
in
{
services.forgejo = {
enable = true;
package = pkgs.forgejo;

    # ── Diretórios ──
    stateDir = "/var/lib/forgejo";

    # ── Database ──
    database = {
      type = "postgres";
      host = "/run/postgresql";
      name = "forgejo";
      user = "forgejo";
      createDatabase = true;
    };

    # ── LFS (Large File Storage) ──
    lfs.enable = true;

    # ── Dump (legacy backup via gitea dump) ──
    dump = {
      enable = true;
      interval = "daily";
      backupDir = "/var/backup/forgejo";
    };

    # ── app.ini settings ──
    settings = {
      # ── Server ──
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        PROTOCOL = "http";
        SSH_DOMAIN = domain;
        SSH_PORT = 22;
        SSH_LISTEN_PORT = 2222;
        START_SSH_SERVER = true;
        LFS_START_SERVER = true;
        OFFLINE_MODE = false;
        LANDING_PAGE = "explore";
      };

      # ── Repository defaults ──
      repository = {
        DEFAULT_BRANCH = "main";
        DEFAULT_PRIVATE = "public";
        MAX_CREATION_LIMIT = -1;  # unlimited
        PREFERRED_LICENSES = "MIT,Apache-2.0,GPL-3.0";
        DISABLE_STARS = false;
        DEFAULT_REPO_UNITS = "repo.code,repo.issues,repo.pulls,repo.releases,repo.wiki,repo.projects,repo.packages";
      };

      # ── UI ──
      ui = {
        DEFAULT_THEME = "forgejo-auto";
        SHOW_USER_EMAIL = false;
        SEARCH_REPO_DESCRIPTION = true;
        AMBIGUOUS_UNICODE_DETECTION = true;
      };

      "ui.meta" = {
        AUTHOR = "Forgejo Instance";
        DESCRIPTION = "Self-hosted Git forge powered by NixOS";
      };

      # ── Service ──
      service = {
        DISABLE_REGISTRATION = false;
        REQUIRE_SIGNIN_VIEW = false;
        REGISTER_EMAIL_CONFIRM = true;
        ENABLE_NOTIFY_MAIL = true;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
        DEFAULT_ALLOW_CREATE_ORGANIZATION = true;
        DEFAULT_ENABLE_TIMETRACKING = true;
        NO_REPLY_ADDRESS = "noreply@${domain}";
      };

      # ── Session ──
      session = {
        PROVIDER = "db";
        COOKIE_SECURE = true;
        COOKIE_NAME = "forgejo_session";
        GC_INTERVAL_TIME = 86400;  # 24h
        SESSION_LIFE_TIME = 604800;  # 7 days
      };

      # ── Cache ──
      cache = {
        ADAPTER = "memory";
        INTERVAL = 60;
        HOST = "";
      };

      # ── Log ──
      log = {
        MODE = "console";
        LEVEL = "Info";
        ROOT_PATH = "/var/lib/forgejo/log";
        ENABLE_ACCESS_LOG = true;
      };

      # ── Security ──
      security = {
        INSTALL_LOCK = true;
        LOGIN_REMEMBER_DAYS = 30;
        MIN_PASSWORD_LENGTH = 12;
        PASSWORD_COMPLEXITY = "lower,upper,digit,spec";
        PASSWORD_CHECK_PWN = true;  # Check HaveIBeenPwned
      };

      # ── OAuth2 ──
      oauth2 = {
        ENABLE = true;
        JWT_SIGNING_ALGORITHM = "EdDSA";
      };

      # ── Actions (CI/CD) ──
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "https://code.forgejo.org";
      };

      # ── Packages ──
      packages = {
        ENABLED = true;
        CHUNKED_UPLOAD_PATH = "/var/lib/forgejo/tmp/package-upload";
      };

      # ── Federation (experimental) ──
      federation = {
        ENABLED = false;  # Enable when stable
      };

      # ── Indexer ──
      indexer = {
        ISSUE_INDEXER_TYPE = "bleve";
        REPO_INDEXER_ENABLED = true;
        REPO_INDEXER_TYPE = "bleve";
        REPO_INDEXER_PATH = "/var/lib/forgejo/indexers/repos.bleve";
        MAX_FILE_SIZE = 1048576;  # 1MB
      };

      # ── Cron jobs ──
      cron = {
        ENABLED = true;
        RUN_AT_START = false;
      };

      "cron.repo_health_check" = {
        SCHEDULE = "@midnight";
        TIMEOUT = "60s";
      };

      "cron.cleanup_old_archives" = {
        SCHEDULE = "@midnight";
        OLDER_THAN = "24h";
      };

      "cron.resync_all_sshkeys" = {
        SCHEDULE = "@midnight";
      };

      # ── Migrations ──
      migrations = {
        ALLOW_LOCAL_NETWORKS = false;
        ALLOWED_DOMAINS = "github.com,gitlab.com,codeberg.org";
      };

      # ── Attachment limits ──
      attachment = {
        MAX_SIZE = 50;  # MB
        MAX_FILES = 10;
        ALLOWED_TYPES = "*/*";
      };

      # ── Markup (Mermaid, math, etc.) ──
      "markup.mermaid" = {
        ENABLED = true;
        FILE_EXTENSIONS = ".mm,.mmd";
        RENDER_COMMAND = "";
        IS_INPUT_FILE = false;
      };

      # ── Picture / Avatar ──
      picture = {
        AVATAR_UPLOAD_PATH = "/var/lib/forgejo/avatars";
        DISABLE_GRAVATAR = true;
        ENABLE_FEDERATED_AVATAR = false;
      };
    };

    # ── Secrets (from SOPS) ──
    secrets = {
      security = {
        SECRET_KEY = config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
      server = {
        LFS_JWT_SECRET = config.sops.secrets."forgejo/lfs-jwt-secret".path;
      };
    };

};

# ── Firewall ──

networking.firewall.allowedTCPPorts = [ 80 443 2222 ];

# ── System user ──

users.users.forgejo = {
isSystemUser = true;
home = "/var/lib/forgejo";
group = "forgejo";
shell = pkgs.bash;
};
users.groups.forgejo = {};

# ── Tmpfiles ──

systemd.tmpfiles.rules = [
"d /var/lib/forgejo 0750 forgejo forgejo -"
"d /var/lib/forgejo/log 0750 forgejo forgejo -"
"d /var/lib/forgejo/tmp 0750 forgejo forgejo -"
"d /var/backup/forgejo 0750 forgejo forgejo -"
];
}

## modules/forgejo/database.nix

PostgreSQL otimizado para Forgejo:

{ config, pkgs, lib, ... }:
{
services.postgresql = {
enable = true;
package = pkgs.postgresql_16;
dataDir = "/var/lib/postgresql/16";

    # ── Authentication ──
    authentication = lib.mkForce ''
      # TYPE  DATABASE  USER      ADDRESS    METHOD
      local   all       all                  peer
      host    all       all       127.0.0.1/32  scram-sha-256
      host    all       all       ::1/128       scram-sha-256
    '';

    # ── Initialization ──
    ensureDatabases = [ "forgejo" ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];

    # ── Performance tuning ──
    settings = {
      # Memory (adjust for your server)
      shared_buffers = "256MB";
      effective_cache_size = "768MB";
      work_mem = "8MB";
      maintenance_work_mem = "128MB";

      # WAL
      wal_buffers = "16MB";
      min_wal_size = "512MB";
      max_wal_size = "2GB";
      checkpoint_completion_target = 0.9;

      # Connections
      max_connections = 100;

      # Query planner
      random_page_cost = 1.1;  # SSD
      effective_io_concurrency = 200;  # SSD

      # Logging
      log_min_duration_statement = 1000;  # Log slow queries >1s
      log_checkpoints = true;
      log_connections = true;
      log_disconnections = true;

      # Locale
      lc_messages = "en_US.UTF-8";
    };

};

# ── Ensure PostgreSQL starts before Forgejo ──

systemd.services.forgejo = {
after = [ "postgresql.service" ];
requires = [ "postgresql.service" ];
};
}

## modules/forgejo/nginx.nix

Reverse proxy com ACME/Let's Encrypt:

{ config, lib, ... }:

let
domain = "git.example.com";
in
{

# ── ACME (Let's Encrypt) ──

security.acme = {
acceptTerms = true;
defaults.email = "admin@example.com";
};

# ── Nginx ──

services.nginx = {
enable = true;
recommendedTlsSettings = true;
recommendedOptimisation = true;
recommendedGzipSettings = true;
recommendedProxySettings = true;

    # ── Security headers ──
    commonHttpConfig = ''
      map $sent_http_content_type $referrer_policy {
        ~image/ "no-referrer";
        default "strict-origin-when-cross-origin";
      }
    '';

    # ── Forgejo vhost ──
    virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;

      extraConfig = ''
        client_max_body_size 512M;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;

          proxy_buffering off;
          proxy_request_buffering off;

          # Timeouts for large Git operations
          proxy_connect_timeout 300;
          proxy_send_timeout 300;
          proxy_read_timeout 300;
          send_timeout 300;
        '';
      };

      # ── Security headers ──
      extraConfig = ''
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy $referrer_policy always;
        add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
        client_max_body_size 512M;
      '';
    };

};
}

## modules/forgejo/actions-runner.nix

Forgejo Actions runner (compatível com GitHub Actions):

{ config, pkgs, lib, ... }:
{

# ── Forgejo Runner ──

services.gitea-actions-runner = {
package = pkgs.forgejo-actions-runner;

    instances = {
      "default" = {
        enable = true;
        name = "nix-runner";
        url = "https://git.example.com";
        tokenFile = config.sops.secrets."forgejo/runner-token".path;

        labels = [
          "ubuntu-latest:docker://node:20-bookworm"
          "ubuntu-22.04:docker://ubuntu:22.04"
          "nix:host"
        ];

        settings = {
          log.level = "info";

          runner = {
            capacity = 4;
            timeout = "3h";
            fetch_timeout = "5s";
            fetch_interval = "2s";
          };

          cache = {
            enabled = true;
            dir = "/var/cache/forgejo-runner";
          };

          container = {
            network = "bridge";
            privileged = false;
            docker_host = "";
            force_pull = false;
            valid_volumes = [
              "/var/cache/forgejo-runner"
            ];
          };

          host = {
            workdir_parent = "/var/lib/forgejo-runner/workdir";
          };
        };
      };
    };

};

# ── Docker (required for container-based actions) ──

virtualisation.docker = {
enable = true;
autoPrune = {
enable = true;
dates = "weekly";
flags = [ "--all" "--volumes" ];
};
};

# ── Directories ──

systemd.tmpfiles.rules = [
"d /var/lib/forgejo-runner 0750 root root -"
"d /var/lib/forgejo-runner/workdir 0750 root root -"
"d /var/cache/forgejo-runner 0755 root root -"
];
}

## modules/forgejo/backup.nix

Backup automatizado com Restic + timer systemd:

{ config, pkgs, lib, ... }:
{

# ── Restic backup to local + remote ──

services.restic.backups = {
forgejo-local = {
initialize = true;
passwordFile = config.sops.secrets."forgejo/restic-password".path;
repository = "/var/backup/forgejo/restic";

      paths = [
        "/var/lib/forgejo"
      ];

      exclude = [
        "/var/lib/forgejo/log"
        "/var/lib/forgejo/tmp"
        "/var/lib/forgejo/indexers"
        "/var/lib/forgejo/queues"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";  # 2 AM daily
        Persistent = true;
        RandomizedDelaySec = "30min";
      };

      # Dump PostgreSQL before backup
      backupPrepareCommand = ''
        ${pkgs.sudo}/bin/sudo -u postgres \
          ${pkgs.postgresql_16}/bin/pg_dump forgejo \
          > /var/lib/forgejo/forgejo-db.sql
        echo "[backup] PostgreSQL dump complete"
      '';

      backupCleanupCommand = ''
        rm -f /var/lib/forgejo/forgejo-db.sql
        echo "[backup] Cleanup complete"
      '';

      # Retention policy
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 2"
      ];
    };

    # ── Optional: Remote backup (S3-compatible) ──
    # forgejo-remote = {
    #   initialize = true;
    #   passwordFile = config.sops.secrets."forgejo/restic-password".path;
    #   repository = "s3:https://s3.example.com/forgejo-backup";
    #   environmentFile = config.sops.secrets."forgejo/s3-env".path;
    #   paths = [ "/var/lib/forgejo" ];
    #   exclude = [ ... ];
    #   timerConfig = {
    #     OnCalendar = "*-*-* 04:00:00";
    #     Persistent = true;
    #   };
    #   pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    # };

};

# ── Backup directories ──

systemd.tmpfiles.rules = [
"d /var/backup/forgejo 0750 root root -"
"d /var/backup/forgejo/restic 0750 root root -"
];
}

## modules/forgejo/monitoring.nix

Prometheus + Grafana para observabilidade:

{ config, pkgs, lib, ... }:
{

# ── Prometheus ──

services.prometheus = {
enable = true;
port = 9090;
retentionTime = "30d";

    scrapeConfigs = [
      {
        job_name = "forgejo";
        static_configs = [{
          targets = [ "127.0.0.1:3000" ];
          labels = { instance = "forgejo"; };
        }];
        metrics_path = "/metrics";
        scrape_interval = "30s";
      }
      {
        job_name = "postgresql";
        static_configs = [{
          targets = [ "127.0.0.1:9187" ];
        }];
        scrape_interval = "30s";
      }
      {
        job_name = "nginx";
        static_configs = [{
          targets = [ "127.0.0.1:9113" ];
        }];
        scrape_interval = "30s";
      }
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:9100" ];
        }];
        scrape_interval = "15s";
      }
    ];

    # ── Alert rules ──
    ruleFiles = [
      (pkgs.writeText "forgejo-alerts.yml" (builtins.toJSON {
        groups = [{
          name = "forgejo";
          rules = [
            {
              alert = "ForgejoDown";
              expr = ''up{job="forgejo"} == 0'';
              "for" = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "Forgejo is down";
                description = "Forgejo has been unreachable for more than 2 minutes.";
              };
            }
            {
              alert = "ForgejoHighMemory";
              expr = ''process_resident_memory_bytes{job="forgejo"} > 1073741824'';
              "for" = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Forgejo high memory usage";
                description = "Forgejo is using more than 1GB of memory.";
              };
            }
            {
              alert = "PostgreSQLDown";
              expr = ''up{job="postgresql"} == 0'';
              "for" = "1m";
              labels.severity = "critical";
              annotations = {
                summary = "PostgreSQL is down";
                description = "PostgreSQL has been unreachable for more than 1 minute.";
              };
            }
            {
              alert = "HighDiskUsage";
              expr = ''(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1'';
              "for" = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Disk space low";
                description = "Less than 10% disk space remaining.";
              };
            }
          ];
        }];
      }))
    ];

};

# ── Prometheus exporters ──

services.prometheus.exporters = {
node = {
enable = true;
port = 9100;
enabledCollectors = [
"systemd" "processes" "filesystem" "diskstats"
"netdev" "meminfo" "cpu" "loadavg"
];
};
postgres = {
enable = true;
port = 9187;
runAsLocalSuperUser = true;
};
nginx = {
enable = true;
port = 9113;
scrapeUri = "http://127.0.0.1:8080/nginx_status";
};
};

# ── Nginx stub_status for exporter ──

services.nginx.virtualHosts."localhost" = {
listen = [{ addr = "127.0.0.1"; port = 8080; }];
locations."/nginx_status" = {
extraConfig = ''
stub_status on;
access_log off;
allow 127.0.0.1;
deny all;
'';
};
};

# ── Grafana ──

services.grafana = {
enable = true;
settings = {
server = {
http_addr = "127.0.0.1";
http_port = 3001;
domain = "grafana.example.com";
root_url = "https://grafana.example.com/";
};
security = {
admin_user = "admin";
admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
};
analytics.reporting_enabled = false;
};

    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };

};
}

## modules/forgejo/hardening.nix

Hardening do serviço via systemd:

{ config, lib, ... }:
{
systemd.services.forgejo.serviceConfig = { # ── Sandboxing ──
ProtectSystem = "strict";
ProtectHome = true;
PrivateTmp = true;
PrivateDevices = true;
ProtectKernelTunables = true;
ProtectKernelModules = true;
ProtectKernelLogs = true;
ProtectControlGroups = true;
ProtectClock = true;
ProtectHostname = true;

    # ── Filesystem ──
    ReadWritePaths = [
      "/var/lib/forgejo"
      "/var/backup/forgejo"
      "/run/forgejo"
    ];

    # ── Network ──
    RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];

    # ── Capabilities ──
    CapabilityBoundingSet = [ "" ];
    AmbientCapabilities = [ "" ];
    NoNewPrivileges = true;

    # ── System calls ──
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
      "~@resources"
    ];
    SystemCallArchitectures = "native";

    # ── Memory ──
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;

    # ── Resource limits ──
    LimitNOFILE = 65536;
    LimitNPROC = 4096;

    # ── Restart policy ──
    Restart = "on-failure";
    RestartSec = 10;
    StartLimitIntervalSec = 60;
    StartLimitBurst = 3;

};

# ── fail2ban para SSH do Forgejo ──

services.fail2ban = {
enable = true;
maxretry = 5;
bantime = "1h";
jails = {
forgejo = {
settings = {
enabled = true;
filter = "forgejo";
action = ''iptables-multiport[name=forgejo, port="2222", protocol=tcp]'';
logpath = "/var/lib/forgejo/log/forgejo.log";
maxretry = 5;
findtime = 600;
bantime = 3600;
};
};
};
};

# ── fail2ban filter ──

environment.etc."fail2ban/filter.d/forgejo.conf".text = ''
[Definition]
failregex = ._(Failed authentication attempt|invalid credentials)._ from <HOST>
ignoreregex =
'';
}

## modules/forgejo/mail.nix

Configuração SMTP para notificações:

{ config, ... }:
{
services.forgejo.settings.mailer = {
ENABLED = true;
PROTOCOL = "smtps";
SMTP_ADDR = "smtp.example.com";
SMTP_PORT = 465;
FROM = "Forgejo <noreply@git.example.com>";
USER = "noreply@git.example.com";
};

# Password via SOPS

services.forgejo.secrets.mailer = {
PASSWD = config.sops.secrets."forgejo/smtp-password".path;
};
}

## hosts/forge/default.nix

Entry point do host:

{ config, pkgs, ... }:
{
imports = [
./hardware-configuration.nix
];

# ── System basics ──

system.stateVersion = "24.11";
networking.hostName = "forge";
time.timeZone = "America/Bahia";
i18n.defaultLocale = "en_US.UTF-8";

# ── Nix settings ──

nix = {
settings = {
experimental-features = [ "nix-command" "flakes" ];
auto-optimise-store = true;
};
gc = {
automatic = true;
dates = "weekly";
options = "--delete-older-than 30d";
};
};

# ── Base packages ──

environment.systemPackages = with pkgs; [
vim
git
htop
tmux
curl
jq
restic
postgresql_16
];

# ── SSH ──

services.openssh = {
enable = true;
settings = {
PermitRootLogin = "prohibit-password";
PasswordAuthentication = false;
KbdInteractiveAuthentication = false;
};
};

# ── Automatic updates ──

system.autoUpgrade = {
enable = true;
flake = "github:YOUR_USER/nixos-forge";
dates = "04:00";
randomizedDelaySec = "30min";
allowReboot = false;
};
}

## Workflow de Deploy

### Primeiro deploy

# 1. Gerar chave AGE para SOPS

age-keygen -o /var/lib/sops-nix/key.txt

# 2. Criar secrets

cat > secrets/forgejo.yaml << 'EOF'
forgejo:
db-password: "CHANGE_ME_STRONG_PASSWORD"
secret-key: "$(openssl rand -hex 32)"
  internal-token: "$(forgejo generate secret INTERNAL_TOKEN)"
oauth2-jwt-secret: "$(forgejo generate secret JWT_SECRET)"
  lfs-jwt-secret: "$(forgejo generate secret LFS_JWT_SECRET)"
runner-token: "REGISTER_VIA_ADMIN_UI"
smtp-password: "YOUR_SMTP_PASSWORD"
restic-password: "$(openssl rand -hex 32)"
EOF

# 3. Encriptar com SOPS

sops -e -i secrets/forgejo.yaml

# 4. Build e deploy

nixos-rebuild switch --flake .#forge

## Exemplo: Workflow Forgejo Actions

Crie `.forgejo/workflows/ci.yaml` em qualquer repositório:

name: CI Pipeline

on:
push:
branches: [main]
pull_request:
branches: [main]

jobs:
test:
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linter
        run: npm run lint

build:
runs-on: ubuntu-latest
needs: test
steps: - uses: actions/checkout@v4

      - name: Build container
        run: |
          docker build -t git.example.com/myorg/myapp:$ github.sha  .

      - name: Push to registry
        run: |
          docker login git.example.com -u $ secrets.REGISTRY_USER  -p $ secrets.REGISTRY_PASS
          docker push git.example.com/myorg/myapp:$ github.sha

Comandos Úteis

# ── Status dos serviços ──

systemctl status forgejo
systemctl status postgresql
systemctl status nginx
systemctl status gitea-runner-default

# ── Logs ──

journalctl -u forgejo -f --no-pager
journalctl -u forgejo -p err --since "1 hour ago"

# ── Admin CLI ──

sudo -u forgejo forgejo admin user list
sudo -u forgejo forgejo admin user create \
 --username admin --password 'STRONG_PASS' \
 --email admin@example.com --admin

# ── Backup manual ──

sudo systemctl start restic-backups-forgejo-local.service
restic -r /var/backup/forgejo/restic snapshots

# ── Restore ──

systemctl stop forgejo
restic -r /var/backup/forgejo/restic restore latest --target /
psql -U forgejo forgejo < /var/lib/forgejo/forgejo-db.sql
systemctl start forgejo

# ── Regenerar indexers ──

sudo -u forgejo forgejo admin repo-sync-releases
sudo -u forgejo forgejo admin regenerate hooks

## Checklist Pós-Deploy TODO:

- [ ] Acessar `https://git.example.com` e criar conta admin
- [ ] Verificar certificado TLS (`curl -vI https://git.example.com`)
- [ ] Testar SSH clone (`git clone ssh://git@git.example.com:2222/user/repo.git`)
- [ ] Configurar SMTP e testar envio de email
- [ ] Registrar Actions runner e testar um workflow
- [ ] Verificar backup executando `restic snapshots`
- [ ] Acessar Grafana (`https://grafana.example.com`) e verificar dashboards
- [ ] Testar fail2ban (`fail2ban-client status forgejo`)
- [ ] Criar organização e repositório de teste
- [ ] Configurar webhook para notificações (Matrix, Slack, Discord)
- [ ] Habilitar 2FA na conta admin
- [ ] Revisar logs: `journalctl -u forgejo -p warning --since today`
