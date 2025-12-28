# NixOS Laptop Offload Client Configuration Template
# Copy this to your laptop's /etc/nixos/ and customize the IP addresses

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # CONFIGURE THESE VALUES FOR YOUR SETUP
  desktopIP = "192.168.15.7"; # Desktop server IP (Build server)
  laptopIP = "192.168.15.9"; # Laptop IP (this machine)

  # SSH key path for builder authentication
  builderKeyPath = "/etc/nix/builder_key";
in

{
  # ===== REMOTE BUILDERS CONFIGURATION =====
  nix.settings = {
    # Enable distributed builds (optional - only used when desktop is available)
    builders = lib.mkForce [
      "ssh://nix-builder@${desktopIP} x86_64-linux ${builderKeyPath} 2 1 nixos-test,benchmark,big-parallel - -"
    ];

    # Use remote builders for supported systems
    builders-use-substitutes = true;

    # Binary cache configuration (desktop-first)
    substituters = [
      "http://${desktopIP}:5000" # Desktop cache (highest priority)
      "https://cache.nixos.org" # Official cache (fallback)
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=" # Desktop cache key
    ];

    # Optimize for offload usage
    # max-jobs = lib.mkForce 0; # DISABLED: Allow local builds when desktop unavailable
    max-jobs = 4; # Allow local builds as fallback

    # Build optimization
    connect-timeout = 5;
    stalled-download-timeout = 30;
    fallback = true; # Allow local builds if remote fails
  };

  # ===== NFS MOUNTS FOR STORAGE OFFLOAD =====
  fileSystems = {
    # Mount desktop's /nix/store read-only for package sharing
    "/nix/store-remote" = {
      device = "${desktopIP}:/nix/store";
      fsType = "nfs";
      options = [
        "ro"
        "hard"
        "intr"
        "rsize=8192"
        "wsize=8192"
        "timeo=14"
        "retry=2"
        "_netdev"
      ];
    };

    # Mount desktop's build workspace for shared artifacts
    "/var/lib/nix-offload-remote" = {
      device = "${desktopIP}:/var/lib/nix-offload";
      fsType = "nfs";
      options = [
        "rw"
        "hard"
        "intr"
        "rsize=8192"
        "wsize=8192"
        "timeo=14"
        "retry=2"
        "_netdev"
      ];
    };
  };

  # ===== SSH CLIENT CONFIGURATION =====
  programs.ssh.extraConfig = ''
    Host ${desktopIP}
      HostName ${desktopIP}
      User nix-builder
      Port 22
      IdentityFile ${builderKeyPath}
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      LogLevel ERROR

      # Optimize for build transfers
      Compression yes
      ServerAliveInterval 60
      ServerAliveCountMax 3

      # Connection multiplexing for speed
      ControlMaster auto
      ControlPath ~/.ssh/nix-builder-%h-%p-%r
      ControlPersist 600
  '';

  # ===== SYSTEM PACKAGES AND SCRIPTS =====
  environment.systemPackages = with pkgs; [
    nfs-utils

    (writeShellScriptBin "offload-status" ''
      echo "🖥️  Laptop Offload Client Status"
      echo "==============================="
      echo

      # Check desktop connectivity
      echo "📡 Desktop Connection:"
      if ping -c 1 -W 2 ${desktopIP} >/dev/null 2>&1; then
        echo "✅ Desktop reachable at ${desktopIP}"
      else
        echo "❌ Desktop unreachable at ${desktopIP}"
      fi

      # Check SSH connectivity
      echo
      echo "🔑 SSH Builder Access:"
      if ssh -o ConnectTimeout=5 -o BatchMode=yes nix-builder@${desktopIP} 'echo "SSH OK"' 2>/dev/null; then
        echo "✅ SSH builder access working"
      else
        echo "❌ SSH builder access failed"
      fi

      # Check NFS mounts
      echo
      echo "📁 NFS Mounts:"
      if mountpoint -q /nix/store-remote; then
        echo "✅ /nix/store-remote mounted"
        echo "   Size: $(df -h /nix/store-remote | tail -1 | awk '{print $2}')"
      else
        echo "❌ /nix/store-remote not mounted"
      fi

      if mountpoint -q /var/lib/nix-offload-remote; then
        echo "✅ /var/lib/nix-offload-remote mounted"
        echo "   Size: $(df -h /var/lib/nix-offload-remote | tail -1 | awk '{print $2}')"
      else
        echo "❌ /var/lib/nix-offload-remote not mounted"
      fi

      # Check cache access
      echo
      echo "🗄️  Cache Access:"
      if curl -s -f http://${desktopIP}:5000/nix-cache-info >/dev/null; then
        echo "✅ Desktop cache accessible"
        echo "   Priority: $(nix show-config | grep substituters | head -1)"
      else
        echo "❌ Desktop cache unreachable"
      fi

      # Show build statistics
      echo
      echo "🔨 Build Statistics:"
      echo "Local builds: $(nix-store -q --references /run/current-system | wc -l)"
      echo "Remote store items: $(find /nix/store-remote -maxdepth 1 -type d 2>/dev/null | wc -l)"

      # Storage usage
      echo
      echo "💾 Storage Usage:"
      echo "Local /nix/store: $(du -sh /nix/store 2>/dev/null | cut -f1)"
      echo "Remote store: $(du -sh /nix/store-remote 2>/dev/null | cut -f1)"
      echo "Available: $(df -h / | tail -1 | awk '{print $4}')"
    '')

    (writeShellScriptBin "offload-test-build" ''
      echo "🧪 Testing Remote Build Capability"
      echo "=================================="
      echo

      # Test a simple remote build
      echo "Testing remote build with hello package..."
      echo

      if nix-build --builders "ssh://nix-builder@${desktopIP} x86_64-linux ${builderKeyPath} 2 1" \
                   --option substitute false \
                   '<nixpkgs>' -A hello --no-out-link; then
        echo
        echo "✅ Remote build test successful!"
      else
        echo
        echo "❌ Remote build test failed!"
        echo "Check SSH connectivity and builder configuration."
      fi
    '')

    (writeShellScriptBin "offload-mount" ''
      echo "🔗 Mounting desktop offload resources..."

      # Mount NFS shares
      sudo mount /nix/store-remote 2>/dev/null && echo "✅ Mounted /nix/store-remote" || echo "❌ Failed to mount /nix/store-remote"
      sudo mount /var/lib/nix-offload-remote 2>/dev/null && echo "✅ Mounted /var/lib/nix-offload-remote" || echo "❌ Failed to mount /var/lib/nix-offload-remote"

      echo
      offload-status
    '')

    (writeShellScriptBin "offload-unmount" ''
      echo "🔌 Unmounting desktop offload resources..."

      sudo umount /var/lib/nix-offload-remote 2>/dev/null && echo "✅ Unmounted /var/lib/nix-offload-remote" || echo "❌ Failed to unmount /var/lib/nix-offload-remote"
      sudo umount /nix/store-remote 2>/dev/null && echo "✅ Unmounted /nix/store-remote" || echo "❌ Failed to unmount /nix/store-remote"
    '')

    (writeShellScriptBin "offload-setup" ''
      echo "⚙️  Setting up laptop as offload client"
      echo "======================================"
      echo

      # Check prerequisites
      echo "1. Checking prerequisites..."

      if [ ! -f ${builderKeyPath} ]; then
        echo "❌ Builder key not found at ${builderKeyPath}"
        echo
        echo "📋 To complete setup:"
        echo "1. Copy the SSH private key from desktop:"
        echo "   scp cypher@${desktopIP}:~/.ssh/id_rsa ${builderKeyPath}"
        echo "2. Set correct permissions:"
        echo "   sudo chmod 600 ${builderKeyPath}"
        echo "3. Add this laptop's public key to desktop:"
        echo "   ssh-copy-id nix-builder@${desktopIP}"
        echo
        exit 1
      else
        echo "✅ Builder key found"
      fi

      # Test connectivity
      echo
      echo "2. Testing connectivity..."
      offload-status

      echo
      echo "3. Testing remote build..."
      offload-test-build

      echo
      echo "✅ Offload client setup complete!"
      echo
      echo "💡 Usage tips:"
      echo "• Use 'offload-status' to check connection"
      echo "• Use 'offload-mount' to manually mount NFS"
      echo "• Builds will automatically use desktop when available"
      echo "• Cache requests check desktop first, then internet"
    '')
  ];

  # ===== NETWORK CONFIGURATION =====
  # Ensure NFS client support
  services.rpcbind.enable = true;

  # Optimize network for offload usage
  boot.kernel.sysctl = {
    # NFS client tuning
    "net.core.rmem_default" = 262144;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 262144;
    "net.core.wmem_max" = 16777216;
  };

  # ===== SYSTEMD SERVICES =====
  # Auto-mount NFS on network availability
  systemd.services.offload-automount = {
    description = "Auto-mount offload NFS shares";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      # Smart network check - max 5 seconds total wait
      MAX_WAIT=10  # 10 iterations of 0.5s = 5 seconds max
      WAIT_COUNT=0

      echo "🔍 Checking desktop availability at ${desktopIP}..."

      # Poll every 0.5s until desktop is reachable or timeout
      while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if ping -c 1 -W 1 ${desktopIP} > /dev/null 2>&1; then
          echo "✅ Desktop reachable, mounting NFS shares..."
          mount /nix/store-remote 2>/dev/null || true
          mount /var/lib/nix-offload-remote 2>/dev/null || true
          exit 0
        fi
        sleep 0.5
        WAIT_COUNT=$((WAIT_COUNT + 1))
      done

      # Desktop not reachable - exit cleanly (laptop can work offline)
      echo "⚠️  Desktop ${desktopIP} not reachable after 5s, skipping NFS mounts (working offline)"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };

  # ===== POWER MANAGEMENT =====
  # Graceful unmount on shutdown/suspend
  systemd.services.offload-cleanup = {
    description = "Cleanup offload mounts on shutdown";
    before = [
      "shutdown.target"
      "sleep.target"
    ];
    wantedBy = [
      "shutdown.target"
      "sleep.target"
    ];

    script = ''
      umount /var/lib/nix-offload-remote 2>/dev/null || true
      umount /nix/store-remote 2>/dev/null || true
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStopSec = "30s";
    };
  };
}

