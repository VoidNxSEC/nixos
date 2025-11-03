{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.virtualization.enable = mkEnableOption "Enable virtualization support (QEMU/KVM)";
    kernelcore.virtualization.virt-manager = mkEnableOption "Enable virt-manager GUI";
    kernelcore.virtualization.libvirtdGroup = mkOption {
      type = types.listOf types.str;
      default = [ "kernelcore" ];
      description = "Users to add to the libvirtd group for VM management";
    };
    kernelcore.virtualization.virtiofs.enable = mkEnableOption "Enable VirtioFS for easy host-guest file sharing";

    kernelcore.virtualization.vmBaseDir = mkOption {
      type = types.str;
      default = "/srv/vms/images";
      description = "Directory where VM disk images are stored (qcow2).";
    };

    kernelcore.virtualization.sourceImageDir = mkOption {
      type = types.str;
      default = "/var/lib/vm-images";
      description = "Directory for original/source VM images (e.g., OVA/VMDK/QCOW2) kept outside the repo.";
    };

    kernelcore.virtualization.vms = mkOption {
      description = "Declarative VM registry for libvirt (qcow2 imports).";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "Enable this VM";
              sourceImage = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional source qcow2 path (e.g., modules/virtualization/wazuh.qcow2). If set, a symlink will be created in vmBaseDir.";
              };
              imageFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Target qcow2 file path. Defaults to vmBaseDir/<name>.qcow2 if null.";
              };
              memoryMiB = mkOption {
                type = types.int;
                default = 4096;
                description = "Memory in MiB.";
              };
              vcpus = mkOption {
                type = types.int;
                default = 2;
                description = "Number of virtual CPUs.";
              };
              network = mkOption {
                type = types.enum [
                  "nat"
                  "bridge"
                ];
                default = "nat";
                description = "Network mode: NAT (default) or bridge.";
              };
              bridgeName = mkOption {
                type = types.str;
                default = "br0";
                description = "Bridge name when network=bridge.";
              };
              macAddress = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional fixed MAC address.";
              };
              autostart = mkOption {
                type = types.bool;
                default = false;
                description = "Mark VM to autostart under libvirt.";
              };
              sharedDirs = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      path = mkOption {
                        type = types.str;
                        description = "Host directory to share";
                      };
                      tag = mkOption {
                        type = types.str;
                        default = "hostshare";
                        description = "Guest mount tag";
                      };
                      driver = mkOption {
                        type = types.enum [
                          "virtiofs"
                          "9p"
                        ];
                        default = "virtiofs";
                        description = "Share driver";
                      };
                      readonly = mkOption {
                        type = types.bool;
                        default = false;
                        description = "Mount read-only";
                      };
                      create = mkOption {
                        type = types.bool;
                        default = true;
                        description = "Create host dir if missing";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Host directories exposed to the guest via virtiofs or 9p.";
              };
              extraVirtInstallArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments to pass to virt-install (e.g., graphics settings).";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf config.kernelcore.virtualization.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;

          # OVMF submodule was removed - UEFI/TPM images now available by default with QEMU
          # For custom OVMF configs, add to environment.systemPackages instead

          # VirtioFS enabled conditionally
          vhostUserPackages = mkIf config.kernelcore.virtualization.virtiofs.enable [ pkgs.virtiofsd ];
        };

        # Allow libvirt group members to manage VMs
        allowedBridges = [
          "virbr0"
          "br0"
        ];
      };

      spiceUSBRedirection.enable = true;
    };

    # PolicyKit rules for non-root VM management
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Libvirt extraConfig - moved to top level
    programs.dconf.enable = mkIf config.kernelcore.virtualization.virt-manager true;

    # User group for non-root VM access
    users.groups.libvirtd.members = config.kernelcore.virtualization.libvirtdGroup;

    # Permite virtiofsd acessar
    #virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

    # CLI and utilities (include vmctl when enabled)
    environment.systemPackages = (
      with pkgs;
      [
        libvirt
        qemu
        qemu_kvm
        bridge-utils
        virt-manager
        jq
      ]
      ++ optionals config.kernelcore.virtualization.virtiofs.enable [ virtiofsd ]
      ++ optionals config.kernelcore.virtualization.virt-manager [
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice
      ]
    );

    # Ensure base directories exist
    systemd.tmpfiles.rules = [
      "d /srv/vms/shared 0755 root libvirtd -"
      "d ${config.kernelcore.virtualization.vmBaseDir} 0755 root libvirtd -"
      "d ${config.kernelcore.virtualization.sourceImageDir} 0750 root libvirtd -"
    ];

    # Build VM registry JSON for scripts/activation
    environment.etc."vm-registry.json".text =
      let
        baseDir = config.kernelcore.virtualization.vmBaseDir;
        vms = mapAttrs (n: v: {
          name = n;
          enable = v.enable or true;
          sourceImage = v.sourceImage;
          imageFile = if v.imageFile != null then v.imageFile else "${baseDir}/" + n + ".qcow2";
          memoryMiB = v.memoryMiB;
          vcpus = v.vcpus;
          network = v.network;
          bridgeName = v.bridgeName;
          macAddress = v.macAddress;
          autostart = v.autostart;
          sharedDirs = v.sharedDirs;
          extraVirtInstallArgs = v.extraVirtInstallArgs;
        }) config.kernelcore.virtualization.vms;
      in
      builtins.toJSON vms;

    # Activation: ensure images are linked and VMs are defined
    system.activationScripts.vmCenter = {
      text = ''
        set -eu
        REG="/etc/vm-registry.json"
        test -f "$REG" || exit 0

        # Ensure libvirt default network exists and is active
        if ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1; then
          ${pkgs.libvirt}/bin/virsh net-autostart default >/dev/null 2>&1 || true
          ${pkgs.libvirt}/bin/virsh net-start default >/dev/null 2>&1 || true
        fi

        # Iterate VMs
        ${pkgs.jq}/bin/jq -r 'to_entries[] | .key + "\t" + (.value | @json)' "$REG" | while IFS=$'\t' read -r NAME JSON; do
          ENABLE=$(${pkgs.jq}/bin/jq -r '.enable' <<<"$JSON")
          [ "$ENABLE" = "true" ] || continue
          IMG=$(${pkgs.jq}/bin/jq -r '.imageFile' <<<"$JSON")
          SRC=$(${pkgs.jq}/bin/jq -r '.sourceImage // empty' <<<"$JSON")
          SRCDIR="${config.kernelcore.virtualization.sourceImageDir}"

          # Link source image into target if provided
          if [ -n "$SRC" ] && [ ! -e "$IMG" ]; then
            # Use absolute path if provided; otherwise look under sourceImageDir
            CANDIDATE="$SRC"
            case "$SRC" in
              /*) ;;
              *) CANDIDATE="$SRCDIR/$SRC" ;;
            esac
            if [ -e "$CANDIDATE" ]; then
              # Ensure parent directory exists
              mkdir -p "$(dirname "$IMG")"
              ln -sfn "$CANDIDATE" "$IMG"
            else
              echo "[vm-center] warning: source image not found: $CANDIDATE" >&2
            fi
          fi

          # Define VM if missing
          if ! ${pkgs.libvirt}/bin/virsh dominfo "$NAME" >/dev/null 2>&1; then
            MEM=$(${pkgs.jq}/bin/jq -r '.memoryMiB' <<<"$JSON")
            VCPUS=$(${pkgs.jq}/bin/jq -r '.vcpus' <<<"$JSON")
            NET=$(${pkgs.jq}/bin/jq -r '.network' <<<"$JSON")
            BR=$(${pkgs.jq}/bin/jq -r '.bridgeName' <<<"$JSON")
            MAC=$(${pkgs.jq}/bin/jq -r '.macAddress // empty' <<<"$JSON")
            EXTRA=()
            mapfile -t EXTRA < <(${pkgs.jq}/bin/jq -r '.extraVirtInstallArgs[]?' <<<"$JSON")

            # Filesystem shares
            FS_ARGS=()
            ${pkgs.jq}/bin/jq -c '.sharedDirs[]? // empty' <<<"$JSON" | while read -r SHARE; do
              SH_PATH=$(${pkgs.jq}/bin/jq -r '.path' <<<"$SHARE")
              SH_TAG=$(${pkgs.jq}/bin/jq -r '.tag' <<<"$SHARE")
              SH_DRV=$(${pkgs.jq}/bin/jq -r '.driver' <<<"$SHARE")
              SH_RO=$(${pkgs.jq}/bin/jq -r '.readonly' <<<"$SHARE")
              SH_CREATE=$(${pkgs.jq}/bin/jq -r '.create' <<<"$SHARE")
              [ "$SH_CREATE" = "true" ] && mkdir -p "$SH_PATH"
              if [ "$SH_DRV" = "virtiofs" ]; then
                FS_ARGS+=("--filesystem" "source=$SH_PATH,target=$SH_TAG,driver_name=virtiofs''${SH_RO:+,readonly=on}")
              else
                FS_ARGS+=("--filesystem" "type=mount,source=$SH_PATH,target=$SH_TAG,accessmode=passthrough''${SH_RO:+,readonly=on}")
              fi
            done

            NETARG="--network network=default"
            if [ "$NET" = "bridge" ]; then
              NETARG="--network bridge=$BR"
            fi
            if [ -n "$MAC" ]; then
              NETARG="$NETARG,mac=$MAC"
            fi

            if [ ! -e "$IMG" ]; then
              echo "[vm-center] image not found for $NAME: $IMG" >&2
              continue
            fi

            echo "[vm-center] defining VM $NAME from $IMG"
            ${pkgs.virt-manager}/bin/virt-install \
              --name "$NAME" \
              --memory "$MEM" \
              --vcpus "$VCPUS" \
              --disk path="$IMG",format=qcow2,bus=virtio \
              "$NETARG" \
              --os-variant detect=on,require=off \
              --import \
              --noautoconsole \
              "${"$"}{FS_ARGS[@]}" \
              "${"$"}{EXTRA[@]}" || true
          fi

          # Autostart flag
          AUT=$(${pkgs.jq}/bin/jq -r '.autostart' <<<"$JSON")
          if [ "$AUT" = "true" ]; then
            ${pkgs.libvirt}/bin/virsh autostart "$NAME" >/dev/null 2>&1 || true
          else
            ${pkgs.libvirt}/bin/virsh autostart "$NAME" --disable >/dev/null 2>&1 || true
          fi
        done
      '';
    };

    # vmctl helper moved into the main environment.systemPackages definition above
  };
}
