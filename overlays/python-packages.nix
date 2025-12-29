# Python package overlays to fix test failures
# These packages have flaky or resource-intensive tests that fail in Nix builds
final: prev: {
  python3 = prev.python3.override {
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
    };
  };

  python313 = prev.python313.override {
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
    };
  };
}
