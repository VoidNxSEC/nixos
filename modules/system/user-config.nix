{ config, lib, ... }:

# ============================================================
# User Configuration — Parameterized identity
# ============================================================
# Replace all hardcoded usernames and home paths with these
# options. Set username once in your host configuration and
# all modules inherit consistent paths automatically.
#
# Usage in hosts/your-host/configuration.nix:
#   config.system.user.username = "alice";
# ============================================================

with lib;

let
  cfg = config.system.user;
in
{
  options.system.user = {
    username = mkOption {
      type = types.str;
      default = "kernelcore";
      description = "Primary system username. Override in your host configuration.";
      example = "alice";
    };

    homeDir = mkOption {
      type = types.path;
      default = "/home/${cfg.username}";
      defaultText = "/home/<username>";
      readOnly = true;
      description = "Home directory — computed from username, do not set directly.";
    };

    projectsDir = mkOption {
      type = types.path;
      default = "${cfg.homeDir}/projects";
      description = "Development projects directory.";
    };

    configDir = mkOption {
      type = types.path;
      default = "${cfg.homeDir}/.config";
      description = "XDG config base directory.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "${cfg.homeDir}/.local/share";
      description = "XDG data base directory.";
    };
  };

  # ── PHASE 3 TODO ──────────────────────────────────────────
  # Sweep all modules that contain hardcoded /home/kernelcore
  # or literal "kernelcore" and replace with:
  #   config.system.user.homeDir
  #   config.system.user.username
  # See docs/runbooks/phase-3-parametrize-paths.md
  # ─────────────────────────────────────────────────────────
  config = { };
}
