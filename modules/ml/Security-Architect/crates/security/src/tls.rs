use crate::{Result, SecurityError};
use rustls::{ClientConfig, ServerConfig, RootCertStore};
use rustls_pemfile::{certs, pkcs8_private_keys};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::sync::Arc;

/// TLS configuration builder for secure connections
pub struct TlsConfigBuilder {
    root_certs: RootCertStore,
    client_cert_chain: Option<Vec<rustls::pki_types::CertificateDer<'static>>>,
    client_key: Option<rustls::pki_types::PrivateKeyDer<'static>>,
    verify_server: bool,
    verify_client: bool,
}

impl TlsConfigBuilder {
    pub fn new() -> Self {
        Self {
            root_certs: RootCertStore::empty(),
            client_cert_chain: None,
            client_key: None,
            verify_server: true,
            verify_client: false,
        }
    }
    
    /// Add system root certificates
    pub fn with_system_roots(mut self) -> Result<Self> {
        // Add native root certificates
        let mut roots = RootCertStore::empty();
        let certs_result = rustls_native_certs::load_native_certs();
        for cert in certs_result.certs {
            roots.add(cert).map_err(|e| {
                SecurityError::Certificate(format!("Failed to add root cert: {}", e))
            })?;
        }
        if let Some(err) = certs_result.errors.first() {
            tracing::warn!("Some native certs failed to load: {}", err);
        }
        self.root_certs = roots;
        Ok(self)
    }
    
    /// Add custom CA certificate
    pub fn with_ca_cert(mut self, ca_path: impl AsRef<Path>) -> Result<Self> {
        let file = File::open(ca_path.as_ref()).map_err(|e| {
            SecurityError::Certificate(format!("Failed to open CA cert: {}", e))
        })?;
        let mut reader = BufReader::new(file);
        
        let certs = certs(&mut reader)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| {
                SecurityError::Certificate(format!("Failed to parse CA cert: {}", e))
            })?;
        
        for cert in certs {
            self.root_certs.add(cert).map_err(|e| {
                SecurityError::Certificate(format!("Failed to add CA cert: {}", e))
            })?;
        }
        
