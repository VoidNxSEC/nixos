// SecureLLM Bridge - Security Module
// Provides cryptographic primitives and security features

pub mod tls;
pub mod crypto;
pub mod secrets;
pub mod sandbox;

use thiserror::Error;

#[derive(Error, Debug)]
pub enum SecurityError {
    #[error("TLS error: {0}")]
    Tls(String),
    
    #[error("Cryptographic error: {0}")]
    Crypto(String),
    
    #[error("Key management error: {0}")]
    KeyManagement(String),
    
    #[error("Certificate error: {0}")]
    Certificate(String),
    
    #[error("Sandbox violation: {0}")]
    Sandbox(String),
    
    #[error("Secret access error: {0}")]
    SecretAccess(String),
    
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, SecurityError>;

/// Security context for a request
#[derive(Debug, Clone)]
pub struct SecurityContext {
    /// TLS peer certificate info (if applicable)
    pub peer_cert: Option<PeerCertInfo>,
    
    /// Whether the connection is encrypted
    pub encrypted: bool,
    
    /// Authentication method used
    pub auth_method: AuthMethod,
    
    /// Security level enforced
    pub security_level: SecurityLevel,
}

#[derive(Debug, Clone)]
pub struct PeerCertInfo {
    pub subject: String,
    pub issuer: String,
    pub fingerprint: String,
    pub valid_until: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthMethod {
    None,
    ApiKey,
    MutualTls,
    OAuth2,
    Custom,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SecurityLevel {
    /// Minimal security (for development only)
    Low,
    
    /// Standard security
    Medium,
    
    /// High security (recommended for production)
    High,
    
    /// Maximum security (for sensitive data)
    Critical,
}

impl SecurityLevel {
    /// Check if TLS is required for this security level
    pub fn requires_tls(&self) -> bool {
        matches!(self, SecurityLevel::High | SecurityLevel::Critical)
    }
    
    /// Check if mutual TLS is required
    pub fn requires_mutual_tls(&self) -> bool {
        matches!(self, SecurityLevel::Critical)
    }
    
    /// Check if audit logging is required
    pub fn requires_audit(&self) -> bool {
        *self >= SecurityLevel::Medium
    }
    
    /// Check if data encryption at rest is required
    pub fn requires_encryption_at_rest(&self) -> bool {
        *self >= SecurityLevel::High
    }
}

impl Default for SecurityContext {
    fn default() -> Self {
        Self {
            peer_cert: None,
            encrypted: false,
            auth_method: AuthMethod::None,
            security_level: SecurityLevel::Medium,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_security_level_requirements() {
        assert!(!SecurityLevel::Low.requires_tls());
        assert!(!SecurityLevel::Medium.requires_tls());
        assert!(SecurityLevel::High.requires_tls());
        assert!(SecurityLevel::Critical.requires_tls());
        
        assert!(!SecurityLevel::High.requires_mutual_tls());
        assert!(SecurityLevel::Critical.requires_mutual_tls());
    }
    
    #[test]
    fn test_security_level_ordering() {
        assert!(SecurityLevel::Critical > SecurityLevel::High);
        assert!(SecurityLevel::High > SecurityLevel::Medium);
        assert!(SecurityLevel::Medium > SecurityLevel::Low);
    }
}
