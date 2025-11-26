/**
 * GitHub OAuth Provider
 *
 * Implements OAuth 2.0 authentication for GitHub API access.
 *
 * Features:
 * - Full OAuth 2.0 flow with PKCE
 * - Token validation via GitHub API
 * - User info fetching
 * - Automatic token refresh
 * - Rate limit handling
 *
 * Documentation: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps
 */
import { OAuthManager } from '../oauth-manager.js';
import { OAuthError, OAuthErrorType, } from '../../types/oauth.js';
import { GITHUB_API_ENDPOINTS, } from '../../types/providers/github.js';
/**
 * GitHub OAuth Provider implementation
 */
export class GitHubOAuthProvider extends OAuthManager {
    /**
     * Create GitHub OAuth provider with default configuration
     */
    static createDefault(clientId, clientSecret, redirectUri, scopes = ['user:email', 'read:user']) {
        const config = {
            provider: 'github',
            clientId,
            clientSecret,
            authorizationUrl: GITHUB_API_ENDPOINTS.authorization,
            tokenUrl: GITHUB_API_ENDPOINTS.token,
            scopes,
            redirectUri,
        };
        return new GitHubOAuthProvider(config);
    }
    /**
     * Validate token by calling GitHub API
     */
    async validateToken(token) {
        try {
            const response = await fetch(GITHUB_API_ENDPOINTS.user, {
                headers: {
                    Authorization: `Bearer ${token.accessToken}`,
                    Accept: 'application/vnd.github.v3+json',
                    'User-Agent': 'SecureLLM-Bridge-MCP',
                },
            });
            return response.ok;
        }
        catch (error) {
            console.error('GitHub token validation failed:', error);
            return false;
        }
    }
    /**
     * Get user information from GitHub
     */
    async getUserInfo(token) {
        try {
            const response = await fetch(GITHUB_API_ENDPOINTS.user, {
                headers: {
                    Authorization: `Bearer ${token.accessToken}`,
                    Accept: 'application/vnd.github.v3+json',
                    'User-Agent': 'SecureLLM-Bridge-MCP',
                },
            });
            if (!response.ok) {
                const error = await response.text();
                throw new OAuthError(OAuthErrorType.PROVIDER_ERROR, `Failed to fetch GitHub user info: ${error}`, 'github');
            }
            const user = await response.json();
            // Fetch email if not included
            if (!user.email && token.scopes.includes('user:email')) {
                try {
                    const emailResponse = await fetch(GITHUB_API_ENDPOINTS.userEmails, {
                        headers: {
                            Authorization: `Bearer ${token.accessToken}`,
                            Accept: 'application/vnd.github.v3+json',
                            'User-Agent': 'SecureLLM-Bridge-MCP',
                        },
                    });
                    if (emailResponse.ok) {
                        const emails = await emailResponse.json();
                        const primaryEmail = emails.find((e) => e.primary);
                        user.email = primaryEmail?.email || null;
                    }
                }
                catch (error) {
                    console.warn('Failed to fetch GitHub user emails:', error);
                }
            }
            return user;
        }
        catch (error) {
            if (error instanceof OAuthError) {
                throw error;
            }
            throw new OAuthError(OAuthErrorType.NETWORK_ERROR, 'Failed to fetch GitHub user info', 'github', error);
        }
    }
    /**
     * Make authenticated request to GitHub API
     */
    async makeRequest(token, endpoint, options = {}) {
        const url = endpoint.startsWith('http')
            ? endpoint
            : `https://api.github.com${endpoint}`;
        try {
            const response = await fetch(url, {
                ...options,
                headers: {
                    Authorization: `Bearer ${token.accessToken}`,
                    Accept: 'application/vnd.github.v3+json',
                    'User-Agent': 'SecureLLM-Bridge-MCP',
                    ...options.headers,
                },
            });
            if (!response.ok) {
                const error = await response.text();
                throw new OAuthError(OAuthErrorType.PROVIDER_ERROR, `GitHub API request failed: ${error}`, 'github');
            }
            return await response.json();
        }
        catch (error) {
            if (error instanceof OAuthError) {
                throw error;
            }
            throw new OAuthError(OAuthErrorType.NETWORK_ERROR, `GitHub API request failed: ${error}`, 'github', error);
        }
    }
    /**
     * List user repositories
     */
    async listRepositories(token, options = {}) {
        const params = new URLSearchParams({
            type: options.type || 'all',
            sort: options.sort || 'updated',
            per_page: String(options.per_page || 30),
            page: String(options.page || 1),
        });
        return this.makeRequest(token, `/user/repos?${params}`);
    }
    /**
     * Get repository details
     */
    async getRepository(token, owner, repo) {
        return this.makeRequest(token, `/repos/${owner}/${repo}`);
    }
    /**
     * Create a gist
     */
    async createGist(token, files, description, isPublic = false) {
        return this.makeRequest(token, '/gists', {
            method: 'POST',
            body: JSON.stringify({
                description,
                public: isPublic,
                files,
            }),
        });
    }
}
//# sourceMappingURL=github-provider.js.map