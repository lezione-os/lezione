//! @file init.c
//! @brief File containing kernel entrypoint and kernel init functions

#include <init/stivale2.h> // For stivale2 protocol type definitions
#include <lib/log.h>       // For log_printf
#include <sys/ports.h>

//! @brief Stack used by kernel on bootstrap
//! As dictated by stivale2 protocol, we should provide an address of the stack
//! that we will use to the bootloader. As bootloader needs to know the stack
//! before kernel even starts, we allocate stack statically as a global
//! uninitialized array
static uint8_t kernel_stack[65536];

// This part is taken from limine-bootloader/limine-barebones
// (https://github.com/limine-bootloader/limine-barebones/blob/master/src-stivale2/kernel.c)
// The stivale2 specification says we need to define a "header structure".
// This structure needs to reside in the .stivale2hdr ELF section in order
// for the bootloader to find it. We use this __attribute__ directive to
// tell the compiler to put the following structure in said section.
__attribute__((section(".stivale2hdr"), used)) struct stivale2_header stivale_hdr = {
    // The entry_point member is used to specify an alternative entry
    // point that the bootloader should jump to instead of the executable's
    // ELF entry point. If we wish to use default ELF entrypoint (which we do
    // set in linker script to kernel_init), we need to set this field to zero
    .entry_point = 0,
    // Let's tell the bootloader where our stack is.
    // We need to add the sizeof(stack) since in x86(_64) the stack grows
    // downwards.
    .stack = (uintptr_t)kernel_stack + sizeof(kernel_stack),
    // No flags are currently defined as per spec and should be left to 0.
    .flags = 0,
    // This header structure is the root of the linked list of header tags and
    // points to the first tag. In our case, we don't use any tags yet, so we
    // set it to 0
    .tags = 0,
};

void kernel_init() {
	// Greet user
	log_printf("Hello, OSDev world!\n");
	log_printf("Printing test %c %d %D %u %U %x %X 0x%p %s!\n", 'a', -123, INT64_MIN, 345,
	           12234392744ULL, 0x123, 0x123456789, 0x101abe, "strings are supported as well");
	// Nothing more to do yet :^(
	// Loop forever
	while (true) {
		// Pause instruction is a hint to CPU that we have entered busy wait
		// loop. This helps CPU to reduce power consumption.
		asm volatile("pause");
	}
}
