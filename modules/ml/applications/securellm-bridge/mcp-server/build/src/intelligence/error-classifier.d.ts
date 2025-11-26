import type { DiagnoseIssue } from "../types/package-debugger.js";
export declare class ErrorClassifier {
    private patterns;
    constructor();
    private initializePatterns;
    /**
     * Classify an error and return structured information
     */
    classifyError(errorLog: string): DiagnoseIssue | null;
    /**
     * Classify multiple errors from a log
     */
    classifyAllErrors(errorLog: string): DiagnoseIssue[];
    private generateProblemDescription;
    private generateCauseDescription;
    private generateSolution;
    private generateFixCommand;
    /**
     * Get dependency mapping for a library
     */
    getLibraryMapping(library: string): string | null;
}
//# sourceMappingURL=error-classifier.d.ts.map