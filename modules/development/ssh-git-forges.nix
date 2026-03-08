{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

with lib;

let
  cfg = config.programs.ssh.gitForges;

  # Access system-level SSH config if available, otherwise defaults
  sysSsh =
    if (osConfig != null && hasAttr "kernelcore" osConfig && hasAttr "ssh" osConfig.kernelcore) then
      osConfig.kernelcore.ssh
    else
      {
        sshDir = "/home/kernelcore/.ssh";
        personalKey = "id_ed25519";
        gitlabKey = "id_ed25519";
        brevKey = "id_rsa";
      };

  # Helper to create standard forge config
  mkForge =
    {
      host,
      user ? "git",
      identity ? null,
      port ? 22,
      extra ? { },
    }:
    {
      hostname = host;
      inherit user port;
      identityFile =
        if identity != null then
          "${sysSsh.sshDir}/${identity}"
        else
          "${sysSsh.sshDir}/${sysSsh.personalKey}";
      identitiesOnly = true;
      # Advanced options for stability and speed
      compression = true;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      extraOptions = {
        PreferredAuthentications = "publickey";
        # Multiplexing for faster git operations
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%r@%h:%p";
        ControlPersist = "10m";
      }
      // extra;
    };

  # ─────────────────────────────────────────────────────────
  # DIAGNOSTIC TOOL
  # ─────────────────────────────────────────────────────────
  checkScript = pkgs.writeShellScriptBin "git-forge-doctor" ''
    # Colors
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    echo -e "''${YELLOW}🩺 Starting Git Forge Connection Diagnostics...''${NC}\n"

    check_forge() {
      local name=$1
      local host=$2
      local user=$3
      local expected_str=$4
      
      echo -ne "Testing ''${name} (''${host})... "
      
      # SSH -T usually returns 1 because shells are disabled, so we capture output
      output=$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "''${user}@''${host}" 2>&1 || true)
      
      if echo "$output" | grep -q "$expected_str"; then
        echo -e "''${GREEN}✅ OK''${NC}"
      else
        echo -e "''${RED}❌ FAIL''${NC}"
        echo -e "   -> Output: $output"
      fi
    }

    # Main Checks
    check_forge "GitHub (Personal)" "github.com" "git" "successfully authenticated"
    check_forge "GitHub (Org)" "github.com-voidnxlabs" "git" "successfully authenticated"
    check_forge "GitLab" "gitlab.com" "git" "Welcome to GitLab"
    check_forge "Codeberg" "codeberg.org" "git" "You've successfully authenticated"
    check_forge "SourceForge" "git.code.sf.net" "git" "Welcome"

    # Azure DevOps (Special case: returns shell not allowed but different msg)
    echo -ne "Testing Azure DevOps... "
    if ssh -T -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no git@ssh.dev.azure.com 2>&1 | grep -q "shell request failed"; then
       echo -e "''${GREEN}✅ OK''${NC} (Authenticated, Shell Disabled)"
    else
       # Sometimes it just works silently or fails hard
       # Let's assume if we didn't get a strict permission denied, we might be ok, but grep is safer
       echo -e "''${YELLOW}⚠️  UNKNOWN''${NC} (Check manually: ssh -T git@ssh.dev.azure.com)"
    fi

    echo -e "\n''${YELLOW}🔍 Checking SSH Agent Keys:''${NC}"
    ssh-add -l || echo -e "''${RED}No keys in agent! Run 'ssh-add <key>' or check your config.''${NC}"
  '';

