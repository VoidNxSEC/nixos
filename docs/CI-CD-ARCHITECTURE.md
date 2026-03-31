# CI/CD Architecture - Local Buildbot and Declarative Test Domain

## Status

This repository is moving away from a GitHub Actions-centric mental model.
The target architecture is:

- `ci-cd/` remains the domain for tests, helpers, and CI tooling.
- `Buildbot` becomes the primary local CI/CD orchestrator.
- `GitHub Actions runner` becomes a compatibility path, not the main control plane.

This document records the intended architecture and the practical migration path.
Execution backlog:

- [`/etc/nixos/docs/CI-CD-TODO.md`](./CI-CD-TODO.md)

## Current Repository Reality

The repository already contains a useful CI/CD domain:

- [`/etc/nixos/ci-cd/default.nix`](../ci-cd/default.nix)
  exports integration tests, module test slots, helpers, and runnable scripts.
- [`/etc/nixos/ci-cd/lib/test-helpers.nix`](../ci-cd/lib/test-helpers.nix)
  provides reusable helpers for NixOS test machines, service waits, port checks,
  firewall assertions, and security checks.
- [`/etc/nixos/ci-cd/integration/security-hardening.nix`](../ci-cd/integration/security-hardening.nix)
  is a real NixOS integration test for security hardening.
- [`/etc/nixos/ci-cd/tailscale-integration-test.nix`](../ci-cd/tailscale-integration-test.nix)
  already exercises Tailscale, NGINX proxying, firewall zones, and monitoring.

The repository contains an active local Buildbot path now:

- [`/etc/nixos/ci-cd/buildbot/master.nix`](../ci-cd/buildbot/master.nix)
- [`/etc/nixos/ci-cd/buildbot/workers.nix`](../ci-cd/buildbot/workers.nix)
- [`/etc/nixos/ci-cd/buildbot/projects.nix`](../ci-cd/buildbot/projects.nix)
- [`/etc/nixos/modules/services/buildbot-local.nix`](../modules/services/buildbot-local.nix)

That Buildbot code is now wired into the imported module tree:

- it is imported through [`/etc/nixos/modules/services/default.nix`](../modules/services/default.nix)
- it exposes typed host options under `kernelcore.ci`
- it runs in a local-first mode without requiring webhook plumbing

The GitHub runner remains a compatibility path, but it is no longer the primary local CI path on `kernelcore`:

- [`/etc/nixos/modules/services/github-runner.nix`](../modules/services/github-runner.nix)
- [`/etc/nixos/hosts/kernelcore/configuration.nix`](../hosts/kernelcore/configuration.nix)

## Core Decision

Do not move the entire `ci-cd/` tree into `modules/`.

That would mix two different concerns:

- test domain and CI helpers
- runtime service orchestration

The correct separation is:

- `ci-cd/` keeps tests, helpers, suites, and CI execution libraries
- `modules/` owns only the declarative runtime bridge that activates Buildbot on the host

## Architectural Roles

### 1. `ci-cd/` is the CI domain

This tree should continue to own:

- NixOS integration tests
- test helper libraries
- suite composition
- test runner scripts
- CI-specific utility logic

Examples:

- [`/etc/nixos/ci-cd/default.nix`](../ci-cd/default.nix)
- [`/etc/nixos/ci-cd/lib/test-helpers.nix`](../ci-cd/lib/test-helpers.nix)
- [`/etc/nixos/ci-cd/integration/security-hardening.nix`](../ci-cd/integration/security-hardening.nix)
- [`/etc/nixos/ci-cd/tailscale-integration-test.nix`](../ci-cd/tailscale-integration-test.nix)

### 2. Buildbot is the local orchestrator

Buildbot should be used for:

- local scheduling
- webhook ingestion when needed
- repository discovery when needed
- selecting test suites
- executing `nix build`, `nix flake check`, and NixOS tests
- publishing local CI state
- pushing binary cache artifacts

In this model, Buildbot is not the place where tests are authored.
It is the place where the existing `ci-cd/` domain is executed.

### 3. GitHub Runner is a compatibility layer

The GitHub runner remains useful for:

- repositories that still require GitHub-hosted workflow semantics
- interoperability with third-party Actions logic
- staged migration while Buildbot becomes the main path

It should not remain the primary control plane for the local Nix infrastructure.

## Test Taxonomy

The repository should use explicit test classes:

### Integration Tests

Primary examples already exist:

- security hardening:
  [`/etc/nixos/ci-cd/integration/security-hardening.nix`](../ci-cd/integration/security-hardening.nix)
