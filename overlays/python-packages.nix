# Python package overlays to fix test failures
# These packages have flaky or resource-intensive tests that fail in Nix builds
final: prev: {
  # Define a CUSTOM python instance for ML/Dev projects
  # This avoids rebuilding the entire system (100GB+ overhead) which happens
  # when overriding the global 'python3' attribute.
  python3_ml = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      # mercantile: CLI tests fail with incorrect output
      mercantile = pyprev.mercantile.overridePythonAttrs (old: {
        doCheck = false;
      });

      # wandb: Tests fail with "can't start new thread" (resource exhaustion)
      wandb = pyprev.wandb.overridePythonAttrs (old: {
        doCheck = false;
      });

      # jax: Tests fail with "can't start new thread" (resource exhaustion)
      jax = pyprev.jax.overridePythonAttrs (old: {
        doCheck = false;
      });

      # mypy: Tests are very slow and resource intensive
      mypy = pyprev.mypy.overridePythonAttrs (old: {
        doCheck = false;
      });

      # pytest-xdist: flaky tests that fail intermittently
      pytest-xdist = pyprev.pytest-xdist.overridePythonAttrs (old: {
        doCheck = false;
      });

      # blis: Fix build failure with AVX512/KNL instructions
      blis = pyprev.blis.overridePythonAttrs (old: {
        BLIS_ARCH = "generic";
      });
    };
  };

  # Same for Python 3.13 if needed
  python313_ml = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      mercantile = pyprev.mercantile.overridePythonAttrs (old: {
        doCheck = false;
      });
      wandb = pyprev.wandb.overridePythonAttrs (old: {
        doCheck = false;
      });
      jax = pyprev.jax.overridePythonAttrs (old: {
        doCheck = false;
      });
      mypy = pyprev.mypy.overridePythonAttrs (old: {
        doCheck = false;
      });
      pytest-xdist = pyprev.pytest-xdist.overridePythonAttrs (old: {
        doCheck = false;
      });
      blis = pyprev.blis.overridePythonAttrs (old: {
        BLIS_ARCH = "generic";
      });
    };
  };

  # Global fix for blis on all python versions (via pythonPackagesExtensions)
  # This avoids rebuilding python interpreter but applies to all python packages
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      blis = python-prev.blis.overridePythonAttrs (old: {
        BLIS_ARCH = "generic";
      });

      # Fix poetry dependency conflict with pbs-installer
      # poetry 2.2.1 requires pbs-installer<2026.0.0 but nixpkgs has 2026.1.13
      poetry = python-prev.poetry.overridePythonAttrs (old: {
        pythonRuntimeDepsCheck = false;
      });
    })
  ];
}
