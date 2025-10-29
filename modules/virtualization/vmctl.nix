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
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Bash completion for vmctl
    environment.etc."bash_completion.d/vmctl".text = ''
      _vmctl_completion() {
        local cur prev commands vms
        cur="''${COMP_WORDS[COMP_CWORD]}"
        prev="''${COMP_WORDS[COMP_CWORD-1]}"
        commands="list ensure start stop restart console destroy convert-ova import-image create-disk wizard"

        # Get list of VMs from registry
        if [ -f /etc/vm-registry.json ]; then
          vms=$(jq -r 'to_entries[] | select(.value.enable==true) | .key' /etc/vm-registry.json 2>/dev/null)
        fi

        case "$prev" in
          vmctl)
            COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
            return 0
            ;;
          ensure|start|stop|restart|console|destroy)
            COMPREPLY=( $(compgen -W "$vms" -- "$cur") )
            return 0
            ;;
          convert-ova|import-image)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0
            ;;
          create-disk)
            # First arg after create-disk is name (any string)
            return 0
            ;;
          *)
            # Check if we're after create-disk <name> - second arg should be size
            if [ "''${COMP_WORDS[COMP_CWORD-2]}" = "create-disk" ]; then
              COMPREPLY=( $(compgen -W "10 20 50 100" -- "$cur") )
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
          text = ''
                      set -euo pipefail
                      REG="/etc/vm-registry.json"
                      SRC_DIR="${config.kernelcore.virtualization.sourceImageDir}"
                      usage() {
                        cat <<EOF
            Usage: vmctl <list|ensure|start|stop|restart|console|destroy|convert-ova|import-image|create-disk|wizard> [args]
            Commands:
              list                 List registered VMs
              ensure [vm]          Ensure VM(s) defined in libvirt
              start <vm>           Start VM
              stop <vm>            Shutdown VM
              restart <vm>         Reboot VM
              console <vm>         Attach console (serial/virt-viewer if available)
              destroy <vm>         Force stop and undefine VM
              convert-ova <ova> [name]
                                   Convert OVA to qcow2 in ${config.kernelcore.virtualization.sourceImageDir}
              import-image <path> [name]
                                   Copy/convert image into ${config.kernelcore.virtualization.sourceImageDir}
              create-disk <name> <GiB>
                                   Create blank qcow2 in ${config.kernelcore.virtualization.vmBaseDir}
              wizard               Interactive generator for a Nix VM snippet
            EOF
                      }

                      ensure_dir() {
                        local d="$1"
                        if ! mkdir -p "$d" 2>/dev/null; then
                          echo "[vmctl] mkdir requires privileges for $d; retrying with sudo" >&2
                          sudo mkdir -p "$d"
                        fi
                      }

                      install_secure() {
                        local src="$1" dst="$2"
                        if ! cp -f "$src" "$dst" 2>/dev/null; then
                          echo "[vmctl] write requires privileges for $dst; retrying with sudo" >&2
                          sudo cp -f "$src" "$dst"
                        fi
                        sudo chown root:libvirtd "$dst" || true
                        sudo chmod 640 "$dst" || true
                      }

                      cmd="''${1:-list}"; vm="''${2:-}"
                      [ -f "$REG" ] || { echo "registry not found: $REG" >&2; exit 1; }

                      list_vms() { ${pkgs.jq}/bin/jq -r 'to_entries[] | select(.value.enable==true) | .key' "$REG"; }

                      ensure_vm() {
                        local NAME="$1"; local JSON
                        JSON=$(${pkgs.jq}/bin/jq -c --arg n "$NAME" 'to_entries[] | select(.key==$n) | .value' "$REG")
                        [ -n "$JSON" ] || { echo "unknown vm: $NAME" >&2; return 1; }
                        local IMG MEM VCPUS NET BR MAC AUT
                        IMG=$(${pkgs.jq}/bin/jq -r '.imageFile' <<<"$JSON")
                        MEM=$(${pkgs.jq}/bin/jq -r '.memoryMiB' <<<"$JSON")
                        VCPUS=$(${pkgs.jq}/bin/jq -r '.vcpus' <<<"$JSON")
                        NET=$(${pkgs.jq}/bin/jq -r '.network' <<<"$JSON")
                        BR=$(${pkgs.jq}/bin/jq -r '.bridgeName' <<<"$JSON")
                        MAC=$(${pkgs.jq}/bin/jq -r '.macAddress // empty' <<<"$JSON")
                        local NETARG="--network network=default"
                        if [ "$NET" = "bridge" ]; then NETARG="--network bridge=$BR"; fi
                        if [ -n "$MAC" ]; then NETARG="$NETARG,mac=$MAC"; fi
                        FS_ARGS=()
                        ${pkgs.jq}/bin/jq -c '.sharedDirs[]? // empty' <<<"$JSON" | while read -r SHARE; do
                          SH_PATH=$(${pkgs.jq}/bin/jq -r '.path' <<<"$SHARE")
                          SH_TAG=$(${pkgs.jq}/bin/jq -r '.tag' <<<"$SHARE")
                          SH_DRV=$(${pkgs.jq}/bin/jq -r '.driver' <<<"$SHARE")
                          SH_RO=$(${pkgs.jq}/bin/jq -r '.readonly' <<<"$SHARE")
                          if [ "$SH_DRV" = "virtiofs" ]; then
                            FS_ARGS+=("--filesystem" "source=$SH_PATH,target=$SH_TAG,driver_name=virtiofs''${SH_RO:+,readonly=on}")
                          else
                            FS_ARGS+=("--filesystem" "type=mount,source=$SH_PATH,target=$SH_TAG,accessmode=passthrough''${SH_RO:+,readonly=on}")
                          fi
                        done
                        if ! ${pkgs.libvirt}/bin/virsh dominfo "$NAME" >/dev/null 2>&1; then
                          [ -e "$IMG" ] || { echo "image missing: $IMG" >&2; return 1; }
                          echo "[vmctl] defining $NAME"
                          ${pkgs.virt-manager}/bin/virt-install --name "$NAME" --memory "$MEM" --vcpus "$VCPUS" --disk path="$IMG",format=qcow2,bus=virtio "$NETARG" --os-variant detect=on,require=off --import --noautoconsole "''${FS_ARGS[@]}" || true
                        fi
                        AUT=$(${pkgs.jq}/bin/jq -r '.autostart' <<<"$JSON")
                        if [ "$AUT" = "true" ]; then ${pkgs.libvirt}/bin/virsh autostart "$NAME" >/dev/null 2>&1 || true; fi
                      }

                      case "$cmd" in
                        list)
                          list_vms ;;
                        ensure)
                          if [ -n "$vm" ]; then ensure_vm "$vm"; else for v in $(list_vms); do ensure_vm "$v"; done; fi ;;
                        start)
                          [ -n "$vm" ] || { usage; exit 1; }
                          ensure_vm "$vm"; ${pkgs.libvirt}/bin/virsh start "$vm" ;;
                        stop)
                          [ -n "$vm" ] || { usage; exit 1; }
                          ${pkgs.libvirt}/bin/virsh shutdown "$vm" ;;
                        restart)
                          [ -n "$vm" ] || { usage; exit 1; }
                          ${pkgs.libvirt}/bin/virsh reboot "$vm" ;;
                        console)
                          [ -n "$vm" ] || { usage; exit 1; }
                          if command -v virt-viewer >/dev/null 2>&1; then virt-viewer "$vm"; else ${pkgs.libvirt}/bin/virsh console "$vm"; fi ;;
                        destroy)
                          [ -n "$vm" ] || { usage; exit 1; }
                          ${pkgs.libvirt}/bin/virsh destroy "$vm" || true
                          ${pkgs.libvirt}/bin/virsh undefine "$vm" || true ;;
                        convert-ova)
                          OVA="''${2:-}"
                          NAME="''${3:-}"
                          [ -n "$OVA" ] || { echo "usage: vmctl convert-ova <ova> [name]" >&2; exit 1; }
                          [ -f "$OVA" ] || { echo "file not found: $OVA" >&2; exit 1; }
                          ensure_dir "$SRC_DIR"
                          tmp=$(mktemp -d)
                          trap 'rm -rf "$tmp"' EXIT
                          echo "[vmctl] extracting VMDK from OVA..."
                          VMDK=$(${pkgs.libarchive}/bin/bsdtar -tf "$OVA" | ${pkgs.gawk}/bin/awk -F/ '/\.vmdk$/ {print $NF; exit}')
                          [ -n "$VMDK" ] || { echo "no VMDK found in OVA" >&2; exit 1; }
                          ${pkgs.libarchive}/bin/bsdtar -xf "$OVA" -C "$tmp" "$VMDK"
                          base=''${NAME:-$(basename "''${OVA%%.ova}" | sed 's/\.[^.]*$//')}
                          OUT="$SRC_DIR/''${base}.qcow2"
                          echo "[vmctl] converting $VMDK -> $OUT"
                          ${pkgs.qemu}/bin/qemu-img convert -O qcow2 "$tmp/$VMDK" "$OUT" || {
                            echo "[vmctl] conversion may require privileges; retrying with sudo" >&2
                            sudo ${pkgs.qemu}/bin/qemu-img convert -O qcow2 "$tmp/$VMDK" "$OUT"
                          }
                          sudo chown root:libvirtd "$OUT" || true
                          sudo chmod 640 "$OUT" || true
                          echo "[vmctl] done: $OUT"
                          echo "Hint: reference this as sourceImage in kernelcore.virtualization.vms.<name>." ;;
                        import-image)
                          SRC_PATH="''${2:-}"; NAME="''${3:-}"
                          [ -n "$SRC_PATH" ] || { echo "usage: vmctl import-image <path> [name]" >&2; exit 1; }
                          [ -f "$SRC_PATH" ] || { echo "file not found: $SRC_PATH" >&2; exit 1; }
                          ensure_dir "$SRC_DIR"
                          base=''${NAME:-$(basename "$SRC_PATH")}
                          case "$base" in
                            *.ova)
                              shift 1; exec "$0" convert-ova "$SRC_PATH" "''${NAME:-}" ;;
                            *.qcow2)
                              OUT="$SRC_DIR/''${base}"
                              echo "[vmctl] copying qcow2 -> $OUT"
                              install_secure "$SRC_PATH" "$OUT" ;;
                            *)
                              OUT="$SRC_DIR/''${base%.*}.qcow2"
                              echo "[vmctl] converting to qcow2 -> $OUT"
                              ${pkgs.qemu}/bin/qemu-img convert -O qcow2 "$SRC_PATH" "$OUT" || {
                                echo "[vmctl] convert requires privileges; retrying with sudo" >&2
                                sudo ${pkgs.qemu}/bin/qemu-img convert -O qcow2 "$SRC_PATH" "$OUT"
                              }
                              sudo chown root:libvirtd "$OUT" || true
                              sudo chmod 640 "$OUT" || true ;;
                          esac
                          echo "[vmctl] imported: $OUT" ;;
                        create-disk)
                          NAME_ARG="''${2:-}"; SIZE_GIB="''${3:-}"
                          [ -n "$NAME_ARG" ] && [ -n "$SIZE_GIB" ] || { echo "usage: vmctl create-disk <name> <GiB>" >&2; exit 1; }
                          DST_DIR="${config.kernelcore.virtualization.vmBaseDir}"
                          ensure_dir "$DST_DIR"
                          OUT="$DST_DIR/''${NAME_ARG}.qcow2"
                          echo "[vmctl] creating disk $OUT (''${SIZE_GIB}G)"
                          ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$OUT" "''${SIZE_GIB}G" || {
                            echo "[vmctl] create requires privileges; retrying with sudo" >&2
                            sudo ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$OUT" "''${SIZE_GIB}G"
                          }
                          sudo chown root:libvirtd "$OUT" || true
                          sudo chmod 640 "$OUT" || true
                          echo "[vmctl] created: $OUT" ;;
                        wizard)
                          DIALOG=dialog
                          tmp=$(mktemp)
                          trap 'rm -f "$tmp"' EXIT
                          $DIALOG --inputbox "VM name (e.g., demo)" 8 50 2>"$tmp" || exit 1
                          NAME=$(cat "$tmp")
                          $DIALOG --inputbox "Memory MiB" 8 50 4096 2>"$tmp" || exit 1
                          MEM=$(cat "$tmp")
                          $DIALOG --inputbox "vCPUs" 8 50 2 2>"$tmp" || exit 1
                          VCPUS=$(cat "$tmp")
                          DEFAULT_SRC="$SRC_DIR/$NAME.qcow2"
                          $DIALOG --inputbox "Source image filename (in $SRC_DIR) or absolute path" 8 70 "$DEFAULT_SRC" 2>"$tmp" || exit 1
                          SRC=$(cat "$tmp")
                          $DIALOG --inputbox "Primary shared dir path (host)" 8 70 "/srv/vms/shared" 2>"$tmp" || exit 1
                          SHARE=$(cat "$tmp")
                          $DIALOG --menu "Network mode" 12 50 2 nat "libvirt default NAT" bridge "bridge br0" 2>"$tmp" || exit 1
                          NET=$(cat "$tmp")
                          BR="br0"
                          if [ "$NET" = "bridge" ]; then
                            $DIALOG --inputbox "Bridge name" 8 50 "$BR" 2>"$tmp" || exit 1
                            BR=$(cat "$tmp")
                          fi
                          clear
                          cat <<SNIP
                  $NAME = {
                    enable = true;
                    sourceImage = "$SRC";
                    imageFile = null;
                    memoryMiB = $MEM;
                    vcpus = $VCPUS;
                    network = "$NET";
                    bridgeName = "$BR";
                    sharedDirs = [ { path = "$SHARE"; tag = "hostshare"; driver = "virtiofs"; readonly = false; create = true; } ];
                    autostart = false;
                    extraVirtInstallArgs = [ "--graphics vnc,listen=0.0.0.0" ];
                  };
            SNIP
                          ;;
                        *) usage; exit 1 ;;
                      esac
          '';
        };
      in
      [ vmctl ];
  };
}