in
{
  options.programs.ssh.gitForges = {
    enable = mkEnableOption "Enable intelligent Git Forge SSH configurations";

    # Allow overriding specific keys per forge
    keys = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Map of forge name (github, gitlab, etc.) to key filename";
    };
  };

  config = mkIf cfg.enable {
    # Install the doctor script
    home.packages = [ checkScript ];

    # Add convenient alias
    home.shellAliases = {
      "git-doctor" = "git-forge-doctor";
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false; # We manually configure defaults in matchBlocks."*"

      # Permite que o Brev CLI escreva no brev_config sem tocar no config
      # gerenciado pelo Nix (read-only). O Include é processado antes dos
      # matchBlocks, então entradas do brev_config têm precedência.
      includes = [ "~/.ssh/brev_config" ];

      # ═══════════════════════════════════════════════════════════
      # INTELLIGENT FORGE CONFIGURATIONS
      # ═══════════════════════════════════════════════════════════
      matchBlocks = {

        # ─────────────────────────────────────────────────────────
        # GITHUB (Primary)
        # ─────────────────────────────────────────────────────────
        "github.com" = mkForge {
          host = "github.com";
          identity = cfg.keys.github or sysSsh.personalKey;
        };

        # GitHub (VoidNxLabs Org) - Intelligent Alias
        "github.com-voidnxlabs" = mkForge {
          host = "github.com";
          identity = sysSsh.orgKey or "id_ed25519_voidnxlabs";
        };

        # ─────────────────────────────────────────────────────────
        # GITLAB
        # ─────────────────────────────────────────────────────────
        "gitlab.com" = mkForge {
          host = "gitlab.com";
          identity = cfg.keys.gitlab or sysSsh.gitlabKey;
        };

        # ─────────────────────────────────────────────────────────
        # CODEBERG (Forgejo)
        # ─────────────────────────────────────────────────────────
        "codeberg.org" = mkForge {
          host = "codeberg.org";
          # Usually uses same key as GitHub or personal
          identity = cfg.keys.codeberg or sysSsh.personalKey;
        };

        # ─────────────────────────────────────────────────────────
        # SOURCEFORGE
        # ─────────────────────────────────────────────────────────
        "git.code.sf.net" = mkForge {
          host = "git.code.sf.net";
          identity = cfg.keys.sourceforge or sysSsh.personalKey;
          # Sourceforge often has legacy algo requirements, but we enforce modern first
          extra = {
            PubkeyAcceptedKeyTypes = "+ssh-rsa"; # Fallback for older SF servers if needed
          };
        };
        # Alias for easier usage
        "sourceforge" = mkForge {
          host = "git.code.sf.net";
          identity = cfg.keys.sourceforge or sysSsh.personalKey;
          extra = {
            PubkeyAcceptedKeyTypes = "+ssh-rsa";
          };
        };

        # ─────────────────────────────────────────────────────────
        # AZURE DEVOPS
        # ─────────────────────────────────────────────────────────
        "ssh.dev.azure.com" = mkForge {
          host = "ssh.dev.azure.com";
          identity = cfg.keys.azure or sysSsh.personalKey;
          port = 22;
          extra = {
            # Azure sometimes requires rsa-sha2
            PubkeyAcceptedKeyTypes = "+ssh-rsa";
          };
        };
        # Visual Studio SSH
        "vs-ssh.visualstudio.com" = mkForge {
          host = "vs-ssh.visualstudio.com";
          identity = cfg.keys.azure or sysSsh.personalKey;
          port = 22;
        };

        # ─────────────────────────────────────────────────────────
        # BREV.DEV (AI/ML Dev Environments)
        # ─────────────────────────────────────────────────────────
        "*.brev.dev" = {
          user = "kernelcore"; # Brev uses specific user
          identityFile = "${sysSsh.sshDir}/${sysSsh.brevKey}";
          identitiesOnly = true;
          extraOptions = {
            StrictHostKeyChecking = "accept-new"; # Ephemeral envs
            AddKeysToAgent = "yes";
          };
        };
      };
    };

    # ═══════════════════════════════════════════════════════════
    # GIT INTEGRATION
    # ═══════════════════════════════════════════════════════════
    # configure git to use these specific aliases if necessary
    # or ensure URL rewrites exist
    programs.git.settings = {
      # Ensure we use SSH for these defined forges
      url = {
        "git@codeberg.org:".insteadOf = "https://codeberg.org/";
        "git@git.code.sf.net:".insteadOf = "https://git.code.sf.net/";
        "git@ssh.dev.azure.com:v3/".insteadOf = "https://dev.azure.com/";
      };
    };
  };
}
