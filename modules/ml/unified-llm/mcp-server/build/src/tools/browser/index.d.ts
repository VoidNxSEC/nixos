/**
 * Advanced Browser Navigation Tools
 * Web scraping and automation with Puppeteer
 */
import { Browser, Page } from 'puppeteer';
import type { BrowserLaunchAdvancedArgs, BrowserExtractDataArgs, BrowserInteractFormArgs, BrowserMonitorChangesArgs, BrowserSearchAggregateArgs, BrowserSessionResult, ToolResult } from '../../types/extended-tools.js';
interface BrowserSession {
    id: string;
    browser: Browser;
    page: Page;
    url: string;
    created: Date;
}
declare class BrowserSessionManager {
    private sessions;
    private allowedDomains;
    createSession(args: BrowserLaunchAdvancedArgs): Promise<BrowserSessionResult>;
    getSession(sessionId: string): BrowserSession | undefined;
    closeSession(sessionId: string): Promise<boolean>;
    closeAll(): Promise<void>;
}
declare const browserManager: BrowserSessionManager;
/**
 * Browser Launch Advanced Tool
 */
export declare class BrowserLaunchAdvancedTool {
    execute(args: BrowserLaunchAdvancedArgs): Promise<BrowserSessionResult>;
}
/**
 * Browser Extract Data Tool
 */
export declare class BrowserExtractDataTool {
    execute(args: BrowserExtractDataArgs): Promise<ToolResult>;
}
/**
 * Browser Interact Form Tool
 */
export declare class BrowserInteractFormTool {
    execute(args: BrowserInteractFormArgs): Promise<ToolResult>;
}
/**
 * Browser Monitor Changes Tool
 */
export declare class BrowserMonitorChangesTool {
    execute(args: BrowserMonitorChangesArgs): Promise<ToolResult>;
}
/**
 * Browser Search Aggregate Tool
 */
export declare class BrowserSearchAggregateTool {
    execute(args: BrowserSearchAggregateArgs): Promise<ToolResult>;
    private searchSource;
}
export declare const browserLaunchAdvancedSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            url: {
                type: string;
                description: string;
            };
            headless: {
                type: string;
                description: string;
            };
            viewport: {
                type: string;
                properties: {
                    width: {
                        type: string;
                    };
                    height: {
                        type: string;
                    };
                };
            };
            user_agent: {
                type: string;
                description: string;
            };
            cookies: {
                type: string;
                items: {
                    type: string;
                    properties: {
                        name: {
                            type: string;
                        };
                        value: {
                            type: string;
                        };
                        domain: {
                            type: string;
                        };
                    };
                };
            };
        };
        required: string[];
    };
};
export declare const browserExtractDataSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            session_id: {
                type: string;
                description: string;
            };
            selectors: {
                type: string;
                items: {
                    type: string;
                    properties: {
                        name: {
                            type: string;
                        };
                        selector: {
                            type: string;
                        };
                        type: {
                            type: string;
                            enum: string[];
                        };
                    };
                    required: string[];
                };
            };
            wait_for: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const browserInteractFormSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            session_id: {
                type: string;
                description: string;
            };
            actions: {
                type: string;
                items: {
                    type: string;
                    properties: {
                        type: {
                            type: string;
                            enum: string[];
                        };
                        selector: {
                            type: string;
                        };
                        value: {
                            type: string;
                        };
                    };
                    required: string[];
                };
            };
            submit_selector: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const browserMonitorChangesSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            session_id: {
                type: string;
                description: string;
            };
            selector: {
                type: string;
                description: string;
            };
            interval_seconds: {
                type: string;
                description: string;
            };
            duration_seconds: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const browserSearchAggregateSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            sources: {
                type: string;
                items: {
                    type: string;
                    enum: string[];
                };
            };
            max_results: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export { browserManager };
//# sourceMappingURL=index.d.ts.map