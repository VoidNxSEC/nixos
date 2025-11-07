/**
 * OAuth Provider Configurations
 */
import { GitHubScope } from '../types/providers/github.js';
/**
 * Default OAuth scopes per provider
 */
export declare const DEFAULT_OAUTH_SCOPES: {
    readonly github: GitHubScope[];
    readonly gitlab: readonly ["read_user", "read_api", "read_repository"];
    readonly google: readonly ["openid", "email", "profile"];
};
/**
 * OAuth provider display names
 */
export declare const OAUTH_PROVIDER_NAMES: {
    readonly github: "GitHub";
    readonly gitlab: "GitLab";
    readonly google: "Google";
};
/**
 * OAuth provider documentation URLs
 */
export declare const OAUTH_PROVIDER_DOCS: {
    readonly github: "https://docs.github.com/en/apps/oauth-apps";
    readonly gitlab: "https://docs.gitlab.com/ee/api/oauth2.html";
    readonly google: "https://developers.google.com/identity/protocols/oauth2";
};
//# sourceMappingURL=oauth-providers.d.ts.map