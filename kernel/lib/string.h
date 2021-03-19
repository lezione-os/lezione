//! @file string.h
//! @brief File containing declarations for string manipulation functions

#pragma once

#include <misc/types.h> // For size_t

//! @brief Calculate length of null-terminated string
//! @param str String, length of which should be calculated
static inline size_t strlen(const char *str) {
	size_t result = 0;
	while (str[result] != '\0') {
		result++;
	}
	return result;
}

//! @brief Copy n bytes from src to dst
//! @param dest Pointer to destination buffer
//! @param src Pointer to data to be copied
//! @param n Number of bytes to be copied
//! @return Value of dest parameter
static inline void *memcpy(void *dest, const void *src, size_t n) {
	char *cdest = dest;
	const char *csrc = src;
	for (size_t i = 0; i < n; ++i) {
		cdest[i] = csrc[i];
	}
	return dest;
}
