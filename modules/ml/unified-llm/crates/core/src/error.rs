use thiserror::Error;

/// Core error types for SecureLLM Bridge
#[derive(Error, Debug)]
pub enum Error {
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Provider error: {provider} - {message}")]
    Provider {
        provider: String,
        message: String,
    },
    
    #[error("Authentication error: {0}")]
    Authentication(String),
    
    #[error("Authorization error: {0}")]
    Authorization(String),
    
    #[error("Rate limit exceeded: {0}")]
    RateLimit(String),
    
    #[error("Invalid request: {0}")]
    InvalidRequest(String),
    
    #[error("Invalid response: {0}")]
    InvalidResponse(String),
    
    #[error("Network error: {0}")]
    Network(String),
    
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    #[error("Security error: {0}")]
    Security(String),
    
    #[error("Audit log error: {0}")]
    Audit(String),
    
    #[error("Sanitization error: {0}")]
    Sanitization(String),
    
    #[error("Certificate error: {0}")]
    Certificate(String),
    
    #[error("Cryptography error: {0}")]
    Crypto(String),
    
    #[error("Secret access error: {0}")]
    SecretAccess(String),
    
    #[error("Sandbox error: {0}")]
    Sandbox(String),
    
    #[error("Timeout error: {0}")]
    Timeout(String),
    
    #[error("Model not found: {0}")]
    ModelNotFound(String),
    
    #[error("Provider not available: {0}")]
    ProviderUnavailable(String),
    
    #[error("Internal error: {0}")]
    Internal(String),
    
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl Error {
    /// Check if error is retryable
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            Error::Network(_) 
            | Error::Timeout(_) 
            | Error::ProviderUnavailable(_)
            | Error::RateLimit(_)
        )
    }
    
    /// Check if error should be logged as security incident
    pub fn is_security_incident(&self) -> bool {
        matches!(
            self,
            Error::Security(_) 
            | Error::Authentication(_) 
            | Error::Authorization(_)
        )
    }
    
    /// Get error severity level
    pub fn severity(&self) -> ErrorSeverity {
        match self {
            Error::Security(_) | Error::Authentication(_) | Error::Authorization(_) => {
                ErrorSeverity::Critical
            }
            Error::Provider { .. } | Error::Network(_) | Error::Timeout(_) => {
                ErrorSeverity::High
            }
            Error::RateLimit(_) | Error::InvalidRequest(_) => {
                ErrorSeverity::Medium
            }
            Error::Config(_) | Error::ModelNotFound(_) => {
                ErrorSeverity::Low
            }
            _ => ErrorSeverity::Medium,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorSeverity {
    Critical,
    High,
    Medium,
    Low,
}

pub type Result<T> = std::result::Result<T, Error>;

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_error_retryable() {
        let err = Error::Network("Connection failed".to_string());
        assert!(err.is_retryable());
        
        let err = Error::InvalidRequest("Bad format".to_string());
        assert!(!err.is_retryable());
    }
    
    #[test]
    fn test_error_security_incident() {
        let err = Error::Security("TLS verification failed".to_string());
        assert!(err.is_security_incident());
        
        let err = Error::RateLimit("Too many requests".to_string());
        assert!(!err.is_security_incident());
    }
    
    #[test]
    fn test_error_severity() {
        let err = Error::Security("Critical issue".to_string());
        assert_eq!(err.severity(), ErrorSeverity::Critical);
        
        let err = Error::Config("Missing field".to_string());
        assert_eq!(err.severity(), ErrorSeverity::Low);
    }
}
