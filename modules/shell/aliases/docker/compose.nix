{ config, pkgs, lib, ... }:

# ============================================================
# Docker Compose Aliases
# ============================================================
# Professional Docker Compose management shortcuts
# ============================================================

{
  environment.shellAliases = {
    # ──────────────────────────────────────────────────────
    # BASIC COMPOSE OPERATIONS
    # ──────────────────────────────────────────────────────

    "dc" = "docker compose";
    "dc-up" = "docker compose up -d";
    "dc-down" = "docker compose down";
    "dc-restart" = "docker compose restart";
    "dc-stop" = "docker compose stop";
    "dc-start" = "docker compose start";

    # ──────────────────────────────────────────────────────
    # LOGS & MONITORING
    # ──────────────────────────────────────────────────────

    "dc-logs" = "docker compose logs -f";
    "dc-ps" = "docker compose ps";
    "dc-top" = "docker compose top";

    # ──────────────────────────────────────────────────────
    # BUILD & REBUILD
    # ──────────────────────────────────────────────────────

    "dc-build" = "docker compose build";
    "dc-rebuild" = "docker compose up -d --build";
    "dc-build-fresh" = "docker compose build --no-cache";

    # ──────────────────────────────────────────────────────
    # CLEANUP
    # ──────────────────────────────────────────────────────

    "dc-clean" = "docker compose down -v --remove-orphans";
    "dc-reset" = "docker compose down -v && docker compose up -d";

    # ──────────────────────────────────────────────────────
    # SPECIFIC SERVICES
    # ──────────────────────────────────────────────────────

    # Execute command in service
    "dc-exec" = "docker compose exec";

    # Run one-off command
    "dc-run" = "docker compose run --rm";

    # Shell in service
    "dc-shell" = ''
      f() { docker compose exec "$1" /bin/bash || docker compose exec "$1" /bin/sh; }; f
    '';

    # ──────────────────────────────────────────────────────
    # MULTIPLE COMPOSE FILES
    # ──────────────────────────────────────────────────────

    # Use custom compose file
    "dc-custom" = "docker compose -f";

    # Use dev compose
    "dc-dev" = "docker compose -f docker-compose.dev.yml";

    # Use prod compose
    "dc-prod" = "docker compose -f docker-compose.prod.yml";

    # ──────────────────────────────────────────────────────
    # STACK-SPECIFIC SHORTCUTS
    # ──────────────────────────────────────────────────────
    # Note: AI/ML aliases are defined in modules/shell/aliases/ai/

    # Database stack
    "db-up" = "docker compose -f docker-compose.db.yml up -d";
    "db-down" = "docker compose -f docker-compose.db.yml down";
    "db-logs" = "docker compose -f docker-compose.db.yml logs -f";
  };
}