        Ok(self)
    }
    
    /// Configure client certificate for mutual TLS
    pub fn with_client_cert(
        mut self,
        cert_path: impl AsRef<Path>,
        key_path: impl AsRef<Path>,
    ) -> Result<Self> {
        // Load certificate chain
        let cert_file = File::open(cert_path.as_ref()).map_err(|e| {
            SecurityError::Certificate(format!("Failed to open client cert: {}", e))
        })?;
        let mut cert_reader = BufReader::new(cert_file);
        let cert_chain = certs(&mut cert_reader)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| {
                SecurityError::Certificate(format!("Failed to parse client cert: {}", e))
            })?;
        
        // Load private key
        let key_file = File::open(key_path.as_ref()).map_err(|e| {
            SecurityError::Certificate(format!("Failed to open client key: {}", e))
        })?;
        let mut key_reader = BufReader::new(key_file);
        let keys = pkcs8_private_keys(&mut key_reader)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| {
                SecurityError::Certificate(format!("Failed to parse private key: {}", e))
            })?;
        
        let key = keys.into_iter().next().ok_or_else(|| {
            SecurityError::Certificate("No private key found".to_string())
        })?;
        
        self.client_cert_chain = Some(cert_chain);
        self.client_key = Some(rustls::pki_types::PrivateKeyDer::Pkcs8(key));
        
        Ok(self)
    }
    
    /// Disable server certificate verification (NOT RECOMMENDED for production)
    pub fn disable_server_verification(mut self) -> Self {
        self.verify_server = false;
        self
    }
    
    /// Enable client certificate verification (for server configs)
    pub fn require_client_cert(mut self) -> Self {
        self.verify_client = true;
        self
    }
    
    /// Build client configuration
    pub fn build_client_config(self) -> Result<Arc<ClientConfig>> {
        let config = if self.verify_server {
            // Normal path with server verification
            let builder = ClientConfig::builder()
                .with_root_certificates(self.root_certs);
            
            if let (Some(cert_chain), Some(key)) = (self.client_cert_chain, self.client_key) {
                builder.with_client_auth_cert(cert_chain, key).map_err(|e| {
                    SecurityError::Certificate(format!("Failed to configure client auth: {}", e))
                })?
            } else {
                builder.with_no_client_auth()
            }
        } else {
            // Dangerous path without server verification
            let builder = ClientConfig::builder()
                .dangerous()
                .with_custom_certificate_verifier(Arc::new(NoVerifier));
            
            if let (Some(cert_chain), Some(key)) = (self.client_cert_chain, self.client_key) {
                builder.with_client_auth_cert(cert_chain, key).map_err(|e| {
                    SecurityError::Certificate(format!("Failed to configure client auth: {}", e))
                })?
            } else {
                builder.with_no_client_auth()
            }
        };
        
        Ok(Arc::new(config))
    }
    
    /// Build server configuration
    pub fn build_server_config(
        self,
        cert_path: impl AsRef<Path>,
        key_path: impl AsRef<Path>,
    ) -> Result<Arc<ServerConfig>> {
        // Load server certificate
        let cert_file = File::open(cert_path.as_ref()).map_err(|e| {
            SecurityError::Certificate(format!("Failed to open server cert: {}", e))
        })?;
        let mut cert_reader = BufReader::new(cert_file);
        let cert_chain = certs(&mut cert_reader)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| {
                SecurityError::Certificate(format!("Failed to parse server cert: {}", e))
            })?;
        
        // Load server key
        let key_file = File::open(key_path.as_ref()).map_err(|e| {
            SecurityError::Certificate(format!("Failed to open server key: {}", e))
        })?;
        let mut key_reader = BufReader::new(key_file);
        let keys = pkcs8_private_keys(&mut key_reader)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| {
                SecurityError::Certificate(format!("Failed to parse server key: {}", e))
            })?;
        
        let key = keys.into_iter().next().ok_or_else(|| {
            SecurityError::Certificate("No private key found".to_string())
        })?;
        
        let config = if self.verify_client {
            let verifier = rustls::server::WebPkiClientVerifier::builder(Arc::new(self.root_certs))
                .build()
                .map_err(|e| SecurityError::Certificate(format!("Failed to build verifier: {}", e)))?;
            
            ServerConfig::builder()
                .with_client_cert_verifier(verifier)
                .with_single_cert(cert_chain, rustls::pki_types::PrivateKeyDer::Pkcs8(key))
                .map_err(|e| SecurityError::Certificate(format!("Failed to configure server: {}", e)))?
        } else {
            ServerConfig::builder()
                .with_no_client_auth()
                .with_single_cert(cert_chain, rustls::pki_types::PrivateKeyDer::Pkcs8(key))
                .map_err(|e| SecurityError::Certificate(format!("Failed to configure server: {}", e)))?
        };
        
        Ok(Arc::new(config))
    }
}

impl Default for TlsConfigBuilder {
    fn default() -> Self {
        Self::new()
    }
}

/// No-op certificate verifier (INSECURE - only for development)
#[derive(Debug)]
struct NoVerifier;

impl rustls::client::danger::ServerCertVerifier for NoVerifier {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::pki_types::CertificateDer<'_>,
        _intermediates: &[rustls::pki_types::CertificateDer<'_>],
        _server_name: &rustls::pki_types::ServerName<'_>,
        _ocsp_response: &[u8],
        _now: rustls::pki_types::UnixTime,
    ) -> std::result::Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        tracing::warn!("Server certificate verification disabled - INSECURE!");
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }
    
    fn verify_tls12_signature(
        &self,
        _message: &[u8],
        _cert: &rustls::pki_types::CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct,
    ) -> std::result::Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }
    
    fn verify_tls13_signature(
        &self,
        _message: &[u8],
        _cert: &rustls::pki_types::CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct,
    ) -> std::result::Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }
    
    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        vec![
            rustls::SignatureScheme::RSA_PKCS1_SHA256,
            rustls::SignatureScheme::ECDSA_NISTP256_SHA256,
            rustls::SignatureScheme::ED25519,
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_tls_config_builder() {
        let builder = TlsConfigBuilder::new();
        assert!(!builder.verify_client);
        assert!(builder.verify_server);
    }
    
    #[test]
    fn test_disable_verification() {
        let builder = TlsConfigBuilder::new().disable_server_verification();
        assert!(!builder.verify_server);
    }
}
