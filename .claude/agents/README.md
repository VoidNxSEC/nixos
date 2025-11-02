# Claude Code Agents - NixOS Restructuring

This directory contains specialized agent configurations for the NixOS repository restructuring mission.

## Agent Types

### 1. Module Refactoring Agent
**Purpose**: Refactor large modules and extract duplicate code
**Responsibilities**:
- Split modules >200 lines
- Extract common patterns from duplicated code
- Create base modules for inheritance
- Ensure proper option definitions

**Files**: `module-refactoring.md`

### 2. Documentation Agent
**Purpose**: Enhance module documentation
**Responsibilities**:
- Add inline documentation headers
- Document all module options
- Create usage examples
- Generate module reference docs

**Files**: `documentation.md`

### 3. Structure Validator Agent
**Purpose**: Validate and enforce repository structure
**Responsibilities**:
- Create default.nix for module categories
- Verify import hierarchies
- Check naming conventions
- Validate module patterns

**Files**: `structure-validator.md`

### 4. Security Auditor Agent
**Purpose**: Security validation and hardening
**Responsibilities**:
- Scan for hardcoded secrets
- Review security module configurations
- Validate SOPS integration
- Check file permissions

**Files**: `security-auditor.md`

### 5. Testing Agent
**Purpose**: Create and run tests
**Responsibilities**:
- Create NixOS VM tests
- Write integration tests
- Validate flake checks
- Generate test reports

**Files**: `testing.md`

## Workflow Orchestration

Agents can be orchestrated in parallel or sequential workflows:

### Phase 1 Workflow (Critical Path)
```
┌─────────────────────────────────────┐
│  Structure Validator Agent          │
│  - Move laptop-offload-client.nix   │
│  - Create module default.nix files  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Security Auditor Agent              │
│  - Validate restructured security    │
│  - Check permissions                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Testing Agent                       │
│  - Run flake check                   │
│  - Validate rebuild                  │
└─────────────────────────────────────┘
```

### Phase 2 Workflow (Parallel Processing)
```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Module Refactoring  │  │ Documentation       │  │ Structure Validator │
│ Agent               │  │ Agent               │  │ Agent               │
│                     │  │                     │  │                     │
│ - VSCode/VSCodium   │  │ - Add headers       │  │ - Create defaults   │
│ - Firefox/Brave     │  │ - Document options  │  │ - Fix naming        │
│ - Split large mods  │  │ - Usage examples    │  │ - Verify hierarchy  │
└──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘
           │                        │                        │
           └────────────────────────┼────────────────────────┘
                                    ▼
                    ┌───────────────────────────┐
                    │  Testing Agent            │
                    │  - Integration tests      │
                    │  - Validate all changes   │
                    └───────────────────────────┘
```

## Agent Communication Protocol

Agents communicate via structured outputs in `/etc/nixos/.claude/workflows/`:

- `phase-1-status.json` - Phase 1 progress
- `phase-2-status.json` - Phase 2 progress
- `issues.json` - Discovered issues
- `recommendations.json` - Improvement suggestions

## Usage

### Launch Single Agent
```bash
# Via Claude Code
/agent module-refactoring "Refactor vscode/vscodium modules"
```

### Launch Agent Workflow
```bash
# Via Claude Code
/workflow phase-1-critical
/workflow phase-2-parallel
```

### Monitor Agent Progress
```bash
cat /etc/nixos/.claude/workflows/phase-1-status.json | jq
```

## Agent State Persistence

Each agent maintains state in:
```
.claude/agents/
├── module-refactoring/
│   ├── state.json          # Current progress
│   ├── completed.json      # Completed tasks
│   └── errors.json         # Encountered errors
├── documentation/
│   └── ...
└── ...
```

## Best Practices

1. **Agent Isolation**: Each agent should work on independent tasks
2. **State Tracking**: Agents must update state files after each action
3. **Error Handling**: Agents must log errors for human review
4. **Validation**: All agent changes must pass `nix flake check`
5. **Rollback**: Git commits after each agent phase for easy rollback

## Agent Templates

New agents should follow the template in `agent-template.md`.
