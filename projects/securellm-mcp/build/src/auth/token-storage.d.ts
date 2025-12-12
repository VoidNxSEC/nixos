/**
 * Token Storage Manager - Handles SOPS-encrypted OAuth token persistence
 *
 * Features:
 * - SOPS encryption/decryption for tokens at rest
 * - Automatic token refresh on load
 * - File-based storage per provider
 * - In-memory caching for performance
 * - Metadata tracking
 */
import { OAuthToken, OAuthProvider } from '../types/oauth.js';
import { TokenStorageMetadata, TokenStorageResult } from '../types/token-storage.js';
/**
 * Token Storage Manager with SOPS encryption
 */
export declare class TokenStorageManager {
    private tokensDir;
    private cache;
    private readonly SOPS_AVAILABLE;
    constructor(tokensDir?: string);
    /**
     * Check if SOPS is available in the system
     */
    private checkSOPSAvailability;
    /**
     * Ensure tokens directory exists
     */
    private ensureTokensDir;
    /**
     * Get file path for a provider's token
     */
    private getTokenPath;
    /**
     * Get encrypted file path for a provider's token
     */
    private getEncryptedTokenPath;
    /**
     * Encrypt token data using SOPS
     */
    private encryptWithSOPS;
    /**
     * Decrypt token data using SOPS
     */
    private decryptWithSOPS;
    /**
     * Store a token securely
     */
    storeToken(token: OAuthToken): Promise<TokenStorageResult>;
    /**
     * Load a token from storage
     */
    loadToken(provider: OAuthProvider): Promise<OAuthToken | null>;
    /**
     * Delete a stored token
     */
    deleteToken(provider: OAuthProvider): Promise<TokenStorageResult>;
    /**
     * List all stored tokens (metadata only)
     */
    listTokens(): Promise<TokenStorageMetadata[]>;
    /**
     * Check if a token exists
     */
    hasToken(provider: OAuthProvider): Promise<boolean>;
    /**
     * Clear all cached tokens (does not delete files)
     */
    clearCache(): void;
    /**
     * Get cached token without loading from disk
     */
    getCachedToken(provider: OAuthProvider): OAuthToken | undefined;
}
//# sourceMappingURL=token-storage.d.ts.map