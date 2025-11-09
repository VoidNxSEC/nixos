{ pkgs, lib, ... }:

{
  # Helper to create a basic NixOS test machine
  makeTestMachine =
    {
      modules ? [ ],
      extraConfig ? { },
    }:
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = modules;

      # Basic configuration for tests
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      fileSystems."/" = {
        device = "/dev/vda";
        fsType = "ext4";
      };

      # Minimal network for tests
      networking.useDHCP = false;
      networking.interfaces.eth0.useDHCP = true;

      # Allow test user
      users.users.test = {
        isNormalUser = true;
        password = "test";
        extraGroups = [ "wheel" ];
      };

      # Merge extra config
      _module.args = extraConfig;
    };

  # Helper to wait for systemd service with timeout
  waitForService = machine: service: timeout: ''
    machine.wait_for_unit("${service}", timeout=${toString timeout})
  '';

  # Helper to check if port is open
  checkPortOpen = machine: port: ''
    machine.wait_for_open_port(${toString port})
  '';

  # Helper to verify file content
  checkFileContains = machine: file: pattern: ''
    machine.succeed("grep -q '${pattern}' ${file}")
  '';

  # Helper to test firewall rules
  checkFirewallRule = machine: rule: ''
    machine.succeed("nft list ruleset | grep -q '${rule}'")
  '';

  # Helper to run security checks
  runSecurityChecks = machine: ''
    # Check kernel hardening
    machine.succeed("sysctl kernel.dmesg_restrict | grep '= 1'")
    machine.succeed("sysctl kernel.kptr_restrict | grep '= 2'")
    machine.succeed("sysctl net.ipv4.conf.all.rp_filter | grep '= 1'")

    # Check no SUID in /tmp
    machine.fail("find /tmp -perm -4000 -type f")

    # Check firewall active
    machine.succeed("systemctl is-active firewall.service")
  '';

  # Helper to test Docker functionality
  testDockerBasics = machine: ''
    # Wait for Docker
    machine.wait_for_unit("docker.service")

    # Test Docker is responding
    machine.succeed("docker info")

    # Test can pull and run container
    machine.succeed("docker run --rm hello-world")

    # Cleanup
    machine.succeed("docker system prune -af")
  '';

  # Helper for network connectivity tests
  testNetworkConnectivity = machine: ''
    # Check network interfaces
    machine.wait_for_unit("network.target")
    machine.succeed("ip addr show | grep -q 'state UP'")

    # Test DNS resolution
    machine.succeed("nslookup google.com")

    # Test HTTP connectivity (if external network available)
    machine.succeed("curl -f https://www.google.com > /dev/null") or machine.log("External network not available")
  '';
}
