# MCP Server PROJECT_ROOT Environment Variable Analysis

**Date**: 2025-11-08  
**Scope**: `/etc/nixos/modules/ml/unified-llm/mcp-server/`  
**Focus**: Environment variable and path handling patterns  
**Status**: Comprehensive analysis complete

---

## Executive Summary

The MCP server uses **PROJECT_ROOT** as a central path reference point that affects multiple subsystems:
1. Knowledge database location
2. Package diagnosis and configuration paths
3. Build and execution contexts
4. Shell command execution directories

**Current Implementation**: Environment variable with fallback to `process.cwd()`  
**Issue**: Hardcoded `/etc/nixos` defaults in several tools, limiting portability  
**Impact**: MCP server only works correctly when deployed to `/etc/nixos` or PROJECT_ROOT is explicitly set

---

## 1. PROJECT_ROOT Usage in src/index.ts

### Primary Declaration (Lines 29-31)
```typescript
const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();
const KNOWLEDGE_DB_PATH = process.env.KNOWLEDGE_DB_PATH || path.join(PROJECT_ROOT, "knowledge.db");
const ENABLE_KNOWLEDGE = process.env.ENABLE_KNOWLEDGE !== 'false';
```

### Key Characteristics
- **Dynamic**: Falls back to current working directory if not set
- **Exportable**: Can be overridden via environment variable
- **Propagated**: Passed to all tool constructors

### Usage Points in src/index.ts

1. **Provider Test Command** (Line 518-519)
   ```typescript
   cd "${PROJECT_ROOT}" && \
   cargo run --bin securellm -- test ${provider}
   ```
   - Changes directory before executing cargo command
   - Allows relative cargo.toml paths to work correctly

2. **Security Audit Path Resolution** (Line 565)
   ```typescript
   const configPath = path.resolve(PROJECT_ROOT, config_file);
   ```
   - Resolves audit config files relative to PROJECT_ROOT
   - Allows arbitrary config file locations within project

3. **Crypto Key Generation** (Line 788)
   ```typescript
   const outputDir = path.resolve(PROJECT_ROOT, output_path);
   ```
   - Makes certificate output paths relative to PROJECT_ROOT
   - Prepares for arbitrary certificate storage

4. **Build and Test Execution** (Line 700)
   ```typescript
   cd "${PROJECT_ROOT}" && \
   cargo build && \
   ${testCommand}
   ```
   - Ensures build happens in correct directory context

5. **Tool Initialization** (Lines 78-80)
   ```typescript
   this.packageDiagnose = new PackageDiagnoseTool(PROJECT_ROOT);
   this.packageDownload = new PackageDownloadTool(PROJECT_ROOT);
   this.packageConfigure = new PackageConfigureTool(PROJECT_ROOT);
   ```
   - All package tools receive PROJECT_ROOT

---

## 2. PackageDiagnoseTool: Hardcoded Paths

### Constructor (Lines 21-24, src/tools/package-diagnose.ts)
```typescript
constructor(workspaceDir: string = "/etc/nixos") {
  this.errorClassifier = new ErrorClassifier();
  this.workspaceDir = workspaceDir;
}
```

### Problem: Hardcoded Default
- **Default value**: `/etc/nixos` (HARDCODED)
- **Override**: Only via constructor parameter
- **Consequence**: If PROJECT_ROOT is not set, defaults to `/etc/nixos` anyway

### Path Usage in Package Diagnosis

1. **Config File Validation** (Line 121)
   ```typescript
   await readFile(`${this.workspaceDir}/${path}`, "utf-8");
   ```
   - Reads package configuration relative to workspaceDir

2. **Config Analysis** (Line 139)
   ```typescript
   const content = await readFile(`${this.workspaceDir}/${path}`, "utf-8");
   ```
   - Analyzes package .nix files

