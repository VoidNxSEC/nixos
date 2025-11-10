/**
 * Dependency Resolver
 *
 * Resolves step dependencies and determines execution order
 * using topological sorting.
 */
import type { TaskStep } from '../../types/planning.js';
/**
 * Dependency Resolver
 */
export declare class DependencyResolver {
    /**
     * Resolve execution order using topological sort
     */
    resolveOrder(steps: TaskStep[]): TaskStep[];
    /**
     * Find steps that can execute in parallel
     */
    findParallelGroups(steps: TaskStep[]): TaskStep[][];
    /**
     * Detect circular dependencies
     */
    hasCircularDependencies(steps: TaskStep[]): boolean;
    /**
     * Build dependency graph (adjacency list)
     */
    private buildDependencyGraph;
    /**
     * Topological sort using DFS
     */
    private topologicalSort;
}
//# sourceMappingURL=dependency-resolver.d.ts.map