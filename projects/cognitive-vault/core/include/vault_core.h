#ifndef VAULT_CORE_H
#define VAULT_CORE_H

#include <stdint.h>
#include <stddef.h>

// String functions
char* vault_hello(const char* name);
void vault_free_string(char* s);

// Crypto functions
uint8_t* vault_encrypt(const char* password, const uint8_t* data, size_t data_len, size_t* out_len);
uint8_t* vault_decrypt(const char* password, const uint8_t* data, size_t data_len, size_t* out_len);
void vault_free_bytes(uint8_t* ptr, size_t len);

#endif