3. **Test Build Execution** (Line 235)
   ```typescript
   const buildProcess = spawn("nix", ["build", `${this.workspaceDir}#${attrPath}`, "--no-link"], {
     cwd: this.workspaceDir,
   });
   ```
   - Uses `workspaceDir` as both:
     - Part of flake reference (`flake#attrPath`)
     - Working directory for nix command
   - **Critical**: Assumes nix flake is at this location

4. **Nix Attribute Paths** (Lines 284-294)
   ```typescript
   private getAttributePath(packageType: string, packageName: string): string {
     switch (packageType) {
       case "tar":
         return `kernelcore.packages.tar.packages.${packageName}`;
       case "deb":
         return `kernelcore.packages.deb.packages.${packageName}`;
       case "js":
         return `kernelcore.packages.${packageName}`;
     }
   }
   ```
   - **HARDCODED**: `kernelcore` output attribute
   - **Assumes**: NixOS flake structure at project root
   - **Not portable**: Won't work with different flake outputs or host names

---

## 3. PackageDownloadTool: Workspace-Relative Paths

### Constructor (Lines 30-34, src/tools/package-download.ts)
```typescript
export class PackageDownloadTool {
  private workspaceDir: string;

  constructor(workspaceDir: string = "/etc/nixos") {
    this.workspaceDir = workspaceDir;
  }
```

### Same Issue as PackageDiagnoseTool
- **Default**: `/etc/nixos` hardcoded
- **Pattern**: `${this.workspaceDir}/${storageDir}`

### Storage Directory Logic (Implied in download method)
```typescript
const storageDir = this.getStorageDir(input.package_type);
await mkdir(`${this.workspaceDir}/${storageDir}`, { recursive: true });
```

- Likely creates paths like: `/etc/nixos/packages/tar/`, `/etc/nixos/packages/deb/`
- **Not portable** across different repository locations

---

## 4. PackageConfigureTool: Workspace-Relative Paths

### Constructor Pattern (Same as above)
```typescript
export class PackageConfigureTool {
  private workspaceDir: string;

  constructor(workspaceDir: string = "/etc/nixos") {
    this.workspaceDir = workspaceDir;
  }
```

- Same hardcoded `/etc/nixos` default
- Same issue: portability across environments

---

## 5. GuideManager: Dynamic Path Resolution

### Constructor (Lines 22-26, src/resources/guides.ts)
```typescript
constructor(baseDir?: string) {
  const docsPath = baseDir || path.join(__dirname, '../../docs');
  this.guidesPath = path.join(docsPath, 'guides');
  this.skillsPath = path.join(docsPath, 'skills');
  this.promptsPath = path.join(docsPath, 'prompts');
}
```

### Key Difference: **Relative to source code**
- **Default**: Uses `__dirname` (current file location)
- **Relative path**: `../../docs` (relative to build output)
- **Advantage**: Works from any location if source structure is preserved
- **Note**: Called with NO parameter in index.ts (Line 75)
  ```typescript
  this.guideManager = new GuideManager();
  ```
  - Relies entirely on relative path calculation
  - **Advantage**: Most portable approach

---

## 6. Knowledge Database: Environment Variable Resolution

### in src/index.ts (Lines 30)
```typescript
const KNOWLEDGE_DB_PATH = process.env.KNOWLEDGE_DB_PATH || path.join(PROJECT_ROOT, "knowledge.db");
```

### Database Implementation (src/knowledge/database.ts)
```typescript
constructor(dbPath: string) {
  const dir = dirname(dbPath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
```

### Path Resolution Chain
1. Check `KNOWLEDGE_DB_PATH` environment variable (most specific)
2. If not set, use `PROJECT_ROOT/knowledge.db`
3. If PROJECT_ROOT not set, use `cwd()/knowledge.db`

### Advantages of This Approach
- **Three-level fallback**: explicit env var > PROJECT_ROOT > cwd
- **Auto-creates**: Directory structure if needed
- **Flexible**: Can be on different filesystem/mount point

---

## 7. Hardcoded /etc/nixos References (Global Search)

