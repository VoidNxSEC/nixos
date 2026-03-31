# CI/CD TODO - Local Buildbot Integration

## Objective

Turn Buildbot into the primary local CI/CD orchestrator for this repository while
keeping `ci-cd/` as the canonical domain for tests, helpers, and CI tooling.

This backlog follows the architecture recorded in:

- `docs/CI-CD-ARCHITECTURE.md`
- `docs/CODEX-RECONCILIATION-TODO.md`

## Principles

- Do not move the full `ci-cd/` tree into `modules/`.
- Keep tests and helpers in `ci-cd/`.
- Add only the runtime activation bridge to `modules/`.
- Keep all secrets in SOPS-backed files.
- Treat the GitHub runner as compatibility, not the main control plane.

## Current State

- `ci-cd/default.nix` already exports integration tests, helper imports, and runner scripts.
- `ci-cd/lib/test-helpers.nix` already provides reusable test helpers.
- `ci-cd/integration/security-hardening.nix` already provides a NixOS integration test for security hardening.
- `ci-cd/tailscale-integration-test.nix` already provides a reusable network/Tailscale-oriented test suite.
- `ci-cd/buildbot/*` is already bridged into the active module tree via `modules/services/buildbot-local.nix`.
- `kernelcore.ci` is available as the host-level entrypoint for local Buildbot.
- `modules/secrets/ci.nix` exists and uses SOPS-backed values from `github.yaml` for now.
- `github-runner` is demoted on `kernelcore`; Buildbot is the intended primary local path.

## Phase 0 - Stabilize the Baseline

- [x] Confirm whether `github-runner` should remain temporarily enabled during Buildbot bring-up.
- [x] Decide the host role for Buildbot:
  - `kernelcore` only
  - dedicated CI host later
  - hybrid master/worker on `kernelcore` first
- [x] Decide the first execution scope:
  - `nix flake check`
  - selected integration tests from `ci-cd/`
  - cache push
  - local dashboard only

Acceptance criteria:

- explicit scope is documented
- no ambiguity remains about first rollout responsibilities

## Phase 1 - Runtime Bridge in `modules/`

- [x] Create a wrapper module for local Buildbot runtime.
- [x] Choose the final path:
  - `modules/services/buildbot-local.nix`
  - or `modules/development/buildbot.nix`
- [x] Import that bridge into the active module tree.
- [x] Expose typed options:
  - `kernelcore.ci.enable`
  - or `kernelcore.services.buildbot.enable`
- [ ] Add configuration options for:
  - role (`master`, `worker`, `combined`)
  - UI port
  - domain/host label
  - worker classes
  - repository discovery mode
  - cache integration

Acceptance criteria:

- Buildbot runtime can be enabled declaratively from a host config
- no direct manual import of `ci-cd/buildbot/*` is required in `flake.nix`

## Phase 2 - CI Secrets

- [x] Create `modules/secrets/ci.nix`.
- [ ] Split CI secrets into a dedicated `secrets/ci.yaml` file if repository permissions and workflow justify it.
- [x] Move CI-specific runtime secrets behind SOPS-backed references.
- [x] Define SOPS-backed secrets for:
  - `ci/github-token`
  - `ci/github-webhook-secret`
  - `ci/cachix-auth-token`
- [x] Keep all runtime references file-backed via `config.sops.secrets.<name>.path`.

Acceptance criteria:

- Buildbot runtime does not depend on unmanaged secret paths
- CI secrets are separated from unrelated app/service secret files

## Phase 3 - Buildbot Configuration Cleanup

- [ ] Review `ci-cd/buildbot/master.nix` and replace assumptions that depend on undeclared options.
- [ ] Review `ci-cd/buildbot/workers.nix` and align worker tuning with the selected role model.
- [ ] Review `ci-cd/buildbot/projects.nix` and decide:
  - topic-based discovery
  - explicit repo list
  - mixed mode
- [ ] Make GitHub integration optional for local-first operation.
- [ ] Ensure local-only mode works without webhook setup.

Acceptance criteria:

- Buildbot can run locally without mandatory GitHub webhook plumbing
- build configuration matches declared options from the runtime bridge

## Phase 4 - Connect Buildbot to the Existing Test Domain

- [ ] Define how Buildbot invokes `ci-cd/default.nix`.
- [ ] Expose test classes as named jobs:
  - flake validation
  - security integration tests
  - networking integration tests
  - tailscale stack tests
  - docker/service tests