- docker services:
  [`/etc/nixos/ci-cd/integration/docker-services.nix`](../ci-cd/integration/docker-services.nix)
- networking:
  [`/etc/nixos/ci-cd/integration/networking.nix`](../ci-cd/integration/networking.nix)
- tailscale stack:
  [`/etc/nixos/ci-cd/tailscale-integration-test.nix`](../ci-cd/tailscale-integration-test.nix)

These are not unit tests. They are system integration tests using the NixOS test framework.

### Module Tests

`moduleTests` is already reserved in:

- [`/etc/nixos/ci-cd/default.nix`](../ci-cd/default.nix)

This is the right place for smaller, narrower checks as the test suite grows.

### Helper-Driven Test Expansion

The helper layer in:

- [`/etc/nixos/ci-cd/lib/test-helpers.nix`](../ci-cd/lib/test-helpers.nix)

should be treated as the standard way to create new tests quickly and consistently.

## Why Buildbot Fits Better Than Hosted CI

For this repository, local Buildbot has structural advantages:

- it understands Nix-native execution better than workflow YAML glued to SaaS runners
- it can schedule heavy local workloads and future GPU-sensitive jobs
- it can coordinate local binary cache strategy
- it can run the same test domain that the repo already stores under `ci-cd/`
- it reduces dependency on external workflow orchestration for core infra validation

This is especially relevant because this repository is not just an application repository.
It is infrastructure, system configuration, test orchestration, and service topology in one place.

## Required Runtime Bridge

What must move into `modules/` is not the test suite.
What must move into `modules/` is the declarative activation bridge.

That bridge should provide:

- `options.kernelcore.ci` or `options.kernelcore.services.buildbot`
- host-level enablement flags
- secret wiring
- systemd/runtime activation
- optional public exposure later through the NGINX/TLS stack

The simplest shape is:

- `ci-cd/` keeps the Buildbot implementation details and test domain
- `modules/` adds a small wrapper module that imports and activates that runtime

## Secrets Model

The repository now has a CI secrets module:

- [`/etc/nixos/modules/secrets/ci.nix`](../modules/secrets/ci.nix)

Current live state:

- local Buildbot authentication is SOPS-backed
- the CI secrets module currently sources those values from [`/etc/nixos/secrets/github.yaml`](../secrets/github.yaml)
- the file split into a dedicated `ci.yaml` can still happen later without changing the runtime API

Secrets remain file-backed via `config.sops.secrets.<name>.path`.

## Recommended Local Buildbot Flow

### Phase 1: Local Only

Buildbot runs locally and executes the test domain already in `ci-cd/`.

Scope:

- `nix flake check`
- selected NixOS tests from `ci-cd/`
- cache push
- local dashboard

GitHub integration stays optional.

### Phase 2: Repository Discovery

Enable Buildbot repository discovery or explicit repo inputs.

Candidate source:

- topic-based or explicit repository lists from
  [`/etc/nixos/ci-cd/buildbot/master.nix`](../ci-cd/buildbot/master.nix)

### Phase 3: Public Exposure

Expose Buildbot behind the repo-wide TLS/proxy stack.

Target:

- Buildbot UI behind NGINX
- certificate issued by the central TLS module
- local upstream only, public TLS termination at the proxy

### Phase 4: GitHub Runner Demotion

Once Buildbot is stable:

- reduce GitHub runner scope
- keep it only for workflows that truly require GitHub Actions semantics

## Immediate Migration Tasks

1. Validate the first real local Buildbot job on `kernelcore`.
2. Keep `ci-cd/` as the canonical place for tests and helpers.
3. Decide whether the secrets should stay co-located in `github.yaml` or move into a dedicated `ci.yaml`.
4. Add cache publish policy only after the local validation path is stable.
5. Expose Buildbot behind the TLS/proxy layer only after local runtime is proven.

## Non-Goals

These are explicitly not the goal of this architecture:

- moving the entire `ci-cd/` tree into `modules/`
- rewriting all tests around GitHub Actions
- making hosted CI the source of truth for infrastructure validation
- mixing service activation logic with test authoring logic

## Summary

The correct composition is:

- `ci-cd/` owns the test domain
- `Buildbot` owns local orchestration
- `modules/` owns the declarative runtime bridge
- `SOPS` owns CI secrets
- `GitHub runner` remains optional compatibility, not the center of the design

This keeps the repository Nix-native, testable, and locally sovereign.
