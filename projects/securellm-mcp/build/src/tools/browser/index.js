/**
 * Advanced Browser Navigation Tools
 * Web scraping and automation with Puppeteer
 */
// @ts-ignore
import puppeteer from 'puppeteer';
class BrowserSessionManager {
    sessions = new Map();
    allowedDomains = ['google.com', 'github.com', 'stackoverflow.com', 'duckduckgo.com', 'localhost'];
    async createSession(args) {
        const { url, headless = true, viewport = { width: 1920, height: 1080 }, user_agent, cookies } = args;
        // Security: validate URL
        const domain = new URL(url).hostname;
        if (!this.allowedDomains.some(d => domain.includes(d))) {
            return {
                success: false,
                error: `Domain ${domain} not in whitelist`,
                timestamp: new Date().toISOString(),
            };
        }
        try {
            const browser = await puppeteer.launch({
                headless,
                args: ['--no-sandbox', '--disable-setuid-sandbox'],
            });
            const page = await browser.newPage();
            await page.setViewport(viewport);
            if (user_agent) {
                await page.setUserAgent(user_agent);
            }
            else {
                // Default to a common browser User-Agent to avoid basic bot detection
                await page.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
            }
            if (cookies && cookies.length > 0) {
                await page.setCookie(...cookies);
            }
            await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
            const sessionId = `browser-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            const session = {
                id: sessionId,
                browser,
                page,
                url,
                created: new Date(),
            };
            this.sessions.set(sessionId, session);
            // Capture screenshot
            const screenshot = await page.screenshot({ encoding: 'base64' });
            const consoleLogs = [];
            page.on('console', (msg) => {
                consoleLogs.push(`[${msg.type()}] ${msg.text()}`);
            });
            return {
                success: true,
                data: {
                    session_id: sessionId,
                    url,
                    screenshot: screenshot,
                    console_logs: consoleLogs,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Browser launch failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    getSession(sessionId) {
        return this.sessions.get(sessionId);
    }
    async closeSession(sessionId) {
        const session = this.sessions.get(sessionId);
        if (session) {
            await session.browser.close();
            this.sessions.delete(sessionId);
            return true;
        }
        return false;
    }
    async closeAll() {
        for (const session of this.sessions.values()) {
            await session.browser.close();
        }
        this.sessions.clear();
    }
}
const browserManager = new BrowserSessionManager();
/**
 * Browser Launch Advanced Tool
 */
export class BrowserLaunchAdvancedTool {
    async execute(args) {
        return await browserManager.createSession(args);
    }
}
/**
 * Browser Extract Data Tool
 */
export class BrowserExtractDataTool {
    async execute(args) {
        const { session_id, selectors, wait_for } = args;
        const session = browserManager.getSession(session_id);
        if (!session) {
            return {
                success: false,
                error: 'Browser session not found',
                timestamp: new Date().toISOString(),
            };
        }
        try {
            const { page } = session;
            if (wait_for) {
                await page.waitForSelector(wait_for, { timeout: 10000 });
            }
            const extracted = {};
            for (const selector of selectors) {
                try {
                    const elements = await page.$$(selector.selector);
                    const values = [];
                    for (const el of elements) {
                        if (selector.type === 'text') {
                            const text = await page.evaluate((e) => e.textContent, el);
                            values.push(text?.trim());
                        }
                        else if (selector.type === 'html') {
                            const html = await page.evaluate((e) => e.innerHTML, el);
                            values.push(html);
                        }
                        else if (selector.type === 'attribute') {
                            const attr = await page.evaluate((e, name) => e.getAttribute(name), el, selector.name || 'href');
                            values.push(attr);
                        }
                    }
                    extracted[selector.name] = values.length === 1 ? values[0] : values;
                }
                catch (error) {
                    extracted[selector.name] = { error: error.message };
                }
            }
            const screenshot = await page.screenshot({ encoding: 'base64' });
            return {
                success: true,
                data: {
                    session_id,
                    extracted,
                    screenshot: screenshot,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Data extraction failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
/**
 * Browser Interact Form Tool
 */
export class BrowserInteractFormTool {
    async execute(args) {
        const { session_id, actions, submit_selector } = args;
        const session = browserManager.getSession(session_id);
        if (!session) {
            return {
                success: false,
                error: 'Browser session not found',
                timestamp: new Date().toISOString(),
            };
        }
        try {
            const { page } = session;
            for (const action of actions) {
                await page.waitForSelector(action.selector, { timeout: 5000 });
                switch (action.type) {
                    case 'fill':
                        await page.type(action.selector, action.value || '');
                        break;
                    case 'click':
                        await page.click(action.selector);
                        break;
                    case 'select':
                        await page.select(action.selector, action.value || '');
                        break;
                    case 'check':
                        await page.click(action.selector);
                        break;
                    case 'upload':
                        const input = await page.$(action.selector);
                        if (input && action.value) {
                            await input.uploadFile(action.value);
                        }
                        break;
                }
                await new Promise(resolve => setTimeout(resolve, 500)); // Small delay between actions
            }
            if (submit_selector) {
                await page.click(submit_selector);
                await page.waitForNavigation({ timeout: 10000 }).catch(() => { });
            }
            const screenshot = await page.screenshot({ encoding: 'base64' });
            return {
                success: true,
                data: {
                    session_id,
                    actions_performed: actions.length,
                    submitted: !!submit_selector,
                    screenshot: screenshot,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Form interaction failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
/**
 * Browser Monitor Changes Tool
 */
export class BrowserMonitorChangesTool {
    async execute(args) {
        const { session_id, selector, interval_seconds, duration_seconds } = args;
        const session = browserManager.getSession(session_id);
        if (!session) {
            return {
                success: false,
                error: 'Browser session not found',
                timestamp: new Date().toISOString(),
            };
        }
        try {
            const { page } = session;
            const changes = [];
            const iterations = Math.min(duration_seconds / interval_seconds, 20); // Max 20 samples
            for (let i = 0; i < iterations; i++) {
                try {
                    const content = await page.$eval(selector, (el) => el.textContent);
                    changes.push({
                        timestamp: new Date().toISOString(),
                        content: content?.trim() || '',
                    });
                }
                catch (error) {
                    changes.push({
                        timestamp: new Date().toISOString(),
                        content: '[ERROR: Element not found]',
                    });
                }
                if (i < iterations - 1) {
                    await new Promise(resolve => setTimeout(resolve, interval_seconds * 1000));
                }
            }
            // Detect if content changed
            const uniqueContents = new Set(changes.map(c => c.content));
            const contentChanged = uniqueContents.size > 1;
            return {
                success: true,
                data: {
                    session_id,
                    selector,
                    changes,
                    content_changed: contentChanged,
                    unique_values: Array.from(uniqueContents),
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Monitoring failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
/**
 * Browser Search Aggregate Tool
 */
export class BrowserSearchAggregateTool {
    async execute(args) {
        const { query, sources, max_results = 10 } = args;
        try {
            const results = {};
            for (const source of sources) {
                try {
                    results[source] = await this.searchSource(source, query, max_results);
                }
                catch (error) {
                    results[source] = { error: error.message };
                }
            }
            return {
                success: true,
                data: {
                    query,
                    sources,
                    results,
                    total_results: Object.values(results).filter((r) => !r.error).length,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Search aggregation failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async searchSource(source, query, maxResults) {
        // Simplified implementation - would use actual search APIs in production
        return {
            source,
            query,
            message: 'Search aggregation requires API keys - simplified implementation',
            results_count: 0,
        };
    }
}
// Export schemas
export const browserLaunchAdvancedSchema = {
    name: "browser_launch_advanced",
    description: "Launch advanced browser session with Puppeteer",
    inputSchema: {
        type: "object",
        properties: {
            url: { type: "string", description: "URL to navigate to" },
            headless: { type: "boolean", description: "Run in headless mode (default: true)" },
            viewport: {
                type: "object",
                properties: {
                    width: { type: "number" },
                    height: { type: "number" },
                },
            },
            user_agent: { type: "string", description: "Custom user agent" },
            cookies: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        name: { type: "string" },
                        value: { type: "string" },
                        domain: { type: "string" },
                    },
                },
            },
        },
        required: ["url"],
    },
};
export const browserExtractDataSchema = {
    name: "browser_extract_data",
    description: "Extract data from web page using CSS selectors",
    inputSchema: {
        type: "object",
        properties: {
            session_id: { type: "string", description: "Browser session ID" },
            selectors: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        name: { type: "string" },
                        selector: { type: "string" },
                        type: { type: "string", enum: ["text", "html", "attribute"] },
                    },
                    required: ["name", "selector", "type"],
                },
            },
            wait_for: { type: "string", description: "Selector to wait for before extracting" },
        },
        required: ["session_id", "selectors"],
    },
};
export const browserInteractFormSchema = {
    name: "browser_interact_form",
    description: "Interact with web forms (fill, click, select, etc.)",
    inputSchema: {
        type: "object",
        properties: {
            session_id: { type: "string", description: "Browser session ID" },
            actions: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        type: { type: "string", enum: ["fill", "click", "select", "check", "upload"] },
                        selector: { type: "string" },
                        value: { type: "string" },
                    },
                    required: ["type", "selector"],
                },
            },
            submit_selector: { type: "string", description: "Submit button selector (optional)" },
        },
        required: ["session_id", "actions"],
    },
};
export const browserMonitorChangesSchema = {
    name: "browser_monitor_changes",
    description: "Monitor element for changes over time",
    inputSchema: {
        type: "object",
        properties: {
            session_id: { type: "string", description: "Browser session ID" },
            selector: { type: "string", description: "Element selector to monitor" },
            interval_seconds: { type: "number", description: "Check interval in seconds" },
            duration_seconds: { type: "number", description: "Total monitoring duration" },
        },
        required: ["session_id", "selector", "interval_seconds", "duration_seconds"],
    },
};
export const browserSearchAggregateSchema = {
    name: "browser_search_aggregate",
    description: "Aggregate search results from multiple sources",
    inputSchema: {
        type: "object",
        properties: {
            query: { type: "string", description: "Search query" },
            sources: {
                type: "array",
                items: { type: "string", enum: ["google", "duckduckgo", "github", "stackoverflow"] },
            },
            max_results: { type: "number", description: "Max results per source (default: 10)" },
        },
        required: ["query", "sources"],
    },
};
export { browserManager };
//# sourceMappingURL=index.js.map