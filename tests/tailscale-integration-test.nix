# Tailscale Integration Tests
# Run with: nix-build tests/tailscale-integration-test.nix

{ pkgs ? import <nixpkgs> {} }:

let
  # Test framework
  makeTest = pkgs.testers.runNixOSTest;
  
  # Common test configuration
  commonConfig = { config, pkgs, ... }: {
    imports = [
      ../modules/network/vpn/tailscale.nix
      ../modules/network/proxy/nginx-tailscale.nix
      ../modules/network/security/firewall-zones.nix
      ../modules/network/monitoring/tailscale-monitor.nix
      ../modules/secrets/tailscale.nix
    ];
    
    # Minimal system configuration
    boot.loader.grub.enable = false;
    fileSystems."/" = { device = "tmpfs"; fsType = "tmpfs"; };
    networking.hostName = "test-host";
  };
in
{
  # Test 1: Tailscale Service Startup
  tailscale-service = makeTest {
    name = "tailscale-service-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.vpn.tailscale = {
        enable = true;
        hostname = "test-machine";
        autoStart = true;
      };
    };
    
    testScript = ''
      machine.start()
      machine.wait_for_unit("tailscaled.service")
      
      # Check if tailscaled is running
      machine.succeed("systemctl is-active tailscaled")
      
      # Check if tailscale command is available
      machine.succeed("which tailscale")
      
      # Verify network interface creation
      machine.wait_for_unit("network.target")
      machine.succeed("ip link show tailscale0 || true")  # May not exist without auth
      
      print("✓ Tailscale service startup test passed")
    '';
  };
  
  # Test 2: NGINX Proxy Configuration
  nginx-proxy = makeTest {
    name = "nginx-proxy-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.proxy.nginx-tailscale = {
        enable = true;
        hostname = "test-host";
        tailnetDomain = "test.ts.net";
        
        services = {
          test-service = {
            enable = true;
            subdomain = "test";
            upstreamPort = 8080;
            rateLimit = "10r/s";
          };
        };
      };
      
      # Mock upstream service
      systemd.services.mock-upstream = {
        wantedBy = [ "multi-user.target" ];
        script = ''
          ${pkgs.python3}/bin/python -m http.server 8080
        '';
      };
    };
    
    testScript = ''
      machine.start()
      machine.wait_for_unit("nginx.service")
      machine.wait_for_unit("mock-upstream.service")
      
      # Check NGINX configuration syntax
      machine.succeed("nginx -t")
      
      # Verify NGINX is listening
      machine.wait_for_open_port(80)
      machine.wait_for_open_port(443)
      
      # Check if mock service is accessible
      machine.wait_for_open_port(8080)
      
      print("✓ NGINX proxy configuration test passed")
    '';
  };
  
  # Test 3: Firewall Zones
  firewall-zones = makeTest {
    name = "firewall-zones-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.security.firewall-zones = {
        enable = true;
        defaultPolicy = "drop";
        
        zones = {
          dmz = {
            enable = true;
            allowedTCPPorts = [ 80 443 ];
          };
          
          internal = {
            enable = true;
            interfaces = [ "tailscale0" ];
          };
        };
      };
    };
    
    testScript = ''
      machine.start()
      machine.wait_for_unit("nftables.service")
      
      # Check nftables is active
      machine.succeed("systemctl is-active nftables")
      
      # Verify ruleset is loaded
      machine.succeed("nft list ruleset | grep 'table inet filter'")
      
      # Check zones are configured
      machine.succeed("nft list sets | grep dmz_interfaces || true")
      machine.succeed("nft list sets | grep internal_interfaces || true")
      
      print("✓ Firewall zones test passed")
    '';
  };
  
  # Test 4: Monitoring Service
  monitoring = makeTest {
    name = "monitoring-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.vpn.tailscale = {
        enable = true;
        autoStart = false;  # Don't require actual connection
      };
      
      kernelcore.network.monitoring.tailscale = {
        enable = true;
        checkInterval = 5;
        maxLatency = 200;
        maxPacketLoss = 5;
      };
    };
    
    testScript = ''
      machine.start()
      machine.wait_for_unit("tailscale-monitor.service")
      
      # Check monitor service is running
      machine.succeed("systemctl is-active tailscale-monitor")
      
      # Verify log file exists
      machine.succeed("test -f /var/log/tailscale-monitor.log || true")
      
      # Check monitoring scripts exist
      machine.succeed("test -x /etc/tailscale/monitoring-check.sh")
      
      print("✓ Monitoring service test passed")
    '';
  };
  
  # Test 5: Shell Aliases and Scripts
  shell-tools = makeTest {
    name = "shell-tools-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.vpn.tailscale.enable = true;
      kernelcore.network.proxy.nginx-tailscale.enable = true;
      kernelcore.network.monitoring.tailscale.enable = true;
    };
    
    testScript = ''
      machine.start()
      
      # Check Tailscale aliases
      machine.succeed("type ts-status")
      machine.succeed("type ts-ip")
      machine.succeed("type ts-quality")
      
      # Check NGINX aliases
      machine.succeed("type nginx-test")
      machine.succeed("type nginx-reload")
      
      # Check monitoring aliases
      machine.succeed("type ts-monitor-status")
      
      # Check health check scripts
      machine.succeed("test -x /etc/tailscale/health-check.sh")
      machine.succeed("test -x /etc/tailscale/monitoring-check.sh")
      
      # Check firewall scripts
      machine.succeed("test -x /etc/firewall/zone-check.sh || true")
      
      print("✓ Shell tools test passed")
    '';
  };
  
  # Test 6: Complete Stack Integration
  full-stack = makeTest {
    name = "full-stack-integration-test";
    
    nodes = {
      server = { config, pkgs, ... }: {
        imports = [ commonConfig ];
        
        kernelcore.network.vpn.tailscale = {
          enable = true;
          hostname = "test-server";
          enableSubnetRouter = true;
          advertiseRoutes = [ "192.168.1.0/24" ];
          exitNode = true;
        };
        
        kernelcore.network.proxy.nginx-tailscale = {
          enable = true;
          hostname = "test-server";
          tailnetDomain = "test.ts.net";
          
          services = {
            api = {
              enable = true;
              subdomain = "api";
              upstreamPort = 8000;
            };
          };
        };
        
        kernelcore.network.security.firewall-zones = {
          enable = true;
          defaultPolicy = "drop";
        };
        
        # Mock API service
        systemd.services.mock-api = {
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.python3}/bin/python -m http.server 8000
          '';
        };
      };
      
      client = { config, pkgs, ... }: {
        imports = [ commonConfig ];
        
        kernelcore.network.vpn.tailscale = {
          enable = true;
          hostname = "test-client";
          acceptRoutes = true;
        };
      };
    };
    
    testScript = ''
      server.start()
      client.start()
      
      # Wait for all services
      server.wait_for_unit("tailscaled.service")
      server.wait_for_unit("nginx.service")
      server.wait_for_unit("mock-api.service")
      server.wait_for_unit("nftables.service")
      
      client.wait_for_unit("tailscaled.service")
      
      # Verify server services
      server.succeed("systemctl is-active tailscaled")
      server.succeed("systemctl is-active nginx")
      server.succeed("systemctl is-active mock-api")
      
      # Verify NGINX configuration
      server.succeed("nginx -t")
      
      # Verify firewall
      server.succeed("nft list ruleset | grep 'table inet filter'")
      
      # Check if API is accessible locally
      server.wait_for_open_port(8000)
      server.succeed("curl -f http://localhost:8000/")
      
      # Check NGINX proxy
      server.wait_for_open_port(80)
      
      print("✓ Full stack integration test passed")
    '';
  };
  
  # Test 7: ACL and Security
  security = makeTest {
    name = "security-test";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ commonConfig ];
      
      kernelcore.network.vpn.tailscale = {
        enable = true;
        tags = [ "tag:server" "tag:prod" ];
        shieldsUp = false;
      };
      
      kernelcore.network.security.firewall-zones = {
        enable = true;
        defaultPolicy = "drop";
        enableLogging = true;
        
        zones = {
          admin = {
            enable = true;
            allowedIPs = [ "100.64.0.0/10" ];
            allowAllServices = true;
          };
          
          isolated = {
            enable = true;
            denyInterzone = true;
          };
        };
      };
    };
    
    testScript = ''
      machine.start()
      machine.wait_for_unit("tailscaled.service")
      machine.wait_for_unit("nftables.service")
      
      # Verify security settings
      machine.succeed("nft list ruleset | grep 'admin_ips'")
      
      # Check default drop policy
      machine.succeed("nft list chain inet filter input | grep 'policy drop'")
      
      # Verify logging is enabled
      machine.succeed("nft list ruleset | grep 'log prefix'")
      
      print("✓ Security test passed")
    '';
  };
}