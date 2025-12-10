# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cache-server.nix
    ./cache-bucket-setup.nix
    ./nginx-module.nix
    ./offload-server.nix
    ./mcp-offload-automation.nix
    # ./nar-server.nix  # Temporarily disabled for testing
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-266a3dbd-0f0b-4e8f-b0ed-44d503ea5db9".device =
    "/dev/disk/by-uuid/266a3dbd-0f0b-4e8f-b0ed-44d503ea5db9";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nixpkgs.config.allowUnfree = true;
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Memory optimization and high offload settings
  nix.settings = {
    # Enable more aggressive garbage collection
    auto-optimise-store = true;
    # Use more cores for building (offload-server.nix will override this)
    # max-jobs = "auto"; # Commented out - defined in offload-server.nix
    cores = 0; # Use all available cores
    # Memory optimization
    sandbox = true;
    # Enable remote builders and binary cache
    builders-use-substitutes = true;
    # Increase memory limits for builds
    extra-sandbox-paths = [ "/tmp" ];
  };

  # Configure zram for memory compression
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # Use 25% of RAM for compressed swap
  };

  # Kernel parameters for better memory management
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Reduce swapping tendency
    "vm.vfs_cache_pressure" = 50; # Reduce VFS cache pressure
    "vm.dirty_ratio" = 15; # Dirty page writeback ratio
    "vm.dirty_background_ratio" = 5; # Background dirty page ratio
  };
  # Enable networking
  networking.networkmanager.enable = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Set your time zone.
  time.timeZone = "America/Bahia";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable LightDM display manager (lightweight)
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.greeters.gtk.enable = true;
  services.displayManager.sessionPackages = [ pkgs.sway ];

  # Enable i3 window manager (lightweight)
  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.extraPackages = with pkgs; [
    dmenu
    i3status
    i3lock
    i3blocks
    polybar
    autotiling
    feh
    dunst
  ];

  # Provide sway as a Wayland alternative for lower resource usage
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      waybar
      wl-clipboard
      grim
      slurp
      mako
    ];
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.voidnx = {
    isNormalUser = true;
    description = "voidnx";
    extraGroups = [
      "networkmanager"
      "wheel"
      "nginx"
      "video"
      "audio"
      "render"
    ];
    packages = with pkgs; [
      # Lightweight alternatives to KDE apps
      xfce.mousepad # Lightweight text editor (instead of kate)
      xfce.thunar # Lightweight file manager
      xfce.xfce4-terminal # Lightweight terminal
      neovim
      xclip
      codex
      cmake
      ninja
      git
      rsync
      vivaldi
      python313
      claude-code
      thunderbird
      openssl
      # i3 related utilities
      rofi # Application launcher (dmenu alternative)
      nitrogen # Wallpaper setter
      picom # Compositor for transparency/effects
      alacritty # Fast terminal emulator
      swaybg
      wl-clipboard
      waybar
      # Modern i3 enhancement packages
      polybar # Modern status bar
      autotiling # Automatic tiling
      feh # Image viewer and wallpaper setter
      dunst # Notification daemon
      playerctl # Media player control
      brightnessctl # Brightness control
      pavucontrol # Audio control
      arandr # Display configuration GUI
      lxappearance # GTK theme configuration
      arc-theme # Modern GTK theme
      papirus-icon-theme # Modern icon theme
      font-awesome # Icon font for polybar
      # Modern fonts
      inter # Inter font family
      fira-code # FiraCode font
      # Mobility tools
      bluez # Bluetooth support
      bluez-tools # Bluetooth utilities
      jq # JSON processor for workspace scripts
      libnotify # Desktop notifications
      htop # System monitor
      # Performance monitoring tools
      iotop # Disk I/O monitor
      nload # Network monitor
      btop # Modern system monitor
      lm_sensors # Hardware sensors
      usbutils # USB utilities (lsusb)
      pciutils # PCI utilities (lspci)
      tree # Directory tree viewer
      ncdu # Disk usage analyzer
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    # Cache management tools
    nix-serve
    nginx
    openssl
    sway
    swaylock
    swayidle
    swaybg
    waybar
    wl-clipboard
    grim
    slurp
    foot
    # Cache management scripts
    (writeShellScriptBin "cache-server-status" ''
      #!/bin/sh
      echo "=== Cache Server Status ==="
      echo "Local URL: http://localhost:5000"
      echo "Public URL: https://cache.local"
      echo ""
      echo "Service Status:"
      systemctl status nix-serve --no-pager -l
      echo ""
      systemctl status nginx --no-pager -l
      echo ""
      echo "Cache Configuration:"
      cat /var/lib/cache-bucket/config.json 2>/dev/null || echo "Config not found"
      echo ""
      echo "Testing connectivity:"
      curl -s -I http://localhost:5000 | head -1 || echo "Local server not responding"
      curl -s -I https://cache.local 2>/dev/null | head -1 || echo "HTTPS endpoint not responding"
    '')
    (writeShellScriptBin "cache-server-restart" ''
      #!/bin/sh
      echo "Restarting cache server services..."
      sudo systemctl restart nix-serve
      sudo systemctl restart nginx
      echo "Services restarted"
      cache-server-status
    '')

    # Theme switching scripts
    (writeShellScriptBin "i3-theme-dark" ''
            #!/bin/sh
            # Switch to dark theme
            echo "Switching to dark theme..."
            
            # Update i3 config
            mkdir -p ~/.config/i3
            cat > ~/.config/i3/theme <<EOF
      # Dark Theme Colors
      set \$bg-color            #2f343f
      set \$inactive-bg-color   #2f343f
      set \$text-color          #f3f4f5
      set \$inactive-text-color #676E7D
      set \$urgent-bg-color     #E53935
      set \$indicator-color     #00ff00

      # Window colors
      #                       border              background         text                 indicator
      client.focused          \$bg-color          \$bg-color          \$text-color          \$indicator-color
      client.unfocused        \$inactive-bg-color \$inactive-bg-color \$inactive-text-color \$indicator-color
      client.focused_inactive \$inactive-bg-color \$inactive-bg-color \$inactive-text-color \$indicator-color
      client.urgent           \$urgent-bg-color   \$urgent-bg-color   \$text-color          \$indicator-color
      EOF

            # Update polybar config for dark theme
            mkdir -p ~/.config/polybar
            cat > ~/.config/polybar/colors.ini <<EOF
      [colors]
      background = #2f343f
      background-alt = #373B41
      foreground = #C5C8C6
      primary = #F0C674
      secondary = #8ABEB7
      alert = #A54242
      disabled = #707880
      EOF

            # Update rofi theme
            mkdir -p ~/.config/rofi
            cat > ~/.config/rofi/config.rasi <<EOF
      @theme "Arc-Dark"
      configuration {
          display-drun: "Applications";
          display-window: "Windows";
          drun-display-format: "{icon} {name}";
          font: "Inter 10";
          modi: "window,run,drun";
          show-icons: true;
          icon-theme: "Papirus-Dark";
      }
      EOF

            # Reload i3 and polybar
            i3-msg reload
            polybar-msg cmd restart 2>/dev/null || true
            
            echo "Dark theme applied!"
    '')

    (writeShellScriptBin "i3-theme-light" ''
            #!/bin/sh
            # Switch to light theme
            echo "Switching to light theme..."
            
            # Update i3 config
            mkdir -p ~/.config/i3
            cat > ~/.config/i3/theme <<EOF
      # Light Theme Colors
      set \$bg-color            #ffffff
      set \$inactive-bg-color   #f5f5f5
      set \$text-color          #2f343f
      set \$inactive-text-color #999999
      set \$urgent-bg-color     #E53935
      set \$indicator-color     #0066cc

      # Window colors
      #                       border              background         text                 indicator
      client.focused          \$bg-color          \$bg-color          \$text-color          \$indicator-color
      client.unfocused        \$inactive-bg-color \$inactive-bg-color \$inactive-text-color \$indicator-color
      client.focused_inactive \$inactive-bg-color \$inactive-bg-color \$inactive-text-color \$indicator-color
      client.urgent           \$urgent-bg-color   \$urgent-bg-color   \$text-color          \$indicator-color
      EOF

            # Update polybar config for light theme
            mkdir -p ~/.config/polybar
            cat > ~/.config/polybar/colors.ini <<EOF
      [colors]
      background = #ffffff
      background-alt = #f5f5f5
      foreground = #2f343f
      primary = #0066cc
      secondary = #00aa88
      alert = #cc0000
      disabled = #999999
      EOF

            # Update rofi theme
            mkdir -p ~/.config/rofi
            cat > ~/.config/rofi/config.rasi <<EOF
      @theme "Arc"
      configuration {
          display-drun: "Applications";
          display-window: "Windows";
          drun-display-format: "{icon} {name}";
          font: "Inter 10";
          modi: "window,run,drun";
          show-icons: true;
          icon-theme: "Papirus";
      }
      EOF

            # Reload i3 and polybar
            i3-msg reload
            polybar-msg cmd restart 2>/dev/null || true
            
            echo "Light theme applied!"
    '')

    (writeShellScriptBin "i3-theme-toggle" ''
      #!/bin/sh
      # Toggle between light and dark themes
      if [ -f ~/.config/i3/current-theme ]; then
        current=$(cat ~/.config/i3/current-theme)
        if [ "$current" = "dark" ]; then
          i3-theme-light
          echo "light" > ~/.config/i3/current-theme
        else
          i3-theme-dark
          echo "dark" > ~/.config/i3/current-theme
        fi
      else
        # Default to dark theme
        i3-theme-dark
        echo "dark" > ~/.config/i3/current-theme
      fi
    '')

    # Mobility/Toggle scripts for convenience
    (writeShellScriptBin "toggle-wifi" ''
      #!/bin/sh
      # Toggle WiFi on/off
      wifi_status=$(nmcli radio wifi)
      if [ "$wifi_status" = "enabled" ]; then
        nmcli radio wifi off
        notify-send "WiFi" "Disabled" -i network-wireless-offline
      else
        nmcli radio wifi on
        notify-send "WiFi" "Enabled" -i network-wireless-online
      fi
    '')

    (writeShellScriptBin "toggle-bluetooth" ''
      #!/bin/sh
      # Toggle Bluetooth on/off
      bt_status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
      if [ "$bt_status" = "yes" ]; then
        bluetoothctl power off
        notify-send "Bluetooth" "Disabled" -i bluetooth-disabled
      else
        bluetoothctl power on
        notify-send "Bluetooth" "Enabled" -i bluetooth-active
      fi
    '')

    (writeShellScriptBin "toggle-notifications" ''
      #!/bin/sh
      # Toggle notification daemon
      if pgrep -x "dunst" > /dev/null; then
        dunstctl set-paused true
        notify-send "Notifications" "Paused" -i notification-disabled
      else
        dunstctl set-paused false
        notify-send "Notifications" "Resumed" -i notification-new
      fi
    '')

    (writeShellScriptBin "power-menu" ''
      #!/bin/sh
      # Power menu with rofi
      options="Lock\nLogout\nSuspend\nReboot\nShutdown"
      selected=$(echo -e "$options" | rofi -dmenu -p "Power Menu" -theme-str 'window {width: 200px;}')

      case $selected in
        "Lock")
          i3lock -c 000000
          ;;
        "Logout")
          i3-msg exit
          ;;
        "Suspend")
          systemctl suspend
          ;;
        "Reboot")
          systemctl reboot
          ;;
        "Shutdown")
          systemctl poweroff
          ;;
      esac
    '')

    (writeShellScriptBin "quick-settings" ''
      #!/bin/sh
      # Quick settings panel
      options="🔧 Theme Toggle\n🔆 Brightness\n🔊 Volume\n📶 WiFi Toggle\n🔵 Bluetooth Toggle\n🔔 Notifications\n⚡ Power Menu\n🖥️  Display Settings\n🎨 Appearance\n📊 System Status\n⚙️  Service Manager\n📈 Performance Monitor\n🧹 System Cleanup\n🔄 System Update\n🛠️  Dev Setup\n🔐 GPG Setup\n🔑 SSH Setup"

      selected=$(echo -e "$options" | rofi -dmenu -p "Quick Settings" -theme-str 'window {width: 320px;}')

      case "$selected" in
        "🔧 Theme Toggle")
          i3-theme-toggle
          ;;
        "🔆 Brightness")
          brightness-control
          ;;
        "🔊 Volume")
          volume-control
          ;;
        "📶 WiFi Toggle")
          toggle-wifi
          ;;
        "🔵 Bluetooth Toggle")
          toggle-bluetooth
          ;;
        "🔔 Notifications")
          toggle-notifications
          ;;
        "⚡ Power Menu")
          power-menu
          ;;
        "🖥️  Display Settings")
          arandr
          ;;
        "🎨 Appearance")
          lxappearance
          ;;
        "📊 System Status")
          alacritty -e system-status
          ;;
        "⚙️  Service Manager")
          service-manager
          ;;
        "📈 Performance Monitor")
          performance-monitor
          ;;
        "🧹 System Cleanup")
          alacritty -e nixos-cleanup
          ;;
        "🔄 System Update")
          alacritty -e bash -c "nixos-update && read -p 'Press Enter to close...'"
          ;;
        "🛠️  Dev Setup")
          alacritty -e dev-setup
          ;;
        "🔐 GPG Setup")
          alacritty -e gpg-setup
          ;;
        "🔑 SSH Setup")
          alacritty -e ssh-setup
          ;;
      esac
    '')

    # System management helpers
    (writeShellScriptBin "nixos-rebuild-switch" ''
      #!/bin/sh
      echo "🔧 Rebuilding NixOS configuration..."
      sudo nixos-rebuild switch --flake .
    '')

    (writeShellScriptBin "nixos-rebuild-test" ''
      #!/bin/sh
      echo "🧪 Testing NixOS configuration..."
      sudo nixos-rebuild test --flake .
    '')

    (writeShellScriptBin "nixos-update" ''
      #!/bin/sh
      echo "📦 Updating NixOS flake inputs..."
      nix flake update
      echo "✅ Flake updated! Run 'nixos-rebuild-switch' to apply changes."
    '')

    (writeShellScriptBin "nixos-cleanup" ''
      #!/bin/sh
      echo "🧹 Cleaning up NixOS..."
      echo "Collecting garbage (older than 7 days)..."
      sudo nix-collect-garbage --delete-older-than 7d
      echo "Optimizing nix store..."
      sudo nix-store --optimize
      echo "✅ Cleanup completed!"
    '')

    (writeShellScriptBin "system-status" ''
      #!/bin/sh
      echo "📊 System Status Report"
      echo "======================"
      echo ""
      echo "🖥️  System Info:"
      echo "Hostname: $(hostname)"
      echo "Uptime: $(uptime -p)"
      echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      echo ""
      echo "💾 Memory Usage:"
      free -h
      echo ""
      echo "💿 Disk Usage:"
      df -h / /nix/store 2>/dev/null | grep -E '^(/dev|Filesystem)'
      echo ""
      echo "🔧 NixOS Generation:"
      sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -3
      echo ""
      echo "🌐 Network Status:"
      nmcli device status | head -5
      echo ""
      echo "🔋 Services Status:"
      systemctl is-active nix-serve nginx bluetooth NetworkManager | \
      paste <(echo -e "nix-serve\nnginx\nbluetooth\nNetworkManager") - | column -t
    '')

    (writeShellScriptBin "service-manager" ''
      #!/bin/sh
      # Interactive service management
      services="nix-serve nginx bluetooth NetworkManager sshd"

      action=$(echo -e "Status\nRestart\nStart\nStop\nEnable\nDisable" | rofi -dmenu -p "Service Action")

      if [ -n "$action" ]; then
        service=$(echo "$services" | tr ' ' '\n' | rofi -dmenu -p "Select Service")
        
        if [ -n "$service" ]; then
          case "$action" in
            "Status")
              alacritty -e systemctl status "$service"
              ;;
            "Restart")
              sudo systemctl restart "$service"
              notify-send "Service Manager" "Restarted $service"
              ;;
            "Start")
              sudo systemctl start "$service"
              notify-send "Service Manager" "Started $service"
              ;;
            "Stop")
              sudo systemctl stop "$service"
              notify-send "Service Manager" "Stopped $service"
              ;;
            "Enable")
              sudo systemctl enable "$service"
              notify-send "Service Manager" "Enabled $service"
              ;;
            "Disable")
              sudo systemctl disable "$service"
              notify-send "Service Manager" "Disabled $service"
              ;;
          esac
        fi
      fi
    '')

    (writeShellScriptBin "nixos-generations" ''
      #!/bin/sh
      echo "📜 NixOS System Generations"
      echo "==========================="
      sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
      echo ""
      echo "Current generation: $(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')"
      echo ""
      read -p "Enter generation number to rollback to (or press Enter to cancel): " gen
      if [ -n "$gen" ]; then
        echo "Rolling back to generation $gen..."
        sudo nixos-rebuild switch --rollback --profile-name "$gen"
      fi
    '')

    (writeShellScriptBin "hardware-info" ''
      #!/bin/sh
      echo "🔧 Hardware Information"
      echo "======================"
      echo ""
      echo "🖥️  CPU Info:"
      lscpu | grep -E "Model name|CPU\(s\)|Architecture|CPU MHz"
      echo ""
      echo "💾 Memory Info:"
      free -h
      echo ""
      echo "💿 Storage Info:"
      lsblk -f
      echo ""
      echo "🔌 USB Devices:"
      lsusb
      echo ""
      echo "🌡️  Temperature (if available):"
      sensors 2>/dev/null || echo "lm-sensors not available"
      echo ""
      echo "🎵 Audio Devices:"
      pactl list short sinks
    '')

    (writeShellScriptBin "performance-monitor" ''
      #!/bin/sh
      # Launch performance monitoring tools
      monitor=$(echo -e "htop (CPU/Memory)\niotop (Disk I/O)\nnload (Network)\nbpytop (All-in-one)" | rofi -dmenu -p "Performance Monitor")

      case "$monitor" in
        "htop (CPU/Memory)")
          alacritty -e htop
          ;;
        "iotop (Disk I/O)")
          alacritty -e sudo iotop
          ;;
        "nload (Network)")
          alacritty -e nload
          ;;
        "bpytop (All-in-one)")
          alacritty -e bpytop
          ;;
      esac
    '')

    # GPG and SSH key management
    (writeShellScriptBin "gpg-setup" ''
      #!/bin/sh
      echo "🔐 GPG Key Setup"
      echo "==============="
      echo ""
      echo "Current GPG keys:"
      gpg --list-secret-keys --keyid-format LONG
      echo ""
      echo "Git signing key configured: 5606AB430E95F5AD"
      echo "Email: pina@voidnx.com"
      echo ""
      if gpg --list-secret-keys | grep -q "5606AB430E95F5AD"; then
        echo "✅ GPG key 5606AB430E95F5AD found"
      else
        echo "⚠️  GPG key 5606AB430E95F5AD not found"
        echo ""
        echo "To import your GPG key:"
        echo "1. Export from another machine: gpg --export-secret-keys 5606AB430E95F5AD > private.key"
        echo "2. Import here: gpg --import private.key"
        echo "3. Trust the key: gpg --edit-key 5606AB430E95F5AD (then 'trust' -> '5' -> 'y' -> 'quit')"
      fi
    '')

    (writeShellScriptBin "ssh-setup" ''
      #!/bin/sh
      echo "🔑 SSH Key Setup"
      echo "==============="
      echo ""
      echo "SSH key fingerprint configured: SHA256:5u1XqWhX0ZzB/POQS1+sdmH/fGhHzX0BuZ8G0+/SYY8"
      echo ""
      if [ -f ~/.ssh/id_rsa ]; then
        echo "Current SSH key fingerprint:"
        ssh-keygen -l -f ~/.ssh/id_rsa
        echo ""
        if ssh-keygen -l -f ~/.ssh/id_rsa | grep -q "5u1XqWhX0ZzB/POQS1+sdmH/fGhHzX0BuZ8G0+/SYY8"; then
          echo "✅ SSH key matches configured fingerprint"
        else
          echo "⚠️  SSH key fingerprint does not match"
        fi
      else
        echo "⚠️  No SSH key found at ~/.ssh/id_rsa"
        echo ""
        read -p "Generate new SSH key? (y/N): " generate
        if [[ "$generate" =~ ^[Yy]$ ]]; then
          ssh-keygen -t rsa -b 4096 -C "pina@voidnx.com"
          echo ""
          echo "New SSH key generated. Add this public key to your Git hosting service:"
          cat ~/.ssh/id_rsa.pub
        fi
      fi
    '')

    (writeShellScriptBin "dev-setup" ''
      #!/bin/sh
      echo "🛠️  Development Environment Setup"
      echo "================================"
      echo ""
      echo "1. Checking GPG configuration..."
      gpg-setup
      echo ""
      echo "2. Checking SSH configuration..."
      ssh-setup
      echo ""
      echo "3. Git configuration:"
      echo "Name: $(git config user.name)"
      echo "Email: $(git config user.email)"
      echo "Signing key: $(git config user.signingkey)"
      echo "Auto-sign commits: $(git config commit.gpgsign)"
      echo ""
      echo "✅ Development environment check complete"
    '')
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
