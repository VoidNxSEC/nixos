{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

# ============================================================
# macOS KVM Module
# ============================================================
# Purpose: Declarative macOS VM management via QEMU/KVM
# Features: Auto-resource detection, GPU passthrough, SSH automation
# Usage: kernelcore.macos-kvm.enable = true;
# ============================================================

let
  cfg = config.kernelcore.virtualization.macos-kvm;

  # Script para baixar macOS installer
  fetchMacosScript = pkgs.writeShellScriptBin "macos-fetch" ''
    set -euo pipefail
    export PATH="${
      lib.makeBinPath [
        pkgs.python313
        pkgs.dmg2img
        pkgs.curl
      ]
    }:$PATH"

    WORK_DIR="${cfg.workDir}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    echo "🍎 Baixando macOS installer..."
    echo ""

    # Baixa script do OSX-KVM
    if [ ! -f fetch-macOS-v2.py ]; then
      curl -sL https://raw.githubusercontent.com/kholia/OSX-KVM/master/fetch-macOS-v2.py -o fetch-macOS-v2.py
    fi

    # Executa o fetch
    python3 fetch-macOS-v2.py

    # Converte DMG para IMG
    if [ -f BaseSystem.dmg ]; then
      echo ""
      echo "📦 Convertendo BaseSystem.dmg → BaseSystem.img..."
      dmg2img -v BaseSystem.dmg BaseSystem.img
      echo ""
      echo "✅ Pronto! Agora execute: macos-vm"
    else
      echo "❌ Erro: BaseSystem.dmg não foi baixado"
      exit 1
    fi
  '';

  # Script principal da VM
  macosVmScript = pkgs.writeShellScriptBin "macos-vm" ''
    set -euo pipefail
    export PATH="${
      lib.makeBinPath [
        pkgs.qemu
        pkgs.OVMF
        pkgs.dmg2img
      ]
    }:$PATH"

    WORK_DIR="${cfg.workDir}"
    mkdir -p "$WORK_DIR"

    # Copia OpenCore se necessário
    if [ ! -d "$WORK_DIR/OpenCore" ]; then
      echo "⚠️  OpenCore não encontrado. Baixando..."
      ${pkgs.curl}/bin/curl -sL https://github.com/kholia/OSX-KVM/raw/master/OpenCore/OpenCore.qcow2 \
        -o "$WORK_DIR/OpenCore.qcow2" --create-dirs
      mkdir -p "$WORK_DIR/OpenCore"
      mv "$WORK_DIR/OpenCore.qcow2" "$WORK_DIR/OpenCore/"
    fi

    cd "$WORK_DIR"

    # Cria disco se não existe
    if [ ! -f mac_hdd_ng.img ]; then
      echo "📀 Criando disco virtual (${toString cfg.diskSizeGB}G)..."
      ${pkgs.qemu}/bin/qemu-img create -f qcow2 mac_hdd_ng.img ${toString cfg.diskSizeGB}G
    fi

    # Auto-detect ou usar valores fixos
    ${
      if cfg.autoDetectResources then
        ''
          # Detecta cores disponíveis
          TOTAL_CORES=$(nproc)
          VM_CORES=$((TOTAL_CORES / 2))
          [ $VM_CORES -lt 4 ] && VM_CORES=4
          [ $VM_CORES -gt ${toString cfg.maxCores} ] && VM_CORES=${toString cfg.maxCores}
          VM_THREADS=2
          VM_SMP=$((VM_CORES * VM_THREADS))

          # Detecta RAM disponível
          TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
          VM_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024 / 2))
          [ $VM_RAM_GB -lt 8 ] && VM_RAM_GB=8
          [ $VM_RAM_GB -gt ${toString cfg.maxMemoryGB} ] && VM_RAM_GB=${toString cfg.maxMemoryGB}
        ''
      else
        ''
          VM_CORES=${toString cfg.cores}
          VM_THREADS=2
          VM_SMP=$((VM_CORES * VM_THREADS))
          VM_RAM_GB=${toString cfg.memoryGB}
        ''
    }

    # Verifica arquivos necessários
    if [ ! -f "$WORK_DIR/BaseSystem.img" ]; then
      echo "❌ BaseSystem.img não encontrado!"
      echo ""
      echo "Execute primeiro: macos-fetch"
      exit 1
    fi

    if [ ! -f "$WORK_DIR/OpenCore/OpenCore.qcow2" ]; then
      echo "❌ OpenCore.qcow2 não encontrado!"
      exit 1
    fi

    echo "🍎 macOS VM - Configuração:"
    echo "   CPU: $VM_SMP vCPUs ($VM_CORES cores × $VM_THREADS threads)"
    echo "   RAM: ''${VM_RAM_GB}G"
    echo "   Disco: $WORK_DIR/mac_hdd_ng.img"
    echo "   SSH: localhost:${toString cfg.sshPort}"
    echo ""

    # Monta comando QEMU
    QEMU_ARGS=(
      -enable-kvm
      -m "''${VM_RAM_GB}G"
      ${optionalString cfg.memoryPrealloc "-mem-prealloc"}
      -cpu "${cfg.cpuModel},kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+avx2,+aes,+xsave,+xsaveopt,+fma,+bmi1,+bmi2,check"
      -machine "q35,accel=kvm,kernel-irqchip=on"
      -smp "$VM_SMP,sockets=1,cores=$VM_CORES,threads=$VM_THREADS"
      -device qemu-xhci,id=xhci
      -device usb-kbd
      -device usb-tablet
      -device "isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
      -drive "if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd"
      -smbios type=2
      -device ich9-intel-hda
      -device hda-duplex
      -device ich9-ahci,id=sata
      -drive "id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file=$WORK_DIR/OpenCore/OpenCore.qcow2"
      -device ide-hd,bus=sata.2,drive=OpenCoreBoot
      -drive "id=InstallMedia,if=none,file=$WORK_DIR/BaseSystem.img,format=raw"
      -device ide-hd,bus=sata.3,drive=InstallMedia
      -drive "id=MacHDD,if=none,file=$WORK_DIR/mac_hdd_ng.img,format=qcow2,cache=${cfg.diskCache},aio=${cfg.diskAio},discard=unmap"
      -device ide-hd,bus=sata.4,drive=MacHDD
      -netdev "user,id=net0,hostfwd=tcp::${toString cfg.sshPort}-:22,hostfwd=tcp::${toString cfg.vncPort}-:5900"
      -device "virtio-net-pci,netdev=net0,id=net0,mac=${cfg.macAddress}"
      ${
        if cfg.display.virtioGl then
          ''
            -device virtio-vga-gl
            -display sdl,gl=on
          ''
        else
          ''
            -vga qxl
            -display sdl
          ''
      }
      ${optionalString cfg.enableQmpSocket "-qmp unix:/tmp/macos-qmp.sock,server,nowait"}
      ${optionalString cfg.enableMonitorSocket "-monitor unix:/tmp/macos-monitor.sock,server,nowait"}
    )

    exec ${pkgs.qemu}/bin/qemu-system-x86_64 "''${QEMU_ARGS[@]}"
  '';

  # Script para SSH
  macosSSHScript = pkgs.writeShellScriptBin "macos-ssh" ''
    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    exec ${pkgs.openssh}/bin/ssh $SSH_OPTS -p ${toString cfg.sshPort} ${cfg.sshUser}@localhost "$@"
  '';

  # Script para SCP
  macosSCPScript = pkgs.writeShellScriptBin "macos-scp" ''
    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    exec ${pkgs.openssh}/bin/scp $SSH_OPTS -P ${toString cfg.sshPort} "$@"
  '';

  # Script para snapshots
  macosSnapshotScript = pkgs.writeShellScriptBin "macos-snapshot" ''
    DISK="${cfg.workDir}/mac_hdd_ng.img"

    case "''${1:-list}" in
      list)
        echo "📸 Snapshots disponíveis:"
        ${pkgs.qemu}/bin/qemu-img snapshot -l "$DISK"
        ;;
      create)
        NAME="''${2:-snapshot-$(date +%Y%m%d-%H%M%S)}"
        echo "📸 Criando snapshot: $NAME"
        ${pkgs.qemu}/bin/qemu-img snapshot -c "$NAME" "$DISK"
        ;;
      apply)
        NAME="''${2:?Uso: macos-snapshot apply <nome>}"
        echo "⏪ Aplicando snapshot: $NAME"
        ${pkgs.qemu}/bin/qemu-img snapshot -a "$NAME" "$DISK"
        ;;
      delete)
        NAME="''${2:?Uso: macos-snapshot delete <nome>}"
        echo "🗑️  Deletando snapshot: $NAME"
        ${pkgs.qemu}/bin/qemu-img snapshot -d "$NAME" "$DISK"
        ;;
      *)
        echo "Uso: macos-snapshot [list|create|apply|delete] [nome]"
        ;;
    esac
  '';

  # Script de benchmark
  macosBenchmarkScript = pkgs.writeShellScriptBin "macos-benchmark" ''
    echo "=== macOS VM Performance Benchmark ==="
    echo ""

    SSH="${macosSSHScript}/bin/macos-ssh"

    if ! $SSH "echo ok" 2>/dev/null; then
      echo "❌ VM não está acessível via SSH"
      exit 1
    fi

    echo "📊 System Info:"
    $SSH "sw_vers; sysctl -n machdep.cpu.brand_string"

    echo ""
    echo "📊 CPU Benchmark (sum 10^7):"
    $SSH "time python3 -c 'sum(range(10**7))'"

    echo ""
    echo "📊 Disk Write (100MB):"
    $SSH "dd if=/dev/zero of=/tmp/test bs=1m count=100 2>&1 | tail -1"

    echo ""
    echo "📊 Disk Read:"
    $SSH "dd if=/tmp/test of=/dev/null bs=1m 2>&1 | tail -1; rm /tmp/test"

    echo ""
    echo "📊 Memory:"
    $SSH "sysctl hw.memsize | awk '{print \$2/1024/1024/1024 \" GB\"}'"
  '';

  # Script de wait for boot
  macosWaitScript = pkgs.writeShellScriptBin "macos-wait" ''
    TIMEOUT=''${1:-300}
    echo "⏳ Aguardando macOS boot (timeout: ''${TIMEOUT}s)..."

    start_time=$(date +%s)
    while true; do
      if ${macosSSHScript}/bin/macos-ssh "echo ok" 2>/dev/null; then
        echo "✅ macOS pronto!"
        exit 0
      fi
      
      elapsed=$(($(date +%s) - start_time))
      if [ $elapsed -ge $TIMEOUT ]; then
        echo "❌ Timeout aguardando boot"
        exit 1
      fi
      
      echo -n "."
      sleep 5
    done
  '';

  # Script de referência ngi-nix
  macosReferenceScript = pkgs.writeShellScriptBin "macos-reference" ''
    echo "🍎 Lançando VM de referência (ngi-nix/OSX-KVM)..."
    echo "Este projeto funciona de primeira - use para comparação."
    echo ""
    exec ${pkgs.nix}/bin/nix run github:ngi-nix/OSX-KVM
  '';

