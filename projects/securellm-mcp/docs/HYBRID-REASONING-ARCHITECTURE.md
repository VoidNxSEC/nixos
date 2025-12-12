
# Hybrid Reasoning + Dev Tools Architecture for MCP Server

**Version**: 2.0  
**Status**: 📋 Planning  
**Created**: 2025-01-XX  
**Last Updated**: 2025-01-XX

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Reasoning Systems (Phase 1)](#2-reasoning-systems-phase-1)
3. [Development Tools (Phase 2)](#3-development-tools-phase-2)
4. [Proactive Logic Layer (Phase 3)](#4-proactive-logic-layer-phase-3)
5. [Integration & Architecture](#5-integration--architecture)
6. [Packaging (Phase 5)](#6-packaging-phase-5)
7. [Implementation Roadmap](#7-implementation-roadmap)
8. [Testing Strategy](#8-testing-strategy)
9. [Success Metrics](#9-success-metrics)

---

## 1. System Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER REQUEST                                 │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     MCP SERVER CORE                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  Tool        │  │  Resource    │  │  Knowledge   │             │
│  │  Registry    │  │  Manager     │  │  Database    │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                ▼                         ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│   REASONING LAYER        │  │   PROACTIVE LAYER        │
│                          │  │                          │
│  ┌─────────────────────┐│  │  ┌─────────────────────┐│
│  │ Context Inference   ││  │  │ Pre-Action Checks   ││
│  └─────────────────────┘│  │  └─────────────────────┘│
│  ┌─────────────────────┐│  │  ┌─────────────────────┐│
│  │ Multi-Step Planner  ││  │  │ Context Enricher    ││
│  └─────────────────────┘│  │  └─────────────────────┘│
│  ┌─────────────────────┐│  │  ┌─────────────────────┐│
│  │ Causal Reasoning    ││  │  │ Smart Cache         ││
│  └─────────────────────┘│  │  └─────────────────────┘│
│  ┌─────────────────────┐│  │                          │
│  │ Adaptive Learning   ││  │                          │
│  └─────────────────────┘│  │                          │
└──────────────────────────┘  └──────────────────────────┘
                │                         │
                └────────────┬────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT TOOLS                                 │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │   Nix   │  │    C    │  │ Haskell │  │   Zig   │  │   Git   │ │
│  │  Tools  │  │  Tools  │  │  Tools  │  │  Tools  │  │  Tools  │ │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  MIDDLEWARE & INFRASTRUCTURE                         │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Rate Limiter │  │ Error Handler│  │ Metrics      │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         RESPONSE                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Core Principles

1. **Intelligence First**: Every operation starts with reasoning before execution
2. **Proactive Action**: Gather context BEFORE asking questions
3. **Fail Fast, Learn Fast**: Use failures to improve future predictions
4. **Modular Design**: Each system can operate independently
5. **Performance Conscious**: Target < 100ms for reasoning, < 2s for proactive actions
6. **Data-Driven**: All decisions backed by metrics and learning

### 1.3 Design Goals

- **Reduce User Friction**: 50% fewer clarifying questions through proactive context gathering
- **Increase Accuracy**: 80%+ prediction accuracy for dependencies and impacts
- **Enable Automation**: Multi-step tasks execute with minimal user intervention
- **Developer Productivity**: Comprehensive dev tools for daily workflow
- **Continuous Improvement**: System learns from every interaction

### 1.4 Integration with Existing Infrastructure

**Current Foundation**:
- Knowledge Database (SQLite + FTS5) → Stores interaction history for learning
- Rate Limiter (Circuit Breaker) → Protects against API overload
- Package Debugger Tools → Existing dev tool foundation
- SOPS Secrets → Secure credential management

**New Additions Leverage Existing**:
- Context Inference reads from Knowledge DB
- Adaptive Learning writes patterns back to Knowledge DB
- All dev tools use existing rate limiter
- Proactive actions cache results in Knowledge DB

### 1.5 Performance & Scalability

**Target Performance**:
- Context inference: < 100ms (in-memory + indexed DB)
- Proactive actions: < 2s (parallel execution)
- Multi-step planning: < 500ms (heuristic-based)
- Causal analysis: < 1s (cached dependency graph)
- Dev tool execution: varies by tool (bounded by timeouts)

**Scalability Strategy**:
- In-memory caching for hot data (LRU cache, 100MB limit)
- Async/parallel execution where possible
- Incremental processing (don't recompute entire graph)
- Background tasks for learning (non-blocking)
- Database connection pooling

**Resource Limits**:
- Memory: 512MB base + 256MB per active reasoning session
- CPU: Prefer I/O-bound operations over CPU-intensive
- Storage: Knowledge DB managed with periodic cleanup
- Network: Rate-limited to respect API constraints

---

## 2. Reasoning Systems (Phase 1)

### 2.1 Context Inference Engine

**Purpose**: Automatically extract entities, topics, and intent from user input and project state.

#### TypeScript Interfaces

```typescript
// Core Context Inference
interface ContextInferenceEngine {
  // Analyze user input
  analyzeInput(input: string): Promise<InputAnalysis>;
  
  // Get current project state
  getProjectState(): Promise<ProjectState>;
  
  // Query interaction history
  getRelevantHistory(context: Context): Promise<HistoryEntry[]>;
  
  // Match against known patterns
  matchPatterns(context: Context): Promise<Pattern[]>;
  
  // Compute relevance scores
  scoreRelevance(items: any[], context: Context): ScoredItem[];
}

interface InputAnalysis {
  intent: 'query' | 'command' | 'modify' | 'create' | 'debug';
  entities: Entity[];
  topics: string[];
  confidence: number;
  ambiguities: Ambiguity[];
}

interface Entity {
  type: 'file' | 'function' | 'module' | 'config' | 'dependency';
  name: string;
  path?: string;
  confidence: number;
}

interface ProjectState {
  rootPath: string;
  flakeExists: boolean;
  gitStatus: GitStatus;
  recentChanges: FileChange[];
  buildStatus: BuildStatus;
  activeFiles: string[];
}

interface GitStatus {
  branch: string;
  modified: string[];
  staged: string[];
  untracked: string[];
  commits: Commit[];
}

interface HistoryEntry {
  timestamp: string;
  action: string;
  context: Context;
  outcome: 'success' | 'failure' | 'partial';
  relevance: number;
}

interface Pattern {
  name: string;
  description: string;
  frequency: number;
  lastSeen: string;
  actions: Action[];
}

interface Context {
  input: string;
  projectState: ProjectState;
  history: HistoryEntry[];
  patterns: Pattern[];
  enrichments: Record<string, any>;
}
```

#### Implementation Strategy

**Components**:

1. **InputAnalyzer**: NLP-lite parsing (no external API)
   ```typescript
   class InputAnalyzer {
     // Extract keywords, entities, intent
     analyze(input: string): InputAnalysis {
       const tokens = this.tokenize(input);
       const intent = this.classifyIntent(tokens);
       const entities = this.extractEntities(tokens);
       const topics = this.extractTopics(tokens);
       
       return {
         intent,
         entities,
         topics,
         confidence: this.calculateConfidence(tokens, entities),
         ambiguities: this.detectAmbiguities(entities, tokens)
       };
     }
     
     private classifyIntent(tokens: string[]): Intent {
       // Keyword-based classification
       const commandKeywords = ['run', 'execute', 'build', 'test'];
       const queryKeywords = ['what', 'why', 'how', 'show'];
       const modifyKeywords = ['change', 'update', 'fix', 'refactor'];
       
       // ... classification logic
     }
   }
   ```

2. **ProjectStateTracker**: File system watcher + git integration
   ```typescript
   class ProjectStateTracker {
     private watcher: FSWatcher;
     private stateCache: Map<string, ProjectState>;
     
     async getCurrentState(): Promise<ProjectState> {
       const cached = this.stateCache.get('current');
       if (cached && !this.isStale(cached)) {
         return cached;
       }
       
       const state = await this.buildState();
       this.stateCache.set('current', state);
       return state;
     }
     
     private async buildState(): Promise<ProjectState> {
       return {
         rootPath: process.cwd(),
         flakeExists: await this.checkFile('flake.nix'),
         gitStatus: await this.getGitStatus(),
         recentChanges: await this.getRecentChanges(),
         buildStatus: await this.getBuildStatus(),
         activeFiles: await this.getActiveFiles()
       };
     }
   }
   ```

3. **HistoryManager**: Query Knowledge DB for relevant past interactions
   ```typescript
   class HistoryManager {
     constructor(private db: KnowledgeDatabase) {}
     
     async getRelevantHistory(
       context: Context,
       limit = 10
     ): Promise<HistoryEntry[]> {
       // Build FTS5 query from context
       const query = this.buildQuery(context);
       
       // Search knowledge DB
       const results = await this.db.searchKnowledge({
         query,
         limit,
         entry_type: 'decision'
       });
       
       // Convert to history entries
       return results.map(r => this.toHistoryEntry(r));
     }
     
     private buildQuery(context: Context): string {
       // Combine entities, topics, intent into FTS5 query
       const terms = [
         ...context.entities.map(e => e.name),
         ...context.topics,
         context.intent
       ];
       return terms.join(' OR ');
     }
   }
   ```

4. **PatternMatcher**: Identify recurring workflows
   ```typescript
   class PatternMatcher {
     private patterns: Map<string, Pattern>;
     
     async matchPatterns(context: Context): Promise<Pattern[]> {
       const matches: Pattern[] = [];
       
       for (const pattern of this.patterns.values()) {
         const score = this.scoreMatch(pattern, context);
         if (score > 0.7) {
           matches.push({ ...pattern, relevance: score });
         }
       }
       
       return matches.sort((a, b) => b.relevance - a.relevance);
     }
     
     private scoreMatch(pattern: Pattern, context: Context): number {
       // Compare pattern actions to current context
       let score = 0;
       
       // Entity overlap
       score += this.entityOverlap(pattern, context) * 0.4;
       
       // Intent match
       if (pattern.intent === context.intent) score += 0.3;
       
       // Topic similarity
       score += this.topicSimilarity(pattern, context) * 0.3;
       
       return score;
     }
   }
   ```

5. **RelevanceScorer**: Rank information by relevance
   ```typescript
   class RelevanceScorer {
     scoreRelevance<T extends { context?: Context }>(
       items: T[],
       context: Context
     ): Array<T & { relevance: number }> {
       return items.map(item => ({
         ...item,
         relevance: this.calculateRelevance(item, context)
       })).sort((a, b) => b.relevance - a.relevance);
     }
     
     private calculateRelevance(item: any, context: Context): number {
       let score = 0;
       
       // Recency (decay over time)
       if (item.timestamp) {
         const age = Date.now() - new Date(item.timestamp).getTime();
         score += Math.exp(-age / (7 * 24 * 60 * 60 * 1000)) * 0.3;
       }
       
       // Frequency (how often used)
       if (item.frequency) {
         score += Math.min(item.frequency / 100, 1) * 0.2;
       }
       
       // Context overlap
       score += this.contextOverlap(item, context) * 0.5;
       
       return score;
     }
   }
   ```

#### Data Flow

```
User Input
    ↓
InputAnalyzer → { intent, entities, topics }
    ↓
ProjectStateTracker → { files, git, build status }
    ↓
HistoryManager → { relevant past interactions }
    ↓
PatternMatcher → { recurring workflows }
    ↓
RelevanceScorer → { ranked results }
    ↓
Enriched Context
```

#### Storage Schema

Knowledge DB extensions:
```sql
-- Store inferred patterns
CREATE TABLE patterns (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  frequency INTEGER DEFAULT 1,
  last_seen TEXT DEFAULT (datetime('now')),
  actions TEXT NOT NULL, -- JSON array
  metadata TEXT DEFAULT '{}'
);

-- Store project state snapshots
CREATE TABLE project_states (
  id INTEGER PRIMARY KEY,
  timestamp TEXT DEFAULT (datetime('now')),
  root_path TEXT NOT NULL,
  git_branch TEXT,
  modified_files TEXT, -- JSON array
  build_status TEXT,
  metadata TEXT DEFAULT '{}'
);

-- Index for fast lookups
CREATE INDEX idx_patterns_name ON patterns(name);
CREATE INDEX idx_patterns_last_seen ON patterns(last_seen DESC);
CREATE INDEX idx_project_states_timestamp ON project_states(timestamp DESC);
```

---

### 2.2 Proactive Action Engine

**Purpose**: Execute preparatory actions BEFORE asking user questions.

#### TypeScript Interfaces

```typescript
interface ProactiveActionEngine {
  // Determine what to check before proceeding
  planPreActions(context: Context): Promise<PreAction[]>;
  
  // Execute checks in parallel
  executePreActions(actions: PreAction[]): Promise<PreActionResult[]>;
  
  // Generate informed questions with gathered data
  generateSmartQuestion(
    context: Context,
    results: PreActionResult[]
  ): SmartQuestion;
}

interface PreAction {
  type: 'list_files' | 'check_git' | 'validate_build' | 'analyze_deps';
  description: string;
  timeout: number;
  priority: number;
}

interface PreActionResult {
  action: PreAction;
  success: boolean;
  data: any;
  duration: number;
  error?: string;
}

interface SmartQuestion {
  question: string;
  context: Context;
  suggestions: Suggestion[];
  constraints: Constraint[];
}

interface Suggestion {
  value: string;
  description: string;
  confidence: number;
  rationale: string;
}

interface Constraint {
  type: 'required' | 'recommended' | 'warning';
  message: string;
  blocker: boolean;
}
```

#### Implementation Strategy

**Interceptor Chain Pattern**:

```typescript
class PreActionInterceptor {
  private validators: PreActionValidator[];
  
  async intercept(
    toolName: string,
    args: any,
    context: Context
  ): Promise<EnrichedContext> {
    // Plan what to check
    const preActions = await this.planPreActions(toolName, args, context);
    
    // Execute in parallel with timeout
    const results = await Promise.allSettled(
      preActions.map(action => 
        this.executeWithTimeout(action, action.timeout)
      )
    );
    
    // Aggregate results
    const enrichments = this.aggregateResults(results);
    
    // Return enriched context
    return {
      ...context,
      preActionResults: enrichments,
      readyToExecute: this.checkReadiness(enrichments)
    };
  }
  
  private async planPreActions(
    toolName: string,
    args: any,
    context: Context
  ): Promise<PreAction[]> {
    const actions: PreAction[] = [];
    
    // File-related tools → list relevant files
    if (this.isFileTool(toolName)) {
      actions.push({
        type: 'list_files',
        description: 'Find relevant files',
        timeout: 1000,
        priority: 1
      });
    }
    
    // Build tools → check build status
    if (this.isBuildTool(toolName)) {
      actions.push({
        type: 'validate_build',
        description: 'Check current build status',
        timeout: 2000,
        priority: 2
      });
    }
    
    // Always check git status for safety
    actions.push({
      type: 'check_git',
      description: 'Get git status',
      timeout: 500,
      priority: 1
    });
    
    return actions.sort((a, b) => a.priority - b.priority);
  }
}
```

**Example Pre-Actions**:

1. **Before asking "which file?"**:
   ```typescript
   async preAction_listFiles(args: any): Promise<FileList> {
     const { pattern, directory } = args;
     
     // List files matching pattern
     const files = await fs.readdir(directory);
     const matching = files.filter(f => 
       f.includes(pattern) || minimatch(f, pattern)
     );
     
     // Get metadata
     const withMetadata = await Promise.all(
       matching.map(async f => ({
         path: f,
         size: (await fs.stat(f)).size,
         modified: (await fs.stat(f)).mtime,
         gitStatus: await this.getGitStatus(f)
       }))
     );
     
     return {
       files: withMetadata,
       count: withMetadata.length,
       suggestion: this.suggestMostLikely(withMetadata, args)
     };
   }
   ```

2. **Before planning changes**:
   ```typescript
   async preAction_validatePreconditions(
     context: Context
   ): Promise<Validation> {
     // Check build status
     const buildOk = await this.checkBuild();
     
     // Analyze dependencies
     const deps = await this.analyzeDependencies(context.entities);
     
     // Find conflicts
     const conflicts = await this.findConflicts(deps);
     
     return {
       canProceed: buildOk && conflicts.breaking.length === 0,
       warnings: [...conflicts.warnings, ...deps.warnings],
       blockers: conflicts.breaking,
       suggestions: this.generateSuggestions(conflicts)
     };
   }
   ```

3. **Before error diagnosis**:
   ```typescript
   async preAction_collectDiagnostics(
     error: Error
   ): Promise<Diagnostics> {
     // Collect logs automatically
     const logs = await this.collectLogs();
     
     // Get git diff
     const diff = await this.getGitDiff();
     
     // Check recent changes
     const recentChanges = await this.getRecentChanges();
     
     // Analyze error pattern
     const similar = await this.findSimilarErrors(error);
     
     return {
       logs,
       diff,
       recentChanges,
       similarErrors: similar,
       hypothesis: this.generateHypothesis(error, similar)
     };
   }
   ```

#### Parallel Execution

```typescript
class ParallelExecutor {
  async executeAll(
    actions: PreAction[],
    timeout = 2000
  ): Promise<PreActionResult[]> {
    const startTime = Date.now();
    
    // Execute with individual timeouts
    const promises = actions.map(async action => {
      try {
        const result = await this.executeWithTimeout(
          action,
          Math.min(action.timeout, timeout)
        );
        return {
          action,
          success: true,
          data: result,
          duration: Date.now() - startTime
        };
      } catch (error: any) {
        return {
          action,
          success: false,
          data: null,
          duration: Date.now() - startTime,
          error: error.message
        };
      }
    });
    
    // Wait for all with global timeout
    const results = await Promise.race([
      Promise.allSettled(promises),
      this.timeoutPromise(timeout)
    ]);
    
    return this.unwrapResults(results);
  }
  
  private async executeWithTimeout<T>(
    action: PreAction,
    timeout: number
  ): Promise<T> {
    return Promise.race([
      this.execute(action),
      this.timeoutPromise(timeout)
    ]);
  }
}
```

#### Graceful Degradation

```typescript
class GracefulDegrader {
  async handleFailure(
    action: PreAction,
    error: Error
  ): Promise<FallbackResult> {
    console.warn(`Pre-action ${action.type} failed: ${error.message}`);
    
    // Log failure but don't block
    await this.logFailure(action, error);
    
    // Return safe default
    switch (action.type) {
      case 'list_files':
        return { files: [], suggestion: 'Ask user for file path' };
      case 'check_git':
        return { status: 'unknown', warning: 'Git unavailable' };
      case 'validate_build':
        return { status: 'unknown', warning: 'Build check skipped' };
      default:
        return { data: null, warning: 'Check failed, proceeding anyway' };
    }
  }
}
```

---

### 2.3 Multi-Step Planner

**Purpose**: Automatically decompose complex tasks into atomic steps with dependencies.

#### TypeScript Interfaces

```typescript
interface MultiStepPlanner {
  // Decompose task into steps
  decompose(task: Task): Promise<ExecutionPlan>;
  
  // Build dependency graph
  buildDependencyGraph(steps: Step[]): DependencyGraph;
  
  // Find execution order
  topologicalSort(graph: DependencyGraph): Step[];
  
  // Execute plan
  execute(plan: ExecutionPlan): Promise<ExecutionResult>;
  
  // Save checkpoint
  checkpoint(state: ExecutionState): Promise<void>;
  
  // Resume from checkpoint
  resume(checkpointId: string): Promise<ExecutionResult>;
}

interface Task {
  description: string;
  context: Context;
  constraints: Constraint[];
}

interface Step {
  id: string;
  description: string;
  action: Action;
  preconditions: Condition[];
  postconditions: Condition[];
  estimatedDuration: number;
  retryable: boolean;
}

interface ExecutionPlan {
  id: string;
  task: Task;
  steps: Step[];
  dependencyGraph: DependencyGraph;
  executionOrder: Step[];
  parallelizable: Step[][];
  estimatedDuration: number;
}

interface DependencyGraph {
  nodes: Map<string, Step>;
  edges: Map<string, string[]>; // stepId -> [dependentStepIds]
}

interface ExecutionState {
  planId: string;
  completed: string[];
  current: string | null;
  pending: string[];
  failed: string[];
  checkpoints: Checkpoint[];
}

interface Checkpoint {
  id: string;
  timestamp: string;
  stepId: string;
  state: any;
}

interface ExecutionResult {
  planId: string;
  success: boolean;
  completedSteps: Step[];
  failedSteps: Step[];
  duration: number;
  checkpoints: Checkpoint[];
}
```

#### Implementation Strategy

**Task Decomposition Heuristics**:

```typescript
class TaskDecomposer {
  async decompose(task: Task): Promise<Step[]> {
    const steps: Step[] = [];
    
    // Analyze task description
    const analysis = await this.analyzeTask(task);
    
    // Apply decomposition rules
    if (analysis.type === 'build') {
      steps.push(...this.decomposeBuildTask(task));
    } else if (analysis.type === 'refactor') {
      steps.push(...this.decomposeRefactorTask(task));
    } else if (analysis.type === 'debug') {
      steps.push(...this.decomposeDebugTask(task));
    } else {
      steps.push(...this.decomposeGenericTask(task));
    }
    
    // Add validation steps
    steps.push(...this.addValidationSteps(steps));
    
    return steps;
  }
  
  private decomposeBuildTask(task: Task): Step[] {
    return [
      {
        id: 'check-dependencies',
        description: 'Verify all dependencies are available',
        action: { type: 'validate', target: 'dependencies' },
        preconditions: [],
        postconditions: [{ type: 'dependencies_valid', value: true }],
        estimatedDuration: 2000,
        retryable: true
      },
      {
        id: 'clean-build',
        description: 'Clean previous build artifacts',
        action: { type: 'execute', command: 'nix build --rebuild' },
        preconditions: [{ type: 'dependencies_valid', value: true }],
        postconditions: [{ type: 'build_clean', value: true }],
        estimatedDuration: 5000,
        retryable: true
      },
      {
        id: 'run-build',
        description: 'Execute build',
        action: { type: 'execute', command: 'nix build' },
        preconditions: [{ type: 'build_clean', value: true }],
        postconditions: [{ type: 'build_success', value: true }],
        estimatedDuration: 30000,
        retryable: true
      },
      {
        id: 'verify-output',
        description: 'Verify build output',
        action: { type: 'validate', target: 'build-output' },
        preconditions: [{ type: 'build_success', value: true }],
        postconditions: [{ type: 'output_valid', value: true }],
        estimatedDuration: 1000,
        retryable: false
      }
    ];
  }
}
```

**Dependency Graph Builder**:

```typescript
class DependencyGraphBuilder {
  buildGraph(steps: Step[]): DependencyGraph {
    const nodes = new Map(steps.map(s => [s.id, s]));
    const edges = new Map<string, string[]>();
    
    // Build edges from preconditions/postconditions
    for (const step of steps) {
      const dependencies: string[] = [];
      
      for (const precond of step.preconditions) {
        // Find steps that produce this postcondition
        const providers = steps.filter(s =>
          s.postconditions.some(post =>
            post.type === precond.type && post.value === precond.value
          )
        );
        
        dependencies.push(...providers.map(p => p.id));
      }
      
      edges.set(step.id, dependencies);
    }
    
    return { nodes, edges };
  }
  
  topologicalSort(graph: DependencyGraph): Step[] {
    const sorted: Step[] = [];
    const visited = new Set<string>();
    const visiting = new Set<string>();
    
    const visit = (nodeId: string) => {
      if (visited.has(nodeId)) return;
      if (visiting.has(nodeId)) {
        throw new Error(`Circular dependency detected at ${nodeId}`);
      }
      
      visiting.add(nodeId);
      
      const deps = graph.edges.get(nodeId) || [];
      for (const dep of deps) {
        visit(dep);
      }
      
      visiting.delete(nodeId);
      visited.add(nodeId);
      sorted.push(graph.nodes.get(nodeId)!);
    };
    
    for (const nodeId of graph.nodes.keys()) {
      visit(nodeId);
    }
    
    return sorted;
  }
  
  findParallelizable(
    graph: DependencyGraph,
    order: Step[]
  ): Step[][] {
    const levels: Step[][] = [];
    const completed = new Set<string>();
    
    while (completed.size < order.length) {
      const level: Step[] = [];
      
      for (const step of order) {
        if (completed.has(step.id)) continue;
        
        // Check if all dependencies completed
        const deps = graph.edges.get(step.id) || [];
        const allDepsComplete = deps.every(d => completed.has(d));
        
        if (allDepsComplete) {
          level.push(step);
        }
      }
      
      if (level.length === 0) break;
      
      levels.push(level);
      level.forEach(s => completed.add(s.id));
    }
    
    return levels;
  }
}
```

**Execution Orchestrator**:

```typescript
class ExecutionOrchestrator {
  async execute(plan: ExecutionPlan): Promise<ExecutionResult> {
    const state: ExecutionState = {
      planId: plan.id,
      completed: [],
      current: null,
      pending: plan.executionOrder.map(s => s.id),
      failed: [],
      checkpoints: []
    };
    
    // Execute levels in parallel
    for (const level of plan.parallelizable) {
      const results = await Promise.allSettled(
        level.map(step => this.executeStep(step, state))
      );
      
      // Process results
      results.forEach((result, i) => {
        const step = level[i];
        if (result.status === 'fulfilled' && result.value.success) {
          state.completed.push(step.id);
          state.pending = state.pending.filter(id => id !== step.id);
        } else {
          state.failed.push(step.id);
          
          // Abort if non-retryable
          if (!step.retryable) {
            throw new Error(`Critical step failed: ${step.id}`);
          }
        }
      });
      
      // Checkpoint after each level
      await this.checkpoint(state);
    }
    
    return this.buildResult(plan, state);
  }
  
  private async executeStep(
    step: Step,
    state: ExecutionState
  ): Promise<StepResult> {
    state.current = step.id;
    
    try {
      // Validate preconditions
      await this.validatePreconditions(step, state);
      
      // Execute action
      const result = await this.executeAction(step.action);
      
      // Validate postconditions
      await this.validatePostconditions(step, result);
      
      return { success: true, result };
    } catch (error: any) {
      // Retry if allowed
      if (step.retryable) {
        return await this.retryStep(step, state, error);
      }
      
      throw error;
    }
  }
  
  private async checkpoint(state: ExecutionState): Promise<void> {
    const checkpoint: Checkpoint = {
      id: `ckpt_${Date.now()}`,
      timestamp: new Date().toISOString(),
      stepId: state.current || 'none',
      state: JSON.parse(JSON.stringify(state))
    };
    
    state.checkpoints.push(checkpoint);
    
    // Persist to Knowledge DB
    await this.db.saveKnowledge({
      type: 'decision',
      content: JSON.stringify(checkpoint),
      tags: ['checkpoint', 'execution'],
      priority: 'high'
    });
  }
  
  async resume(checkpointId: string): Promise<ExecutionResult> {
    // Load checkpoint from DB
    const checkpoint = await this.loadCheckpoint(checkpointId);
    const state = checkpoint.state;
    
    // Rebuild plan
    const plan = await this.rebuildPlan(state);
    
    // Continue execution from pending steps
    return await this.execute(plan);
  }
}
```

---

### 2.4 Causal Reasoning Engine

**Purpose**: Build and maintain dependency graphs to predict change impacts.

#### TypeScript Interfaces

```typescript
interface CausalReasoningEngine {
  // Build project dependency graph
  buildDependencyGraph(projectPath: string): Promise<DependencyGraph>;
  
  // Analyze cause-effect relationships
  analyzeCausality(change: Change): Promise<CausalAnalysis>;
  
  // Predict impact of changes
  predictImpact(changes: Change[]): Promise<ImpactPrediction>;
  
  // Detect constraint violations
  detectConflicts(changes: Change[]): Promise<Conflict[]>;
  
  // Suggest mitigations
  suggestMitigations(conflicts: Conflict[]): Promise<Mitigation[]>;
}

interface DependencyGraph {
  nodes: Map<string, Node>;
  edges: Map<string, Edge[]>;
  metadata: GraphMetadata;
}

interface Node {
  id: string;
  type: 'file' | 'module' | 'function' | 'config' | 'service';
  path: string;
  metadata: NodeMetadata;
}

interface Edge {
  from: string;
  to: string;
  type: 'import' | 'reference' | 'calls' | 'configures' | 'depends';
  strength: number; // 0-1
  metadata: EdgeMetadata;
}

interface Change {
  target: Node;
  changeType: 'add' | 'modify' | 'delete';
  details: any;
}

interface CausalAnalysis {
  directEffects: Effect[];
  transitiveEffects: Effect[];
  confidence: number;
}

interface Effect {
  node: Node;
  impactType: 'breaks' | 'affects' | 'improves';
  severity: number; // 0-1
  reason: string;
}

interface ImpactPrediction {
  affectedNodes: Node[];
  breakingChanges: Effect[];
  warnings: Warning[];
  estimatedRisk: number; // 0-1
}

interface Conflict {
  type: 'breaking' | 'warning' | 'info';
  nodes: Node[];
  description: string;
  severity: number;
}

interface Mitigation {
  conflict: Conflict;
  strategy: string;
  steps: Step[];
  estimatedCost: number;
}
```

#### Implementation Strategy

**Graph Builder**:

```typescript
class DependencyGraphBuilder {
  async buildGraph(projectPath: string): Promise<DependencyGraph> {
    const graph: DependencyGraph = {
      nodes: new Map(),
      edges: new Map(),
      metadata: {
        buildTime: Date.now(),
        projectPath,
        version: '1.0.0'
      }
    };
    
    // Scan project files
    const files = await this.scanProject(projectPath);
    
    // Build nodes
    for (const file of files) {
      const node = await this.analyzeFile(file);
      graph.nodes.set(node.id, node);
    }
    
    // Build edges
    for (const node of graph.nodes.values()) {
      const edges = await this.findDependencies(node);
      graph.edges.set(node.id, edges);
    }
    
    // Calculate edge strengths
    await this.calculateEdgeStrengths(graph);
    
    return graph;
  }
  
  private async analyzeFile(filePath: string): Promise<Node> {
    const content = await fs.readFile(filePath, 'utf-8');
    const ext = path.extname(filePath);
    
    // Parse based on file type
    if (ext === '.nix') {
      return this.analyzeNixFile(filePath, content);
    } else if (ext === '.ts' || ext === '.js') {
      return this.analyzeJSFile(filePath, content);
    } else {
      return this.analyzeGenericFile(filePath, content);
    }
  }
  
  private async findDependencies(node: Node): Promise<Edge[]> {
    const edges: Edge[] = [];
    
    if (node.type === 'file') {
      // Find imports
      const imports = await this.findImports(node);
      edges.push(...imports.map(i => ({
        from: node.id,
        to: i.target,
        type: 'import' as const,
        strength: 0.9,
        metadata: { line: i.line }
      })));
      
      // Find references
      const refs = await this.findReferences(node);
      edges.push(...refs.map(r => ({
        from: node.id,
        to: r.target,
        type: 'reference' as const,
        strength: 0.6,
        metadata: { line: r.line }
      })));
    }
    
    return edges;
  }
  
  private async calculateEdgeStrengths(graph: DependencyGraph): Promise<void> {
    // Use PageRank-style algorithm to determine importance
    const scores = new Map<string, number>();
    
    // Initialize
    for (const nodeId of graph.nodes.keys()) {
      scores.set(nodeId, 1.0);
    }
    
    // Iterate
    for (let i = 0; i < 10; i++) {
      const newScores = new Map<string, number>();
      
      for (const [nodeId, edges] of graph.edges) {
        const incomingScore = edges.reduce((sum, edge) => {
          const sourceScore = scores.get(edge.from) || 0;
          return sum + sourceScore * edge.strength;
        }, 0);
        
        newScores.set(nodeId, 0.15 + 0.85 * incomingScore);
      }
      
      scores.clear();
      newScores.forEach((score, id) => scores.set(id, score));
    }
    
    // Update edge strengths based on node importance
    for (const edges of graph.edges.values()) {
      for (const edge of edges) {
        const targetScore = scores.get(edge.to) || 0;
        edge.strength *= targetScore;
      }
    }
  }
}
```

**Impact Predictor**:

```typescript
class ImpactPredictor {
  async predictImpact(
    changes: Change[],
    graph: DependencyGraph
  ): Promise<ImpactPrediction> {
    const affectedNodes = new Set<Node>();
    const breakingChanges: Effect[] = [];
    const warnings: Warning[] = [];
    
    // For each change, traverse graph
    for (const change of changes) {
      const effects = await this.traverseImpact(change, graph);
      
      effects.forEach(effect => {
        affectedNodes.add(effect.node);
        
        if (effect.impactType === 'breaks') {
          breakingChanges.push(effect);
        } else if (effect.impactType === 'affects') {
          warnings.push({
            node: effect.node,
            message: effect.reason,
            severity: effect.severity
          });
        }
      });
    }
    
    // Estimate risk
    const risk = this.calculateRisk(breakingChanges, warnings, affectedNodes);
    
    return {
      affectedNodes: Array.from(affectedNodes),
      breakingChanges,
      warnings,
      estimatedRisk: risk
    };
  }
  
  private async traverseImpact(
    change: Change,
    graph: DependencyGraph,
    visited = new Set<string>()
  ): Promise<Effect[]> {
    if (visited.has(change.target.id)) return [];
    visited.add(change.target.id);
    
    const effects: Effect[] = [];
    const edges = graph.edges.get(change.target.id) || [];
    
    // Check direct dependents
    const dependents = edges.filter(e => e.type === 'import' || e.type === 'reference');
    
    for (const edge of dependents) {
      const dependent = graph.nodes.get(edge.to);
      if (!dependent) continue;
      
      // Determine impact type
      const impactType = this.determineImpact(change, edge, dependent);
      
      effects.push({
        node: dependent,
        impactType,
        severity: edge.strength,
        reason: this.explainImpact(change, edge, dependent)
      });
      
      // Traverse transitively (with decay)
      if (edge.strength > 0.3) {
        const transitiveEffects = await this.traverseImpact(
          { ...change, target: dependent },
          graph,
          visited
        );
        effects.push(...transitiveEffects.map(e => ({
          ...e,
          severity: e.severity * 0.7 // Decay
        })));
      }
    }
    
    return effects;
  }
  
  private determineImpact(
    change: Change,
    edge: Edge,
    dependent: Node
  ): Effect['impactType'] {
    if (change.changeType === 'delete') {
      return 'breaks';
    }
    
    if (change.changeType === 'modify') {
      // Check if public API changed
      if (this.isPublicAPIChange(change)) {
        return edge.type === 'import' ? 'breaks' : 'affects';
      }
      return 'affects';
    }
    
    return 'improves';
  }
  
  private calculateRisk(
    breaking: Effect[],
    warnings: Warning[],
    affected: Set<Node>
  ): number {
    const breakingWeight = breaking.reduce((sum, e) => sum + e.severity, 0);
    const warningWeight = warnings.reduce((sum, w) => sum + w.severity * 0.5, 0);
    const affectedWeight = affected.size * 0.1;
    
    return Math.min(1.0, (breakingWeight + warningWeight + affectedWeight) / 10);
  }
}
```

**Conflict Detector**:

```typescript
class ConflictDetector {
  async detectConflicts(
    changes: Change[],
    graph: DependencyGraph
  ): Promise<Conflict[]> {
    const conflicts: Conflict[] = [];
    
    // Check for direct conflicts
    conflicts.push(...this.findDirectConflicts(changes));
    
    // Check for dependency conflicts
    conflicts.push(...await this.findDependencyConflicts(changes, graph));
    
    // Check for constraint violations
    conflicts.push(...await this.findConstraintViolations(changes, graph));
    
    return conflicts.sort((a, b) => b.severity - a.severity);
  }
  
  private findDirectConflicts(changes: Change[]): Conflict[] {
    const conflicts: Conflict[] = [];
    const targets = new Map<string, Change[]>();
    
    // Group changes by target
    for (const change of changes) {
      const existing = targets.get(change.target.id) || [];
      existing.push(change);
      targets.set(change.target.id, existing);
    }
    
    // Find conflicting changes to same target
    for (const [targetId, targetChanges] of targets) {
      if (targetChanges.length > 1) {
        conflicts.push({
          type: 'breaking',
          nodes: targetChanges.map(c => c.target),
          description: `Multiple conflicting changes to ${targetId}`,
          severity: 0.9
        });
      }
    }
    
    return conflicts;
  }
  
  private async findDependencyConflicts(
    changes: Change[],
    graph: DependencyGraph
  ): Promise<Conflict[]> {
    const conflicts: Conflict[] = [];
    
    // For each delete, check if other changes depend on it
    const deletes = changes.filter(c => c.changeType === 'delete');
    const others = changes.filter(c => c.changeType !== 'delete');
    
    for (const del of deletes) {
      for (const other of others) {
        const depends = await this.checkDependency(other.target, del.target, graph);
        if (depends) {
          conflicts.push({
            type: 'breaking',
            nodes: [other.target, del.target],
            description: `${other.target.path} depends on ${del.target.path} which is being deleted`,
            severity: 1.0
          });
        }
      }
    }
    
    return conflicts;
  }
}
```

**Mitigation Suggester**:

```typescript
class MitigationSuggester {
  async suggestMitigations(conflicts: Conflict[]): Promise<Mitigation[]> {
    const mitigations: Mitigation[] = [];
    
    for (const conflict of conflicts) {
      if (conflict.type === 'breaking') {
        mitigations.push(...this.suggestForBreaking(conflict));
      } else {
        mitigations.push(...this.suggestForWarning(conflict));
      }
    }
    
    return mitigations.sort((a, b) => a.estimatedCost - b.estimatedCost);
  }
  
  private suggestForBreaking(conflict: Conflict): Mitigation[] {
    const mitigations: Mitigation[] = [];
    
    if (conflict.description.includes('deleted')) {
      mitigations.push({
        conflict,
        strategy: 'Deprecate instead of delete',
        steps: [
          { description: 'Mark as deprecated', action: 'annotate' },
          { description: 'Update documentation', action: 'docs' },
          { description: 'Schedule removal', action: 'schedule' }
        ],
        estimatedCost: 3
      });
      
      mitigations.push({
        conflict,
        strategy: 'Update dependents first',
        steps: [
          { description: 'Find all dependents', action: 'search' },
          { description: 'Update each dependent', action: 'refactor' },
          { description: 'Verify no breakage', action: 'test' },
          { description: 'Delete target', action: 'delete' }
        ],
        estimatedCost: 8
      });
    }
    
    return mitigations;
  }
}
```

---

### 2.5 Adaptive Learning System

**Purpose**: Learn from interactions to optimize future predictions and strategies.

#### TypeScript Interfaces

```typescript
interface AdaptiveLearningSystem {
  // Record action outcome
  recordFeedback(feedback: Feedback): Promise<void>;
  
  // Track performance metrics
  trackMetrics(metrics: PerformanceMetrics): Promise<void>;
  
  // Optimize strategy selection
  optimizeStrategy(context: Context): Promise<Strategy>;
  
  // Learn user preferences
  learnPreferences(interaction: Interaction): Promise<void>;
  
  // Generate periodic insights
  generateInsights(): Promise<Insight[]>;
}

interface Feedback {
  actionId: string;
  outcome: 'success' | 'failure' | 'partial';
  userRating?: number; // 1-5
  explicit?: boolean;
  context: Context;
  timestamp: string;
}

interface PerformanceMetrics {
  actionType: string;
  duration: number;
  retries: number;
  success: boolean;
  context: Context;
}

interface Strategy {
  name: string;
  approach: string;
  confidence: number;
  rationale: string;
  alternatives: Strategy[];
}

interface Interaction {
  type: string;
  context: Context;
  userChoice: any;
  alternatives: any[];
  timestamp: string;
}

interface Insight {
  category: 'pattern' | 'optimization' | 'warning';
  description: string;
  confidence: number;
  actionable: boolean;
  recommendation?: string;
}

interface LearningModel {
  // Pattern frequencies
  patterns: Map<string, PatternStats>;
  
  // Strategy success rates
  strategies: Map<string, StrategyStats>;
  
  // User preferences
  preferences: UserPreferences;
  
  // Performance baselines
  baselines: Map<string, Baseline>;
}

interface PatternStats {
  pattern: string;
  frequency: number;
  lastSeen: string;
  successRate: number;
  avgDuration: number;
}

interface StrategyStats {
  strategy: string;
  timesUsed: number;
  successRate: number;
  avgConfidence: number;
  contexts: string[];
}

interface UserPreferences {
  preferredTools: Map<string, number>;
  avoidedPatterns: string[];
  responseStyle: 'verbose' | 'concise';
  riskTolerance: 'low' | 'medium' | 'high';
}

interface Baseline {
  metric: string;
  value: number;
  stdDev: number;
  samples: number;
}
```

#### Implementation Strategy

**Feedback Collector**:

```typescript
class FeedbackCollector {
  constructor(private db: KnowledgeDatabase) {}
  
  async recordFeedback(feedback: Feedback): Promise<void> {
    // Store in Knowledge DB
    await this.db.saveKnowledge({
      type: 'insight',
      content: JSON.stringify(feedback),
      tags: ['feedback', feedback.outcome, feedback.actionId],
      priority: feedback.outcome === 'failure' ? 'high' : 'medium',
      metadata: {
        explicit: feedback.explicit || false,
        rating: feedback.userRating
      }
    });
    
    // Update learning model
    await this.updateModel(feedback);
  }
  
  async collectImplicitFeedback(
    action: Action,
    result: ActionResult
  ): Promise<Feedback> {
    // Infer feedback from result
    const outcome = result.success ? 'success' : 
                    result.partial ? 'partial' : 
                    'failure';
    
    const feedback: Feedback = {
      actionId: action.id,
      outcome,
      explicit: false,
      context: result.context,
      timestamp: new Date().toISOString()
    };
    
    // Add retry count as signal
    if (result.retries > 0) {
      feedback.userRating = Math.max(1, 5 - result.retries);
    }
    
    await this.recordFeedback(feedback);
    return feedback;
  }
  
  private async updateModel(feedback: Feedback): Promise<void> {
    // Update pattern statistics
    const pattern = this.identifyPattern(feedback.context);
    if (pattern) {
      await this.updatePatternStats(pattern, feedback);
    }
    
    // Update strategy statistics
    const strategy = feedback.context.strategy;
    if (strategy) {
      await this.updateStrategyStats(strategy, feedback);
    }
  }
}
```

**Performance Tracker**:

```typescript
class PerformanceTracker {
  private metrics: Map<string, PerformanceMetrics[]> = new Map();
  
  async trackMetrics(metrics: PerformanceMetrics): Promise<void> {
    const key = metrics.actionType;
    const existing = this.metrics.get(key) || [];
    existing.push(metrics);
    
    // Keep only recent metrics (last 100)
    if (existing.length > 100) {
      existing.shift();
    }
    
    this.metrics.set(key, existing);
    
    // Compute baseline
    await this.updateBaseline(key, existing);
    
    // Check for anomalies
    await this.checkAnomalies(metrics, existing);
  }
  
  private async updateBaseline(
    actionType: string,
    metrics: PerformanceMetrics[]
  ): Promise<void> {
    const durations = metrics.map(m => m.duration);
    const mean = durations.reduce((a, b) => a + b, 0) / durations.length;
    const variance = durations.reduce((sum, d) => 
      sum + Math.pow(d - mean, 2), 0) / durations.length;
    const stdDev = Math.sqrt(variance);
    
    const baseline: Baseline = {
      metric: `${actionType}_duration`,
      value: mean,
      stdDev,
      samples: metrics.length
    };
    
    await this.storeBaseline(baseline);
  }
  
  private async checkAnomalies(
    current: PerformanceMetrics,
    history: PerformanceMetrics[]
  ): Promise<void> {
    const mean = history.reduce((sum, m) => sum + m.duration, 0) / history.length;
    const stdDev = Math.sqrt(
      history.reduce((sum, m) => sum + Math.pow(m.duration - mean, 2), 0) / history.length
    );
    
    // Check if current is > 3 standard deviations from mean
    if (Math.abs(current.duration - mean) > 3 * stdDev) {
      await this.recordAnomaly({
        type: 'performance',
        metric: `${current.actionType}_duration`,
        expected: mean,
        actual: current.duration,
        severity: 'high'
      });
    }
  }
}
```

**Strategy Optimizer**:

```typescript
class StrategyOptimizer {
  private model: LearningModel;
  
  async optimizeStrategy(context: Context): Promise<Strategy> {
    // Get candidate strategies
    const candidates = await this.getCandidateStrategies(context);
    
    // Score each strategy
    const scored = candidates.map(s => ({
      strategy: s,
      score: this.scoreStrategy(s, context)
    }));
    
    // Select best strategy
    scored.sort((a, b) => b.score - a.score);
    const best = scored[0];
    
    return {
      name: best.strategy.name,
      approach: best.strategy.approach,
      confidence: best.score,
      rationale: this.explainChoice(best.strategy, context),
      alternatives: scored.slice(1, 3).map(s => s.strategy)
    };
  }
  
  private scoreStrategy(strategy: Strategy, context: Context): number {
    let score = 0;
    
    // Historical success rate (40%)
    const stats = this.model.strategies.get(strategy.name);
    if (stats) {
      score += stats.successRate * 0.4;
    }
    
    // Context similarity (30%)
    score += this.contextSimilarity(strategy, context) * 0.3;
    
    // User preference (20%)
    score += this.preferenceMatch(strategy, context) * 0.2;
    
    // Recency (10%)
    if (stats) {
      const daysSinceUse = this.daysSince(stats.lastUsed);
      score += Math.exp(-daysSinceUse / 30) * 0.1;
    }
    
    return score;
  }
  
  private contextSimilarity(strategy: Strategy, context: Context): number {
    const stats = this.model.strategies.get(strategy.name);
    if (!stats) return 0;
    
    // Compare context features
    const features = this.extractFeatures(context);
    const overlap = stats.contexts.filter(c => 
      features.some(f => c.includes(f))
    ).length;
    
    return overlap / Math.max(stats.contexts.length, features.length);
  }
}
```

**Preference Learner**:

```typescript
class PreferenceLearner {
  private preferences: UserPreferences = {
    preferredTools: new Map(),
    avoidedPatterns: [],
    responseStyle: 'concise',
    riskTolerance: 'medium'
  };
  
  async learnPreferences(interaction: Interaction): Promise<void> {
    // Track tool usage
    const tool = interaction.type;
    const count = this.preferences.preferredTools.get(tool) || 0;
    this.preferences.preferredTools.set(tool, count + 1);
    
    // Learn from choices
    if (interaction.alternatives.length > 0) {
      const chosen = interaction.userChoice;
      const notChosen = interaction.alternatives.filter(a => a !== chosen);
      
      // If consistently avoiding certain patterns
      for (const alt of notChosen) {
        await this.trackAvoidance(alt);
      }
    }
    
    // Infer response style
    await this.inferResponseStyle(interaction);
    
    // Infer risk tolerance
    await this.inferRiskTolerance(interaction);
    
    // Persist preferences
    await this.persistPreferences();
  }
  
  private async trackAvoidance(alternative: any): Promise<void> {
    const pattern = this.identifyPattern(alternative);
    if (!pattern) return;
    
    const avoidCount = this.avoidanceCounts.get(pattern) || 0;
    this.avoidanceCounts.set(pattern, avoidCount + 1);
    
    // If avoided 3+ times, add to avoided patterns
    if (avoidCount >= 3 && !this.preferences.avoidedPatterns.includes(pattern)) {
      this.preferences.avoidedPatterns.push(pattern);
    }
  }
  
  private async inferResponseStyle(interaction: Interaction): Promise<void> {
    // Analyze user's question patterns
    if (interaction.context.input.length > 100) {
      // User writes detailed questions → prefer verbose responses
      this.styleVotes.verbose++;
    } else if (interaction.context.input.split(' ').length < 5) {
      // User writes terse questions → prefer concise responses
      this.styleVotes.concise++;
    }
    
    // Update preference if clear pattern emerges
    if (this.styleVotes.verbose > this.styleVotes.concise * 2) {
      this.preferences.responseStyle = 'verbose';
    } else if (this.styleVotes.concise > this.styleVotes.verbose * 2) {
      this.preferences.responseStyle = 'concise';
    }
  }
  
  private async inferRiskTolerance(interaction: Interaction): Promise<void> {
    // Check if user approved risky operations
    const risk = this.assessRisk(interaction);
    
    if (risk > 0.7 && interaction.userChoice === 'proceed') {
      this.riskVotes.high++;
    } else if (risk > 0.3 && interaction.userChoice === 'proceed') {
      this.riskVotes.medium++;
    } else if (risk > 0.1 && interaction.userChoice === 'cancel') {
      this.riskVotes.low++;
    }
    
    // Update tolerance
    const total = this.riskVotes.low + this.riskVotes.medium + this.riskVotes.high;
    if (total >= 5) {
      const high = this.riskVotes.high / total;
      const low = this.riskVotes.low / total;
      
      if (high > 0.6) {
        this.preferences.riskTolerance = 'high';
      } else if (low > 0.6) {
        this.preferences.riskTolerance = 'low';
      } else {
        this.preferences.riskTolerance = 'medium';
      }
    }
  }
}
```

**Insight Generator**:

```typescript
class InsightGenerator {
  async generateInsights(): Promise<Insight[]> {
    const insights: Insight[] = [];
    
    // Pattern insights
    insights.push(...await this.analyzePatterns());
    
    // Performance insights
    insights.push(...await this.analyzePerformance());
    
    // Strategy insights
    insights.push(...await this.analyzeStrategies());
    
    // Anomaly insights
    insights.push(...await this.analyzeAnomalies());
    
    return insights.sort((a, b) => b.confidence - a.confidence);
  }
  
  private async analyzePatterns(): Promise<Insight[]> {
    const insights: Insight[] = [];
    const patterns = await this.getFrequentPatterns();
    
    for (const pattern of patterns) {
      if (pattern.frequency > 10 && pattern.successRate < 0.5) {
        insights.push({
          category: 'warning',
          description