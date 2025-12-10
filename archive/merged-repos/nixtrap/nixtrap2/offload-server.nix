{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NixOS Desktop Offload Server - Complete Implementation
  # Serves laptop with storage, builds, and cache offloading

  # ===== NFS SERVER FOR STORAGE OFFLOAD =====
  services.nfs.server = {
    enable = true;
    exports = ''
      # Export /nix/store read-only to LAN
      /nix/store 192.168.15.0/24(ro,sync,no_subtree_check,no_root_squash)

      # Export build workspace read-write  
      /var/lib/nix-offload 192.168.15.0/24(rw,sync,no_subtree_check,no_root_squash)

      # Export cache storage
      /var/cache/nix-serve 192.168.15.0/24(ro,sync,no_subtree_check,no_root_squash)
    '';
  };

  # Configure NFS ports manually via services
  services.rpcbind.enable = true;

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-offload 0755 root root -"
    "d /var/lib/nix-offload/builds 0755 root root -"
    "d /var/lib/nix-offload/cache 0755 root root -"
    "d /var/lib/nix-offload/logs 0755 root root -"
  ];

  # ===== SSH CONFIGURATION FOR REMOTE BUILDERS =====
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      AllowUsers = [
        "voidnx"
        "nix-builder"
      ];
    };
    extraConfig = ''
      # Optimize for build transfers
      Compression yes
      TCPKeepAlive yes
      ClientAliveInterval 60
      ClientAliveCountMax 3
    '';
  };

  # Create dedicated builder user
  users.users.nix-builder = {
    isSystemUser = true;
    group = "nix-builder";
    home = "/var/lib/nix-builder";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Desktop's own key for local testing
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCukF93mPDil5qsoY1HFTlA8g8rAajjyks7m7HFWHgApI4iecCvRCSn7TJT+QpDWkWBglbmPeHkpQ2Gt+4At2Nn1pF0MeVzD/x7bM2rqH0EaJxGnozsfYGTMFq94vY7ZFhQn22z9jiXV2sGFq3VhpQmY6V+of8XbaYGSRZ0I3haptpYAPzr7C5cHuRa4432sQKTufqUipQrcVnJQqxcguGhA+TUi/62hHLMDPL2xpmqMkyE8HRLeq9V7JwSC7NwVwdZ1dCAHnRj0vyOB2yHq5y1KzHdU4OXG7KNV07kEPC8Jyc1wAsmc8Ilkqoa4Xeo27VJ7aWwOVh0ir2HKdL9BEvJOLvjD2QeKaWNf2N0XanCY3ZLZfTZvGT6XJtdsQdx5gT9FSbvY6LC59hEedy2UjYfG7GRh0Vk2PWrDwh62tZE6smJYHCplv/R5/wiDWOeHtI+6G+edJ6UlS7BTRUX+/l7vvT3j0uqZX19leXTbFkScbvDH1zw8Iu1tC1ivdf8etpHbh5P+Y6xaZnHGez5Ccvj5979Das/tLgDMhPv6jVPZo2PiVsnXpCMSxSwVqz3Vk7W0fM1cFVVtFfB2EYeQzQvKTgGlSjjVm+Am//PCQ4DcjqQG72XiXjKsBht/GyVsZmYqGTR4qki8y00s5TlcFLGbg++NAm6lxd/k4B/Ko6VtQ== voidnx@nixos-desktop-builder"
      # Add laptop's SSH key here when configuring client
    ];
  };

  users.groups.nix-builder = { };

  # ===== NIX DISTRIBUTED BUILDS CONFIGURATION =====
  nix.settings = {
    # Enable as a build machine
    trusted-users = [
      "root"
      "voidnx"
      "nix-builder"
    ];

    # Optimize for distributed builds
    max-jobs = lib.mkForce 2; # Use both CPU cores for offload builds
    cores = 0; # Use all available cores per job

    # Build machine specific settings
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
    ];

    # Cache settings for offload
    keep-outputs = true;
    keep-derivations = true;

    # Network optimization
    connect-timeout = 5;
    stalled-download-timeout = 30;
  };

  # ===== PERFORMANCE MONITORING SERVICES =====
  systemd.services.offload-monitor = {
    description = "Monitor offload server performance";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "nfs-server.service"
    ];

    script = ''
            #!/bin/sh
            LOG_FILE="/var/lib/nix-offload/logs/monitor.log"
            
            log() {
              echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
            }
            
            while true; do
              # Check system resources
              CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
              MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
              DISK_USAGE=$(df /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
              
              # Check services
              NFS_STATUS=$(systemctl is-active nfs-server && echo "UP" || echo "DOWN")
              SSH_STATUS=$(systemctl is-active sshd && echo "UP" || echo "DOWN")
              CACHE_STATUS=$(systemctl is-active nix-serve && echo "UP" || echo "DOWN")
              
              # Check network connections
              ACTIVE_BUILDS=$(ss -tn state established '( dport = :22 )' | wc -l)
              CACHE_REQUESTS=$(ss -tn state established '( dport = :5000 )' | wc -l)
              
              # Log status
              log "CPU: $CPU_USAGE% | MEM: $MEM_USAGE% | DISK: $DISK_USAGE% | NFS: $NFS_STATUS | SSH: $SSH_STATUS | CACHE: $CACHE_STATUS | BUILDS: $ACTIVE_BUILDS | REQUESTS: $CACHE_REQUESTS"
              
              # Create status JSON for MCP
              cat > /var/lib/nix-offload/status.json <<EOF
      {
        "timestamp": "$(date -Iseconds)",
        "cpu_usage": "$CPU_USAGE",
        "memory_usage": "$MEM_USAGE", 
        "disk_usage": "$DISK_USAGE",
        "services": {
          "nfs": "$NFS_STATUS",
          "ssh": "$SSH_STATUS", 
          "cache": "$CACHE_STATUS"
        },
        "connections": {
          "active_builds": $ACTIVE_BUILDS,
          "cache_requests": $CACHE_REQUESTS
        }
      }
      EOF
              
              sleep 30
            done
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10s";
      User = "root";
    };
  };

  # ===== CLEANUP AND OPTIMIZATION SERVICE =====
  systemd.services.offload-cleanup = {
    description = "Cleanup and optimize offload storage";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "offload-cleanup" ''
        #!/bin/sh

        # Cleanup old build logs
        find /var/lib/nix-offload/logs -name "*.log" -mtime +7 -delete

        # Optimize nix store
        nix-store --optimize

        # Cleanup old cache entries
        find /var/cache/nix-serve -name "*.tmp" -mtime +1 -delete

        # Update cache statistics
        STORE_SIZE=$(du -sh /nix/store | cut -f1)
        OFFLOAD_SIZE=$(du -sh /var/lib/nix-offload | cut -f1)
        echo "$(date): Store: $STORE_SIZE, Offload: $OFFLOAD_SIZE" >> /var/lib/nix-offload/logs/sizes.log
      ''}";
    };
  };

  # Run cleanup daily
  systemd.timers.offload-cleanup = {
    description = "Daily offload cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # ===== FIREWALL CONFIGURATION =====
  networking.firewall = {
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP cache
      443 # HTTPS cache (future)
      2049 # NFS
      4000 # NFS statd
      4001 # NFS lockd
      4002 # NFS mountd
      5000 # nix-serve
      111 # RPC portmapper
    ];
    allowedUDPPorts = [
      111 # RPC portmapper
      2049 # NFS
      4000 # NFS statd
      4001 # NFS lockd
      4002 # NFS mountd
    ];
  };

  # ===== MANAGEMENT SCRIPTS =====
  environment.systemPackages = with pkgs; [
    nfs-utils
    (writeShellScriptBin "offload-status" ''
      echo "=== NixOS Offload Server Status ==="
      echo
      echo "📊 System Resources:"
      echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')%"
      echo "Memory: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
      echo "Disk (/nix/store): $(df -h /nix/store | tail -1 | awk '{print $4}') free"
      echo
      echo "🌐 Network & Services:"
      systemctl is-active --quiet nfs-server && echo "✅ NFS Server: Running" || echo "❌ NFS Server: Failed"
      systemctl is-active --quiet sshd && echo "✅ SSH Server: Running" || echo "❌ SSH Server: Failed"  
      systemctl is-active --quiet nix-serve && echo "✅ Cache Server: Running" || echo "❌ Cache Server: Failed"
      echo "IP Address: $(ip route get 1.1.1.1 | awk '{print $7}' | head -1)"
      echo
      echo "🔗 Active Connections:"
      echo "SSH builds: $(ss -tn state established '( dport = :22 )' | wc -l)"
      echo "Cache requests: $(ss -tn state established '( dport = :5000 )' | wc -l)"
      echo
      echo "📁 Storage Usage:" 
      echo "Nix store: $(du -sh /nix/store 2>/dev/null | cut -f1)"
      echo "Offload data: $(du -sh /var/lib/nix-offload 2>/dev/null | cut -f1)"
      echo
      if [ -f /var/lib/nix-offload/status.json ]; then
        echo "📈 Live Status (JSON):"
        cat /var/lib/nix-offload/status.json | ${jq}/bin/jq '.'
      fi
    '')

    (writeShellScriptBin "offload-test" ''
      echo "🧪 Testing Offload Server Components..."
      echo

      # Test NFS
      echo "Testing NFS exports:"
      showmount -e localhost || echo "❌ NFS exports failed"
      echo

      # Test SSH
      echo "Testing SSH access:"
      ssh -o ConnectTimeout=5 -o BatchMode=yes localhost 'echo "SSH OK"' 2>/dev/null || echo "❌ SSH test failed"
      echo

      # Test Cache
      echo "Testing cache server:"
      curl -s -f http://localhost:5000/nix-cache-info >/dev/null && echo "✅ Cache server OK" || echo "❌ Cache server failed"
      echo

      # Test Network
      echo "Testing network connectivity:"
      ping -c 1 -W 2 192.168.15.1 >/dev/null && echo "✅ Network OK" || echo "❌ Network issues"
      echo

      echo "🎯 Offload server ready for clients!"
    '')

    (writeShellScriptBin "offload-setup-client" ''
            echo "🔧 Setting up laptop as offload client..."
            
            if [ $# -ne 1 ]; then
              echo "Usage: offload-setup-client <laptop-ip>"
              exit 1
            fi
            
            LAPTOP_IP="$1"
            SERVER_IP="$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)"
            
            echo "Server IP: $SERVER_IP"
            echo "Laptop IP: $LAPTOP_IP"
            echo
            
            # Generate SSH key for laptop if needed
            if [ ! -f ~/.ssh/id_rsa ]; then
              ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            fi
            
            echo "📋 Configuration for laptop /etc/nixos/configuration.nix:"
            echo
            cat <<EOF
      # Add to laptop configuration.nix:
      nix.settings = {
        substituters = [
          "https://cache.nixos.org"
          "http://$SERVER_IP:5000"  # Desktop cache
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE="
        ];
        builders = [
          "ssh://nix-builder@$SERVER_IP x86_64-linux /etc/nix/builder_key 2 1 nixos-test,benchmark,big-parallel"
        ];
        builders-use-substituters = true;
      };

      # NFS mounts for storage offload
      fileSystems."/nix/store-remote" = {
        device = "$SERVER_IP:/nix/store";
        fsType = "nfs";
        options = [ "ro" "hard" "intr" ];
      };
      EOF
            echo
            echo "📝 Next steps:"
            echo "1. Copy this configuration to laptop"
            echo "2. Copy SSH key to laptop: scp ~/.ssh/id_rsa laptop:/etc/nix/builder_key"
            echo "3. Add laptop's public key to server"
            echo "4. Run: nixos-rebuild switch"
    '')

    (writeShellScriptBin "offload-logs" ''
      echo "📄 Recent offload server logs:"
      echo
      echo "=== Monitor Logs ==="
      tail -20 /var/lib/nix-offload/logs/monitor.log 2>/dev/null || echo "No monitor logs yet"
      echo
      echo "=== NFS Logs ==="
      journalctl -u nfs-server --no-pager -n 10
      echo
      echo "=== SSH Logs ==="
      journalctl -u sshd --no-pager -n 10 | grep -v "Connection closed"
      echo
      echo "=== Cache Logs ==="
      journalctl -u nix-serve --no-pager -n 10
    '')
  ];
}
