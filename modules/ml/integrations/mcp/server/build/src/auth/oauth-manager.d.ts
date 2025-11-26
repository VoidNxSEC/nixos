/**
 * OAuth 2.0 Manager - Base class for OAuth authentication flows
 *
 * Provides:
 * - Authorization URL generation with PKCE support
 * - Token exchange (authorization code → access token)
 * - Token refresh
 * - State management for CSRF protection
 * - Token validation and expiration checks
 */
import { OAuthConfig, OAuthToken, OAuthState, OAuthTokenRequest, OAuthProvider } from '../types/oauth.js';
/**
 * Base OAuth Manager for handling OAuth 2.0 flows
 */
export declare abstract class OAuthManager {
    protected config: OAuthConfig;
    private states;
    private readonly STATE_EXPIRY_MS;
    constructor(config: OAuthConfig);
    /**
     * Validate OAuth configuration
     */
    private validateConfig;
    /**
     * Generate a cryptographically secure random state
     */
    protected generateState(): string;
    /**
     * Generate PKCE code verifier and challenge
     */
    protected generatePKCE(): {
        verifier: string;
        challenge: string;
    };
    /**
     * Build authorization URL for OAuth flow
     * @param usePKCE Whether to use PKCE (default: true for security)
     */
    buildAuthorizationUrl(usePKCE?: boolean): string;
    /**
     * Clean up expired states (CSRF protection)
     */
    private cleanExpiredStates;
    /**
     * Verify OAuth state parameter (CSRF protection)
     */
    protected verifyState(state: string): OAuthState;
    /**
     * Exchange authorization code for access token
     */
    exchangeToken(request: OAuthTokenRequest): Promise<OAuthToken>;
    /**
     * Parse token response from provider
     */
    protected parseTokenResponse(data: any): OAuthToken;
    /**
     * Refresh an access token using refresh token
     */
    refreshToken(token: OAuthToken): Promise<OAuthToken>;
    /**
     * Check if a token is expired
     */
    isTokenExpired(token: OAuthToken): boolean;
    /**
     * Get provider name
     */
    getProvider(): OAuthProvider;
    /**
     * Provider-specific token validation (override in subclasses)
     */
    abstract validateToken(token: OAuthToken): Promise<boolean>;
    /**
     * Provider-specific user info fetching (override in subclasses)
     */
    abstract getUserInfo(token: OAuthToken): Promise<any>;
}
//# sourceMappingURL=oauth-manager.d.ts.map