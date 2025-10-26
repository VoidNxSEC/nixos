{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    kernelcore.hardware.wifi-optimization.enable = mkEnableOption "Enable WiFi performance optimizations";
  };

  config = mkIf config.kernelcore.hardware.wifi-optimization.enable {

    # Disable power management for MediaTek MT7921 WiFi card
    # This reduces latency by preventing the card from entering power-saving modes
    boot.extraModprobeConfig = ''
      # MediaTek MT7921 WiFi optimizations
      options mt7921e power_save=0

      # Additional WiFi performance tweaks
      options cfg80211 ieee80211_regdom=BR
    '';

    # Kernel parameters for improved WiFi performance
    boot.kernelParams = [
      # Reduce WiFi power management
      "iwlwifi.power_save=0"
    ];

    # NetworkManager optimizations for better roaming and connection stability
    networking.networkmanager.wifi = {
      # Disable MAC address randomization (can cause connection issues)
      macAddress = "preserve";

      # Prevent aggressive power saving
      powersave = false;

      # Increase scan interval to reduce overhead (seconds)
      scanRandMacAddress = false;
    };

    # NetworkManager connection settings
    networking.networkmanager.settings = {
      connection = {
        # Reduce connection timeout (in seconds)
        "ipv4.dhcp-timeout" = "20";
        "ipv6.dhcp-timeout" = "20";
      };

      device = {
        # Use wpa_supplicant backend for better performance
        "wifi.backend" = "wpa_supplicant";
      };
    };

    # Optimize DNS resolution for lower latency
    networking.networkmanager.insertNameservers = [
      "1.1.1.1"      # Cloudflare primary
      "1.0.0.1"      # Cloudflare secondary
      "8.8.8.8"      # Google primary
      "8.8.4.4"      # Google secondary
    ];

    # systemd-resolved optimizations
    services.resolved = {
      enable = true;
      dnssec = "false";  # DNSSEC can add latency

      # DNS-over-TLS for privacy without sacrificing too much performance
      dnsovertls = "opportunistic";

      # Fallback DNS servers
      fallbackDns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
        "9.9.9.9"
        "149.112.112.112"
      ];

      extraConfig = ''
        # Cache DNS responses for 5 minutes
        CacheFromLocalhost=yes
        DNSStubListener=yes

        # Reduce DNS query timeouts
        Timeout=2s

        # Try multiple servers in parallel
        MulticastDNS=no
        LLMNR=no
      '';
    };

    # Note: avahi (mDNS) is required by GNOME, so we keep it enabled
    # If not using GNOME, you can disable it with: services.avahi.enable = false;

    # System-wide network optimizations
    boot.kernel.sysctl = {
      # TCP optimizations for WiFi
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";

      # Reduce TCP retransmission timeout
      "net.ipv4.tcp_fin_timeout" = 30;

      # Enable TCP fast open
      "net.ipv4.tcp_fastopen" = 3;

      # Disable IPv6 if not needed (reduces overhead)
      # Uncomment if you don't use IPv6
      # "net.ipv6.conf.all.disable_ipv6" = 1;
      # "net.ipv6.conf.default.disable_ipv6" = 1;
    };

    # Install WiFi debugging/monitoring tools
    environment.systemPackages = with pkgs; [
      iw                # WiFi configuration utility
      wirelesstools     # iwconfig, iwlist, etc.
      wavemon           # WiFi monitoring tool
    ];

    # Systemd service to monitor and log WiFi signal quality
    systemd.services.wifi-monitor = {
      description = "WiFi Signal Quality Monitor";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };

    # Create a helper script for WiFi diagnostics
    environment.etc."wifi-diagnostics.sh" = {
      text = ''
        #!/usr/bin/env bash

        echo "=== WiFi Diagnostics ==="
        echo

        echo "Current Connection:"
        ${pkgs.networkmanager}/bin/nmcli device wifi list | grep "^\*"
        echo

        echo "Signal Quality:"
        cat /proc/net/wireless
        echo

        echo "Link Information:"
        ${pkgs.iw}/bin/iw dev wlp62s0 link 2>/dev/null || echo "iw command not available"
        echo

        echo "Latency Test:"
        ${pkgs.curl}/bin/curl -w "\nTempo DNS: %{time_namelookup}s\nTempo conexão: %{time_connect}s\nTempo total: %{time_total}s\n" -o /dev/null -s https://1.1.1.1
        echo

        echo "DNS Query Time:"
        ${pkgs.dig}/bin/dig @1.1.1.1 google.com | grep "Query time"
      '';
      mode = "0755";
    };

  };
}
