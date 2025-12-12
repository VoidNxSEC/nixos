# GitHub OAuth Provider

Complete guide for GitHub OAuth integration in SecureLLM Bridge MCP.

## Overview

The GitHub OAuth Provider enables secure authentication and API access to GitHub resources.

## Setup

### 1. Create GitHub OAuth App

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click "New OAuth App"
3. Fill in:
   - **Application name**: SecureLLM Bridge MCP
   - **Homepage URL**: `http://localhost:3000`
   - **Authorization callback URL**: `http://localhost:3000/callback`
4. Save and note your **Client ID** and **Client Secret**

### 2. Store Credentials Securely

```bash
# Create SOPS-encrypted config
echo "GITHUB_CLIENT_ID=your_client_id_here" > secrets/oauth/github.env
echo "GITHUB_CLIENT_SECRET=your_client_secret_here" >> secrets/oauth/github.env

# Encrypt with SOPS
sops --encrypt secrets/oauth/github.env > secrets/oauth/github.env.enc

# Remove plaintext
rm secrets/oauth/github.env
```

### 3. Initialize Provider

```typescript
import { GitHubOAuthProvider } from './auth/providers/github-provider.js';

const github = GitHubOAuthProvider.createDefault(
  process.env.GITHUB_CLIENT_ID!,
  process.env.GITHUB_CLIENT_SECRET!,
  'http://localhost:3000/callback',
  ['user:email', 'read:user', 'repo']
);
```

## OAuth Flow

### Step 1: Generate Authorization URL

```typescript
const authUrl = github.buildAuthorizationUrl();
console.log(`Visit: ${authUrl}`);
// User visits URL and authorizes app
```

### Step 2: Exchange Code for Token

```typescript
// Receive code and state from OAuth callback
const token = await github.exchangeToken({
  code: req.query.code,
  state: req.query.state,
});
```

### Step 3: Store Token

```typescript
import { TokenStorageManager } from './auth/token-storage.js';

const storage = new TokenStorageManager();
await storage.storeToken(token);
```

### Step 4: Use Token

```typescript
// Validate token
const isValid = await github.validateToken(token);

// Get user info
const user = await github.getUserInfo(token);
console.log(`Authenticated as: ${user.login}`);
```

## Available Scopes

| Scope | Description |
|-------|-------------|
| `repo` | Full control of private repositories |
| `repo:status` | Access commit status |
| `public_repo` | Access public repositories |
| `user` | Read/write user profile info |
| `user:email` | Access user email addresses |
| `read:user` | Read user profile data |
| `gist` | Create/manage gists |
| `workflow` | Update GitHub Action workflows |

## API Methods

### User Information

```typescript
// Get authenticated user
const user = await github.getUserInfo(token);

console.log({
  username: user.login,
  name: user.name,
  email: user.email,
  avatar: user.avatar_url,
});
```

### Repositories

```typescript
// List user repositories
const repos = await github.listRepositories(token, {
  type: 'owner',     // all, owner, public, private, member
  sort: 'updated',   // created, updated, pushed, full_name
  per_page: 30,
  page: 1,
});

// Get specific repository
const repo = await github.getRepository(token, 'owner', 'repo-name');
```

### Gists

```typescript
// Create a gist
const gist = await github.createGist(
  token,
  {
    'example.js': {
      content: 'console.log("Hello from OAuth!");',
    },
    'readme.md': {
      content: '# Example Gist\nCreated via API',
    },
  },
  'Example Gist',
  false // private
);

console.log(`Gist URL: ${gist.html_url}`);
```

### Generic API Requests

```typescript
// Make any GitHub API request
const issues = await github.makeRequest(
  token,
  '/repos/owner/repo/issues?state=open'
);

// POST request
const issue = await github.makeRequest(
  token,
  '/repos/owner/repo/issues',
  {
    method: 'POST',
    body: JSON.stringify({
      title: 'Bug report',
      body: 'Found via OAuth integration',
    }),
  }
);
```

## Token Management

### Check Token Expiration

```typescript
if (github.isTokenExpired(token)) {
  console.log('Token expired, refreshing...');
  const newToken = await github.refreshToken(token);
  await storage.storeToken(newToken);
}
```

### Validate Token

```typescript
const isValid = await github.validateToken(token);
if (!isValid) {
  console.log('Token invalid, need to re-authenticate');
}
```

### Delete Token

```typescript
await storage.deleteToken('github');
console.log('Token deleted');
```

## Error Handling

```typescript
import { OAuthError, OAuthErrorType } from './types/oauth.js';

try {
  const token = await github.exchangeToken({ code, state });
} catch (error) {
  if (error instanceof OAuthError) {
    switch (error.type) {
      case OAuthErrorType.INVALID_STATE:
        console.error('CSRF attack detected or state expired');
        break;
      case OAuthErrorType.PROVIDER_ERROR:
        console.error('GitHub rejected the request:', error.message);
        break;
      case OAuthErrorType.NETWORK_ERROR:
        console.error('Network issue:', error.message);
        break;
    }
  }
}
```

## Rate Limiting

GitHub API has rate limits:
- **Authenticated**: 5,000 requests per hour
- **Unauthenticated**: 60 requests per hour

Check rate limit:

```typescript
const rateLimit = await github.makeRequest(token, '/rate_limit');
console.log('Remaining requests:', rateLimit.rate.remaining);
console.log('Resets at:', new Date(rateLimit.rate.reset * 1000));
```

## Best Practices

1. **Always use PKCE** (enabled by default)
2. **Request minimum scopes** needed
3. **Store tokens with SOPS encryption**
4. **Check token expiration** before use
5. **Handle rate limits** gracefully
6. **Validate tokens** periodically

## Security Considerations

- Never log full access tokens
- Rotate tokens regularly
- Use refresh tokens when available
- Monitor for unauthorized access
- Implement token revocation

## Troubleshooting

### "Invalid state" error
- State expired (10-minute timeout)
- CSRF attack detected
- Solution: Generate new authorization URL

### "Token validation failed"
- Token expired
- Token revoked by user
- Solution: Request new authorization

### "Rate limit exceeded"
- Too many API requests
- Solution: Implement backoff, cache results

## Next Steps

- [Phase 2.4: MCP Tool Integration](../IMPLEMENTATION-ROADMAP.md#phase-24)
- [Phase 2.5: Session Management](../IMPLEMENTATION-ROADMAP.md#phase-25)
- [OAuth Architecture](../OAUTH-ARCHITECTURE.md)