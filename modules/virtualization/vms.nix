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
              enableClipboard = mkOption {
                type = types.bool;
                default = true;
                description = "Enable clipboard sharing between host and guest via SPICE";
              };
              additionalDisks = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      path = mkOption {
                        type = types.str;
                        description = "Path to the additional disk image";
                      };
                      size = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "Size of the disk (e.g., '20G', '50G'). If null, assumes disk already exists.";
                      };
                      format = mkOption {
                        type = types.enum [
                          "qcow2"
                          "raw"
                        ];
                        default = "qcow2";
                        description = "Disk format";
                      };
                      bus = mkOption {
                        type = types.enum [
                          "virtio"
                          "scsi"
                          "sata"
                          "ide"
                        ];
                        default = "virtio";
                        description = "Disk bus type";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Additional disk images to attach to the VM";
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

          # CRITICAL: Enable shared memory for VirtioFS support
          verbatimConfig = ''
            # VirtioFS requires shared memory
            memory_backing_dir = "/dev/shm"

            # Fix core dump limit error
            max_core = "unlimited"
          '';
        };

        # Allow libvirt group members to manage VMs
        allowedBridges = [
          "virbr0"
          "br0"
        ];
      };

      spiceUSBRedirection.enable = true;
    };

    # Fix libvirtd systemd limits
    systemd.services.libvirtd.serviceConfig = {
      LimitNOFILE = "infinity";
      LimitCORE = "infinity";
      LimitMEMLOCK = "infinity";
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

    # Ensure base directories exist with WRITE permissions for libvirtd group
    systemd.tmpfiles.rules = [
      "d /srv/vms/shared 0775 root libvirtd -"
      "d ${config.kernelcore.virtualization.vmBaseDir} 0775 root libvirtd -"
      "d ${config.kernelcore.virtualization.sourceImageDir} 0770 root libvirtd -"
      "d /var/lib/libvirt/images 0770 root libvirtd -"
      # Fix existing directories and files permissions recursively
      "Z /srv/vms/shared 0775 root libvirtd -"
      "Z ${config.kernelcore.virtualization.vmBaseDir} 0775 root libvirtd -"
      "Z ${config.kernelcore.virtualization.sourceImageDir} 0770 root libvirtd -"
      "Z /var/lib/libvirt/images 0770 root libvirtd -"
      # Files in VM images need to be readable by qemu-libvirtd (uid:301)
      "z /var/lib/libvirt/images/*.qcow2 0660 root libvirtd -"
      "z /var/lib/libvirt/images/*.img 0660 root libvirtd -"
      "z /var/lib/libvirt/images/*.raw 0660 root libvirtd -"
      "z ${config.kernelcore.virtualization.vmBaseDir}/*.qcow2 0660 root libvirtd -"
      "z ${config.kernelcore.virtualization.vmBaseDir}/*.img 0660 root libvirtd -"
      "z ${config.kernelcore.virtualization.vmBaseDir}/*.raw 0660 root libvirtd -"
    ];

    # Comprehensive libvirt initialization (network, storage, etc)
    systemd.services.libvirtd-setup = {
      description = "Initialize libvirt default resources (network, storage pool)";
      after = [ "libvirtd.service" ];
      wants = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
                sleep 2  # Give libvirtd time to fully start

                echo "[libvirt-setup] Initializing libvirt resources..."

                # ═══ 1. Default Network ═══
                if ! ${pkgs.libvirt}/bin/virsh net-info default &>/dev/null; then
                  echo "[libvirt-setup] Creating default network..."
                  ${pkgs.libvirt}/bin/virsh net-define /dev/stdin <<'EOF'
        <network>
          <name>default</name>
          <forward mode='nat'/>
          <bridge name='virbr0' stp='on' delay='0'/>
          <ip address='192.168.122.1' netmask='255.255.255.0'>
            <dhcp>
              <range start='192.168.122.2' end='192.168.122.254'/>
            </dhcp>
          </ip>
        </network>
        EOF
                fi
                ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
                ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
                echo "[libvirt-setup] ✓ Default network ready"

                # ═══ 2. Default Storage Pool ═══
                if ! ${pkgs.libvirt}/bin/virsh pool-info default &>/dev/null; then
                  echo "[libvirt-setup] Creating default storage pool..."
                  ${pkgs.libvirt}/bin/virsh pool-define /dev/stdin <<'EOF'
        <pool type='dir'>
          <name>default</name>
          <target>
            <path>/var/lib/libvirt/images</path>
            <permissions>
              <mode>0770</mode>
              <owner>0</owner>
              <group>$(getent group libvirtd | cut -d: -f3)</group>
            </permissions>
          </target>
        </pool>
        EOF
                fi
                ${pkgs.libvirt}/bin/virsh pool-start default 2>/dev/null || true
                ${pkgs.libvirt}/bin/virsh pool-autostart default 2>/dev/null || true
                echo "[libvirt-setup] ✓ Default storage pool ready"

                echo "[libvirt-setup] ✅ Libvirt initialization complete"
      '';
    };

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
          enableClipboard = v.enableClipboard;
          additionalDisks = v.additionalDisks;
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

          # Fix permissions on image file (must be root:libvirtd 0660 for qemu-libvirtd uid:301)
          if [ -e "$IMG" ]; then
            # Get the real file (follow symlinks)
            REAL_IMG=$(readlink -f "$IMG")
            if [ -n "$REAL_IMG" ] && [ -f "$REAL_IMG" ]; then
              echo "[vm-center] fixing permissions on $REAL_IMG"
              chgrp libvirtd "$REAL_IMG" 2>/dev/null || true
              chmod 0660 "$REAL_IMG" 2>/dev/null || true
            fi
          else
            echo "[vm-center] image not found for $NAME: $IMG" >&2
          fi

          # Define VM if missing
          if ! ${pkgs.libvirt}/bin/virsh dominfo "$NAME" >/dev/null 2>&1; then
            # Use real path (follow symlinks) for virt-install
            REAL_IMG=$(readlink -f "$IMG" 2>/dev/null || echo "$IMG")
            if [ ! -f "$REAL_IMG" ]; then
              echo "[vm-center] cannot find image file: $IMG" >&2
              continue
            fi

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

            # Build network arg
            NETARG_VALUE="network=default"
            if [ "$NET" = "bridge" ]; then
              NETARG_VALUE="bridge=$BR"
            fi
            if [ -n "$MAC" ]; then
              NETARG_VALUE="$NETARG_VALUE,mac=$MAC"
            fi

            # Graphics configuration - SPICE with clipboard support
            ENABLE_CLIP=$(${pkgs.jq}/bin/jq -r '.enableClipboard // true' <<<"$JSON")
            GRAPHICS_ARGS=()
            if [ "$ENABLE_CLIP" = "true" ]; then
              # SPICE graphics with clipboard sharing enabled
              GRAPHICS_ARGS+=("--graphics" "spice,listen=127.0.0.1")
              GRAPHICS_ARGS+=("--video" "qxl")
              GRAPHICS_ARGS+=("--channel" "spicevmc,target_type=virtio,name=com.redhat.spice.0")
            fi

            # Memory backing for VirtioFS
            MEM_BACKING=()
            if [ "''${#FS_ARGS[@]}" -gt 0 ]; then
              MEM_BACKING=("--memorybacking" "source.type=memfd,access.mode=shared")
            fi

            echo "[vm-center] defining VM $NAME from $REAL_IMG"
            ${pkgs.virt-manager}/bin/virt-install \
              --name "$NAME" \
              --memory "$MEM" \
              --vcpus "$VCPUS" \
              "''${MEM_BACKING[@]}" \
              --disk path="$REAL_IMG",format=qcow2,bus=virtio \
              --network "$NETARG_VALUE" \
              --os-variant detect=on,require=off \
              --import \
              --noautoconsole \
              "''${FS_ARGS[@]}" \
              "''${GRAPHICS_ARGS[@]}" \
              "''${EXTRA[@]}" || true
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
