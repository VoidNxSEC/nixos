# Claude Code Workflows - NixOS Restructuring

This directory contains workflow definitions for orchestrating multi-agent and multi-skill operations.

## Workflow Types

### 1. Sequential Workflows
Tasks executed one after another, each depending on previous completion.

**Use Cases**:
- Critical path tasks
- Validation pipelines
- Deployment workflows

**Example**: Phase 1 Critical Path
```yaml
workflow: phase-1-critical
type: sequential
steps:
  - agent: structure-validator
    task: move-laptop-offload-client
  - agent: structure-validator
    task: create-module-defaults
  - agent: security-auditor
    task: validate-security-structure
  - agent: testing
    task: run-flake-check
```

---

### 2. Parallel Workflows
Tasks executed concurrently, independent of each other.

**Use Cases**:
- Code refactoring
- Documentation generation
- Independent module updates

**Example**: Phase 2 Refactoring
```yaml
workflow: phase-2-parallel
type: parallel
max_concurrent: 3
steps:
  - agent: module-refactoring
    task: refactor-vscode-vscodium
  - agent: module-refactoring
    task: refactor-firefox-brave
  - agent: documentation
    task: add-module-headers
```

---

### 3. Hybrid Workflows
Combination of sequential and parallel execution.

**Use Cases**:
- Complex multi-phase operations
- Validation → Action → Validation patterns

**Example**: Complete Module Refactor
```yaml
workflow: complete-module-refactor
type: hybrid
phases:
  - name: validation
    type: sequential
    steps:
      - agent: structure-validator
        task: validate-current-state
      - skill: module-validate
        targets: all

  - name: refactoring
    type: parallel
    max_concurrent: 3
    steps:
      - agent: module-refactoring
        task: split-large-modules
      - agent: documentation
        task: generate-docs
      - skill: default-nix-create
        targets: all-categories

  - name: final-validation
    type: sequential
    steps:
      - agent: testing
        task: run-all-tests
      - skill: flake-validate
```

---

## Active Workflows

### Phase 1: Critical Path (Week 1)

**File**: `phase-1-critical.yaml`

**Objectives**:
1. Move misplaced modules
2. Create module default.nix files
3. Restructure security modules
4. Validate changes

**Status**: Not Started
**Duration**: 3-5 days
**Prerequisites**: None

---

### Phase 2: Structural Improvements (Week 2)

**File**: `phase-2-structural.yaml`

**Objectives**:
1. Refactor duplicate code
2. Split large modules
3. Enhance documentation
4. Optimize imports

**Status**: Not Started
**Duration**: 5-7 days
**Prerequisites**: Phase 1 Complete

---

### Phase 3: Documentation & Testing (Week 3)

**File**: `phase-3-docs-testing.yaml`

**Objectives**:
1. Generate comprehensive docs
2. Create test infrastructure
3. Add inline documentation
4. Create usage examples

**Status**: Not Started
**Duration**: 5-7 days
**Prerequisites**: Phase 2 Complete

---

### Phase 4: Advanced Optimizations (Week 4+)

**File**: `phase-4-advanced.yaml`

**Objectives**:
1. Multi-host architecture
2. CI/CD enhancement
3. Development tools
4. Performance optimization

**Status**: Not Started
**Duration**: 2+ weeks
**Prerequisites**: Phase 3 Complete

---

## Workflow Execution

### Manual Execution

```bash
# Execute workflow via Claude Code
/workflow phase-1-critical

# Execute specific phase of hybrid workflow
/workflow complete-module-refactor --phase validation

# Execute with dry-run
/workflow phase-2-structural --dry-run
```

### Automated Execution

```bash
# Via CI/CD
nix run .#workflow-runner phase-1-critical

# Cron-scheduled
# (Add to configuration.nix)
systemd.timers.nixos-workflow = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "weekly";
    Persistent = true;
  };
};
```

---

## Workflow State Tracking

### State Files

Each workflow maintains state in `.claude/workflows/[workflow-name]/`:

```
.claude/workflows/phase-1-critical/
├── state.json              # Current workflow state
├── progress.json           # Detailed progress
├── logs/                   # Execution logs
│   ├── 2025-11-01.log
│   └── 2025-11-02.log
└── results/                # Agent/skill outputs
    ├── structure-validator.json
    └── testing.json
```

### State Schema

**state.json**:
```json
{
  "workflow": "phase-1-critical",
  "version": "1.0.0",
  "status": "running|completed|failed|paused",
  "started_at": "2025-11-01T10:00:00Z",
  "updated_at": "2025-11-01T12:30:00Z",
  "completed_at": null,
  "current_step": 2,
  "total_steps": 4,
  "errors": [],
  "metadata": {
    "triggered_by": "manual",
    "git_commit": "abc123"
  }
}
```

**progress.json**:
```json
{
  "steps": [
    {
      "id": 1,
      "name": "move-laptop-offload-client",
      "agent": "structure-validator",
      "status": "completed",
      "started_at": "2025-11-01T10:00:00Z",
      "completed_at": "2025-11-01T10:15:00Z",
      "duration_seconds": 900,
      "outputs": {
        "files_modified": 2,
        "git_commit": "def456"
      }
    },
    {
      "id": 2,
      "name": "create-module-defaults",
      "agent": "structure-validator",
      "status": "running",
      "started_at": "2025-11-01T10:15:00Z",
      "progress_percent": 45
    }
  ]
}
```