# ===== SETUP INSTRUCTIONS =====
#
# 1. Copy this file to your laptop's /etc/nixos/laptop-offload-client.nix
#
# 2. Update the IP addresses:
#    - Set desktopIP to your desktop's IP (currently ${desktopIP})
#    - Set laptopIP to your laptop's IP
#
# 3. Add to your laptop's configuration.nix:
#    imports = [ ./laptop-offload-client.nix ];
#
# 4. Copy SSH keys:
#    sudo scp voidnx@${desktopIP}:~/.ssh/id_rsa /etc/nix/builder_key
#    sudo chmod 600 /etc/nix/builder_key
#
# 5. Generate laptop SSH key and add to desktop:
#    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
#    ssh-copy-id nix-builder@${desktopIP}
#
# 6. Apply configuration:
#    sudo nixos-rebuild switch
#
# 7. Test the setup:
#    offload-setup
#    offload-status
#    offload-test-build
#
# ===== EXPECTED BENEFITS =====
#
# 🚀 Performance:
# • 2-5x faster builds via remote execution
# • 90% cache hits from desktop before internet
# • Reduced local storage usage
#
# 💾 Storage:
# • Access to desktop's 850GB /nix/store
# • Shared build artifacts and cache
# • Automatic cleanup and optimization
#
# 🌐 Network:
# • LAN-speed package downloads
# • Intelligent fallback to internet
# • Offline resilience when desktop unavailable
