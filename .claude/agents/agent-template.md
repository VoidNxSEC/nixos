# Agent Template: [Agent Name]

## Agent Metadata
- **Name**: [Agent Name]
- **Version**: 1.0.0
- **Purpose**: [Brief description]
- **Phase**: [Phase 1/2/3/4]
- **Parallelizable**: [Yes/No]

## Capabilities
List of specific capabilities this agent provides:
1. Capability 1
2. Capability 2
3. ...

## Dependencies
- **Required Tools**: [nix, git, etc.]
- **Required Agents**: [None / List of prerequisite agents]
- **Required Files**: [Files that must exist]

## Configuration

### Options
```yaml
option1:
  type: string
  default: "value"
  description: "What this option does"

option2:
  type: boolean
  default: false
  description: "Enable/disable feature"
```

### Example Configuration
```yaml
agent: agent-name
config:
  option1: "custom-value"
  option2: true
```

## Tasks

### Task 1: [Task Name]
**Description**: What this task accomplishes

**Inputs**:
- Input 1: Description
- Input 2: Description

**Steps**:
1. Step 1
2. Step 2
3. ...

**Outputs**:
- Output 1: Description
- Output 2: Description

**Validation**:
```bash
# How to verify this task completed successfully
command-to-validate
```

### Task 2: [Task Name]
[Repeat pattern above]

## Error Handling

### Error Type 1
**Symptom**: What user will see
**Cause**: Why it happens
**Resolution**: How to fix
**Rollback**: How to undo changes

### Error Type 2
[Repeat pattern above]

## State Management

### State File: `.claude/agents/[agent-name]/state.json`
```json
{
  "version": "1.0.0",
  "status": "running|completed|failed",
  "current_task": "task-name",
  "progress": {
    "total_tasks": 10,
    "completed_tasks": 5,
    "failed_tasks": 0
  },
  "last_updated": "2025-11-01T19:00:00Z"
}
```

### Completed Tasks: `.claude/agents/[agent-name]/completed.json`
```json
[
  {
    "task": "task-1",
    "completed_at": "2025-11-01T18:30:00Z",
    "files_modified": ["file1.nix", "file2.nix"],
    "git_commit": "abc123"
  }
]
```

### Errors: `.claude/agents/[agent-name]/errors.json`
```json
[
  {
    "task": "task-2",
    "error": "Error description",
    "timestamp": "2025-11-01T18:45:00Z",
    "stack_trace": "...",
    "recovery_action": "Manual intervention required"
  }
]
```

## Usage Examples

### Example 1: Basic Usage
```bash
# Launch agent with default config
/agent [agent-name]
```

### Example 2: Custom Configuration
```bash
# Launch with custom options
/agent [agent-name] --config '{"option1": "value"}'
```

### Example 3: Resume After Error
```bash
# Resume from last checkpoint
/agent [agent-name] --resume
```

## Validation Checklist

After agent completes, verify:
- [ ] All tasks completed successfully
- [ ] `nix flake check` passes
- [ ] `sudo nixos-rebuild test` succeeds
- [ ] State files updated
- [ ] Git commits created
- [ ] Documentation updated (if applicable)

## Rollback Procedure

If agent fails or causes issues:

```bash
# 1. Check agent state
cat .claude/agents/[agent-name]/state.json

# 2. Review errors
cat .claude/agents/[agent-name]/errors.json

# 3. Rollback git changes
git log --oneline | grep "[agent-name]"
git reset --hard [commit-before-agent]

# 4. Rebuild system
sudo nixos-rebuild switch

# 5. Clean agent state
rm -rf .claude/agents/[agent-name]/state.json
```

## Testing

### Unit Tests
```bash
# Test individual agent functions
[test-command]
```

### Integration Tests
```bash
# Test agent in isolated environment
nix build .#vm-image
# Run agent in VM
```

## Maintenance

### Version Updates
Update `agent-template.md` when:
- New capabilities added
- Breaking changes to agent protocol
- New state management features

### Deprecation
Mark deprecated features:
```yaml
option_old:
  deprecated: true
  replacement: "option_new"
  removal_version: "2.0.0"
```

## Support

**Issues**: File in `/etc/nixos/.claude/agents/[agent-name]/issues/`
**Documentation**: Link to relevant docs
**Maintainer**: kernelcore