in
{
  options.kernelcore.virtualization.macos-kvm = {
    enable = mkEnableOption "Enable macOS KVM virtual machine support";

    workDir = mkOption {
      type = types.str;
      default = "/home/kernelcore/.macos-kvm";
      description = "Directory for macOS VM files (disk, installer, OpenCore)";
    };

    # Resource options
    autoDetectResources = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically detect CPU cores and RAM (uses 50% of host resources)";
    };

    cores = mkOption {
      type = types.int;
      default = 4;
      description = "Number of CPU cores (when autoDetect is disabled)";
    };

    maxCores = mkOption {
      type = types.int;
      default = 8;
      description = "Maximum CPU cores to use (when autoDetect is enabled)";
    };

    memoryGB = mkOption {
      type = types.int;
      default = 8;
      description = "Memory in GB (when autoDetect is disabled)";
    };

    maxMemoryGB = mkOption {
      type = types.int;
      default = 32;
      description = "Maximum memory in GB (when autoDetect is enabled)";
    };

    memoryPrealloc = mkOption {
      type = types.bool;
      default = true;
      description = "Preallocate memory for faster boot";
    };

    diskSizeGB = mkOption {
      type = types.int;
      default = 256;
      description = "Virtual disk size in GB";
    };

    # CPU options
    cpuModel = mkOption {
      type = types.str;
      default = "Cascadelake-Server";
      description = "CPU model to emulate (Penryn for compatibility, Cascadelake-Server for performance)";
    };

    # Disk options
    diskCache = mkOption {
      type = types.enum [
        "none"
        "writeback"
        "writethrough"
      ];
      default = "writeback";
      description = "Disk cache mode";
    };

    diskAio = mkOption {
      type = types.enum [
        "native"
        "threads"
        "io_uring"
      ];
      default = "threads";
      description = "Disk async I/O mode";
    };

    # Network options
    sshPort = mkOption {
      type = types.port;
      default = 10022;
      description = "Host port forwarded to guest SSH (22)";
    };

    vncPort = mkOption {
      type = types.port;
      default = 5900;
      description = "Host port forwarded to guest VNC/Screen Sharing";
    };

    macAddress = mkOption {
      type = types.str;
      default = "52:54:00:c9:18:27";
      description = "MAC address for the VM network interface";
    };

    sshUser = mkOption {
      type = types.str;
      default = "admin";
      description = "Default SSH username for macOS VM";
    };

    # Display options
    display = {
      virtioGl = mkOption {
        type = types.bool;
        default = true;
        description = "Use VirtIO GPU with OpenGL acceleration (recommended)";
      };
    };

    # Control sockets
    enableQmpSocket = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QMP control socket at /tmp/macos-qmp.sock";
    };

    enableMonitorSocket = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QEMU monitor socket at /tmp/macos-monitor.sock";
    };

    # GPU Passthrough (advanced)
    passthrough = {
      enable = mkEnableOption "Enable GPU passthrough (requires IOMMU)";

      gpuIds = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "10de:1b80"
          "10de:10f0"
        ];
        description = "PCI IDs for GPU passthrough (vendor:device format)";
      };

      gpuPciAddresses = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "01:00.0"
          "01:00.1"
        ];
        description = "PCI addresses for GPU passthrough";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure virtualization is enabled
    kernelcore.virtualization.enable = true;

    # IOMMU configuration for passthrough
    boot.kernelParams = lib.optionals cfg.passthrough.enable (
      [
        "intel_iommu=on"
        "iommu=pt"
      ]
      ++ (map (id: "vfio-pci.ids=${id}") cfg.passthrough.gpuIds)
    );

    boot.kernelModules = lib.optionals cfg.passthrough.enable [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    # Ensure work directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.workDir} 0755 kernelcore users -"
      "d ${cfg.workDir}/OpenCore 0755 kernelcore users -"
    ];

    # Install all macOS KVM tools
    environment.systemPackages = [
      fetchMacosScript
      macosVmScript
      macosSSHScript
      macosSCPScript
      macosSnapshotScript
      macosBenchmarkScript
      macosWaitScript
      macosReferenceScript

      # Dependencies
      pkgs.qemu
      pkgs.OVMF
      pkgs.dmg2img
      pkgs.python313
      pkgs.socat # For QMP/monitor socket control
    ];

    # Add user to kvm group
    users.users.kernelcore.extraGroups = [
      "kvm"
      "libvirtd"
    ];
  };
}
