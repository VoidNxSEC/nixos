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

import fs from 'node:fs/promises';
import path from 'node:path';
import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import {
  OAuthToken,
  OAuthProvider,
  OAuthError,
  OAuthErrorType,
} from '../types/oauth.js';
import {
  EncryptedTokenStorage,
  TokenStorageMetadata,
  TokenStorageResult,
} from '../types/token-storage.js';

const execAsync = promisify(exec);

/**
 * Token Storage Manager with SOPS encryption
 */
export class TokenStorageManager {
  private tokensDir: string;
  private cache: Map<OAuthProvider, OAuthToken> = new Map();
  private readonly SOPS_AVAILABLE: boolean;

  constructor(tokensDir: string = './secrets/oauth') {
    this.tokensDir = tokensDir;
    this.SOPS_AVAILABLE = this.checkSOPSAvailability();
  }

  /**
   * Check if SOPS is available in the system
   */
  private checkSOPSAvailability(): boolean {
    try {
      execAsync('which sops');
      return true;
    } catch {
      console.warn('SOPS not available - tokens will be stored unencrypted (DEV ONLY)');
      return false;
    }
  }

  /**
   * Ensure tokens directory exists
   */
  private async ensureTokensDir(): Promise<void> {
    try {
      await fs.mkdir(this.tokensDir, { recursive: true });
    } catch (error) {
      throw new OAuthError(
        OAuthErrorType.NETWORK_ERROR,
        `Failed to create tokens directory: ${error}`,
        undefined,
        error as Error
      );
    }
  }

  /**
   * Get file path for a provider's token
   */
  private getTokenPath(provider: OAuthProvider): string {
    return path.join(this.tokensDir, `${provider}.token.json`);
  }

  /**
   * Get encrypted file path for a provider's token
   */
  private getEncryptedTokenPath(provider: OAuthProvider): string {
    return path.join(this.tokensDir, `${provider}.token.enc.json`);
  }

  /**
   * Encrypt token data using SOPS
   */
  private async encryptWithSOPS(data: string, filePath: string): Promise<void> {
    if (!this.SOPS_AVAILABLE) {
      // DEV MODE: Store unencrypted with warning
      await fs.writeFile(filePath.replace('.enc.json', '.dev.json'), data, 'utf-8');
      return;
    }

    try {
      // Write plaintext temporarily
      const tempPath = `${filePath}.tmp`;
      await fs.writeFile(tempPath, data, 'utf-8');

      // Encrypt with SOPS
      await execAsync(`sops --encrypt --input-type json --output-type json ${tempPath} > ${filePath}`);

      // Remove plaintext
      await fs.unlink(tempPath);
    } catch (error) {
      throw new OAuthError(
        OAuthErrorType.NETWORK_ERROR,
        `SOPS encryption failed: ${error}`,
        undefined,
        error as Error
      );
    }
  }

  /**
   * Decrypt token data using SOPS
   */
  private async decryptWithSOPS(filePath: string): Promise<string> {
    if (!this.SOPS_AVAILABLE) {
      // DEV MODE: Read unencrypted file
      const devPath = filePath.replace('.enc.json', '.dev.json');
      try {
        return await fs.readFile(devPath, 'utf-8');
      } catch {
        throw new OAuthError(
          OAuthErrorType.NETWORK_ERROR,
          'Token file not found (DEV mode)',
          undefined
        );
      }
    }

    try {
      const { stdout } = await execAsync(`sops --decrypt ${filePath}`);
      return stdout;
    } catch (error) {
      throw new OAuthError(
        OAuthErrorType.NETWORK_ERROR,
        `SOPS decryption failed: ${error}`,
        undefined,
        error as Error
      );
    }
  }

