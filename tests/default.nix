{
  pkgs ? import <nixpkgs> { },
}:

let
  lib = pkgs.lib;

  # Import test helpers
  helpers = import ./lib/test-helpers.nix { inherit pkgs lib; };

  # Import all integration tests. Each file wraps make-test-python.nix,
  # which returns a function { system, pkgs, ... } -> derivation — call it
  # here so consumers (flake checks) get real derivations.
  callTest =
    path:
    import path { inherit pkgs lib; } {
      inherit pkgs;
      inherit (pkgs.stdenv.hostPlatform) system;
    };

  integrationTests = {
    security = callTest ./integration/security-hardening.nix;
    docker = callTest ./integration/docker-services.nix;
    networking = callTest ./integration/networking.nix;
  };

  # VM tests (lightweight variants)
  vmTests = {
    # Add VM-specific tests here
  };

  # Module tests (unit tests for specific modules)
  moduleTests = {
    # Add module-specific tests here
  };

  # Combined test suite
  allTests = integrationTests // vmTests // moduleTests;

in
{
  # Export all tests
  inherit integrationTests vmTests moduleTests;

  # Export combined tests
  inherit allTests;
  testSuites = allTests;

  # Export helpers for use in other tests
  inherit helpers;

  # Default: run all tests
  default = allTests;

  # Test runner script
  runAllTests = pkgs.writeShellScriptBin "run-all-tests" ''
    set -e
    echo "🧪 Running NixOS test suite..."
    echo ""

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: test: ''
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running test: ${name}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        nix build -f ${./default.nix} ${lib.escapeShellArg "testSuites.${name}"} --print-build-logs || {
          echo "❌ Test failed: ${name}"
          exit 1
        }
        echo "✅ Test passed: ${name}"
        echo ""
      '') allTests
    )}

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All tests passed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';

  # Test specific module
  runTest =
    testName:
    pkgs.writeShellScriptBin "run-test-${testName}" ''
      set -e
      echo "🧪 Running test: ${testName}"
      nix build -f ${./default.nix} ${lib.escapeShellArg "testSuites.${testName}"} --print-build-logs
      echo "✅ Test passed: ${testName}"
    '';
}