- [ ] Decide whether to wrap `ci-cd/default.nix` in:
  - `apps`
  - `checks`
  - shell scripts
  - or a dedicated Buildbot job adapter
- [ ] Reuse `ci-cd/lib/test-helpers.nix` as the canonical helper layer for new tests.

Acceptance criteria:

- Buildbot runs the existing CI domain rather than duplicating it
- new tests are authored in `ci-cd/`, not embedded into Buildbot runtime code

## Phase 5 - Test Taxonomy and Coverage

- [ ] Formalize test classes in `ci-cd/default.nix`:
  - `integrationTests`
  - `moduleTests`
  - `vmTests`
- [ ] Add at least one real entry under `moduleTests`.
- [ ] Decide which tests are safe for every push vs scheduled/manual runs.
- [ ] Add naming conventions for:
  - quick checks
  - expensive integration tests
  - network-dependent tests
  - cache-sensitive tests

Acceptance criteria:

- test scope is predictable
- Buildbot can select suites by class without ad hoc filtering

## Phase 6 - Host Wiring

- [x] Add host-level Buildbot configuration to `hosts/kernelcore/configuration.nix`.
- [ ] Decide if first rollout is:
  - combined master/worker on `kernelcore`
  - master only
  - worker only
- [ ] Ensure required firewall and local service exposure are declared.
- [ ] Verify interaction with:
  - Nix daemon
  - Cachix
  - local Docker usage if needed
  - future GPU-aware jobs

Acceptance criteria:

- `kernelcore` can bring Buildbot up declaratively
- runtime services start without relying on manual out-of-band steps

## Phase 7 - GitHub Runner Demotion

- [ ] Decide whether to:
  - disable `github-runner`
  - keep it disabled by default
  - keep it enabled only for specific repos/workflows
- [ ] Remove any assumption that GitHub runner is the primary CI system.
- [ ] Update docs to reflect Buildbot-first local CI/CD.

Acceptance criteria:

- Buildbot is the documented primary path
- GitHub runner is clearly described as compatibility or migration support

## Phase 8 - Binary Cache and Artifacts

- [ ] Confirm Cachix path and signing key ownership.
- [ ] Define which Buildbot jobs may push cache artifacts.
- [ ] Separate validation-only jobs from publish jobs.
- [ ] Document cache promotion policy.

Acceptance criteria:

- cache push is controlled and deliberate
- not every local validation job publishes artifacts

## Phase 9 - UI and Network Exposure

- [ ] Decide whether Buildbot UI remains local-only at first.
- [ ] If public exposure is needed later:
  - expose behind `nginx-public`
  - terminate TLS centrally
  - keep Buildbot on local upstream only
- [ ] Choose final hostname, for example:
  - `ci.voidnx.com`
  - `buildbot.voidnx.com`

Acceptance criteria:

- UI exposure is consistent with the repo-wide TLS/proxy strategy
- Buildbot does not manage its own public TLS independently

## Phase 10 - Documentation and Operational Runbooks

- [ ] Keep `docs/CI-CD-ARCHITECTURE.md` aligned with runtime reality.
- [ ] Add a Buildbot local operator guide.
- [ ] Add a CI secrets setup guide.
- [ ] Add a job map:
  - what each Buildbot job runs
  - expected duration
  - required secrets
  - publish/no-publish behavior

Acceptance criteria:

- a future session can continue implementation without reconstructing the architecture from chat history

## Immediate Next Actions

- [x] Create the runtime bridge module under `modules/`.
- [x] Declare typed options for Buildbot activation.
- [x] Add `modules/secrets/ci.nix`.
- [x] Wire a first local-only Buildbot execution path to the existing `ci-cd/` suites.
- [x] Reevaluate `github-runner` after the first successful Buildbot run.

## Deferred

- [ ] public webhook automation
- [ ] public Buildbot UI behind TLS
- [ ] multi-host worker distribution
- [ ] GPU-specialized worker classes
- [ ] cross-repository topic discovery at scale

## Notes

- `ci-cd/` is a strong asset already and should be preserved as a coherent testing domain.
- The missing piece is declarative runtime activation, not more test authoring infrastructure.
- The bridge should stay small; the CI domain should remain in `ci-cd/`.
