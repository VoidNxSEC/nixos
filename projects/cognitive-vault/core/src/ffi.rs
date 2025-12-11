use crate::crypto::{VaultCrypto, SALT_LEN};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::slice;

// ... existing vault_hello ...

#[no_mangle]
pub unsafe extern "C" fn vault_encrypt(
    password: *const c_char,
    data: *const u8,
    data_len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if password.is_null() || data.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }

    let c_pass = CStr::from_ptr(password);
    let pass_str = match c_pass.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let input_data = slice::from_raw_parts(data, data_len);

    // 1. Generate Salt
    let salt = VaultCrypto::generate_salt();

    // 2. Derive Key
    let key = match VaultCrypto::derive_key(pass_str, &salt) {
        Ok(k) => k,
        Err(_) => return std::ptr::null_mut(),
    };

    // 3. Encrypt
    let encrypted = match VaultCrypto::encrypt(input_data, &key) {
        Ok(enc) => enc,
        Err(_) => return std::ptr::null_mut(),
    };

    // 4. Concat Salt (16) + Encrypted (Nonce 12 + Ciphertext)
    let mut result = Vec::with_capacity(salt.len() + encrypted.len());
    result.extend_from_slice(&salt);
    result.extend_from_slice(&encrypted);

    *out_len = result.len();
    
    let ptr = result.as_mut_ptr();
    std::mem::forget(result); // Leak to transfer ownership
    ptr
}

#[no_mangle]
pub unsafe extern "C" fn vault_decrypt(
    password: *const c_char,
    data: *const u8,
    data_len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if password.is_null() || data.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }

    if data_len < SALT_LEN {
        return std::ptr::null_mut();
    }

    let c_pass = CStr::from_ptr(password);
    let pass_str = match c_pass.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let input_blob = slice::from_raw_parts(data, data_len);
    let (salt, encrypted_data) = input_blob.split_at(SALT_LEN);

    // 1. Derive Key
    let key = match VaultCrypto::derive_key(pass_str, salt) {
        Ok(k) => k,
        Err(_) => return std::ptr::null_mut(),
    };

    // 2. Decrypt
    let mut decrypted = match VaultCrypto::decrypt(encrypted_data, &key) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };

    *out_len = decrypted.len();
    let ptr = decrypted.as_mut_ptr();
    std::mem::forget(decrypted);
    ptr
}

#[no_mangle]
pub unsafe extern "C" fn vault_free_bytes(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    let _ = Vec::from_raw_parts(ptr, len, len);
}

// ... existing free_string ...


/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// Must be called exactly once for each pointer returned by the library.
#[no_mangle]
pub unsafe extern "C" fn vault_free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    // Retake ownership and drop
    let _ = CString::from_raw(s);
}
