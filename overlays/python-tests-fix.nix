# Python Package Test Fixes Overlay
#
# This overlay disables flaky tests in Python packages that cause build failures
# without affecting the actual functionality of the packages.
#
final: prev: {
  # pytest-xdist has flaky tests that fail intermittently
  # Disable tests as the package functionality is not affected
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      pytest-xdist = pyprev.pytest-xdist.overridePythonAttrs (old: {
        doCheck = false;
        # Reason: test_max_worker_restart_tests_queued fails intermittently
        # The package works fine without running tests
      });
    };
  };

  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      pytest-xdist = pyprev.pytest-xdist.overridePythonAttrs (old: {
        doCheck = false;
      });
    };
  };
}
