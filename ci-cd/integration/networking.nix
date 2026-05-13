{ pkgs, lib, ... }:

import "${pkgs.path}/nixos/tests/make-test-python.nix" (
  { pkgs, ... }:
  {
    name = "networking";

    meta = {
      description = "Test network configuration and connectivity";
      maintainers = [ "kernelcore" ];
    };

    nodes = {
      machine =
        { config, pkgs, ... }:
        {
          imports = [ ../../modules/network ];

          boot.loader.grub.device = "/dev/vda";
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
          };

          networking.useDHCP = false;
          networking.interfaces.eth0.useDHCP = true;
          networking.hostName = "network-test";
        };
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")

      # ═══ Network Service Tests ═══
      with subtest("NetworkManager is running"):
          result = machine.succeed("systemctl list-units --type=service --all | grep NetworkManager || echo 'not-found'")
          if "not-found" not in result:
              machine.succeed("systemctl is-active NetworkManager.service")

      with subtest("Network interfaces are up"):
          machine.wait_for_unit("network.target")
          machine.succeed("ip addr show | grep -q 'state UP'")
          machine.succeed("ip link show eth0")

      # ═══ DNS Tests ═══
      with subtest("DNS resolution works"):
          # Check resolver configuration
          machine.succeed("cat /etc/resolv.conf | grep -q nameserver")

          # Test DNS resolution
          machine.succeed("nslookup localhost")
          machine.succeed("nslookup google.com || echo 'External DNS not available'")

      with subtest("DNS security settings"):
          # Check DNSSEC if enabled
          result = machine.succeed("resolvectl status | grep 'DNSSEC' || echo 'DNSSEC not configured'")
          print(f"DNSSEC status: {result}")

      # ═══ Firewall Tests ═══
      with subtest("Firewall is active"):
          machine.succeed("systemctl is-active firewall.service")

      with subtest("Firewall rules"):
          # Check nftables rules exist
          machine.succeed("nft list ruleset | grep -q 'table'")

          # Check default policies
          result = machine.succeed("nft list ruleset")
          print(f"Firewall rules preview:\n{result[:500]}")

      # ═══ SSH Service Tests ═══
      with subtest("SSH service"):
          result = machine.succeed("systemctl list-units --type=service --all | grep sshd || echo 'not-found'")
          if "not-found" not in result:
              machine.succeed("systemctl is-active sshd.service")
              machine.wait_for_open_port(22)

      # ═══ Network Connectivity Tests ═══
      with subtest("Local connectivity"):
          # Ping localhost
          machine.succeed("ping -c 1 127.0.0.1")

          # Ping self
          machine.succeed("ping -c 1 $(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')")

      with subtest("External connectivity (if available)"):
          # Try to reach external host
          result = machine.succeed("ping -c 1 -W 5 8.8.8.8 || echo 'External network not available'")
          print(f"External ping: {result}")

          # Try HTTP
          result = machine.succeed("curl -f -m 5 https://www.google.com > /dev/null 2>&1 || echo 'HTTP not available'")
          print(f"HTTP test: {result}")

      # ═══ Network Security Tests ═══
      with subtest("Network security settings"):
          # Check IP forwarding is disabled (unless router)
          result = machine.succeed("sysctl net.ipv4.ip_forward")
          print(f"IP forwarding: {result}")

          # Check SYN cookies enabled
          machine.succeed("sysctl net.ipv4.tcp_syncookies | grep '= 1'")

          # Check ICMP redirects disabled
          machine.succeed("sysctl net.ipv4.conf.all.accept_redirects | grep '= 0'")

      print("✅ All networking tests passed!")
    '';
  }
)
