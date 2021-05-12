//! @file log.c
//! @brief File containing definitions for logging functions

#include <lib/fmt.h>   // For vsnprintf
#include <sys/ports.h> // For outb

//! @brief Maximum length of the buffer for log_printf
#define LOG_BUFFER_SIZE 4096

//! @brief Print one character to kernel log
//! @param character Character to be printed
void log_putc(char character) {
	// Print one character to QEMU debugcon
	outb(0xe9, (uint8_t)character);
}

//! @brief Print string to kernel log
//! @param data Pointer to the first char of the string that is to be printed
//! @param size Size of the string
void log_write(char *data, size_t size) {
	for (size_t i = 0; i < size; ++i) {
		log_putc(data[i]);
	}
}

//! @brief Print formatted message to kernel log
//! @param format Format string for the message
//! @param ... Arguments for the format string
void log_printf(const char *fmt, ...) {
	// Buffer that messages will be formatted to
	static char buf[LOG_BUFFER_SIZE];
	// Initialize varargs
	va_list args;
	va_start(args, fmt);
	// Format message
	int bytes_written = vsnprintf(buf, LOG_BUFFER_SIZE, fmt, args);
	// Write message
	log_write(buf, bytes_written);
	// Deinitialize varargs
	va_end(args);
}