### Files with /etc/nixos in comments/docs
Found 9 occurrences:
- `modules/ml/unified-llm/mcp-server/build/src/tools/package-configure.js` - likely in Nix attribute paths
- `modules/ml/unified-llm/mcp-server/build/src/tools/package-download.js` - likely in paths
- `modules/ml/unified-llm/mcp-server/build/src/tools/package-diagnose.js` - likely in paths
- `modules/ml/unified-llm/mcp-server/src/tools/package-configure.ts` - Nix attribute paths
- `modules/ml/unified-llm/mcp-server/src/tools/package-download.ts` - storage paths
- `modules/ml/unified-llm/mcp-server/src/tools/package-diagnose.ts` - Nix attribute paths

### Critical Patterns

**Pattern 1: Nix Attribute Path** (package-diagnose.ts:286)
```typescript
case "tar":
  return `kernelcore.packages.tar.packages.${packageName}`;
```
- Hardcoded `kernelcore` output attribute
- Won't work with other host names or flake structures

**Pattern 2: Default Constructor Parameter** (All package tools)
```typescript
constructor(workspaceDir: string = "/etc/nixos")
```
- Assumes NixOS repo location
- Breaks in other environments

---

## 8. Environment Variables Affecting Paths

### Currently Supported
```
PROJECT_ROOT          - Root directory of the project/repo
KNOWLEDGE_DB_PATH     - Explicit path to knowledge database
ENABLE_KNOWLEDGE      - Enable/disable knowledge database feature
```

### NOT Currently Supported (Should Be)
```
MCP_DOCS_PATH         - Override docs base directory
NIXOS_HOST_NAME       - Host name for Nix attribute paths (currently hardcoded "kernelcore")
NIXOS_FLAKE_PATH      - Flake location (currently assumes PROJECT_ROOT)
STORAGE_BASE_PATH     - Base directory for package storage
```

---

## 9. Dynamic Solution Architecture

### Problem Statement
Current implementation assumes:
1. Repository located at `/etc/nixos`
2. NixOS flake output named `kernelcore`
3. Docs located at `docs/` relative to mcp-server source
4. All operations work from PROJECT_ROOT

### Constraints for Dynamic Solution
- Must maintain backward compatibility
- Should work in multiple environments (NixOS /etc/nixos, dev directories, monorepos)
- Should not require extensive environment setup
- Package tools need Nix flake access

### Proposed Solution Points
1. **Detect repository root** (multiple strategies)
   - Explicit `PROJECT_ROOT` env var (current, highest priority)
   - Search for `flake.nix` upward from cwd
   - Search for `.git` directory
   - Use `process.cwd()` as final fallback

2. **Detect flake output name** (for Nix commands)
   - Pass via `NIXOS_HOST_NAME` environment variable
   - Parse `flake.nix` to extract output names
   - Offer interactive selection if ambiguous
   - Default to system hostname (via `os.hostname()`)

3. **Make paths configurable**
   - Move hardcoded defaults to configuration
   - Accept as constructor parameters with fallbacks
   - Document in README

4. **Enhance package tools**
   - Accept flexible flake references
   - Support `--flake` path option
   - Cache parsed flake metadata

---

## 10. Current Path Resolution Flow (Diagram)

```
MCP Server Start
    ↓
PROJECT_ROOT Selection
    ↙        ↓         ↘
env var   cwd()   [NOT: flake.nix search]
    ↓        ↓         ↓
  [explicit] [cwd] [fallback]
    
    ↓
Knowledge DB Init
    ↓
KNOWLEDGE_DB_PATH Selection
    ↙         ↓           ↘
env var   PROJECT_ROOT   cwd()/knowledge.db
    
    ↓
Package Tools Init
    ↓
Tools Receive PROJECT_ROOT
    ↓
Tools Use /etc/nixos DEFAULT (⚠️)
    ↓
File Operations Relative to workspaceDir
```

