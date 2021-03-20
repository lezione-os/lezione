ENTRY(kernel_init)

SECTIONS {
    /* Base of kernel physical window + 2 GB */
    . = 0xffffffff80200000;

    /* Stivale 2 info for the bootloader */
    .stivale2hdr : ALIGN(4K) {
        KEEP(*(.stivale2hdr))
    }

    /* Kernel code */
    .text : ALIGN(4K) {
        *(.text*)
    }

    /* Readonly kernel data */
    .rodata : ALIGN(4K) {
        *(.rodata*)
    }

    /* Readable and writable kernel data */
    .data : ALIGN(4K) {
        *(.data*)
    }

    /* Readable writeable unitialized kernel memory */
    .bss : ALIGN(4K) {
        *(.bss*)
    }
}
