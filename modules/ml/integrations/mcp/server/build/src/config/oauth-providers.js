/**
 * OAuth Provider Configurations
 */
/**
 * Default OAuth scopes per provider
 */
export const DEFAULT_OAUTH_SCOPES = {
    github: ['user:email', 'read:user', 'repo'],
    gitlab: ['read_user', 'read_api', 'read_repository'],
    google: ['openid', 'email', 'profile'],
};
/**
 * OAuth provider display names
 */
export const OAUTH_PROVIDER_NAMES = {
    github: 'GitHub',
    gitlab: 'GitLab',
    google: 'Google',
};
/**
 * OAuth provider documentation URLs
 */
export const OAUTH_PROVIDER_DOCS = {
    github: 'https://docs.github.com/en/apps/oauth-apps',
    gitlab: 'https://docs.gitlab.com/ee/api/oauth2.html',
    google: 'https://developers.google.com/identity/protocols/oauth2',
};
//# sourceMappingURL=oauth-providers.js.map