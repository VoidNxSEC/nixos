# Claude Code Skills - NixOS Repository

This directory contains reusable skills for NixOS repository maintenance and development.

## Available Skills

### 1. Nix Module Generator (`nix-module-gen`)
**Purpose**: Generate new NixOS modules from templates

**Usage**:
```bash
/skill nix-module-gen --name my-feature --category hardware
```

**Options**:
- `--name`: Module name
- `--category`: Module category (hardware, security, development, etc.)
- `--with-options`: Generate with option definitions
- `--with-docs`: Include documentation template

**Output**: Creates new module in correct location with proper structure

---

### 2. Module Validator (`module-validate`)
**Purpose**: Validate module structure and conventions

**Usage**:
```bash
/skill module-validate modules/security/hardening.nix
```

**Checks**:
- ✅ Proper option definitions
- ✅ Documentation present
- ✅ Naming conventions
- ✅ Import hierarchy
- ✅ Security considerations

**Output**: Validation report with issues and suggestions

---

### 3. Duplicate Code Detector (`duplicate-detect`)
**Purpose**: Find duplicate code across modules

**Usage**:
```bash
/skill duplicate-detect --threshold 80
```

**Options**:
- `--threshold`: Similarity percentage (default: 80%)
- `--category`: Limit to specific module category
- `--report`: Generate detailed report

**Output**: List of duplicate code blocks with similarity scores

---

### 4. Module Splitter (`module-split`)
**Purpose**: Split large modules into smaller components

**Usage**:
```bash
/skill module-split modules/browsers/chromium.nix --target-size 150
```

**Options**:
- `--target-size`: Target lines per file (default: 150)
- `--preserve-options`: Keep all options in main file
- `--create-default`: Create default.nix aggregator

**Output**: Split module files with proper imports

---

### 5. Documentation Generator (`doc-gen`)
**Purpose**: Generate documentation from module definitions

**Usage**:
```bash
/skill doc-gen --category security --output docs/modules/security.md
```

**Options**:
- `--category`: Module category to document
- `--format`: markdown/html/man (default: markdown)
- `--include-examples`: Add usage examples
- `--output`: Output file path

**Output**: Comprehensive module documentation

---

### 6. Default.nix Creator (`default-nix-create`)
**Purpose**: Create default.nix aggregator for module categories

**Usage**:
```bash
/skill default-nix-create modules/applications/
```

**Options**:
- `--recursive`: Include subdirectories
- `--exclude`: Exclude specific files
- `--template`: Use custom template

**Output**: default.nix file importing all modules in category

---

### 7. Security Scanner (`security-scan`)
**Purpose**: Scan for security issues and hardcoded secrets

**Usage**:
```bash
/skill security-scan --deep
```

**Options**:
- `--deep`: Perform deep scan (slower, more thorough)
- `--category`: Limit to specific category
- `--report`: Generate security report

**Checks**:
- 🔒 Hardcoded secrets
- 🔒 Insecure configurations
- 🔒 Missing security options
- 🔒 Weak permissions
- 🔒 Deprecated security practices

**Output**: Security scan report with severity levels

---

### 8. Import Optimizer (`import-optimize`)
**Purpose**: Optimize module imports in flake.nix

**Usage**:
```bash
/skill import-optimize flake.nix
```

**Actions**:
- Replace individual imports with default.nix imports
- Remove unused imports
- Organize imports by category
- Add comments for clarity

**Output**: Optimized flake.nix with reduced import lines

---

### 9. Test Generator (`test-gen`)
**Purpose**: Generate NixOS tests for modules

**Usage**:
```bash
/skill test-gen modules/security/hardening.nix
```

**Options**:
- `--type`: vm/integration/unit (default: vm)
- `--coverage`: Generate coverage tests
- `--examples`: Include example test cases

**Output**: Test files in tests/ directory

---

### 10. Flake Validator (`flake-validate`)
**Purpose**: Comprehensive flake validation

**Usage**:
```bash
/skill flake-validate --strict
```

**Checks**:
- ✅ `nix flake check` passes
- ✅ All inputs locked
- ✅ Outputs properly structured
- ✅ Module imports valid
- ✅ No circular dependencies

**Output**: Validation report with errors and warnings

---

## Skill Development

### Creating New Skills

1. **Create skill file**: `.claude/skills/my-skill.md`
2. **Follow template**: Use `skill-template.md`
3. **Implement logic**: Add skill implementation
4. **Test skill**: Validate in isolated environment
5. **Document**: Add to this README

### Skill Template Structure

```markdown
# Skill: [Skill Name]

## Metadata
- Name: skill-name
- Version: 1.0.0
- Category: [generation/validation/optimization]

## Purpose
[Brief description]

## Usage
```bash
/skill skill-name [options]
```

## Implementation
[How the skill works]

## Examples
[Usage examples]

## Tests
[How to test the skill]
```

## Skill Composition

Skills can be composed into workflows:

```yaml
workflow: refactor-module
steps:
  - skill: module-validate
    input: modules/browsers/chromium.nix
  - skill: module-split
    input: modules/browsers/chromium.nix
    options:
      target-size: 150
  - skill: default-nix-create
    input: modules/browsers/
  - skill: flake-validate
  - skill: test-gen
    input: modules/browsers/chromium-base.nix
```

## Skill Registry

Skills are registered in `.claude/skills/registry.json`:

```json
{
  "skills": [
    {
      "name": "nix-module-gen",
      "version": "1.0.0",
      "file": "nix-module-gen.md",
      "category": "generation",
      "tags": ["module", "template", "generator"]
    }
  ]
}
```

## Best Practices

1. **Idempotency**: Skills should be safe to run multiple times
2. **Validation**: Always validate before making changes
3. **Backup**: Create git commits before destructive operations
4. **Logging**: Log all actions for auditing
5. **Error Handling**: Gracefully handle and report errors

## Skill Testing

Test skills in isolated environment:

```bash
# Create test branch
git checkout -b test-skill-[skill-name]

# Run skill
/skill [skill-name] [options]

# Validate
nix flake check

# If successful, merge
git checkout main
git merge test-skill-[skill-name]

# If failed, rollback
git checkout main
git branch -D test-skill-[skill-name]
```

## Maintenance

### Updating Skills
- Review skill effectiveness monthly
- Update based on user feedback
- Deprecate unused skills
- Version bump for breaking changes

### Adding Dependencies
Document skill dependencies:
```yaml
dependencies:
  tools:
    - nix >= 2.18
    - git >= 2.40
  skills:
    - module-validate (for validation)
```