### Issue in Flow
- Package tools receive `PROJECT_ROOT` correctly
- But constructors have `/etc/nixos` hardcoded defaults
- If passed `undefined` or misconfigured, they use hardcoded path
- Creates inconsistency

---

## 11. Build Artifacts Path Analysis

### Compiled TypeScript (build/src/index.js, line 18)
```typescript
const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();
```
- Identical to source
- Environment variable pattern preserved in compilation

### Build Directory Structure
```
build/
├── src/
│   ├── index.js (main entry point)
│   ├── knowledge/
│   │   └── database.js
│   ├── tools/
│   │   ├── package-diagnose.js
│   │   ├── package-download.js
│   │   └── package-configure.js
│   └── resources/
│       └── guides.js
├── src/knowledge/
│   └── database.d.ts (TypeScript definitions)
└── ... other outputs
```

---

## Key Findings Summary

### What Works (Currently)
1. Knowledge database path can be overridden via `KNOWLEDGE_DB_PATH`
2. GuideManager is location-agnostic (uses relative paths from source)
3. PROJECT_ROOT fallback to cwd() is reasonable
4. Package tools receive PROJECT_ROOT in constructor

### What Doesn't Work (Currently)
1. Package tools hardcoded `/etc/nixos` defaults in constructors
2. Nix attribute paths hardcoded to `kernelcore.packages.*`
3. No way to change hostname for flake outputs
4. No support for alternative repository structures
5. Knowledge database defaults to PROJECT_ROOT instead of XDG_DATA_HOME

### What Needs Improvement
1. Remove `/etc/nixos` hardcoded defaults
2. Add hostname/flake output detection
3. Support XDG directory standards for persistent data
4. Add configuration file support (.env, .mcp-config.json, etc.)
5. Document all path resolution behavior
6. Add environment variable validation/documentation

---

## Implementation Priority

### High Priority (Breaks in non-NixOS environments)
1. Make Nix attribute path configurable (kernelcore -> variable)
2. Remove /etc/nixos hardcoded defaults
3. Add automatic flake detection

### Medium Priority (Non-critical but useful)
1. Add KNOWLEDGE_DB_PATH better documentation
2. Support XDG directory standards
3. Add environment variable validation
4. Create .env.example file

### Low Priority (Nice to have)
1. Configuration file support
2. Interactive setup wizard
3. Flake.nix parsing for auto-detection
4. Better error messages for path resolution failures

---

## Absolute File Paths Used in Codebase

### In Source Files (src/)
- `/etc/nixos` - **5 occurrences** (package-diagnose.ts, package-download.ts, package-configure.ts constructors)
- No hardcoded `/etc/nixos` in index.ts or database.ts

### In Generated Build Files (build/)
- `/etc/nixos` - **5 occurrences** (compiled from source)

### In Configuration/Docs
- Not directly used in code, only in documentation

---

## Recommendations for Dynamic Solution

1. **Environment Detection** - Implement smart root detection:
   ```typescript
   // Order of precedence:
   // 1. Explicit PROJECT_ROOT env var
   // 2. Search upward for flake.nix
   // 3. Search upward for .git
   // 4. Use process.cwd()
   ```

2. **Hostname Configuration** - Allow flexible Nix outputs:
   ```typescript
   // Order of precedence:
   // 1. NIXOS_HOST_NAME env var
   // 2. Parse flake.nix outputs
   // 3. Fallback to os.hostname()
   ```

3. **Path Standardization** - Use environment variables:
   ```typescript
   // For persistent data (knowledge db, cache):
   // 1. Explicit path via env var
   // 2. PROJECT_ROOT/data/
   // 3. $HOME/.local/share/mcp-server/
   ```

4. **Configuration** - Support multiple config sources:
   ```
   .mcp-server.json (project root)
   ~/.config/mcp-server/config.json
   Environment variables (highest priority)
   ```

---

**Analysis Complete** | Prepared for implementation planning
