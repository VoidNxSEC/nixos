/**
 * GitHub OAuth provider types
 */
/**
 * GitHub user information
 */
export interface GitHubUser {
    /** GitHub user ID */
    id: number;
    /** Username */
    login: string;
    /** Display name */
    name: string | null;
    /** Email address */
    email: string | null;
    /** Avatar URL */
    avatar_url: string;
    /** Profile URL */
    html_url: string;
    /** User type (User or Organization) */
    type: string;
    /** Account creation date */
    created_at: string;
    /** Last update date */
    updated_at: string;
}
/**
 * GitHub OAuth scopes
 */
export type GitHubScope = 'repo' | 'repo:status' | 'public_repo' | 'user' | 'user:email' | 'read:user' | 'gist' | 'workflow';
/**
 * GitHub API endpoints
 */
export declare const GITHUB_API_ENDPOINTS: {
    readonly authorization: "https://github.com/login/oauth/authorize";
    readonly token: "https://github.com/login/oauth/access_token";
    readonly user: "https://api.github.com/user";
    readonly userEmails: "https://api.github.com/user/emails";
};
//# sourceMappingURL=github.d.ts.map