# macOS VM Module - OSX-KVM Integration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hyperlab.macos;

  # Helper script for macOS VM
  macosVmScript = pkgs.writeShellScriptBin "macos-vm" ''
    set -e

    MACOS_DIR="$HOME/.hyperlab/macos-vm"

    mkdir -p "$MACOS_DIR"
    cd "$MACOS_DIR"

    case "$1" in
      init)
        echo "🍎 Initializing macOS VM environment..."
        
        if [ ! -d "OSX-KVM" ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/kholia/OSX-KVM.git
        fi
        
        cd OSX-KVM
        
        echo "📥 Downloading macOS installer..."
        echo "Available versions:"
        echo "  1) Sonoma (14)"
        echo "  2) Ventura (13)"
        echo "  3) Monterey (12)"
        read -p "Choose version [1]: " version
        version=''${version:-1}
        
        ${pkgs.python3}/bin/python3 fetch-macOS-v2.py
        
        echo "🔄 Converting DMG to IMG..."
        ${pkgs.dmg2img}/bin/dmg2img -i BaseSystem.dmg BaseSystem.img
        
        echo "💾 Creating virtual disk (${toString cfg.diskSize}GB)..."
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 mac_hdd_ng.img ${toString cfg.diskSize}G
        
        echo "✅ macOS VM initialized!"
        echo "Run 'macos-vm start' to boot"
        ;;
        
      start)
        echo "🚀 Starting macOS VM..."
        cd OSX-KVM
        
        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -enable-kvm \
          -m ${toString cfg.memory} \
          -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check \
          -machine q35 \
          -smp ${toString cfg.cpus},cores=${toString (cfg.cpus / 2)},sockets=1 \
          -device usb-ehci,id=ehci \
          -device nec-usb-xhci,id=xhci \
          -global nec-usb-xhci.msi=off \
          -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
          -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
          -smbios type=2 \
          -device ich9-intel-hda -device hda-duplex \
          -device ich9-ahci,id=sata \
          -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="OpenCore/OpenCore.qcow2" \
          -device ide-hd,bus=sata.2,drive=OpenCoreBoot \
          -device ide-hd,bus=sata.3,drive=InstallMedia \
          -drive id=InstallMedia,if=none,file="BaseSystem.img",format=raw \
          -drive id=MacHDD,if=none,file="mac_hdd_ng.img",format=qcow2 \
          -device ide-hd,bus=sata.4,drive=MacHDD \
          -netdev user,id=net0,hostfwd=tcp::${toString cfg.sshPort}-:22,hostfwd=tcp::${toString cfg.vncPort}-:5900 \
          -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
          -monitor stdio \
          -device virtio-vga-gl \
          -display ${cfg.display} \
          ''${MACOS_EXTRA_ARGS:-}
        ;;
        
      headless)
        echo "🖥️ Starting macOS VM (headless)..."
        MACOS_EXTRA_ARGS="-nographic -vnc :${toString (cfg.vncPort - 5900)}" $0 start
        ;;
        
      ssh)
        echo "🔗 Connecting to macOS VM via SSH..."
        ${pkgs.openssh}/bin/ssh -p ${toString cfg.sshPort} localhost
        ;;
        
      vnc)
        echo "🖥️ Connecting to macOS VM via VNC..."
        ${pkgs.tigervnc}/bin/vncviewer localhost:${toString cfg.vncPort}
        ;;
        
      gpu-passthrough)
        echo "🎮 Starting macOS VM with GPU passthrough..."
        
        GPU_ARGS=""
        ${optionalString (cfg.gpuPassthrough.enable) ''
          GPU_ARGS="-device vfio-pci,host=${cfg.gpuPassthrough.pciAddress}"
        ''}
        
        MACOS_EXTRA_ARGS="$GPU_ARGS" $0 start
        ;;
        
      status)
        if pgrep -f "qemu.*mac_hdd_ng" > /dev/null; then
          echo "✅ macOS VM is running"
          echo "SSH: localhost:${toString cfg.sshPort}"
          echo "VNC: localhost:${toString cfg.vncPort}"
        else
          echo "❌ macOS VM is not running"
        fi
        ;;
        
      stop)
        echo "🛑 Stopping macOS VM..."
        pkill -f "qemu.*mac_hdd_ng" || true
        ;;
        
      snapshot)
        echo "📸 Creating snapshot..."
        cd OSX-KVM
        ${pkgs.qemu}/bin/qemu-img snapshot -c "snapshot-$(date +%Y%m%d-%H%M%S)" mac_hdd_ng.img
        ${pkgs.qemu}/bin/qemu-img snapshot -l mac_hdd_ng.img
        ;;
        
      *)
        echo "🍎 macOS VM Manager"
        echo ""
        echo "Usage: macos-vm <command>"
        echo ""
        echo "Commands:"
        echo "  init           - Download macOS and setup VM"
        echo "  start          - Start VM with display"
        echo "  headless       - Start VM headless (VNC only)"
        echo "  ssh            - Connect via SSH"
        echo "  vnc            - Connect via VNC viewer"
        echo "  gpu-passthrough - Start with GPU passthrough"
        echo "  status         - Check VM status"
        echo "  stop           - Stop the VM"
        echo "  snapshot       - Create disk snapshot"
        ;;
    esac
  '';

in
{
  options.hyperlab.macos = {
    enable = mkEnableOption "macOS VM support";

    memory = mkOption {
      type = types.int;
      default = 8192;
      description = "RAM in MB";
    };

    cpus = mkOption {
      type = types.int;
      default = 4;
      description = "Number of CPU cores";
    };

    diskSize = mkOption {
      type = types.int;
      default = 128;
      description = "Disk size in GB";
    };

    sshPort = mkOption {
      type = types.port;
      default = 10022;
      description = "SSH forward port";
    };

    vncPort = mkOption {
      type = types.port;
      default = 5901;
      description = "VNC port";
    };

    display = mkOption {
      type = types.str;
      default = "sdl,gl=on";
      description = "QEMU display backend";
    };

    gpuPassthrough = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPU passthrough";
      };

      pciAddress = mkOption {
        type = types.str;
        default = "01:00.0";
        description = "GPU PCI address";
      };
    };
  };

  config = mkIf cfg.enable {
    # KVM requirements
    boot.extraModprobeConfig = ''
      options kvm ignore_msrs=1 report_ignored_msrs=0
      options kvm_intel nested=1
      options kvm_intel emulate_invalid_guest_state=0
    '';

    boot.kernelModules = [
      "kvm-intel"
      "kvm"
    ];

    # Virtualization
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };

    # User permissions
    users.users.${config.hyperlab.user or "pina"}.extraGroups = [
      "libvirtd"
      "kvm"
      "input"
    ];

    # Packages
    environment.systemPackages = with pkgs; [
      macosVmScript
      qemu
      OVMF
      libvirt
      virt-manager
      virt-viewer
      dmg2img
      tigervnc
      python3
      python3Packages.requests
    ];

    # Firewall for VM access
    networking.firewall.allowedTCPPorts = [
      cfg.sshPort
      cfg.vncPort
    ];

    # Systemd service for auto-start (optional)
    systemd.services.macos-vm = mkIf false {
      # Disabled by default
      description = "macOS Virtual Machine";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "libvirtd.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = config.hyperlab.user or "pina";
        ExecStart = "${macosVmScript}/bin/macos-vm headless";
        ExecStop = "${macosVmScript}/bin/macos-vm stop";
        Restart = "on-failure";
      };
    };
  };
}
