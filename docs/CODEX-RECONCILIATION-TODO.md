# Codex Reconciliation TODO

## Objective

Close the inconsistencies introduced or exposed during the recent Codex work
before expanding the rollout scope again.

This backlog is narrower than the broader CI/CD roadmap.
Most of the items below are now implemented; the remaining value of this file is
to preserve the execution order and acceptance criteria that were used.

- `docs/CI-CD-TODO.md` remains the strategic Buildbot roadmap
- this file tracks the concrete reconciliation work needed to make the current
  state internally consistent

## Verified Problem Set

The items below are based on the current repository state:

- `ci-cd/default.nix` does not export suite names like `security` at the top
  level, while the Buildbot bridge currently calls `nix build -f ./ci-cd/default.nix <suite>`
  via `master.nix`
- the Buildbot worker supports `passwordFile`, but the Buildbot master still
  registers the worker using the inline password option
- the runtime/docs state drifted after the bridge landed
- the repo-wide TLS layer exists, but `Gitea` and `Forgejo` still advertise the
  Tailscale hostname and legacy per-service TLS paths still exist in the
  `Gitea` module
- certificate secrets still fall back to the legacy `gitea.yaml`
- `github-runner` is still the active host path even though the intended
  architecture is Buildbot-first local CI/CD

## Phase 0 - Stop Immediate Regressions

- [x] Fix the Buildbot suite invocation contract.
- [x] Decide one canonical interface for `ci-cd/default.nix`:
  - export suite aliases at the top level
  - or make Buildbot call `allTests.<suite>` / `integrationTests.<suite>`
- [x] Align `runAllTests` and `runTest` with the same contract.
- [x] Keep the default local suite meaningful and cheap enough for first rollout.

Acceptance criteria:

- a configured Buildbot job can resolve the selected suite names without ad hoc
  shell hacks
- the direct scripts and the Buildbot path call the same test interface

## Phase 1 - Secrets and Worker Authentication

- [x] Fix the master/worker password split so `passwordFile` and worker
  registration use the same source of truth.
- [x] Create `modules/secrets/ci.nix`.
- [ ] Create `secrets/ci.yaml`.
- [x] Move any remaining inline Buildbot secrets to SOPS-backed files.
- [ ] Decide which secrets are required for local-only mode vs later GitHub
  integration.

Acceptance criteria:

- local Buildbot can run without inline credentials
- future GitHub/webhook integration has a clean secret home

## Phase 2 - Host Runtime Coherence

- [x] Decide whether `github-runner` stays enabled during Buildbot bring-up.
- [ ] If it stays enabled, document why and limit its role explicitly.
- [x] If it does not stay enabled, disable it before enabling `kernelcore.ci`.
- [x] Add the first host-level `kernelcore.ci` block to
  `hosts/kernelcore/configuration.nix`.
- [ ] Start with the smallest sane role:
  - `combined` on `kernelcore`
  - or `master` only if the worker still needs cleanup

Acceptance criteria:

- the host has one clearly documented primary CI path
- `rebuild` is not blocked by obsolete automation services

## Phase 3 - TLS and Service Identity Convergence

- [ ] Decide the first public identities for:
  - `Gitea`
  - `Forgejo`
  - later `Buildbot`
- [x] Align `ROOT_URL` and advertised domains with the central TLS plan.
- [x] Keep services on local HTTP upstreams behind the future proxy.
- [x] Remove legacy per-service `localhost.crt` / `localhost.key` wiring from
  `modules/services/gitea-showcase.nix`.
- [x] Remove or retire the service-specific Cloudflare DNS sync path from the
  `Gitea` module.
- [ ] Finish migrating the TLS token to `secrets/certificates.yaml`.

Acceptance criteria:

- service identity, ACME cert inventory, and proxy plan refer to the same names
- no default path depends on self-managed TLS inside the `Gitea` service module

## Phase 4 - Documentation Reconciliation

- [x] Update `docs/CI-CD-ARCHITECTURE.md` to reflect that the Buildbot bridge is
  already imported through `modules/services/default.nix`.
- [x] Update `docs/CI-CD-TODO.md` so completed bridge work is no longer listed as
  pending.
- [ ] Add a short operator note describing the current local-only Buildbot
  baseline and what is still intentionally deferred.
- [ ] Document the current TLS transition state:
  - central ACME layer exists
  - public proxy is not finished yet
  - services still expose local/Tailscale paths during the migration

Acceptance criteria:

- a future session does not have to rediscover which parts are done vs pending
- docs stop contradicting the current repository state

## Phase 5 - Validation Gates

- [ ] Run `nix flake check --no-build`.
- [ ] Validate the affected modules after each phase instead of waiting for the
  full rollout.
- [ ] After host wiring, use `rebuild` on `kernelcore`.
- [ ] If Buildbot is enabled, verify the resulting units and first local job.
- [ ] Keep runtime validation notes in the docs or commit message context.

Acceptance criteria:

- every phase ends with a clear validation artifact
- runtime changes are not merged purely on static evaluation

## Recommended Execution Order

1. Phase 0
2. Phase 1
3. Phase 4
4. Phase 2
5. Phase 3
6. Phase 5 continuously after each phase

## Notes

- Do not expand the Buildbot scope before Phase 0 and Phase 1 are closed.
- Do not finalize public TLS/domain work before the proxy layer is ready.
- Do not let the docs drift again after the next implementation pass.
