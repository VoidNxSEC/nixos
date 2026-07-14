# ============================================
# vmctl — declarative VM management CLI (aggregator)
# ============================================
# Phase 5 split (previously a single 959-line vmctl.nix):
# - default.nix → options, bash completion, package wiring
# - cli.nix     → the vmctl shell script body (bash)
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.virtualization.vmctl;
in
{
  options.kernelcore.virtualization.vmctl = {
    enable = mkEnableOption "Install the vmctl helper CLI for managing declarative VMs" // {
      default = false;
    };

    # Nova opção: logging verboso
    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose logging for vmctl operations";
    };

    # Nova opção: dry-run mode
    dryRun = mkOption {
      type = types.bool;
      default = false;
      description = "Print commands without executing (for debugging)";
    };
  };

  config = mkIf cfg.enable {
    # Bash completion for vmctl
    environment.etc."bash_completion.d/vmctl".text = ''
      _vmctl_completion() {
        local cur prev commands vms
        cur="''${COMP_WORDS[COMP_CWORD]}"
        prev="''${COMP_WORDS[COMP_CWORD-1]}"
        commands="list ensure start stop restart console destroy convert-ova import-image create-disk wizard scan auto-import status snapshot"

        if [ -f /etc/vm-registry.json ]; then
          vms=$(jq -r 'to_entries[] | select(.value.enable==true) | .key' /etc/vm-registry.json 2>/dev/null)
        fi

        case "$prev" in
          vmctl)
            COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
            return 0
            ;;
          ensure|start|stop|restart|console|destroy|status|snapshot)
            COMPREPLY=( $(compgen -W "$vms" -- "$cur") )
            return 0
            ;;
          convert-ova|import-image)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0
            ;;
          create-disk)
            return 0
            ;;
          *)
            if [ "''${COMP_WORDS[COMP_CWORD-2]}" = "create-disk" ]; then
              COMPREPLY=( $(compgen -W "10 20 50 100 200" -- "$cur") )
              return 0
            fi
            ;;
        esac
      }
      complete -F _vmctl_completion vmctl
    '';

    environment.systemPackages =
      let
        vmctl = pkgs.writeShellApplication {
          name = "vmctl";
          runtimeInputs = [
            pkgs.libvirt
            pkgs.virt-manager
            pkgs.jq
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gawk
            pkgs.qemu
            pkgs.libarchive
            pkgs.dialog
          ];
          text = import ./cli.nix { inherit config cfg; };
        };
      in
      [ vmctl ];
  };
}
