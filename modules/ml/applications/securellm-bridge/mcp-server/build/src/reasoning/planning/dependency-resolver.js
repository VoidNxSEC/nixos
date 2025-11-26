/**
 * Dependency Resolver
 *
 * Resolves step dependencies and determines execution order
 * using topological sorting.
 */
/**
 * Dependency Resolver
 */
export class DependencyResolver {
    /**
     * Resolve execution order using topological sort
     */
    resolveOrder(steps) {
        const graph = this.buildDependencyGraph(steps);
        const sorted = this.topologicalSort(graph);
        return sorted.map(id => steps.find(s => s.id === id));
    }
    /**
     * Find steps that can execute in parallel
     */
    findParallelGroups(steps) {
        const groups = [];
        const completed = new Set();
        const remaining = [...steps];
        while (remaining.length > 0) {
            // Find steps with all dependencies completed
            const ready = remaining.filter(step => step.dependencies.every(dep => completed.has(dep)));
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
    hasCircularDependencies(steps) {
        const graph = this.buildDependencyGraph(steps);
        const visited = new Set();
        const recursionStack = new Set();
        const hasCycle = (node) => {
            visited.add(node);
            recursionStack.add(node);
            const neighbors = graph.get(node) || [];
            for (const neighbor of neighbors) {
                if (!visited.has(neighbor)) {
                    if (hasCycle(neighbor))
                        return true;
                }
                else if (recursionStack.has(neighbor)) {
                    return true;
                }
            }
            recursionStack.delete(node);
            return false;
        };
        for (const node of graph.keys()) {
            if (!visited.has(node)) {
                if (hasCycle(node))
                    return true;
            }
        }
        return false;
    }
    /**
     * Build dependency graph (adjacency list)
     */
    buildDependencyGraph(steps) {
        const graph = new Map();
        for (const step of steps) {
            if (!graph.has(step.id)) {
                graph.set(step.id, []);
            }
            for (const dep of step.dependencies) {
                if (!graph.has(dep)) {
                    graph.set(dep, []);
                }
                graph.get(dep).push(step.id);
            }
        }
        return graph;
    }
    /**
     * Topological sort using DFS
     */
    topologicalSort(graph) {
        const visited = new Set();
        const stack = [];
        const visit = (node) => {
            if (visited.has(node))
                return;
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
//# sourceMappingURL=dependency-resolver.js.map