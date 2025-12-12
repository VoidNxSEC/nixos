/**
 * Token storage types and interfaces
 */

import { OAuthToken, OAuthProvider } from './oauth.js';

/**
 * Encrypted token storage format
 */
export interface EncryptedTokenStorage {
  /** Encrypted token data (JSON string encrypted with SOPS) */
  encrypted: string;
  /** Provider this token is for */
  provider: OAuthProvider;
  /** Timestamp when token was stored */
  storedAt: number;
  /** SOPS version used for encryption */
  sopsVersion?: string;
}

/**
 * Token storage metadata
 */
export interface TokenStorageMetadata {
  /** Provider */
  provider: OAuthProvider;
  /** When token was stored */
  storedAt: number;
  /** Token expiration (if known) */
  expiresAt?: number;
  /** Whether token has refresh capability */
  hasRefreshToken: boolean;
}

/**
 * Token storage operations result
 */
export interface TokenStorageResult {
  /** Whether operation succeeded */
  success: boolean;
  /** Error message if failed */
  error?: string;
  /** Token metadata if successful */
  metadata?: TokenStorageMetadata;
}