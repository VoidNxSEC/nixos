{ ... }:

# ═══════════════════════════════════════════════════════════
# VIRTUALIZAÇÃO & CONTAINERS — libvirt/KVM, VMs declarativas,
# Docker/Podman, containers ML/dev
# ═══════════════════════════════════════════════════════════

{
  kernelcore.virtualization = {
    # TODO: Needs ajustments related to libvirt-kvm root and user group permissions, need sync and tests
    enable = false;
    virt-manager = true;
    libvirtdGroup = [ "libvirtd" ];
    virtiofs.enable = true;
    vmBaseDir = "/srv/vms/images";
    sourceImageDir = "/var/lib/vm-images";

    macos-kvm = {
      enable = false;
      autoDetectResources = true;
      maxCores = 8;
      maxMemoryGB = 32;
      diskSizeGB = 256;
      cpuModel = "Cascadelake-Server";
      memoryPrealloc = true;
      sshPort = 10022;
      vncPort = 5900;
      sshUser = "admin";
      display.virtioGl = true;
      enableQmpSocket = true;
      enableMonitorSocket = true;
    };

    vms = {
      wazuh = {
        enable = false;
        sourceImage = "wazuh.qcow2";
        imageFile = null;
        memoryMiB = 4096;
        vcpus = 2;
        network = "nat";
        bridgeName = "br0";
        enableClipboard = true;
        sharedDirs = [
          {
            path = "/srv/vms/shared";
            tag = "hostshare";
            driver = "virtiofs";
            readonly = false;
            create = true;
          }
        ];
        autostart = false;
      };

      nx = {
        enable = false;
        sourceImage = "voidnx.qcow2";
        memoryMiB = 4096;
        vcpus = 2;
        network = "nat";
        bridgeName = "br0";
        autostart = false;
        sharedDirs = [
          {
            path = "/srv/vms/shared";
            tag = "hostshare";
            driver = "virtiofs";
            readonly = false;
            create = true;
          }
        ];
        enableClipboard = true;
      };
    };
  };

  kernelcore.virtualization.vmctl-cli = {
    enable = false;
    vms.wazuh = {
      image = "/var/lib/vm-images/wazuh.qcow2";
      memory = "4G";
      cpus = 2;
    };
  };

  kernelcore.containers = {
    docker.enable = false;
    podman = {
      enable = false;
      dockerCompat = false;
      enableNvidia = true;
    };
    nixos.enable = false;

    # ML/AI Containers
    ml = {
      enable = false;

      # Ollama with llama.cpp from host
      ollama = {
        enable = true;
        port = 11434;
        modelsPath = "/var/lib/ollama/models";
        bindLlamaCpp = true; # Bind llama.cpp from host
      };

      # Jupyter Lab for ML development
      jupyter = {
        enable = true;
        port = 8888;
        notebooksPath = "/home/kernelcore/dev/notebooks";
      };
    };

    # Development Containers
    dev = {
      enable = false;

      # VS Code in browser – accessible via dev-code-start / dev-code-enter
      code-server = {
        enable = true;
        port = 8443;
        workspacePath = "/home/kernelcore/dev";
      };

      # Reverse proxy (Caddy)
      proxy = {
        enable = true;
        httpPort = 80;
        httpsPort = 443;
      };
    };
  };
}
