# OAuth Token Storage with SOPS

## Overview

OAuth tokens are encrypted at rest using SOPS (Secrets OPerationS) with AGE encryption.

## Architecture

### Storage Structure

```
secrets/oauth/
  github.token.enc.json     # GitHub token (SOPS-encrypted)
  gitlab.token.enc.json     # GitLab token (SOPS-encrypted)
  google.token.enc.json     # Google token (SOPS-encrypted)
```

### Encryption Flow

1. **Store Token**:
   - Token → JSON serialize
   - Wrap in `EncryptedTokenStorage`
   - Encrypt with SOPS using AGE key
   - Write to `{provider}.token.enc.json`
   - Cache in memory

2. **Load Token**:
   - Check in-memory cache first
   - If not cached, decrypt with SOPS
   - Parse and validate token
   - Cache for future use

3. **Delete Token**:
   - Remove encrypted file
   - Clear from cache

## Security Features

### SOPS Integration
- AGE encryption with host SSH key
- Automatic key rotation support
- Integration with existing NixOS SOPS setup

### In-Memory Caching
- Reduces disk I/O and SOPS calls
- Cleared on restart (ephemeral)
- No plaintext on disk (except during encryption)

### Development Mode
- Fallback when SOPS unavailable
- Stores as `.dev.json` (unencrypted)
- **NEVER use in production**

## Usage

```typescript
import { TokenStorageManager } from './auth/token-storage.js';

// Initialize
const storage = new TokenStorageManager('./secrets/oauth');

// Store token
const result = await storage.storeToken(oauthToken);
if (result.success) {
  console.log('Token stored:', result.metadata);
}

// Load token
const token = await storage.loadToken('github');
if (token) {
  console.log('Token loaded:', token.provider);
}

// List all tokens
const tokens = await storage.listTokens();
tokens.forEach(meta => {
  console.log(`${meta.provider}: expires ${meta.expiresAt}`);
});

// Delete token
await storage.deleteToken('github');
```

## SOPS Setup

### Prerequisites

1. **Install SOPS**:
   ```bash
   nix-shell -p sops
   ```

2. **Generate AGE Key** (if not exists):
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

3. **Configure .sops.yaml**:
   ```yaml
   creation_rules:
     - path_regex: secrets/oauth/.*\.token\.enc\.json$
       age: age1your_public_key_here
   ```

### Manual Operations

#### Encrypt Token
```bash
sops --encrypt --input-type json secrets/oauth/github.token.json > secrets/oauth/github.token.enc.json
```

#### Decrypt Token
```bash
sops --decrypt secrets/oauth/github.token.enc.json
```

#### Edit Token (in-place)
```bash
sops secrets/oauth/github.token.enc.json
```

## Best Practices

1. **Never Commit Plaintext**:
   - Add `*.token.json` to `.gitignore`
   - Only commit `.token.enc.json` files

2. **Rotate Tokens Regularly**:
   - Use refresh tokens when available
   - Re-authenticate periodically

3. **Monitor Expiration**:
   - Check `expiresAt` before use
   - Refresh proactively (5-minute buffer)

4. **Backup Encrypted Tokens**:
   - `.enc.json` files are safe to backup
   - Store AGE private key separately

## Error Handling

### SOPS Not Available
```typescript
// Falls back to dev mode automatically
// Warning logged: "SOPS not available - tokens will be stored unencrypted"
```

### Decryption Fails
```typescript
// Returns null
const token = await storage.loadToken('github');
if (!token) {
  // Token not found or decryption failed
}
```

### Permission Denied
```typescript
// Throws OAuthError with NETWORK_ERROR type
try {
  await storage.storeToken(token);
} catch (error) {
  if (error instanceof OAuthError) {
    console.error('Storage failed:', error.message);
  }
}
```

## Integration with OAuth Manager

See [`docs/OAUTH-ARCHITECTURE.md`](./OAUTH-ARCHITECTURE.md) for full OAuth flow with token storage.

## Next Steps

- Phase 2.3: Provider implementations will use TokenStorageManager
- Phase 2.5: Session management will handle automatic refresh
- Phase 2.6: Complete usage examples and guides