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
import {
  OAuthConfig,
  OAuthToken,
  OAuthError,
  OAuthErrorType,
} from '../../types/oauth.js';
import {
  GitHubUser,
  GitHubScope,
  GITHUB_API_ENDPOINTS,
} from '../../types/providers/github.js';

/**
 * GitHub OAuth Provider implementation
 */
export class GitHubOAuthProvider extends OAuthManager {
  /**
   * Create GitHub OAuth provider with default configuration
   */
  static createDefault(
    clientId: string,
    clientSecret: string,
    redirectUri: string,
    scopes: GitHubScope[] = ['user:email', 'read:user']
  ): GitHubOAuthProvider {
    const config: OAuthConfig = {
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
  public async validateToken(token: OAuthToken): Promise<boolean> {
    try {
      const response = await fetch(GITHUB_API_ENDPOINTS.user, {
        headers: {
          Authorization: `Bearer ${token.accessToken}`,
          Accept: 'application/vnd.github.v3+json',
          'User-Agent': 'SecureLLM-Bridge-MCP',
        },
      });

      return response.ok;
    } catch (error) {
      console.error('GitHub token validation failed:', error);
      return false;
    }
  }

  /**
   * Get user information from GitHub
   */
  public async getUserInfo(token: OAuthToken): Promise<GitHubUser> {
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
        throw new OAuthError(
          OAuthErrorType.PROVIDER_ERROR,
          `Failed to fetch GitHub user info: ${error}`,
          'github'
        );
      }

      const user: GitHubUser = await response.json();

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
            const primaryEmail = emails.find((e: any) => e.primary);
            user.email = primaryEmail?.email || null;
          }
        } catch (error) {
          console.warn('Failed to fetch GitHub user emails:', error);
        }
      }

      return user;
    } catch (error) {
      if (error instanceof OAuthError) {
        throw error;
      }
      throw new OAuthError(
        OAuthErrorType.NETWORK_ERROR,
        'Failed to fetch GitHub user info',
        'github',
        error as Error
      );
    }
  }

  /**
   * Make authenticated request to GitHub API
   */
  public async makeRequest<T = any>(
    token: OAuthToken,
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
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
        throw new OAuthError(
          OAuthErrorType.PROVIDER_ERROR,
          `GitHub API request failed: ${error}`,
          'github'
        );
      }

      return await response.json();
    } catch (error) {
      if (error instanceof OAuthError) {
        throw error;
      }
      throw new OAuthError(
        OAuthErrorType.NETWORK_ERROR,
        `GitHub API request failed: ${error}`,
        'github',
        error as Error
      );
    }
  }

  /**
   * List user repositories
   */
  public async listRepositories(
    token: OAuthToken,
    options: {
      type?: 'all' | 'owner' | 'public' | 'private' | 'member';
      sort?: 'created' | 'updated' | 'pushed' | 'full_name';
      per_page?: number;
      page?: number;
    } = {}
  ): Promise<any[]> {
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
  public async getRepository(
    token: OAuthToken,
    owner: string,
    repo: string
  ): Promise<any> {
    return this.makeRequest(token, `/repos/${owner}/${repo}`);
  }

  /**
   * Create a gist
   */
  public async createGist(
    token: OAuthToken,
    files: Record<string, { content: string }>,
    description?: string,
    isPublic: boolean = false
  ): Promise<any> {
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