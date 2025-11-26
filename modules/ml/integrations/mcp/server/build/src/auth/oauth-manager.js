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
import crypto from 'node:crypto';
import { OAuthError, OAuthErrorType, } from '../types/oauth.js';
/**
 * Base OAuth Manager for handling OAuth 2.0 flows
 */
export class OAuthManager {
    config;
    states = new Map();
    STATE_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
    constructor(config) {
        this.validateConfig(config);
        this.config = config;
    }
    /**
     * Validate OAuth configuration
     */
    validateConfig(config) {
        if (!config.clientId) {
            throw new OAuthError(OAuthErrorType.INVALID_CONFIG, 'OAuth client ID is required', config.provider);
        }
        if (!config.clientSecret) {
            throw new OAuthError(OAuthErrorType.INVALID_CONFIG, 'OAuth client secret is required', config.provider);
        }
        if (!config.authorizationUrl) {
            throw new OAuthError(OAuthErrorType.INVALID_CONFIG, 'Authorization URL is required', config.provider);
        }
        if (!config.tokenUrl) {
            throw new OAuthError(OAuthErrorType.INVALID_CONFIG, 'Token URL is required', config.provider);
        }
        if (!config.redirectUri) {
            throw new OAuthError(OAuthErrorType.INVALID_CONFIG, 'Redirect URI is required', config.provider);
        }
    }
    /**
     * Generate a cryptographically secure random state
     */
    generateState() {
        return crypto.randomBytes(32).toString('base64url');
    }
    /**
     * Generate PKCE code verifier and challenge
     */
    generatePKCE() {
        const verifier = crypto.randomBytes(32).toString('base64url');
        const challenge = crypto
            .createHash('sha256')
            .update(verifier)
            .digest('base64url');
        return { verifier, challenge };
    }
    /**
     * Build authorization URL for OAuth flow
     * @param usePKCE Whether to use PKCE (default: true for security)
     */
    buildAuthorizationUrl(usePKCE = true) {
        const state = this.generateState();
        const oauthState = {
            state,
            provider: this.config.provider,
            createdAt: Date.now(),
        };
        const params = new URLSearchParams({
            client_id: this.config.clientId,
            redirect_uri: this.config.redirectUri,
            response_type: 'code',
            state,
            scope: this.config.scopes.join(' '),
        });
        if (usePKCE) {
            const { verifier, challenge } = this.generatePKCE();
            oauthState.codeVerifier = verifier;
            params.set('code_challenge', challenge);
            params.set('code_challenge_method', 'S256');
        }
        this.states.set(state, oauthState);
        this.cleanExpiredStates();
        return `${this.config.authorizationUrl}?${params.toString()}`;
    }
    /**
     * Clean up expired states (CSRF protection)
     */
    cleanExpiredStates() {
        const now = Date.now();
        for (const [key, state] of this.states.entries()) {
            if (now - state.createdAt > this.STATE_EXPIRY_MS) {
                this.states.delete(key);
            }
        }
    }
    /**
     * Verify OAuth state parameter (CSRF protection)
     */
    verifyState(state) {
        const oauthState = this.states.get(state);
        if (!oauthState) {
            throw new OAuthError(OAuthErrorType.INVALID_STATE, 'Invalid or expired OAuth state', this.config.provider);
        }
        const now = Date.now();
        if (now - oauthState.createdAt > this.STATE_EXPIRY_MS) {
            this.states.delete(state);
            throw new OAuthError(OAuthErrorType.INVALID_STATE, 'OAuth state has expired', this.config.provider);
        }
        return oauthState;
    }
    /**
     * Exchange authorization code for access token
     */
    async exchangeToken(request) {
        const oauthState = this.verifyState(request.state);
        this.states.delete(request.state); // Single use
        const params = new URLSearchParams({
            grant_type: 'authorization_code',
            code: request.code,
            redirect_uri: this.config.redirectUri,
            client_id: this.config.clientId,
            client_secret: this.config.clientSecret,
        });
        if (oauthState.codeVerifier && request.codeVerifier) {
            params.set('code_verifier', request.codeVerifier);
        }
        try {
            const response = await fetch(this.config.tokenUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    Accept: 'application/json',
                },
                body: params.toString(),
            });
            if (!response.ok) {
                const error = await response.text();
                throw new OAuthError(OAuthErrorType.PROVIDER_ERROR, `Token exchange failed: ${error}`, this.config.provider);
            }
            const data = await response.json();
            return this.parseTokenResponse(data);
        }
        catch (error) {
            if (error instanceof OAuthError) {
                throw error;
            }
            throw new OAuthError(OAuthErrorType.NETWORK_ERROR, 'Failed to exchange authorization code', this.config.provider, error);
        }
    }
    /**
     * Parse token response from provider
     */
    parseTokenResponse(data) {
        const token = {
            accessToken: data.access_token,
            refreshToken: data.refresh_token,
            tokenType: data.token_type || 'Bearer',
            scopes: this.config.scopes,
            provider: this.config.provider,
        };
        if (data.expires_in) {
            token.expiresAt = Date.now() + data.expires_in * 1000;
        }
        return token;
    }
    /**
     * Refresh an access token using refresh token
     */
    async refreshToken(token) {
        if (!token.refreshToken) {
            throw new OAuthError(OAuthErrorType.REFRESH_FAILED, 'No refresh token available', this.config.provider);
        }
        const params = new URLSearchParams({
            grant_type: 'refresh_token',
            refresh_token: token.refreshToken,
            client_id: this.config.clientId,
            client_secret: this.config.clientSecret,
        });
        try {
            const response = await fetch(this.config.tokenUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    Accept: 'application/json',
                },
                body: params.toString(),
            });
            if (!response.ok) {
                const error = await response.text();
                throw new OAuthError(OAuthErrorType.REFRESH_FAILED, `Token refresh failed: ${error}`, this.config.provider);
            }
            const data = await response.json();
            return this.parseTokenResponse(data);
        }
        catch (error) {
            if (error instanceof OAuthError) {
                throw error;
            }
            throw new OAuthError(OAuthErrorType.NETWORK_ERROR, 'Failed to refresh token', this.config.provider, error);
        }
    }
    /**
     * Check if a token is expired
     */
    isTokenExpired(token) {
        if (!token.expiresAt) {
            return false; // No expiration info
        }
        // Add 5 minute buffer for clock skew
        return Date.now() >= token.expiresAt - 5 * 60 * 1000;
    }
    /**
     * Get provider name
     */
    getProvider() {
        return this.config.provider;
    }
}
//# sourceMappingURL=oauth-manager.js.map