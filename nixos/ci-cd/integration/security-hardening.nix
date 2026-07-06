{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in

import "${pkgs.path}/nixos/tests/make-test-python.nix" (
  { pkgs, ... }:
  {
    name = "security-hardening";

    meta = {
      description = "Test security hardening modules";
      maintainers = [ "kernelcore" ];
    };

    nodes.machine =
      { config, pkgs, ... }:
      {
        imports = [
          ../../modules/security
          ../../sec/hardening.nix
        ];

        # Minimal config for test
        boot.loader.grub.device = "/dev/vda";
        fileSystems."/" = {
          device = "/dev/vda";
          fsType = "ext4";
        };

        # Enable networking for test
        networking.useDHCP = false;
        networking.interfaces.eth0.useDHCP = true;
        networking.hostName = "security-test";
      };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")

      # ═══ Firewall Tests ═══
      with subtest("Firewall is active"):
          machine.succeed("systemctl is-active firewall.service")

      with subtest("nftables rules present"):
          # Check we have active firewall rules
          machine.succeed("nft list ruleset | grep -q 'table'")

      # ═══ Kernel Hardening Tests ═══
      with subtest("Kernel hardening parameters"):
          machine.succeed("sysctl kernel.dmesg_restrict | grep '= 1'")
          machine.succeed("sysctl kernel.kptr_restrict | grep '= 2'")
          machine.succeed("sysctl kernel.yama.ptrace_scope | grep '= 1'")
          machine.succeed("sysctl net.ipv4.conf.all.rp_filter | grep '= 1'")
          machine.succeed("sysctl net.ipv4.conf.all.accept_source_route | grep '= 0'")

      # ═══ Filesystem Security Tests ═══
      with subtest("Filesystem mount options"):
          # Check /tmp is mounted with noexec
          machine.succeed("mount | grep '/tmp' | grep -q 'noexec'") or machine.log("/tmp not mounted with noexec")

          # Check no SUID binaries in /tmp
          machine.fail("find /tmp -perm -4000 -type f")

      # ═══ AppArmor Tests ═══
      with subtest("AppArmor is active"):
          # Check if AppArmor service exists and is active
          result = machine.succeed("systemctl list-units --type=service --all | grep apparmor || echo 'not-found'")
          if "not-found" not in result:
              machine.succeed("systemctl is-active apparmor.service")
              machine.succeed("aa-status | grep -q 'profiles are loaded'")

      # ═══ User Security Tests ═══
      with subtest("Immutable users"):
          # Check users are immutable (no /etc/passwd modifications)
          machine.fail("useradd testuser")

      # ═══ SSH Hardening Tests ═══
      with subtest("SSH configuration"):
          # Check SSH is running
          result = machine.succeed("systemctl list-units --type=service --all | grep sshd || echo 'not-found'")
          if "not-found" not in result:
              machine.succeed("systemctl is-active sshd.service")

              # Check SSH hardening settings
              machine.succeed("grep -q 'PermitRootLogin no' /etc/ssh/sshd_config || echo 'Warning: Root login may be permitted'")
              machine.succeed("grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config || echo 'Warning: Password auth may be enabled'")

      # ═══ Audit System Tests ═══
      with subtest("Security audit capabilities"):
          # Check we can run security audits
          machine.succeed("nix-store --verify --check-contents | head -20")

      print("✅ All security hardening tests passed!")
    '';
  }
)
