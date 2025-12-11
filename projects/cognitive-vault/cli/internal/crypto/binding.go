package crypto

/*
#cgo LDFLAGS: -lvault_core
#include <stdlib.h>
#include <stdint.h>
#include "vault_core.h"
*/
import "C"

import (
	"errors"
	"unsafe"
)

// Encrypt encrypts data using a key derived from password (AES-256-GCM + Argon2id).
// Returns a byte slice containing [Salt(16) | Nonce(12) | Ciphertext(...) | Tag(16)].
func Encrypt(password string, data []byte) ([]byte, error) {
	cPassword := C.CString(password)
	defer C.free(unsafe.Pointer(cPassword))

	cData := C.CBytes(data)
	defer C.free(cData)

	var outLen C.size_t
	ptr := C.vault_encrypt(cPassword, (*C.uint8_t)(cData), C.size_t(len(data)), &outLen)

	if ptr == nil {
		return nil, errors.New("encryption failed in core")
	}
	defer C.vault_free_bytes(ptr, outLen)

	result := C.GoBytes(unsafe.Pointer(ptr), C.int(outLen))
	return result, nil
}

// Decrypt decrypts data encrypted by Encrypt.
func Decrypt(password string, data []byte) ([]byte, error) {
	cPassword := C.CString(password)
	defer C.free(unsafe.Pointer(cPassword))

	cData := C.CBytes(data)
	defer C.free(cData)

	var outLen C.size_t
	ptr := C.vault_decrypt(cPassword, (*C.uint8_t)(cData), C.size_t(len(data)), &outLen)

	if ptr == nil {
		return nil, errors.New("decryption failed in core (wrong password or corrupted data)")
	}
	defer C.vault_free_bytes(ptr, outLen)

	result := C.GoBytes(unsafe.Pointer(ptr), C.int(outLen))
	return result, nil
}
