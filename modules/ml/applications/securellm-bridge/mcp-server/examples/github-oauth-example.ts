/**
 * GitHub OAuth Provider Usage Example
 * 
 * This example demonstrates:
 * 1. Creating a GitHub OAuth provider
 * 2. Generating authorization URL
 * 3. Exchanging code for token
 * 4. Fetching user info
 * 5. Making authenticated API requests
 * 6. Storing and loading tokens with SOPS
 */

import { GitHubOAuthProvider } from '../src/auth/providers/github-provider.js';
import { TokenStorageManager } from '../src/auth/token-storage.js';

async function main() {
  // Step 1: Create GitHub OAuth provider
  const github = GitHubOAuthProvider.createDefault(
    process.env.GITHUB_CLIENT_ID || 'your-client-id',
    process.env.GITHUB_CLIENT_SECRET || 'your-client-secret',
    'http://localhost:3000/callback',
    ['user:email', 'read:user', 'repo']
  );

  console.log('GitHub OAuth Provider initialized');

  // Step 2: Generate authorization URL
  const authUrl = github.buildAuthorizationUrl();
  console.log('\nAuthorization URL:');
  console.log(authUrl);
  console.log('\nVisit this URL in your browser and authorize the app');

  // Step 3: After user authorizes, exchange code for token
  // (In real app, this would come from OAuth callback)
  const code = 'authorization-code-from-callback';
  const state = 'state-from-callback';
  
  try {
    // Exchange code for token
    const token = await github.exchangeToken({ code, state });
    console.log('\nToken received successfully!');
    console.log('Access token:', token.accessToken.substring(0, 20) + '...');
    console.log('Expires at:', token.expiresAt ? new Date(token.expiresAt) : 'Never');

    // Step 4: Store token securely with SOPS
    const storage = new TokenStorageManager();
    const result = await storage.storeToken(token);
    
    if (result.success) {
      console.log('\nToken stored securely');
      console.log('Metadata:', result.metadata);
    }

    // Step 5: Validate token
    const isValid = await github.validateToken(token);
    console.log('\nToken valid:', isValid);

    // Step 6: Fetch user info
    const user = await github.getUserInfo(token);
    console.log('\nUser info:');
    console.log(`- Username: ${user.login}`);
    console.log(`- Name: ${user.name}`);
    console.log(`- Email: ${user.email}`);
    console.log(`- Profile: ${user.html_url}`);

    // Step 7: List user repositories
    const repos = await github.listRepositories(token, {
      type: 'owner',
      sort: 'updated',
      per_page: 5,
    });
    console.log(`\nRecent repositories (${repos.length}):`);
    repos.forEach((repo: any) => {
      console.log(`- ${repo.full_name} (${repo.description || 'No description'})`);
    });

    // Step 8: Create a gist
    const gist = await github.createGist(
      token,
      {
        'example.txt': {
          content: 'This is an example gist created via OAuth!',
        },
      },
      'Example OAuth Gist',
      false // private
    );
    console.log('\nGist created:');
    console.log(`- URL: ${gist.html_url}`);

    // Step 9: Load token later
    console.log('\n--- Simulating app restart ---');
    const loadedToken = await storage.loadToken('github');
    if (loadedToken) {
      console.log('Token loaded from storage successfully');
      
      // Check if token needs refresh
      if (github.isTokenExpired(loadedToken)) {
        console.log('Token expired, refreshing...');
        const newToken = await github.refreshToken(loadedToken);
        await storage.storeToken(newToken);
        console.log('Token refreshed and stored');
      } else {
        console.log('Token still valid');
      }
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

// Run example (commented out - uncomment to test)
// main().catch(console.error);

export { main as runGitHubOAuthExample };