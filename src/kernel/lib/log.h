//! @file log.c
//! @brief File containing declarations for logging functions

#pragma once

#include <misc/types.h> // For fixed width integer types

//! @brief Print one character to kernel log
//! @param character Character to be printed
void log_putc(char character);

//! @brief Print string to kernel log
//! @param data Pointer to the first char of the string that is to be printed
//! @param size Size of the string
void log_write(char *data, size_t size);

//! @brief Print formatted message to kernel log
//! @param format Format string for the message
//! @param ... Arguments for the format string
void log_printf(const char *fmt, ...);
