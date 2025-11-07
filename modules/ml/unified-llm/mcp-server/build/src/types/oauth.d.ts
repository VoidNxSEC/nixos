/**
 * OAuth 2.0 authentication types and interfaces
 */
/**
 * Supported OAuth providers
 */
export type OAuthProvider = 'github' | 'gitlab' | 'google';
/**
 * OAuth 2.0 configuration for a provider
 */
export interface OAuthConfig {
    /** Provider identifier */
    provider: OAuthProvider;
    /** OAuth client ID */
    clientId: string;
    /** OAuth client secret */
    clientSecret: string;
    /** Authorization endpoint URL */
    authorizationUrl: string;
    /** Token endpoint URL */
    tokenUrl: string;
    /** OAuth scopes requested */
    scopes: string[];
    /** Redirect URI for OAuth callback */
    redirectUri: string;
}
/**
 * OAuth access token with metadata
 */
export interface OAuthToken {
    /** Access token */
    accessToken: string;
    /** Refresh token (optional) */
    refreshToken?: string;
    /** Token type (usually "Bearer") */
    tokenType: string;
    /** Token expiration timestamp (Unix epoch) */
    expiresAt?: number;
    /** OAuth scopes granted */
    scopes: string[];
    /** Provider this token is for */
    provider: OAuthProvider;
}
/**
 * OAuth authentication state
 */
export interface OAuthState {
    /** Random state parameter for CSRF protection */
    state: string;
    /** Provider this state is for */
    provider: OAuthProvider;
    /** Timestamp when state was created */
    createdAt: number;
    /** Optional PKCE code verifier */
    codeVerifier?: string;
}
/**
 * OAuth authorization code exchange request
 */
export interface OAuthTokenRequest {
    /** Authorization code from OAuth callback */
    code: string;
    /** State parameter for verification */
    state: string;
    /** Optional PKCE code verifier */
    codeVerifier?: string;
}
/**
 * OAuth error types
 */
export declare enum OAuthErrorType {
    INVALID_CONFIG = "invalid_config",
    INVALID_STATE = "invalid_state",
    TOKEN_EXPIRED = "token_expired",
    REFRESH_FAILED = "refresh_failed",
    PROVIDER_ERROR = "provider_error",
    NETWORK_ERROR = "network_error"
}
/**
 * OAuth error with context
 */
export declare class OAuthError extends Error {
    type: OAuthErrorType;
    provider?: OAuthProvider | undefined;
    originalError?: Error | undefined;
    constructor(type: OAuthErrorType, message: string, provider?: OAuthProvider | undefined, originalError?: Error | undefined);
}
//# sourceMappingURL=oauth.d.ts.map