---

## Workflow Templates

### Basic Sequential Template

```yaml
workflow: my-workflow
description: "Brief description of what this workflow does"
version: 1.0.0
type: sequential

prerequisites:
  - phase-1-complete
  - flake-check-passing

steps:
  - id: step-1
    type: agent
    agent: agent-name
    task: task-name
    config:
      option1: value1

  - id: step-2
    type: skill
    skill: skill-name
    options:
      option1: value1

validation:
  - nix flake check
  - nixos-rebuild test

on_success:
  - git commit -m "Workflow completed"
  - notify: success

on_failure:
  - git reset --hard HEAD
  - notify: failure
```

### Parallel Template

```yaml
workflow: my-parallel-workflow
description: "Parallel execution workflow"
version: 1.0.0
type: parallel
max_concurrent: 3

steps:
  - id: step-1
    type: agent
    agent: agent-name-1
    task: task-1

  - id: step-2
    type: agent
    agent: agent-name-2
    task: task-2

  - id: step-3
    type: agent
    agent: agent-name-3
    task: task-3

sync_point: all-complete

validation:
  - nix flake check

on_success:
  - git commit -m "Parallel workflow completed"
```

---

## Monitoring & Observability

### Real-time Monitoring

```bash
# Monitor workflow progress
watch -n 5 'cat .claude/workflows/phase-1-critical/state.json | jq'

# Stream workflow logs
tail -f .claude/workflows/phase-1-critical/logs/$(date +%Y-%m-%d).log

# Check specific step status
cat .claude/workflows/phase-1-critical/progress.json | jq '.steps[] | select(.id == 2)'
```

### Metrics Collection

Workflows emit metrics to `.claude/workflows/metrics.json`:

```json
{
  "workflows": [
    {
      "name": "phase-1-critical",
      "executions": 3,
      "success_rate": 0.67,
      "avg_duration_seconds": 1800,
      "last_execution": "2025-11-01T12:00:00Z"
    }
  ],
  "agents": {
    "structure-validator": {
      "invocations": 10,
      "success_rate": 0.9,
      "avg_duration_seconds": 300
    }
  }
}
```

---

## Error Handling & Recovery

### Automatic Recovery

Workflows support checkpoint-based recovery:

```yaml
workflow: resilient-workflow
type: sequential
recovery_strategy: checkpoint

steps:
  - id: step-1
    checkpoint: true  # Creates checkpoint after completion
    ...

  - id: step-2
    checkpoint: true
    on_failure:
      retry: 3
      backoff: exponential
    ...
```

### Manual Recovery

```bash
# Check failure point
cat .claude/workflows/[workflow]/state.json | jq '.errors'

# Resume from last checkpoint
/workflow [workflow-name] --resume

# Skip failed step and continue
/workflow [workflow-name] --skip-step 3 --resume

# Rollback to checkpoint
/workflow [workflow-name] --rollback-to-checkpoint 2
```

---

## Workflow Composition

Workflows can invoke other workflows:

```yaml
workflow: meta-workflow
type: sequential

steps:
  - id: phase-1
    type: workflow
    workflow: phase-1-critical

  - id: validation
    type: skill
    skill: flake-validate

  - id: phase-2
    type: workflow
    workflow: phase-2-structural
    condition: phase-1.status == "success"
```

---

## Best Practices

1. **Atomic Steps**: Each step should be independent and atomic
2. **Checkpointing**: Add checkpoints before risky operations
3. **Validation**: Validate after each phase
4. **Logging**: Comprehensive logging for debugging
5. **Idempotency**: Steps should be safe to re-run
6. **Rollback**: Always have rollback strategy
7. **Testing**: Test workflows in isolated environment first

---

## Testing Workflows

### Dry Run Mode

```bash
# Simulate workflow without making changes
/workflow phase-1-critical --dry-run
```

### Isolated Testing

```bash
# Create test branch
git checkout -b test-workflow-phase-1

# Run workflow
/workflow phase-1-critical

# Validate
nix flake check
sudo nixos-rebuild test

# If successful
git checkout main
git merge test-workflow-phase-1

# If failed
git checkout main
git branch -D test-workflow-phase-1
```

---

## Workflow Versioning

Workflows follow semantic versioning:

- **Major**: Breaking changes to workflow structure
- **Minor**: New steps/features, backward compatible
- **Patch**: Bug fixes, no functional changes

**Example**:
```yaml
workflow: phase-1-critical
version: 2.1.3
changelog:
  - 2.1.3: Fixed validation step timeout
  - 2.1.0: Added security audit step
  - 2.0.0: Restructured to hybrid workflow (BREAKING)
```

---

## Maintenance

### Regular Reviews
- Review workflow effectiveness weekly during active phases
- Update based on execution metrics
- Optimize slow steps
- Remove deprecated workflows

### Documentation
- Keep README updated with new workflows
- Document lessons learned
- Share workflow patterns that work well

**Maintained By**: kernelcore
**Last Updated**: 2025-11-01
