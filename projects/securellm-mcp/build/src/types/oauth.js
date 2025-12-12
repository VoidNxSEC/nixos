/**
 * OAuth 2.0 authentication types and interfaces
 */
/**
 * OAuth error types
 */
export var OAuthErrorType;
(function (OAuthErrorType) {
    OAuthErrorType["INVALID_CONFIG"] = "invalid_config";
    OAuthErrorType["INVALID_STATE"] = "invalid_state";
    OAuthErrorType["TOKEN_EXPIRED"] = "token_expired";
    OAuthErrorType["REFRESH_FAILED"] = "refresh_failed";
    OAuthErrorType["PROVIDER_ERROR"] = "provider_error";
    OAuthErrorType["NETWORK_ERROR"] = "network_error";
})(OAuthErrorType || (OAuthErrorType = {}));
/**
 * OAuth error with context
 */
export class OAuthError extends Error {
    type;
    provider;
    originalError;
    constructor(type, message, provider, originalError) {
        super(message);
        this.type = type;
        this.provider = provider;
        this.originalError = originalError;
        this.name = 'OAuthError';
    }
}
//# sourceMappingURL=oauth.js.map