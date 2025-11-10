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
export class DependencyResolver {
  /**
   * Resolve execution order using topological sort
   */
  public resolveOrder(steps: TaskStep[]): TaskStep[] {
    const graph = this.buildDependencyGraph(steps);
    const sorted = this.topologicalSort(graph);
    
    return sorted.map(id => steps.find(s => s.id === id)!);
  }

  /**
   * Find steps that can execute in parallel
   */
  public findParallelGroups(steps: TaskStep[]): TaskStep[][] {
    const groups: TaskStep[][] = [];
    const completed = new Set<string>();
    const remaining = [...steps];

    while (remaining.length > 0) {
      // Find steps with all dependencies completed
      const ready = remaining.filter(step => 
        step.dependencies.every(dep => completed.has(dep))
      );

      if (ready.length === 0) {
        // Circular dependency or blocked
        break;
      }

      groups.push(ready);
      
      // Mark as completed
      ready.forEach(step => {
        completed.add(step.id);
        const index = remaining.indexOf(step);
        remaining.splice(index, 1);
      });
    }

    return groups;
  }

  /**
   * Detect circular dependencies
   */
  public hasCircularDependencies(steps: TaskStep[]): boolean {
    const graph = this.buildDependencyGraph(steps);
    const visited = new Set<string>();
    const recursionStack = new Set<string>();

    const hasCycle = (node: string): boolean => {
      visited.add(node);
      recursionStack.add(node);

      const neighbors = graph.get(node) || [];
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          if (hasCycle(neighbor)) return true;
        } else if (recursionStack.has(neighbor)) {
          return true;
        }
      }

      recursionStack.delete(node);
      return false;
    };

    for (const node of graph.keys()) {
      if (!visited.has(node)) {
        if (hasCycle(node)) return true;
      }
    }

    return false;
  }

  /**
   * Build dependency graph (adjacency list)
   */
  private buildDependencyGraph(steps: TaskStep[]): Map<string, string[]> {
    const graph = new Map<string, string[]>();

    for (const step of steps) {
      if (!graph.has(step.id)) {
        graph.set(step.id, []);
      }
      
      for (const dep of step.dependencies) {
        if (!graph.has(dep)) {
          graph.set(dep, []);
        }
        graph.get(dep)!.push(step.id);
      }
    }

    return graph;
  }

  /**
   * Topological sort using DFS
   */
  private topologicalSort(graph: Map<string, string[]>): string[] {
    const visited = new Set<string>();
    const stack: string[] = [];

    const visit = (node: string) => {
      if (visited.has(node)) return;
      visited.add(node);

      const neighbors = graph.get(node) || [];
      for (const neighbor of neighbors) {
        visit(neighbor);
      }

      stack.unshift(node);
    };

    for (const node of graph.keys()) {
      visit(node);
    }

    return stack;
  }
}