  /**
   * Store a token securely
   */
  public async storeToken(token: OAuthToken): Promise<TokenStorageResult> {
    try {
      await this.ensureTokensDir();

      const storage: EncryptedTokenStorage = {
        encrypted: JSON.stringify(token),
        provider: token.provider,
        storedAt: Date.now(),
        sopsVersion: this.SOPS_AVAILABLE ? 'sops-encrypted' : 'dev-unencrypted',
      };

      const filePath = this.getEncryptedTokenPath(token.provider);
      await this.encryptWithSOPS(JSON.stringify(storage, null, 2), filePath);

      // Update cache
      this.cache.set(token.provider, token);

      return {
        success: true,
        metadata: {
          provider: token.provider,
          storedAt: storage.storedAt,
          expiresAt: token.expiresAt,
          hasRefreshToken: !!token.refreshToken,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Load a token from storage
   */
  public async loadToken(provider: OAuthProvider): Promise<OAuthToken | null> {
    // Check cache first
    if (this.cache.has(provider)) {
      return this.cache.get(provider)!;
    }

    try {
      const filePath = this.getEncryptedTokenPath(provider);

      // Check if file exists
      try {
        await fs.access(filePath);
      } catch {
        // Try dev file if encrypted doesn't exist
        const devPath = filePath.replace('.enc.json', '.dev.json');
        try {
          await fs.access(devPath);
        } catch {
          return null; // No token stored
        }
      }

      const decrypted = await this.decryptWithSOPS(filePath);
      const storage: EncryptedTokenStorage = JSON.parse(decrypted);
      const token: OAuthToken = JSON.parse(storage.encrypted);

      // Update cache
      this.cache.set(provider, token);

      return token;
    } catch (error) {
      console.error(`Failed to load token for ${provider}:`, error);
      return null;
    }
  }

  /**
   * Delete a stored token
   */
  public async deleteToken(provider: OAuthProvider): Promise<TokenStorageResult> {
    try {
      const filePath = this.getEncryptedTokenPath(provider);
      const devPath = filePath.replace('.enc.json', '.dev.json');

      // Try to delete both encrypted and dev files
      try {
        await fs.unlink(filePath);
      } catch {
        // Ignore if doesn't exist
      }

      try {
        await fs.unlink(devPath);
      } catch {
        // Ignore if doesn't exist
      }

      // Remove from cache
      this.cache.delete(provider);

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * List all stored tokens (metadata only)
   */
  public async listTokens(): Promise<TokenStorageMetadata[]> {
    try {
      await this.ensureTokensDir();
      const files = await fs.readdir(this.tokensDir);
      const metadata: TokenStorageMetadata[] = [];

      for (const file of files) {
        if (file.endsWith('.enc.json') || file.endsWith('.dev.json')) {
          const provider = file.split('.')[0] as OAuthProvider;
          const filePath = path.join(this.tokensDir, file);

          try {
            const decrypted = await this.decryptWithSOPS(filePath);
            const storage: EncryptedTokenStorage = JSON.parse(decrypted);
            const token: OAuthToken = JSON.parse(storage.encrypted);

            metadata.push({
              provider: token.provider,
              storedAt: storage.storedAt,
              expiresAt: token.expiresAt,
              hasRefreshToken: !!token.refreshToken,
            });
          } catch (error) {
            console.error(`Failed to read token metadata for ${provider}:`, error);
          }
        }
      }

      return metadata;
    } catch (error) {
      console.error('Failed to list tokens:', error);
      return [];
    }
  }

  /**
   * Check if a token exists
   */
  public async hasToken(provider: OAuthProvider): Promise<boolean> {
    if (this.cache.has(provider)) {
      return true;
    }

    try {
      const filePath = this.getEncryptedTokenPath(provider);
      const devPath = filePath.replace('.enc.json', '.dev.json');

      try {
        await fs.access(filePath);
        return true;
      } catch {
        try {
          await fs.access(devPath);
          return true;
        } catch {
          return false;
        }
      }
    } catch {
      return false;
    }
  }

  /**
   * Clear all cached tokens (does not delete files)
   */
  public clearCache(): void {
    this.cache.clear();
  }

  /**
   * Get cached token without loading from disk
   */
  public getCachedToken(provider: OAuthProvider): OAuthToken | undefined {
    return this.cache.get(provider);
  }
}