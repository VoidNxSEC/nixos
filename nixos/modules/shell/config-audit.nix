{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
#NOTE: DEEPSEEK do that bad work, suspicious. TODO: Fix that shit.
let
  cfg = config.kernelcore.shell.config-audit;

  # ── CLI binary — wraps the Python script ────────────────────────
  audit-script = pkgs.writeShellScriptBin "audit-config" ''
    SCRIPT_DIR="/etc/nixos/scripts"
    cd /etc/nixos
    exec ${pkgs.python3}/bin/python3 "$SCRIPT_DIR/config-audit-master.py" "$@"
  '';

  # ── zsh completion file ─────────────────────────────────────────
  audit-zsh-completion = pkgs.writeText "_audit-config" ''
    #compdef audit-config audit audit-check audit-gap audit-dead

    local -a flags
    flags=(
      '--json[Saída JSON]'
      '--unconfigured[Só opções sem config no host]'
      '--unused[Só opções configuradas sem ref em módulo]'
      '--validate[Contra-fact-check: validação tripla]'
      '--help[Mostrar ajuda]'
    )

    case $words[2] in
      --module)
        if [[ $CURRENT -eq 3 ]]; then
          local -a mods
          mods=(''${(f)"$(find /etc/nixos/modules -name '*.nix' -printf '%f\n' 2>/dev/null | sed 's/\.nix$//' | sort -u)"})
          _describe 'module' mods
          return
        fi
        ;;
    esac

    _arguments -s : \
      '--json[Saída JSON]' \
      '--unconfigured[Só opções sem config no host]' \
      '--unused[Só opções configuradas sem ref em módulo]' \
      '--validate[Contra-fact-check: validação tripla]' \
      '--module[Filtrar por módulo]:module:->modules' \
      '--help[Mostrar ajuda]' \
      && return

    case $state in
      modules)
        local -a mods
        mods=(''${(f)"$(find /etc/nixos/modules -name '*.nix' -printf '%f\n' | sed 's/\.nix$//' | sort -u)"})
        _describe 'module' mods
        ;;
    esac
  '';

  # ── bash completion file ────────────────────────────────────────
  audit-bash-completion = pkgs.writeText "audit-config.bash" ''
    _audit_config() {
      local cur prev opts
      COMPREPLY=()
      cur="''${COMP_WORDS[COMP_CWORD]}"
      prev="''${COMP_WORDS[COMP_CWORD-1]}"
      opts="--json --unconfigured --unused --validate --module --help"

      if [[ "''${prev}" == "--module" ]]; then
        local mods
        mods=$(find /etc/nixos/modules -name '*.nix' -printf '%f\n' 2>/dev/null | sed 's/\.nix$//' | sort -u)
        COMPREPLY=($(compgen -W "''${mods}" -- "''${cur}"))
        return 0
      fi

      COMPREPLY=($(compgen -W "''${opts}" -- "''${cur}"))
      return 0
    }
    complete -F _audit_config audit-config audit audit-check audit-gap audit-dead
  '';

in
{
  options.kernelcore.shell.config-audit = {
    enable = mkEnableOption "Enable config-audit CLI with aliases and autocomplete";
  };

  config = mkIf cfg.enable {
    # ── Binary ────────────────────────────────────────────────────
    environment.systemPackages = [ audit-script ];

    # ── Completion files ──────────────────────────────────────────
    environment.etc = {
      "zsh/site-functions/_audit-config".source = audit-zsh-completion;
      "bash-completion/completions/audit-config".source = audit-bash-completion;
    };

    # ── Shell aliases ─────────────────────────────────────────────
    programs.zsh.shellAliases = {
      "audit" = "audit-config";
      "audit-check" = "audit-config --validate";
      "audit-gap" = "audit-config --unconfigured";
      "audit-dead" = "audit-config --unused";
    };

    programs.bash.shellAliases = {
      "audit" = "audit-config";
      "audit-check" = "audit-config --validate";
      "audit-gap" = "audit-config --unconfigured";
      "audit-dead" = "audit-config --unused";
    };

    # ── zsh: ensure completion dir is in fpath ─────────────────────
    programs.zsh.interactiveShellInit = ''
      fpath=(/etc/zsh/site-functions $fpath)
      autoload -Uz compinit && compinit -u 2>/dev/null
    '';

  };
}
