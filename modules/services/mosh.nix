{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.services.mosh = {
      enable = mkEnableOption "Enable Mosh server for mobile shell connections";

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically open firewall ports for Mosh (UDP 60000-61000)";
      };

      portRange = mkOption {
        type = types.submodule {
          options = {
            from = mkOption {
              type = types.int;
              default = 60000;
              description = "Starting port for Mosh server";
            };
            to = mkOption {
              type = types.int;
              default = 61000;
              description = "Ending port for Mosh server";
            };
          };
        };
        default = {
          from = 60000;
          to = 61000;
        };
        description = "UDP port range for Mosh connections";
      };

      enableMotd = mkOption {
        type = types.bool;
        default = true;
        description = "Display message of the day on Mosh connections";
      };
    };
  };

  config = mkIf config.kernelcore.services.mosh.enable {
    # Install Mosh package
    environment.systemPackages = with pkgs; [
      mosh
    ];

    # Configure Mosh server
    programs.mosh = {
      enable = true;
      # Mosh works over SSH, so SSH must be enabled
      # OpenSSH configuration is handled by modules/security/ssh.nix
    };

    # Open firewall for Mosh UDP ports
    networking.firewall = mkIf config.kernelcore.services.mosh.openFirewall {
      allowedUDPPortRanges = [
        {
          from = config.kernelcore.services.mosh.portRange.from;
          to = config.kernelcore.services.mosh.portRange.to;
        }
      ];
    };

    # Message of the Day for Mosh connections
    environment.etc."mosh/motd.txt" = mkIf config.kernelcore.services.mosh.enableMotd {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║                    Mobile Shell (Mosh) Connection              ║
        ╚════════════════════════════════════════════════════════════════╝

        Welcome to NixOS with Mosh!

        Mosh provides:
        - ✓ Seamless roaming between networks
        - ✓ Local echo for responsive typing
        - ✓ Connection survival during IP changes
        - ✓ Predictive display for low-latency feel

        System: ${config.networking.hostName}
        Kernel: ${pkgs.linux.version or "N/A"}

        For help, visit: https://mosh.org/

      '';
      mode = "0644";
    };

    # Setup instructions file
    environment.etc."mosh/setup-instructions.txt" = {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║              Mosh Server Setup - iOS Blink Shell              ║
        ╚════════════════════════════════════════════════════════════════╝

        ## SERVER CONFIGURATION (NixOS):

        Mosh server is now ENABLED and configured with:
        - Port Range: UDP ${toString config.kernelcore.services.mosh.portRange.from}-${toString config.kernelcore.services.mosh.portRange.to}
        - Firewall: ${if config.kernelcore.services.mosh.openFirewall then "OPEN" else "CLOSED"}
        - SSH Backend: OpenSSH (configured via modules/security/ssh.nix)

        ## CLIENT SETUP (Blink Shell on iOS):

        ### 1. Install Blink Shell:
           - Download from App Store: https://apps.apple.com/app/blink-shell/id1156707581
           - Or use Build.Blink.sh for advanced features

        ### 2. Add SSH Keys to Blink:
           a. Open Blink Shell on your iOS device
           b. Type: config
           c. Tap "Keys"
           d. Generate new key or import existing key
           e. Copy the public key

        ### 3. Add Your iOS Public Key to This Server:
           On the NixOS server, run:

           # Create .ssh directory if it doesn't exist
           mkdir -p ~/.ssh
           chmod 700 ~/.ssh

           # Add your iOS device's public key
           echo "YOUR_PUBLIC_KEY_FROM_BLINK" >> ~/.ssh/authorized_keys
           chmod 600 ~/.ssh/authorized_keys

        ### 4. Configure Mosh Host in Blink:
           a. In Blink, type: config
           b. Tap "Hosts"
           c. Tap "+" to add new host
           d. Configure:
              - Host: ${config.networking.hostName}
              - HostName: YOUR_SERVER_IP_OR_DOMAIN
              - Port: 22 (SSH port)
              - User: kernelcore (or your username)
              - Key: Select the key you added
              - Mosh: Enable toggle (turn ON)
              - Mosh Port: ${toString config.kernelcore.services.mosh.portRange.from}
              - Mosh Server: mosh-server (default)
              - Mosh Startup: (leave empty)

        ### 5. Connect from Blink:
           Simply type in Blink:

           mosh kernelcore@YOUR_SERVER_IP

           Or use the saved host:

           mosh ${config.networking.hostName}

        ## FIREWALL CONFIGURATION:

        If connecting from outside your local network:
        - Port forward UDP ${toString config.kernelcore.services.mosh.portRange.from}-${toString config.kernelcore.services.mosh.portRange.to} on your router
        - SSH port 22 (TCP) must also be accessible
        - Consider using Tailscale for secure remote access

        ## ADVANCED OPTIONS:

        ### Custom Mosh Server Path:
        If using custom mosh-server location:
        mosh --server=/custom/path/to/mosh-server user@host

        ### Specify Port Range:
        mosh -p 60001 user@host

        ### SSH Configuration:
        Mosh uses SSH for initial authentication, then switches to UDP.
        SSH configuration is managed by: /etc/nixos/modules/security/ssh.nix

        ## TROUBLESHOOTING:

        ### "Connection refused" or "No route to host":
        - Check firewall: sudo firewall-cmd --list-all
        - Verify SSH works first: ssh kernelcore@YOUR_SERVER_IP
        - Check Mosh server is installed: which mosh-server

        ### "mosh-server not found":
        - Ensure mosh is in PATH on server
        - Try: mosh --server=/run/current-system/sw/bin/mosh-server user@host

        ### "Connection times out after SSH":
        - Verify UDP ports ${toString config.kernelcore.services.mosh.portRange.from}-${toString config.kernelcore.services.mosh.portRange.to} are open
        - Check router port forwarding for UDP
        - Test local network first before trying remote

        ### "Permission denied (publickey)":
        - SSH keys issue - fix SSH first
        - Verify public key is in ~/.ssh/authorized_keys
        - Check key permissions: chmod 600 ~/.ssh/authorized_keys

        ## USEFUL COMMANDS:

        Test SSH connection first:
        ssh kernelcore@YOUR_SERVER_IP

        Connect with verbose output:
        mosh --ssh="ssh -v" kernelcore@YOUR_SERVER_IP

        Check open Mosh sessions:
        ps aux | grep mosh-server

        Kill stuck Mosh sessions:
        pkill -u $USER mosh-server

        View Mosh logs:
        journalctl -u sshd -f

        ## SECURITY NOTES:

        - Mosh uses SSH for authentication, then encrypted UDP for session
        - AES-128-OCB encryption for the session
        - No authentication after initial SSH handshake
        - Server doesn't accept inbound connections after session start
        - Firewall rules only allow UDP for established sessions

        For more information:
        - Mosh documentation: https://mosh.org/
        - Blink Shell docs: https://docs.blink.sh/
      '';
      mode = "0644";
    };

    # Add shell aliases for Mosh management
    environment.shellAliases = {
      mosh-sessions = "ps aux | grep mosh-server";
      mosh-kill = "pkill -u $USER mosh-server";
      mosh-test = "echo 'Testing Mosh installation:' && mosh-server --version && echo 'Mosh is working!'";
    };

    # Ensure SSH is enabled (Mosh requires SSH)
    assertions = [
      {
        assertion = config.services.openssh.enable;
        message = "Mosh requires SSH to be enabled. Enable kernelcore.security.ssh or services.openssh";
      }
    ];
  };
}
