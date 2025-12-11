use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use argon2::{
    password_hash::rand_core::OsRng,
    Argon2,
};
use rand::RngCore;
use thiserror::Error;
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Error, Debug)]
pub enum CryptoError {
    #[error("Encryption failed")]
    EncryptionError,
    #[error("Decryption failed")]
    DecryptionError,
    #[error("Key derivation failed")]
    KdfError,
    #[error("Invalid password")]
    InvalidPassword,
}

pub const SALT_LEN: usize = 16;
pub const NONCE_LEN: usize = 12;
pub const KEY_LEN: usize = 32;

#[derive(Zeroize, ZeroizeOnDrop)]
pub struct SecretKey([u8; KEY_LEN]);

impl SecretKey {
    pub fn as_bytes(&self) -> &[u8; KEY_LEN] {
        &self.0
    }
}

pub struct VaultCrypto;

impl VaultCrypto {
    /// Derives a 32-byte key from a password and salt using Argon2id
    pub fn derive_key(password: &str, salt: &[u8]) -> Result<SecretKey, CryptoError> {
        let mut key = [0u8; KEY_LEN];
        
        let argon2 = Argon2::default();
        argon2
            .hash_password_into(password.as_bytes(), salt, &mut key)
            .map_err(|_| CryptoError::KdfError)?;

        Ok(SecretKey(key))
    }

    /// Generates a random salt
    pub fn generate_salt() -> [u8; SALT_LEN] {
        let mut salt = [0u8; SALT_LEN];
        OsRng.fill_bytes(&mut salt);
        salt
    }

    /// Encrypts data using AES-256-GCM
    /// Returns (nonce + ciphertext)
    pub fn encrypt(data: &[u8], key: &SecretKey) -> Result<Vec<u8>, CryptoError> {
        let cipher = Aes256Gcm::new(key.as_bytes().into());
        let mut nonce_bytes = [0u8; NONCE_LEN];
        OsRng.fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = cipher
            .encrypt(nonce, data)
            .map_err(|_| CryptoError::EncryptionError)?;

        // Prepend nonce to ciphertext for storage
        let mut result = Vec::with_capacity(NONCE_LEN + ciphertext.len());
        result.extend_from_slice(&nonce_bytes);
        result.extend_from_slice(&ciphertext);

        Ok(result)
    }

    /// Decrypts data using AES-256-GCM
    /// Expects (nonce + ciphertext)
    pub fn decrypt(encrypted_data: &[u8], key: &SecretKey) -> Result<Vec<u8>, CryptoError> {
        if encrypted_data.len() < NONCE_LEN {
            return Err(CryptoError::DecryptionError);
        }

        let (nonce_bytes, ciphertext) = encrypted_data.split_at(NONCE_LEN);
        let nonce = Nonce::from_slice(nonce_bytes);
        let cipher = Aes256Gcm::new(key.as_bytes().into());

        cipher
            .decrypt(nonce, ciphertext)
            .map_err(|_| CryptoError::DecryptionError)
    }
}

