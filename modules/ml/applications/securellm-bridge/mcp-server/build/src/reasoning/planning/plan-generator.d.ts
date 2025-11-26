/**
 * Plan Generator
 *
 * Generates execution plans from user input using context and patterns.
 */
import type { PlanningContext, ExecutionPlan } from '../../types/planning.js';
/**
 * Plan Generator
 */
export declare class PlanGenerator {
    /**
     * Generate execution plan from context
     */
    generatePlan(context: PlanningContext): ExecutionPlan;
    /**
     * Generate steps based on intent
     */
    private generateSteps;
    /**
     * Generate steps for create intent
     */
    private generateCreateSteps;
    /**
     * Generate steps for edit intent
     */
    private generateEditSteps;
    /**
     * Generate steps for debug intent
     */
    private generateDebugSteps;
    /**
     * Generate steps for build intent
     */
    private generateBuildSteps;
    /**
     * Generate steps for test intent
     */
    private generateTestSteps;
    /**
     * Generate steps for refactor intent
     */
    private generateRefactorSteps;
    /**
     * Generate generic steps
     */
    private generateGenericSteps;
    /**
     * Generate plan name
     */
    private generatePlanName;
}
//# sourceMappingURL=plan-generator.d.ts.map