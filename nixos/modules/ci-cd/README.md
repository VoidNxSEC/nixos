# NixOS Tests

Comprehensive test suite for NixOS configuration.

## Test Structure

```
tests/
├── default.nix              # Main test aggregator
├── README.md                # This file
├── lib/
│   └── test-helpers.nix     # Reusable test helpers
├── integration/
│   ├── security-hardening.nix  # Security module tests
│   ├── docker-services.nix     # Docker/container tests
│   └── networking.nix          # Network configuration tests
├── modules/                 # Module-specific unit tests
└── vm/                      # VM-specific tests
```

## Running Tests

### Run All Tests

```bash
# Build and run all tests
nix build -f tests/default.nix allTests --print-build-logs

# Or use the test runner script
nix build -f tests/default.nix runAllTests
./result/bin/run-all-tests
```

### Run Individual Tests

```bash
# Security hardening tests
nix build -f tests security --print-build-logs

# Docker services tests
nix build -f tests docker --print-build-logs

# Networking tests
nix build -f tests networking --print-build-logs
```

### Run Tests via Flake

Add to your `flake.nix`:

```nix
checks.${system} = {
  # Existing checks
  fmt = ...;
  iso = ...;

  # NEW: Add all tests
  tests = (import ./tests { inherit pkgs; }).allTests;

  # Or individual tests
  security-tests = (import ./tests { inherit pkgs; }).security;
  docker-tests = (import ./tests { inherit pkgs; }).docker;
  network-tests = (import ./tests { inherit pkgs; }).networking;
};
```

Then run:

```bash
nix flake check --print-build-logs
```

## Test Categories

### Integration Tests (`integration/`)

Test interaction between multiple modules:

- **security-hardening.nix**: Tests firewall, kernel hardening, AppArmor, SSH security
- **docker-services.nix**: Tests Docker daemon, containers, volumes, networks
- **networking.nix**: Tests network connectivity, DNS, firewall, SSH

### Module Tests (`modules/`)

Unit tests for individual modules (to be added):

- Test module options work correctly
- Test module conflicts are handled
- Test module defaults

### VM Tests (`vm/`)

Lightweight VM tests (to be added):

- Quick boot tests
- Basic functionality tests
- Regression tests

## Writing Tests

### Basic Test Structure

```nix
{ pkgs, lib, ... }:

import "${pkgs.path}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  name = "my-test";

  meta = {
    description = "Test description";
    maintainers = [ "kernelcore" ];
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/my-module ];
    # Minimal configuration
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    with subtest("My test case"):
        machine.succeed("command-that-should-succeed")
        machine.fail("command-that-should-fail")

    print("✅ Test passed!")
  '';
})
```

### Using Test Helpers

```nix
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  testScript = ''
    ${helpers.waitForService "machine" "docker.service" 30}
    ${helpers.checkPortOpen "machine" 8080}
    ${helpers.runSecurityChecks "machine"}
  '';
}
```

### Common Test Patterns

#### Testing Services

```python
# Wait for service
machine.wait_for_unit("myservice.service")

# Check service is active
machine.succeed("systemctl is-active myservice.service")

# Check service logs
machine.succeed("journalctl -u myservice.service | grep 'Started'")
```

#### Testing Network

```python
# Wait for port
machine.wait_for_open_port(8080)

# Test HTTP endpoint
machine.succeed("curl -f http://localhost:8080")

# Test DNS
machine.succeed("nslookup example.com")
```

#### Testing Files

```python
# Check file exists
machine.succeed("test -f /path/to/file")

# Check file content
machine.succeed("grep -q 'pattern' /path/to/file")

# Check file permissions
machine.succeed("stat -c '%a' /path/to/file | grep -q '600'")
```

#### Testing Security

```python
# Check sysctl setting
machine.succeed("sysctl kernel.dmesg_restrict | grep '= 1'")

# Check firewall
machine.succeed("nft list ruleset | grep 'my-rule'")

# Check no SUID in /tmp
machine.fail("find /tmp -perm -4000")
```

## Test Helpers

Available helpers in `lib/test-helpers.nix`:

- `makeTestMachine`: Create basic test machine configuration
- `waitForService`: Wait for systemd service with timeout
- `checkPortOpen`: Check if port is open
- `checkFileContains`: Verify file content
- `checkFirewallRule`: Test firewall rules
- `runSecurityChecks`: Run standard security checks
- `testDockerBasics`: Test Docker functionality
- `testNetworkConnectivity`: Test network connectivity

## CI/CD Integration

### GitHub Actions

```yaml
test-modules:
  name: Test NixOS modules
  runs-on: [self-hosted, nixos]
  steps:
    - uses: actions/checkout@v4

    - name: Run integration tests
      run: nix build -f tests allTests --print-build-logs

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: result/
```

### GitLab CI

```yaml
test:modules:
  stage: test
  script:
    - nix build -f tests allTests --print-build-logs
  artifacts:
    paths:
      - result/
```

## Debugging Tests

### Interactive Test

```bash
# Build test and drop into Python REPL
nix build -f tests security

# Run test interactively
$(nix-build tests -A security)/bin/nixos-test-driver

# In REPL:
>>> start_all()
>>> machine.shell_interact()  # Get shell on test machine
```

### View Test Logs

```bash
# Build with trace
nix build -f tests security --print-build-logs --show-trace

# View test output
cat result/test-output.log
```

### Common Issues

1. **Test times out**: Increase timeout in `wait_for_unit`
2. **Network not available**: Tests may run without external network
3. **Service fails to start**: Check `journalctl` in test script
4. **Permission denied**: Check file permissions and ownership

## Coverage

Track test coverage:

```bash
# Generate coverage report
./scripts/test-coverage.sh

# View coverage report
cat coverage-report.md
```

Current coverage: See [coverage-report.md](../coverage-report.md)

## Contributing

When adding new modules:

1. Create test in `tests/integration/` or `tests/modules/`
2. Add test to `tests/default.nix`
3. Update this README
4. Run `nix build -f tests allTests` to verify
5. Add to CI/CD pipeline

## References

- [NixOS Test Framework](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- [make-test-python.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-test-python.nix)
- [Test Examples](https://github.com/NixOS/nixpkgs/tree/master/nixos/tests)
