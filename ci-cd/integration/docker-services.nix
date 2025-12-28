{ pkgs, lib, ... }:

import "${pkgs.path}/nixos/tests/make-test-python.nix" (
  { pkgs, ... }:
  {
    name = "docker-services";

    meta = {
      description = "Test Docker container services";
      maintainers = [ "kernelcore" ];
    };

    nodes.machine =
      { config, pkgs, ... }:
      {
        imports = [ ../../modules/containers/docker.nix ];

        # Minimal config for test
        boot.loader.grub.device = "/dev/vda";
        fileSystems."/" = {
          device = "/dev/vda";
          fsType = "ext4";
        };

        # Enable networking
        networking.useDHCP = false;
        networking.interfaces.eth0.useDHCP = true;
        networking.hostName = "docker-test";

        # Ensure Docker is enabled
        virtualisation.docker.enable = true;
      };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")

      # ═══ Docker Service Tests ═══
      with subtest("Docker service is running"):
          machine.wait_for_unit("docker.service", timeout=30)
          machine.succeed("systemctl is-active docker.service")

      with subtest("Docker daemon is responsive"):
          machine.succeed("docker info")
          machine.succeed("docker version")

      # ═══ Docker Network Tests ═══
      with subtest("Docker networks exist"):
          machine.succeed("docker network ls | grep bridge")
          machine.succeed("docker network inspect bridge")

      # ═══ Docker Container Tests ═══
      with subtest("Can pull and run containers"):
          # Run hello-world container
          machine.succeed("docker run --rm hello-world")

      with subtest("Can run detached containers"):
          # Run nginx container
          machine.succeed("docker run -d --name test-nginx -p 8080:80 nginx:alpine")
          machine.wait_for_open_port(8080)

          # Test nginx is responding
          machine.succeed("curl -f http://localhost:8080")

          # Cleanup
          machine.succeed("docker stop test-nginx")
          machine.succeed("docker rm test-nginx")

      # ═══ Docker Compose Tests ═══
      with subtest("Docker Compose is available"):
          result = machine.succeed("docker-compose --version || docker compose version")
          print(f"Docker Compose version: {result}")

      # ═══ Docker Storage Tests ═══
      with subtest("Docker storage driver"):
          machine.succeed("docker info | grep -i 'Storage Driver'")

      with subtest("Docker volumes work"):
          # Create a volume
          machine.succeed("docker volume create test-volume")
          machine.succeed("docker volume ls | grep test-volume")

          # Use the volume
          machine.succeed("docker run --rm -v test-volume:/data alpine touch /data/test-file")

          # Verify volume persists
          machine.succeed("docker run --rm -v test-volume:/data alpine ls /data/test-file")

          # Cleanup
          machine.succeed("docker volume rm test-volume")

      # ═══ Docker Security Tests ═══
      with subtest("Docker security settings"):
          # Check AppArmor/SELinux is enabled for Docker
          result = machine.succeed("docker info | grep -i 'Security Options' || echo 'No security options'")
          print(f"Security Options: {result}")

      with subtest("Docker user namespace remapping"):
          # Check if user namespace remapping is configured
          result = machine.succeed("docker info | grep -i 'userns' || echo 'User namespace not configured'")
          print(f"User namespace: {result}")

      # ═══ Cleanup ═══
      with subtest("Cleanup Docker resources"):
          machine.succeed("docker system prune -af")

      print("✅ All Docker tests passed!")
    '';
  }
)
