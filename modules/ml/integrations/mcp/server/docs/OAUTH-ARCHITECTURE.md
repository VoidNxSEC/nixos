# OAuth Authentication Architecture

## Overview

The SecureLLM Bridge MCP server implements OAuth 2.0 authentication with PKCE for secure third-party service integration.

## Architecture

### Core Components

1. **OAuthManager** (Base Class)
   - Abstract base for all OAuth providers
   - Handles authorization URL generation
   - Manages token exchange and refresh
   - State management for CSRF protection
   - PKCE support for enhanced security

2. **Provider Implementations** (Phase 2.3)
   - GitHubOAuthProvider
   - GitLabOAuthProvider
   - GoogleOAuthProvider

3. **Token Storage** (Phase 2.2)
   - SOPS-encrypted token persistence
   - Automatic token refresh
   - Secure key rotation

4. **Session Management** (Phase 2.5)
   - Multi-provider session handling
   - Token lifecycle management
   - Automatic cleanup

## OAuth Flow

```
┌─────────┐                                  ┌──────────┐
│  User   │                                  │ Provider │
└────┬────┘                                  └────┬─────┘
     │                                            │
     │ 1. Request auth URL                        │
     │ ────────────────────────►                  │
     │                           [Generate state] │
     │                           [Generate PKCE]  │
     │ ◄────────────────────────                  │
     │ 2. Authorization URL                       │
     │                                            │
     │ 3. User authorizes (browser)              │
     │ ─────────────────────────────────────────►│
     │                                            │
     │ 4. Callback with code + state             │
     │ ◄─────────────────────────────────────────│
     │                                            │
     │ 5. Exchange code for token                │
     │ ────────────────────────►                  │
     │                           [Verify state]   │
     │                           [Exchange code]  │
     │ ◄────────────────────────                  │
     │ 6. Access token                            │
     │                                            │
     │ 7. Store token (SOPS)                     │
     │ ────────────────────────►                  │
     │                           [Encrypt token]  │
     │                           [Save to disk]   │
     │                                            │
```

## Security Features

### PKCE (Proof Key for Code Exchange)
- Protects against authorization code interception
- SHA-256 code challenge
- Default enabled for all flows

### CSRF Protection
- Cryptographically random state parameter
- 10-minute state expiration
- Single-use states

### Token Security
- SOPS encryption at rest
- In-memory token caching
- Automatic refresh before expiry
- Secure key rotation support

## Configuration

Each provider requires:
```typescript
{
  clientId: string;        // From provider OAuth app
  clientSecret: string;    // Encrypted in SOPS
  authorizationUrl: string;
  tokenUrl: string;
  scopes: string[];
  redirectUri: string;     // Your callback URL
}
```

## Token Storage

Tokens are stored encrypted using SOPS:
```
secrets/oauth/
  github.token.enc
  gitlab.token.enc
  google.token.enc
```

## Usage Example (Phase 2.4)

```typescript
// Generate authorization URL
const authUrl = oauthManager.buildAuthorizationUrl();
console.log(`Visit: ${authUrl}`);

// After user authorizes, exchange code
const token = await oauthManager.exchangeToken({
  code: '...',
  state: '...',
  codeVerifier: '...'
});

// Use token
const userInfo = await oauthManager.getUserInfo(token);

// Token auto-refreshes when needed
if (oauthManager.isTokenExpired(token)) {
  const newToken = await oauthManager.refreshToken(token);
}
```

## Next Steps

- Phase 2.2: SOPS token storage integration
- Phase 2.3: Provider implementations (GitHub, GitLab, Google)
- Phase 2.4: MCP tool `oauth_authenticate`
- Phase 2.5: Session management system
- Phase 2.6: Documentation and usage examples