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
export type GitHubScope =
  | 'repo'           // Full repo access
  | 'repo:status'    // Repo status access
  | 'public_repo'    // Public repo access
  | 'user'           // User data access
  | 'user:email'     // User email access
  | 'read:user'      // Read user data
  | 'gist'           // Gist access
  | 'workflow';      // GitHub Actions workflow access

/**
 * GitHub API endpoints
 */
export const GITHUB_API_ENDPOINTS = {
  authorization: 'https://github.com/login/oauth/authorize',
  token: 'https://github.com/login/oauth/access_token',
  user: 'https://api.github.com/user',
  userEmails: 'https://api.github.com/user/emails',
} as const;