/**
 * Plan Generator
 *
 * Generates execution plans from user input using context and patterns.
 */
import { randomUUID } from 'crypto';
/**
 * Plan Generator
 */
export class PlanGenerator {
    /**
     * Generate execution plan from context
     */
    generatePlan(context) {
        const { enrichedContext, userInput } = context;
        // Generate steps based on intent
        const steps = this.generateSteps(context);
        // Calculate total duration
        const estimatedDuration = steps.reduce((sum, step) => sum + step.estimatedDuration, 0);
        return {
            id: randomUUID(),
            name: this.generatePlanName(enrichedContext.input.intent, userInput),
            steps,
            estimatedDuration,
            currentStep: 0,
            status: 'pending',
            createdAt: Date.now(),
        };
    }
    /**
     * Generate steps based on intent
     */
    generateSteps(context) {
        const { enrichedContext } = context;
        const intent = enrichedContext.input.intent;
        switch (intent) {
            case 'create':
                return this.generateCreateSteps(context);
            case 'edit':
                return this.generateEditSteps(context);
            case 'debug':
                return this.generateDebugSteps(context);
            case 'build':
                return this.generateBuildSteps(context);
            case 'test':
                return this.generateTestSteps(context);
            case 'refactor':
                return this.generateRefactorSteps(context);
            default:
                return this.generateGenericSteps(context);
        }
    }
    /**
     * Generate steps for create intent
     */
    generateCreateSteps(context) {
        const steps = [];
        steps.push({
            id: 'validate_requirements',
            name: 'Validate Requirements',
            description: 'Ensure all requirements are clear',
            status: 'pending',
            priority: 'critical',
            dependencies: [],
            estimatedDuration: 500,
            metadata: {},
        });
        steps.push({
            id: 'create_structure',
            name: 'Create Structure',
            description: 'Create file/directory structure',
            status: 'pending',
            priority: 'high',
            dependencies: ['validate_requirements'],
            estimatedDuration: 1000,
            metadata: {},
        });
        steps.push({
            id: 'implement_logic',
            name: 'Implement Logic',
            description: 'Write implementation code',
            status: 'pending',
            priority: 'high',
            dependencies: ['create_structure'],
            estimatedDuration: 3000,
            metadata: {},
        });
        steps.push({
            id: 'verify_creation',
            name: 'Verify Creation',
            description: 'Verify files were created correctly',
            status: 'pending',
            priority: 'normal',
            dependencies: ['implement_logic'],
            estimatedDuration: 500,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate steps for edit intent
     */
    generateEditSteps(context) {
        const steps = [];
        steps.push({
            id: 'locate_target',
            name: 'Locate Target',
            description: 'Find file/function to edit',
            status: 'pending',
            priority: 'critical',
            dependencies: [],
            estimatedDuration: 500,
            metadata: {},
        });
        steps.push({
            id: 'backup_original',
            name: 'Backup Original',
            description: 'Create backup before changes',
            status: 'pending',
            priority: 'high',
            dependencies: ['locate_target'],
            estimatedDuration: 200,
            metadata: {},
        });
        steps.push({
            id: 'apply_changes',
            name: 'Apply Changes',
            description: 'Make requested modifications',
            status: 'pending',
            priority: 'high',
            dependencies: ['backup_original'],
            estimatedDuration: 2000,
            metadata: {},
        });
        steps.push({
            id: 'verify_changes',
            name: 'Verify Changes',
            description: 'Ensure changes are correct',
            status: 'pending',
            priority: 'normal',
            dependencies: ['apply_changes'],
            estimatedDuration: 500,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate steps for debug intent
     */
    generateDebugSteps(context) {
        const steps = [];
        steps.push({
            id: 'reproduce_issue',
            name: 'Reproduce Issue',
            description: 'Confirm the issue exists',
            status: 'pending',
            priority: 'critical',
            dependencies: [],
            estimatedDuration: 1000,
            metadata: {},
        });
        steps.push({
            id: 'analyze_logs',
            name: 'Analyze Logs',
            description: 'Check logs and error messages',
            status: 'pending',
            priority: 'high',
            dependencies: ['reproduce_issue'],
            estimatedDuration: 1500,
            metadata: {},
        });
        steps.push({
            id: 'identify_root_cause',
            name: 'Identify Root Cause',
            description: 'Find source of the problem',
            status: 'pending',
            priority: 'high',
            dependencies: ['analyze_logs'],
            estimatedDuration: 2000,
            metadata: {},
        });
        steps.push({
            id: 'apply_fix',
            name: 'Apply Fix',
            description: 'Implement solution',
            status: 'pending',
            priority: 'high',
            dependencies: ['identify_root_cause'],
            estimatedDuration: 2500,
            metadata: {},
        });
        steps.push({
            id: 'verify_fix',
            name: 'Verify Fix',
            description: 'Confirm issue is resolved',
            status: 'pending',
            priority: 'normal',
            dependencies: ['apply_fix'],
            estimatedDuration: 1000,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate steps for build intent
     */
    generateBuildSteps(context) {
        const steps = [];
        steps.push({
            id: 'check_dependencies',
            name: 'Check Dependencies',
            description: 'Verify all dependencies available',
            status: 'pending',
            priority: 'critical',
            dependencies: [],
            estimatedDuration: 1000,
            metadata: {},
        });
        steps.push({
            id: 'run_build',
            name: 'Run Build',
            description: 'Execute build process',
            status: 'pending',
            priority: 'high',
            dependencies: ['check_dependencies'],
            estimatedDuration: 5000,
            metadata: {},
        });
        steps.push({
            id: 'verify_artifacts',
            name: 'Verify Artifacts',
            description: 'Check build outputs',
            status: 'pending',
            priority: 'normal',
            dependencies: ['run_build'],
            estimatedDuration: 500,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate steps for test intent
     */
    generateTestSteps(context) {
        const steps = [];
        steps.push({
            id: 'setup_test_env',
            name: 'Setup Test Environment',
            description: 'Prepare test environment',
            status: 'pending',
            priority: 'high',
            dependencies: [],
            estimatedDuration: 1000,
            metadata: {},
        });
        steps.push({
            id: 'run_tests',
            name: 'Run Tests',
            description: 'Execute test suite',
            status: 'pending',
            priority: 'high',
            dependencies: ['setup_test_env'],
            estimatedDuration: 3000,
            metadata: {},
        });
        steps.push({
            id: 'analyze_results',
            name: 'Analyze Results',
            description: 'Review test outcomes',
            status: 'pending',
            priority: 'normal',
            dependencies: ['run_tests'],
            estimatedDuration: 500,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate steps for refactor intent
     */
    generateRefactorSteps(context) {
        const steps = [];
        steps.push({
            id: 'analyze_code',
            name: 'Analyze Code',
            description: 'Review code structure',
            status: 'pending',
            priority: 'high',
            dependencies: [],
            estimatedDuration: 1500,
            metadata: {},
        });
        steps.push({
            id: 'plan_refactor',
            name: 'Plan Refactor',
            description: 'Design refactoring strategy',
            status: 'pending',
            priority: 'high',
            dependencies: ['analyze_code'],
            estimatedDuration: 1000,
            metadata: {},
        });
        steps.push({
            id: 'apply_refactor',
            name: 'Apply Refactor',
            description: 'Execute refactoring changes',
            status: 'pending',
            priority: 'high',
            dependencies: ['plan_refactor'],
            estimatedDuration: 3000,
            metadata: {},
        });
        steps.push({
            id: 'verify_refactor',
            name: 'Verify Refactor',
            description: 'Ensure functionality preserved',
            status: 'pending',
            priority: 'normal',
            dependencies: ['apply_refactor'],
            estimatedDuration: 1000,
            metadata: {},
        });
        return steps;
    }
    /**
     * Generate generic steps
     */
    generateGenericSteps(context) {
        return [{
                id: 'execute_task',
                name: 'Execute Task',
                description: 'Perform requested operation',
                status: 'pending',
                priority: 'high',
                dependencies: [],
                estimatedDuration: 2000,
                metadata: {},
            }];
    }
    /**
     * Generate plan name
     */
    generatePlanName(intent, input) {
        const shortInput = input.length > 50 ? input.substring(0, 47) + '...' : input;
        return `${intent.charAt(0).toUpperCase() + intent.slice(1)}: ${shortInput}`;
    }
}
//# sourceMappingURL=plan-generator.js.map