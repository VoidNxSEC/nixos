# /etc/nixos/modules/services/ci/buildbot-master.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ci;
  hasMaster =
    cfg.enable
    && builtins.elem cfg.role [
      "master"
      "combined"
    ];
  escapePy = lib.escape [
    "\\"
    "'"
  ];
  workerPasswordExpr =
    if cfg.worker.passwordFile != null then
      "open('${escapePy (toString cfg.worker.passwordFile)}', 'r', encoding='utf-8').read().strip()"
    else
      "'${escapePy cfg.worker.password}'";

  workerDefinitions = [
    "worker.Worker('${escapePy cfg.worker.name}', ${workerPasswordExpr})"
  ];

  factorySteps =
    optional cfg.jobs.enableFlakeCheck ''
      steps.ShellCommand(
        name='flake-check',
        command=['${pkgs.bash}/bin/bash', '-lc', 'cd /etc/nixos && nix flake check --no-build path:.']
      )
    ''
    ++ map (suite: ''
      steps.ShellCommand(
        name='suite-${suite}',
        command=['${pkgs.bash}/bin/bash', '-lc', 'cd /etc/nixos && nix build -f ./ci-cd/default.nix ${escapeShellArg "testSuites.${suite}"} --print-build-logs']
      )
    '') cfg.jobs.suites
    ++ optional cfg.jobs.enableTailscaleSmoke ''
      steps.ShellCommand(
        name='tailscale-smoke',
        command=['${pkgs.bash}/bin/bash', '-lc', 'cd /etc/nixos && nix build -f ./ci-cd/tailscale-integration-test.nix tailscale-service --print-build-logs']
      )
    '';
in
mkIf hasMaster {
  services.buildbot-master = {
    enable = true;
    title = cfg.title;
    titleUrl = cfg.titleUrl;
    buildbotUrl = cfg.buildbotUrl;
    listenAddress = cfg.listenAddress;
    port = cfg.port;
    pbPort = cfg.pbPort;
    packages = cfg.worker.packages;
    workers = workerDefinitions;
    schedulers = [
      "schedulers.ForceScheduler(name='force-local', builderNames=['local-ci'])"
    ];
    builders = [
      "util.BuilderConfig(name='local-ci', workernames=['${cfg.worker.name}'], factory=factory)"
    ];
    factorySteps = factorySteps;
    extraConfig = ''
      c['buildbotNetUsageData'] = None
    '';
  };
}
