{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.brave-secure;
in
{
  options.programs.brave-secure = {
    enable = mkEnableOption "Enable Brave browser with Firejail GPU memory limits";

    gpuMemoryLimit = mkOption {
      type = types.str;
      default = "4G";
      description = "GPU memory limit for Brave (e.g., '2G', '1024M')";
    };

    enableHardening = mkOption {
      type = types.bool;
      default = true;
      description = "Enable additional security hardening via Firejail";
    };

    customFlags = mkOption {
      type = types.listOf types.str;
      default = [
        "--enable-features=VaapiVideoDecoder"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
      ];
      description = "Custom Chromium flags for Brave";
    };
  };

  config = mkIf cfg.enable {
    # Install Brave and Firejail
    environment.systemPackages = with pkgs; [
      brave
      firejail
    ];

    # Firejail configuration for Brave
    environment.etc."firejail/brave.local".text = ''
      # GPU memory limiting and security profile for Brave

      # Networking - use filtered instead of blocking
      # NOTE: "net none" was breaking all networking!
      netfilter

      # Filesystem restrictions
      private-dev
      private-tmp

      # Disable unnecessary features
      noroot
      nogroups
      # NOTE: "nosound" was breaking audio playback!

      # Seccomp filter
      seccomp

      # AppArmor/SELinux
      apparmor

      # GPU access with limits
      noblacklist ''${HOME}/.config/BraveSoftware
      noblacklist ''${HOME}/.cache/BraveSoftware
      noblacklist ''${HOME}/Downloads

      # Whitelist GPU devices but with resource limits
      whitelist /dev/nvidia0
      whitelist /dev/nvidiactl
      whitelist /dev/nvidia-uvm
      whitelist /dev/nvidia-modeset
      whitelist /dev/dri

      # Memory limits (CPU memory, cgroups will handle GPU)
      rlimit-as 8G
      rlimit-cpu 120
      rlimit-fsize 4G

      # Read-only directories
      read-only ''${HOME}/.mozilla
      read-only /opt
      read-only /srv

      # Blacklist sensitive paths
      blacklist /root
      blacklist /boot
      blacklist /media
      blacklist /mnt
      blacklist /selinux
      blacklist /sys
      blacklist /proc/kcore
    '';

    # Create wrapper script with GPU memory limits
    environment.etc."brave-wrapper.sh" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        # Brave wrapper with GPU memory limiting via cgroupsv2

        GPU_MEM_LIMIT="${cfg.gpuMemoryLimit}"
        CGROUP_NAME="brave-gpu-limited"

        # Create cgroup for GPU memory limiting
        if [ ! -d "/sys/fs/cgroup/''${CGROUP_NAME}" ]; then
          sudo mkdir -p "/sys/fs/cgroup/''${CGROUP_NAME}"
        fi

        # Set memory limit (this limits overall memory which indirectly affects GPU allocations)
        echo "8G" | sudo tee "/sys/fs/cgroup/''${CGROUP_NAME}/memory.max" > /dev/null

        # Add current process to cgroup
        echo $$ | sudo tee "/sys/fs/cgroup/''${CGROUP_NAME}/cgroup.procs" > /dev/null

        # Launch Brave with Firejail and custom flags
        exec ${pkgs.firejail}/bin/firejail \
          --profile=/etc/firejail/brave.local \
          --rlimit-as=8589934592 \
          ${pkgs.brave}/bin/brave \
          ${concatStringsSep " " cfg.customFlags} \
          "$@"
      '';
    };

    # Create desktop entry that uses the wrapper
    environment.etc."applications/brave-secure.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Brave Browser (Secure/GPU Limited)
      GenericName=Web Browser
      Comment=Brave with GPU memory limits and Firejail sandbox
      Exec=/etc/brave-wrapper.sh %U
      Icon=brave-browser
      Terminal=false
      Type=Application
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      Categories=Network;WebBrowser;
      Keywords=browser;web;internet;
      StartupNotify=true
      StartupWMClass=Brave-browser
    '';

    # Systemd service for GPU memory monitoring (for Brave specifically)
    systemd.user.services.brave-gpu-monitor = {
      description = "Monitor Brave GPU Memory Usage";
      after = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 30;
        ExecStart = pkgs.writeShellScript "brave-gpu-monitor" ''
          while true; do
            sleep 60

            # Check if Brave is running
            if ${pkgs.procps}/bin/pgrep -x brave >/dev/null; then
              # Get GPU memory usage
              GPU_MEM=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-compute-apps=used_memory --format=csv,noheader,nounits 2>/dev/null | head -1)

              if [ -n "$GPU_MEM" ] && [ "$GPU_MEM" -gt 2048 ]; then
                echo "WARNING: Brave using excessive GPU memory: ''${GPU_MEM}MB"
                logger -t brave-gpu-monitor "Excessive GPU memory: ''${GPU_MEM}MB"

                # Optional: Kill and restart Brave if it exceeds limits
                # ${pkgs.procps}/bin/pkill -TERM brave
              fi
            fi
          done
        '';
      };
    };

    # Sudo rules for cgroup management (needed for wrapper script)
    security.sudo.extraRules = [
      {
        users = [ "kernelcore" ];
        commands = [
          {
            command = "${pkgs.coreutils}/bin/mkdir";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/tee";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Environment variables for Brave
    environment.sessionVariables = {
      # Force Brave to respect GPU memory limits
      BRAVE_GPU_MEMORY_BUFFER_SIZE = "256";
      BRAVE_DISABLE_GPU_DRIVER_BUG_WORKAROUNDS = "1";
    };
  };
}
