{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hardware.trezor;
in
{
  options.hardware.trezor = {
    enable = mkEnableOption "Trezor hardware wallet udev rules";

    enableSSHAgent = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Trezor as SSH authentication agent";
    };
  };

  config = mkIf cfg.enable {
    # Add trezor package for trezorctl and dependencies
    environment.systemPackages =
      with pkgs;
      [
        trezor-suite
        trezor_agent
      ]
      ++ optionals cfg.enableSSHAgent [
        libagent
        pinentry
      ];

    # Trezor udev rules
    services.udev.packages = with pkgs; [
      trezor-udev-rules
    ];

    # Add user to plugdev group for Trezor access
    users.groups.plugdev = { };

    # Note: Users need to be added to plugdev group manually
    # users.users.<username>.extraGroups = [ "plugdev" ];

    # ============================================================
    # SSH Agent Configuration with Trezor
    # ============================================================

    # System-wide environment for SSH agent
    environment.variables = mkIf cfg.enableSSHAgent {
      # Use gpg-agent with SSH support
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh";
    };

    # Instructions for users
    environment.etc."trezor/ssh-setup-instructions.txt" = mkIf cfg.enableSSHAgent {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║              Trezor SSH Agent Setup Instructions               ║
        ╚════════════════════════════════════════════════════════════════╝

        ## INITIAL SETUP:

        1. Connect your Trezor device to the computer

        2. Initialize Trezor SSH identity:
           $ trezor-agent user@hostname -v

           This will:
           - Generate a unique SSH public key from your Trezor
           - Display the public key for you to copy

        3. Add the public key to your target server:
           $ trezor-agent user@hostname -v | ssh-add -

           Or manually copy it to ~/.ssh/authorized_keys on the target server

        4. Export your SSH public key:
           $ trezor-agent user@hostname -v > ~/.ssh/trezor_rsa.pub

        ## DAILY USE:

        1. Connect to SSH using Trezor:
           $ trezor-agent user@hostname -- ssh user@hostname

           The Trezor will prompt you to confirm the connection on the device.

        2. For SCP/RSYNC with Trezor:
           $ trezor-agent user@hostname -- scp file.txt user@hostname:/path/
           $ trezor-agent user@hostname -- rsync -av /local/ user@hostname:/remote/

        3. For Git operations with Trezor SSH:
           $ trezor-agent user@hostname -- git push

        ## ADVANCED: Shell Wrapper

        Create an alias in your shell config (~/.bashrc or home-manager):

           alias tssh='trezor-agent user@hostname -- ssh'
           alias tgit='trezor-agent git@github.com -- git'

        Then use:
           $ tssh user@hostname
           $ tgit push

        ## GPG + SSH INTEGRATION (Alternative Method):

        If you prefer using GPG with Trezor for SSH:

        1. Set up Trezor GPG:
           $ trezor-gpg init "Your Name <email@example.com>"

        2. Get your GPG key ID:
           $ gpg --list-keys

        3. Enable SSH authentication subkey:
           $ gpg --expert --edit-key YOUR_KEY_ID
           gpg> addkey
           (Select: RSA - sign, encrypt, authenticate)
           gpg> save

        4. Export SSH public key from GPG:
           $ gpg --export-ssh-key YOUR_KEY_ID > ~/.ssh/trezor_gpg.pub

        5. Configure GPG agent (already done in home-manager):
           - enableSshSupport = true (in gpg-agent config)

        6. Add to target server's authorized_keys:
           $ cat ~/.ssh/trezor_gpg.pub | ssh user@host 'cat >> ~/.ssh/authorized_keys'

        ## TROUBLESHOOTING:

        - "Device not found": Check USB connection and udev rules
        - "Permission denied": Ensure you're in 'plugdev' group (check: groups)
        - "Agent not responding": Restart gpg-agent (gpgconf --kill gpg-agent)
        - Trezor not prompting: Update Trezor firmware and try again

        ## SECURITY NOTES:

        - Your private key NEVER leaves the Trezor device
        - Each SSH connection requires physical confirmation on Trezor
        - Different identities can be generated for different servers
        - Lost Trezor? Your SSH access is protected by your recovery seed

        ## USEFUL COMMANDS:

        - List GPG keys: gpg --list-keys
        - Restart GPG agent: gpgconf --kill gpg-agent
        - Check SSH agent: ssh-add -L
        - Test Trezor connection: trezorctl ping

        For more information:
        - https://github.com/romanz/trezor-agent
        - man trezor-agent
      '';
      mode = "0644";
    };
  };
}
