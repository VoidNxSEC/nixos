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
          text = ''
                        set -euo pipefail

                        # ══════════════════════════════════════════════════════════════════
                        # Configuration
                        # ══════════════════════════════════════════════════════════════════
                        readonly REG="/etc/vm-registry.json"
                        readonly SRC_DIR="${config.kernelcore.virtualization.sourceImageDir}"
                        readonly VM_BASE_DIR="${config.kernelcore.virtualization.vmBaseDir}"
                        readonly VERBOSE="${toString cfg.verbose}"
                        readonly DRY_RUN="${toString cfg.dryRun}"

                        # ══════════════════════════════════════════════════════════════════
                        # Logging & Helpers
                        # ══════════════════════════════════════════════════════════════════
                        readonly C_RESET='\033[0m'
                        readonly C_RED='\033[0;31m'
                        readonly C_GREEN='\033[0;32m'
                        readonly C_YELLOW='\033[0;33m'
                        readonly C_BLUE='\033[0;34m'
                        readonly C_CYAN='\033[0;36m'

                        log_info()  { printf "''${C_CYAN}[vmctl]''${C_RESET} %s\n" "$*"; }
                        log_ok()    { printf "''${C_GREEN}[vmctl ✓]''${C_RESET} %s\n" "$*"; }
                        log_warn()  { printf "''${C_YELLOW}[vmctl ⚠]''${C_RESET} %s\n" "$*" >&2; }
                        log_error() { printf "''${C_RED}[vmctl ✗]''${C_RESET} %s\n" "$*" >&2; }
                        log_debug() { [[ "$VERBOSE" == "true" ]] && printf "''${C_BLUE}[vmctl DBG]''${C_RESET} %s\n" "$*" || true; }
                        die()       { log_error "$*"; exit 1; }

                        # Sanitize VM name (security)
                        sanitize_name() {
                          local name="$1"
                          # Allow only alphanumeric, dash, underscore
                          if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                            die "Invalid VM name: '$name' (only alphanumeric, dash, underscore allowed)"
                          fi
                          echo "$name"
                        }

                        # Execute with optional sudo retry
                        run_privileged() {
                          local desc="$1"; shift
                          log_debug "Attempting: $*"
                          if [[ "$DRY_RUN" == "true" ]]; then
                            log_info "[DRY-RUN] Would execute: $*"
                            return 0
                          fi
                          if ! "$@" 2>/dev/null; then
                            log_warn "$desc requires privileges; retrying with sudo"
                            sudo "$@"
                          fi
                        }

                        # Secure file installation (DRY pattern)
                        install_secure() {
                          local src="$1" dst="$2"
                          run_privileged "copy" cp -f "$src" "$dst"
                          sudo chown root:libvirtd "$dst" 2>/dev/null || true
                          sudo chmod 640 "$dst" 2>/dev/null || true
                        }

                        ensure_dir() {
                          local d="$1"
                          [[ -d "$d" ]] && return 0
                          run_privileged "mkdir $d" mkdir -p "$d"
                        }

                        # Create disk with format support
                        create_disk_helper() {
                          local path="$1" size="$2" format="''${3:-qcow2}"

                          # Fix permissions on existing disk
                          if [[ -f "$path" ]]; then
                            log_debug "Disk already exists: $path"
                            run_privileged "fix disk permissions" chgrp libvirtd "$path"
                            run_privileged "fix disk permissions" chmod 0660 "$path"
                            return 0
                          fi

                          log_info "Creating disk: $path (''${size}, format=$format)"
                          run_privileged "disk creation" qemu-img create -f "$format" "$path" "$size"
                          # Set correct permissions: root:libvirtd 0660 for qemu-libvirtd (uid:301)
                          run_privileged "fix disk permissions" chgrp libvirtd "$path"
                          run_privileged "fix disk permissions" chmod 0660 "$path"
                          log_ok "Disk created: $path"
                        }

                        # Smart image finder - searches multiple locations and fixes permissions
                        find_image() {
                          local img_path="$1"
                          local found_path=""

                          # If absolute path exists, use it
                          if [[ "$img_path" = /* ]] && [[ -f "$img_path" ]]; then
                            found_path="$img_path"
                          # Try sourceImageDir
                          elif [[ -f "$SRC_DIR/$img_path" ]]; then
                            found_path="$SRC_DIR/$img_path"
                          # Try libvirt default images dir
                          elif [[ -f "/var/lib/libvirt/images/$img_path" ]]; then
                            found_path="/var/lib/libvirt/images/$img_path"
                          # Try vmBaseDir
                          elif [[ -f "$VM_BASE_DIR/$img_path" ]]; then
                            found_path="$VM_BASE_DIR/$img_path"
                          else
                            # Try basename in all locations
                            local basename
                            basename="$(basename "$img_path")"
                            for dir in "$SRC_DIR" "/var/lib/libvirt/images" "$VM_BASE_DIR"; do
                              if [[ -f "$dir/$basename" ]]; then
                                found_path="$dir/$basename"
                                break
                              fi
                            done
                          fi

                          # Not found?
                          if [[ -z "$found_path" ]]; then
                            return 1
                          fi

                          # Fix permissions: must be root:libvirtd 0660 for qemu-libvirtd (uid:301)
                          log_debug "Ensuring correct permissions on $found_path"
                          run_privileged "fix image permissions" chgrp libvirtd "$found_path"
                          run_privileged "fix image permissions" chmod 0660 "$found_path"

                          echo "$found_path"
                          return 0
                        }

                        # ══════════════════════════════════════════════════════════════════
                        # Usage
                        # ══════════════════════════════════════════════════════════════════
                        usage() {
                          cat <<'EOF'
            Usage: vmctl <command> [args]

            VM Management:
              list                 List registered VMs
              status [vm]          Show VM status (all or specific)
              ensure [vm]          Ensure VM(s) defined in libvirt
              start <vm>           Start VM
              stop <vm>            Shutdown VM gracefully
              restart <vm>         Reboot VM
              console <vm>         Attach console (virt-viewer or serial)
              destroy <vm>         Force stop and undefine VM
              snapshot <vm> [name] Create snapshot of VM

            Image Discovery & Import:
              scan                 Scan for VM images in common locations
              auto-import <path> [name]
                                   Auto-import discovered image as VM
              import-image <path> [name]
                                   Copy/convert image into source directory
              convert-ova <ova> [name]
                                   Convert OVA to qcow2

            Disk Management:
              create-disk <name> <GiB>
                                   Create blank qcow2 disk

            Configuration:
              wizard               Interactive VM configuration generator

            EOF
                          cat <<EOF
            Directories:
              Source images:  $SRC_DIR
              VM disks:       $VM_BASE_DIR
              Libvirt images: /var/lib/libvirt/images
            EOF
                        }

                        # ══════════════════════════════════════════════════════════════════
                        # Core Functions
                        # ══════════════════════════════════════════════════════════════════
                        list_vms() {
                          jq -r 'to_entries[] | select(.value.enable==true) | .key' "$REG"
                        }

                        # FIX: Status command (novo)
                        show_status() {
                          local vm="''${1:-}"
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo " VM Status"
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          if [[ -n "$vm" ]]; then
                            virsh dominfo "$vm" 2>/dev/null || log_warn "VM '$vm' not defined in libvirt"
                          else
                            printf "%-20s %-12s %-10s\n" "NAME" "STATE" "AUTOSTART"
                            printf "%-20s %-12s %-10s\n" "----" "-----" "---------"
                            for v in $(list_vms); do
                              local state autostart
                              state=$(virsh domstate "$v" 2>/dev/null || echo "undefined")
                              autostart=$(virsh dominfo "$v" 2>/dev/null | awk '/Autostart:/{print $2}' || echo "-")
                              printf "%-20s %-12s %-10s\n" "$v" "$state" "$autostart"
                            done
                          fi
                        }

                        # FIX: Corrigido subshell bug com process substitution
                        scan_images() {
                          local SCAN_DIRS=(
                            "$SRC_DIR"
                            "$VM_BASE_DIR"
                            "/var/lib/libvirt/images"
                            "$HOME/Downloads"
                          )

                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo " Scanning for VM images..."
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo

                          local found=0
                          local img

                          for dir in "''${SCAN_DIRS[@]}"; do
                            [[ -d "$dir" ]] || continue

                            # FIX: Use process substitution instead of pipe to avoid subshell
                            while IFS= read -r -d "" img; do
                              found=1
                              local size name
                              size=$(du -h "$img" 2>/dev/null | cut -f1)
                              name=$(basename "$img" | sed 's/\.[^.]*$//')

                              echo "📦 Found: $(basename "$img")"
                              echo "   Path: $img"
                              echo "   Size: $size"
                              echo "   Suggested name: $name"
                              echo "   Import: vmctl auto-import \"$img\" \"$name\""
                              echo
                            done < <(find "$dir" -maxdepth 2 -type f \( \
                              -name "*.qcow2" -o -name "*.vmdk" -o -name "*.ova" \
                              -o -name "*.vdi" -o -name "*.raw" -o -name "*.img" \
                            \) -print0 2>/dev/null)
                          done

                          if [[ $found -eq 0 ]]; then
                            log_warn "No VM images found in scanned directories."
                            echo
                            echo "Scanned locations:"
                            for dir in "''${SCAN_DIRS[@]}"; do
                              echo "  - $dir"
                            done
                            echo
                            echo "To create a new VM disk: vmctl create-disk <name> <size-GB>"
                          fi
                        }

                        # FIX: Corrigido heredoc e interpolação
                        auto_import() {
                          local SRC_PATH="''${1:-}"
                          local NAME="''${2:-}"

                          [[ -n "$SRC_PATH" ]] || {
                            echo "Usage: vmctl auto-import <image-path> <vm-name>"
                            echo
                            echo "Run 'vmctl scan' to discover available images."
                            exit 1
                          }

                          [[ -f "$SRC_PATH" ]] || die "Image not found: $SRC_PATH"

                          NAME="''${NAME:-$(basename "$SRC_PATH" | sed 's/\.[^.]*$//')}"
                          NAME=$(sanitize_name "$NAME")

                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo " Auto-importing: $NAME"
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo

                          "$0" import-image "$SRC_PATH" "$NAME"

                          log_ok "Image imported successfully!"
                          echo
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo " Next steps:"
                          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                          echo

                          # FIX: Heredoc corrigido - não usa quoted para permitir interpolação
                          cat <<NIXSNIP
            1. Add VM to configuration.nix:

            kernelcore.virtualization.vms = {
              $NAME = {
                enable = true;
                sourceImage = "$NAME.qcow2";
                memoryMiB = 4096;
                vcpus = 2;
                network = "nat";
                enableClipboard = true;
              };
            };

            2. Rebuild NixOS:
               sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

            3. Start VM:
               vmctl start $NAME
            NIXSNIP
                        }

                        # FIX: Corrigido subshell bug com mapfile/readarray
                        ensure_vm() {
                          local NAME="$1"
                          NAME=$(sanitize_name "$NAME")

                          local JSON
                          JSON=$(jq -c --arg n "$NAME" 'to_entries[] | select(.key==$n) | .value' "$REG")
                          [[ -n "$JSON" ]] || die "Unknown VM: $NAME"

                          local IMG MEM VCPUS NET BR MAC AUT SRC_IMG
                          IMG=$(jq -r '.imageFile' <<<"$JSON")
                          SRC_IMG=$(jq -r '.sourceImage // empty' <<<"$JSON")
                          MEM=$(jq -r '.memoryMiB' <<<"$JSON")
                          VCPUS=$(jq -r '.vcpus' <<<"$JSON")
                          NET=$(jq -r '.network' <<<"$JSON")
                          BR=$(jq -r '.bridgeName' <<<"$JSON")
                          MAC=$(jq -r '.macAddress // empty' <<<"$JSON")

                          # Build network args (correct virt-install format)
                          local -a NETARG=()
                          if [[ "$NET" == "bridge" ]]; then
                            if [[ -n "$MAC" ]]; then
                              NETARG=("--network" "bridge=$BR,mac=$MAC")
                            else
                              NETARG=("--network" "bridge=$BR")
                            fi
                          else
                            if [[ -n "$MAC" ]]; then
                              NETARG=("--network" "network=default,mac=$MAC")
                            else
                              NETARG=("--network" "default")
                            fi
                          fi

                          # FIX: Use arrays properly without subshell
                          local -a FS_ARGS=()
                          local -a EXTRA_ARGS=()

                          # Read shared dirs into array using mapfile
                          local shares
                          mapfile -t shares < <(jq -c '.sharedDirs[]? // empty' <<<"$JSON")

                          for SHARE in "''${shares[@]}"; do
                            [[ -z "$SHARE" ]] && continue
                            local SH_PATH SH_TAG SH_DRV SH_RO
                            SH_PATH=$(jq -r '.path' <<<"$SHARE")
                            SH_TAG=$(jq -r '.tag' <<<"$SHARE")
                            SH_DRV=$(jq -r '.driver' <<<"$SHARE")
                            SH_RO=$(jq -r '.readonly' <<<"$SHARE")

                            if [[ "$SH_DRV" == "virtiofs" ]]; then
                              FS_ARGS+=("--filesystem" "source=$SH_PATH,target=$SH_TAG,driver.type=virtiofs''${SH_RO:+,readonly=on}")
                            else
                              FS_ARGS+=("--filesystem" "type=mount,source=$SH_PATH,target=$SH_TAG,accessmode=passthrough''${SH_RO:+,readonly=on}")
                            fi
                          done

                          # Read extra args
                          mapfile -t EXTRA_ARGS < <(jq -r '.extraVirtInstallArgs[]? // empty' <<<"$JSON")

                          # Handle additional disks
                          local -a DISK_ARGS=()
                          local additional_disks
                          mapfile -t additional_disks < <(jq -c '.additionalDisks[]? // empty' <<<"$JSON")

                          for DISK in "''${additional_disks[@]}"; do
                            [[ -z "$DISK" ]] && continue
                            local DISK_PATH DISK_SIZE DISK_FORMAT DISK_BUS
                            DISK_PATH=$(jq -r '.path' <<<"$DISK")
                            DISK_SIZE=$(jq -r '.size // empty' <<<"$DISK")
                            DISK_FORMAT=$(jq -r '.format // "qcow2"' <<<"$DISK")
                            DISK_BUS=$(jq -r '.bus // "virtio"' <<<"$DISK")

                            # Create disk if size is specified and disk doesn't exist
                            if [[ -n "$DISK_SIZE" ]]; then
                              create_disk_helper "$DISK_PATH" "$DISK_SIZE" "$DISK_FORMAT"
                            fi

                            # Add disk argument for virt-install
                            DISK_ARGS+=("--disk" "path=$DISK_PATH,format=$DISK_FORMAT,bus=$DISK_BUS")
                          done

                          if ! virsh dominfo "$NAME" >/dev/null 2>&1; then
                            # Smart image discovery
                            local FOUND_IMG=""
                            if [[ -e "$IMG" ]]; then
                              FOUND_IMG="$IMG"
                            elif [[ -n "$SRC_IMG" ]]; then
                              # Try to find sourceImage in multiple locations
                              if FOUND_IMG=$(find_image "$SRC_IMG"); then
                                log_info "Found image: $FOUND_IMG"
                                # Create symlink if IMG and FOUND_IMG are different
                                if [[ "$IMG" != "$FOUND_IMG" ]] && [[ ! -e "$IMG" ]]; then
                                  ensure_dir "$(dirname "$IMG")"
                                  log_debug "Creating symlink: $IMG -> $FOUND_IMG"
                                  run_privileged "symlink" ln -sf "$FOUND_IMG" "$IMG"
                                fi
                                IMG="$FOUND_IMG"
                              else
                                log_error "Image not found: $SRC_IMG"
                                log_error "Searched in:"
                                log_error "  - $SRC_DIR"
                                log_error "  - /var/lib/libvirt/images"
                                log_error "  - $VM_BASE_DIR"
                                echo
                                log_info "Available images in /var/lib/libvirt/images:"
                                find /var/lib/libvirt/images -maxdepth 1 \( -name "*.qcow2" -o -name "*.img" -o -name "*.raw" \) 2>/dev/null | while read -r img; do echo "  - $(basename "$img")"; done || echo "  (none found)"
                                echo
                                log_info "Run 'vmctl scan' to discover available images"
                                die "Cannot proceed without image"
                              fi
                            else
                              die "Image missing: $IMG (no sourceImage specified)"
                            fi

                            log_info "Defining VM: $NAME"
                            log_debug "Image: $IMG, Memory: $MEM MiB, vCPUs: $VCPUS"

                            # Build memory backing args if VirtioFS is used
                            local -a MEM_ARGS=()
                            if [[ "''${#FS_ARGS[@]}" -gt 0 ]]; then
                              MEM_ARGS=("--memorybacking" "source.type=memfd,access.mode=shared")
                              log_debug "VirtioFS detected: enabling shared memory"
                            fi

                            # Graphics and console (clipboard support if enabled)
                            local CLIP_ENABLED
                            CLIP_ENABLED=$(jq -r '.enableClipboard' <<<"$JSON")
                            local -a GRAPHICS_ARGS=()
                            if [[ "$CLIP_ENABLED" == "true" ]]; then
                              GRAPHICS_ARGS=("--graphics" "spice,listen=none" "--video" "qxl" "--channel" "spicevmc")
                            else
                              GRAPHICS_ARGS=("--graphics" "spice,listen=none" "--video" "qxl")
                            fi

                            virt-install \
                              --name "$NAME" \
                              --memory "$MEM" \
                              --vcpus "$VCPUS" \
                              "''${MEM_ARGS[@]}" \
                              --disk "path=$IMG,format=qcow2,bus=virtio" \
                              "''${DISK_ARGS[@]}" \
                              "''${NETARG[@]}" \
                              "''${GRAPHICS_ARGS[@]}" \
                              --console "pty,target.type=serial" \
                              --os-variant detect=on,require=off \
                              --import \
                              --noautoconsole \
                              "''${FS_ARGS[@]}" \
                              "''${EXTRA_ARGS[@]}" || true

                            log_ok "VM '$NAME' defined"
                          else
                            log_info "VM '$NAME' already defined"
                          fi

                          AUT=$(jq -r '.autostart' <<<"$JSON")
                          [[ "$AUT" == "true" ]] && virsh autostart "$NAME" >/dev/null 2>&1 || true
                        }

                        # Snapshot command (novo)
                        create_snapshot() {
                          local vm="$1" snap_name="''${2:-snap-$(date +%Y%m%d-%H%M%S)}"
                          vm=$(sanitize_name "$vm")
                          log_info "Creating snapshot '$snap_name' for VM '$vm'"
                          virsh snapshot-create-as "$vm" "$snap_name" --description "Created by vmctl" || die "Snapshot failed"
                          log_ok "Snapshot '$snap_name' created"
                        }

                        # ══════════════════════════════════════════════════════════════════
                        # Main Command Router
                        # ══════════════════════════════════════════════════════════════════
                        cmd="''${1:-list}"
                        vm="''${2:-}"

                        # Skip registry check for some commands
                        if [[ ! "$cmd" =~ ^(scan|wizard|create-disk)$ ]]; then
                          [[ -f "$REG" ]] || die "Registry not found: $REG"
                        fi

                        case "$cmd" in
                          list)
                            list_vms
                            ;;

                          status)
                            show_status "$vm"
                            ;;

                          ensure)
                            if [[ -n "$vm" ]]; then
                              ensure_vm "$vm"
                            else
                              for v in $(list_vms); do
                                ensure_vm "$v"
                              done
                            fi
                            ;;

                          start)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            vm=$(sanitize_name "$vm")
                            ensure_vm "$vm"
                            virsh start "$vm"
                            log_ok "VM '$vm' started"
                            ;;

                          stop)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            vm=$(sanitize_name "$vm")
                            virsh shutdown "$vm"
                            log_ok "Shutdown signal sent to '$vm'"
                            ;;

                          restart)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            vm=$(sanitize_name "$vm")
                            virsh reboot "$vm"
                            log_ok "Reboot signal sent to '$vm'"
                            ;;

                          console)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            vm=$(sanitize_name "$vm")
                            if command -v virt-viewer >/dev/null 2>&1; then
                              virt-viewer "$vm"
                            else
                              virsh console "$vm"
                            fi
                            ;;

                          destroy)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            vm=$(sanitize_name "$vm")
                            log_warn "Destroying VM '$vm'..."
                            virsh destroy "$vm" 2>/dev/null || true
                            virsh undefine "$vm" 2>/dev/null || true
                            log_ok "VM '$vm' destroyed and undefined"
                            ;;

                          snapshot)
                            [[ -n "$vm" ]] || { usage; exit 1; }
                            create_snapshot "$vm" "''${3:-}"
                            ;;

                          convert-ova)
                            OVA="''${2:-}"
                            NAME="''${3:-}"
                            [[ -n "$OVA" ]] || die "Usage: vmctl convert-ova <ova> [name]"
                            [[ -f "$OVA" ]] || die "File not found: $OVA"

                            ensure_dir "$SRC_DIR"

                            tmp=$(mktemp -d)
                            trap 'rm -rf "$tmp"' EXIT

                            log_info "Extracting VMDK from OVA..."
                            VMDK=$(bsdtar -tf "$OVA" | awk -F/ '/\.vmdk$/ {print $NF; exit}')
                            [[ -n "$VMDK" ]] || die "No VMDK found in OVA"

                            bsdtar -xf "$OVA" -C "$tmp" "$VMDK"

                            base="''${NAME:-$(basename "''${OVA%.ova}")}"
                            base=$(sanitize_name "$base")
                            OUT="$SRC_DIR/''${base}.qcow2"

                            log_info "Converting $VMDK -> $OUT"
                            run_privileged "conversion" qemu-img convert -p -O qcow2 "$tmp/$VMDK" "$OUT"
                            sudo chown root:libvirtd "$OUT" 2>/dev/null || true
                            sudo chmod 640 "$OUT" 2>/dev/null || true

                            log_ok "Done: $OUT"
                            echo "Hint: reference as sourceImage in kernelcore.virtualization.vms.<name>"
                            ;;

                          import-image)
                            SRC_PATH="''${2:-}"
                            NAME="''${3:-}"
                            [[ -n "$SRC_PATH" ]] || die "Usage: vmctl import-image <path> [name]"
                            [[ -f "$SRC_PATH" ]] || die "File not found: $SRC_PATH"

                            ensure_dir "$SRC_DIR"

                            base="''${NAME:-$(basename "$SRC_PATH")}"

                            case "$base" in
                              *.ova)
                                exec "$0" convert-ova "$SRC_PATH" "''${NAME:-}"
                                ;;
                              *.qcow2)
                                base=$(sanitize_name "''${base%.qcow2}")
                                OUT="$SRC_DIR/''${base}.qcow2"
                                log_info "Copying qcow2 -> $OUT"
                                install_secure "$SRC_PATH" "$OUT"
                                ;;
                              *)
                                base=$(sanitize_name "''${base%.*}")
                                OUT="$SRC_DIR/''${base}.qcow2"
                                log_info "Converting to qcow2 -> $OUT"
                                run_privileged "conversion" qemu-img convert -p -O qcow2 "$SRC_PATH" "$OUT"
                                sudo chown root:libvirtd "$OUT" 2>/dev/null || true
                                sudo chmod 640 "$OUT" 2>/dev/null || true
                                ;;
                            esac
                            log_ok "Imported: $OUT"
                            ;;

                          create-disk)
                            NAME_ARG="''${2:-}"
                            SIZE_GIB="''${3:-}"
                            [[ -n "$NAME_ARG" && -n "$SIZE_GIB" ]] || die "Usage: vmctl create-disk <name> <GiB>"

                            NAME_ARG=$(sanitize_name "$NAME_ARG")
                            # Validate size is numeric
                            [[ "$SIZE_GIB" =~ ^[0-9]+$ ]] || die "Size must be a number (GiB)"

                            ensure_dir "$VM_BASE_DIR"
                            OUT="$VM_BASE_DIR/''${NAME_ARG}.qcow2"

                            log_info "Creating disk $OUT (''${SIZE_GIB}G)"
                            run_privileged "disk creation" qemu-img create -f qcow2 "$OUT" "''${SIZE_GIB}G"
                            sudo chown root:libvirtd "$OUT" 2>/dev/null || true
                            sudo chmod 640 "$OUT" 2>/dev/null || true
                            log_ok "Created: $OUT"
                            ;;

                          wizard)
                            DIALOG=dialog
                            tmp=$(mktemp)
                            trap 'rm -f "$tmp"' EXIT

                            # Mode selection
                            $DIALOG --title "VM Configuration Wizard" \
                              --menu "Select wizard mode:" 12 60 2 \
                              basic "Basic mode (quick setup)" \
                              advanced "Advanced mode (all options)" \
                              2>"$tmp" || exit 1
                            MODE=$(cat "$tmp")

                            # ═══ Common questions ═══
                            $DIALOG --inputbox "VM name (alphanumeric, dash, underscore):" 8 60 2>"$tmp" || exit 1
                            NAME=$(cat "$tmp")
                            NAME=$(sanitize_name "$NAME")

                            $DIALOG --menu "Memory (MiB):" 15 60 5 \
                              2048 "2 GB" \
                              4096 "4 GB (recommended)" \
                              8192 "8 GB" \
                              16384 "16 GB" \
                              custom "Custom amount" \
                              2>"$tmp" || exit 1
                            MEM=$(cat "$tmp")
                            if [[ "$MEM" == "custom" ]]; then
                              $DIALOG --inputbox "Memory MiB:" 8 50 4096 2>"$tmp" || exit 1
                              MEM=$(cat "$tmp")
                            fi

                            $DIALOG --menu "vCPUs:" 15 60 5 \
                              1 "1 core" \
                              2 "2 cores (recommended)" \
                              4 "4 cores" \
                              8 "8 cores" \
                              custom "Custom" \
                              2>"$tmp" || exit 1
                            VCPUS=$(cat "$tmp")
                            if [[ "$VCPUS" == "custom" ]]; then
                              $DIALOG --inputbox "vCPUs:" 8 50 2 2>"$tmp" || exit 1
                              VCPUS=$(cat "$tmp")
                            fi

                            DEFAULT_SRC="$SRC_DIR/$NAME.qcow2"
                            $DIALOG --inputbox "Source image path:" 8 70 "$DEFAULT_SRC" 2>"$tmp" || exit 1
                            SRC=$(cat "$tmp")

                            # Network
                            $DIALOG --menu "Network mode:" 12 60 2 \
                              nat "NAT (default, internet access)" \
                              bridge "Bridge (direct network access)" \
                              2>"$tmp" || exit 1
                            NET=$(cat "$tmp")

                            BR="br0"
                            MAC=""
                            if [[ "$NET" == "bridge" ]]; then
                              $DIALOG --inputbox "Bridge name:" 8 50 "$BR" 2>"$tmp" || exit 1
                              BR=$(cat "$tmp")

                              if [[ "$MODE" == "advanced" ]]; then
                                $DIALOG --yesno "Set fixed MAC address?" 8 50 && {
                                  $DIALOG --inputbox "MAC address (e.g., 52:54:00:12:34:56):" 8 60 2>"$tmp" || exit 1
                                  MAC=$(cat "$tmp")
                                }
                              fi
                            fi

                            # ═══ Mode-specific questions ═══
                            IMG_FILE=""
                            AUTOSTART="false"
                            CLIPBOARD="true"
                            SHARED_DIRS_CONFIG=""
                            ADDITIONAL_DISKS_CONFIG=""

                            if [[ "$MODE" == "basic" ]]; then
                              # Basic mode: single shared dir
                              $DIALOG --yesno "Add shared directory?" 8 50 && {
                                $DIALOG --inputbox "Shared directory path (host):" 8 70 "/srv/vms/shared" 2>"$tmp" || exit 1
                                SHARE=$(cat "$tmp")
                                SHARED_DIRS_CONFIG="  sharedDirs = [{
                path = \"$SHARE\";
                tag = \"hostshare\";
                driver = \"virtiofs\";
                readonly = false;
                create = true;
              }];"
                              }
                            else
                              # Advanced mode

                              # Image file (target path)
                              $DIALOG --yesno "Specify custom image file path?\n(default: $VM_BASE_DIR/$NAME.qcow2)" 10 60 && {
                                $DIALOG --inputbox "Image file path:" 8 70 "$VM_BASE_DIR/$NAME.qcow2" 2>"$tmp" || exit 1
                                IMG_FILE=$(cat "$tmp")
                              }

                              # Autostart
                              $DIALOG --yesno "Enable autostart?" 8 50 && AUTOSTART="true"

                              # Clipboard
                              $DIALOG --yesno "Enable clipboard sharing?" 8 50 || CLIPBOARD="false"

                              # Shared directories (multiple)
                              SHARE_LIST=""
                              while $DIALOG --yesno "Add shared directory?" 8 50; do
                                $DIALOG --inputbox "Shared directory path (host):" 8 70 "/srv/vms/shared" 2>"$tmp" || break
                                SHARE_PATH=$(cat "$tmp")

                                $DIALOG --inputbox "Mount tag:" 8 50 "hostshare" 2>"$tmp" || break
                                SHARE_TAG=$(cat "$tmp")

                                $DIALOG --menu "Driver:" 12 60 2 \
                                  virtiofs "VirtioFS (recommended)" \
                                  9p "9p (legacy)" \
                                  2>"$tmp" || break
                                SHARE_DRV=$(cat "$tmp")

                                $DIALOG --yesno "Read-only?" 8 50 && SHARE_RO="true" || SHARE_RO="false"

                                SHARE_LIST="''${SHARE_LIST}  {
                path = \"$SHARE_PATH\";
                tag = \"$SHARE_TAG\";
                driver = \"$SHARE_DRV\";
                readonly = $SHARE_RO;
                create = true;
              }
            "
                              done

                              if [[ -n "$SHARE_LIST" ]]; then
                                SHARED_DIRS_CONFIG="  sharedDirs = [
            $SHARE_LIST  ];"
                              fi

                              # Additional disks
                              DISK_LIST=""
                              while $DIALOG --yesno "Add additional disk?" 8 50; do
                                $DIALOG --inputbox "Disk path:" 8 70 "$VM_BASE_DIR/$NAME-data.qcow2" 2>"$tmp" || break
                                DISK_PATH=$(cat "$tmp")

                                $DIALOG --inputbox "Disk size (e.g., 20G, 50G, leave empty if exists):" 8 60 "20G" 2>"$tmp" || break
                                DISK_SIZE=$(cat "$tmp")

                                $DIALOG --menu "Disk format:" 12 60 2 \
                                  qcow2 "QCOW2 (recommended)" \
                                  raw "RAW (better performance)" \
                                  2>"$tmp" || break
                                DISK_FMT=$(cat "$tmp")

                                $DIALOG --menu "Bus type:" 15 60 4 \
                                  virtio "VirtIO (recommended)" \
                                  scsi "SCSI" \
                                  sata "SATA" \
                                  ide "IDE" \
                                  2>"$tmp" || break
                                DISK_BUS=$(cat "$tmp")

                                DISK_SIZE_FIELD=""
                                [[ -n "$DISK_SIZE" ]] && DISK_SIZE_FIELD="
                size = \"$DISK_SIZE\";"

                                DISK_LIST="''${DISK_LIST}  {
                path = \"$DISK_PATH\";$DISK_SIZE_FIELD
                format = \"$DISK_FMT\";
                bus = \"$DISK_BUS\";
              }
            "
                              done

                              if [[ -n "$DISK_LIST" ]]; then
                                ADDITIONAL_DISKS_CONFIG="  additionalDisks = [
            $DISK_LIST  ];"
                              fi
                            fi

                            # ═══ Generate configuration ═══
                            clear
                            echo "════════════════════════════════════════════════════════════════"
                            echo " VM Configuration (add to configuration.nix)"
                            echo "════════════════════════════════════════════════════════════════"
                            echo

                            cat <<NIXCONFIG
            kernelcore.virtualization.vms.$NAME = {
              enable = true;
              sourceImage = "$SRC";
            NIXCONFIG

                            [[ -n "$IMG_FILE" ]] && echo "  imageFile = \"$IMG_FILE\";"

                            cat <<NIXCONFIG
              memoryMiB = $MEM;
              vcpus = $VCPUS;
              network = "$NET";
              bridgeName = "$BR";
            NIXCONFIG

                            [[ -n "$MAC" ]] && echo "  macAddress = \"$MAC\";"
                            echo "  autostart = $AUTOSTART;"

                            [[ -n "$SHARED_DIRS_CONFIG" ]] && echo "$SHARED_DIRS_CONFIG"
                            [[ -n "$ADDITIONAL_DISKS_CONFIG" ]] && echo "$ADDITIONAL_DISKS_CONFIG"

                            cat <<NIXCONFIG
              enableClipboard = $CLIPBOARD;
            };
            NIXCONFIG

                            echo
                            echo "════════════════════════════════════════════════════════════════"
                            echo " Next steps:"
                            echo "════════════════════════════════════════════════════════════════"
                            echo " 1. Add the above to your configuration.nix"
                            echo " 2. sudo nixos-rebuild switch --flake /etc/nixos#kernelcore"
                            echo " 3. vmctl start $NAME"
                            echo "════════════════════════════════════════════════════════════════"
                            ;;

                          scan)
                            scan_images
                            ;;

                          auto-import)
                            shift
                            auto_import "$@"
                            ;;

                          *)
                            usage
                            exit 1
                            ;;
                        esac
          '';
        };
      in
      [ vmctl ];
  };
}
