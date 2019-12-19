/*
 * link.ld
 *  Linker script.
 *
 */

ENTRY(_boot);

SECTIONS
{
    . = 0x80000; /* This is already 4KiB aligned */
    .text :
    {
        KEEP(*(.text.boot)) *(.text .text.*)
    }

    .rodata :
    {
        *(.rodata .rodata.*)
    }
    . = ALIGN(4096); /* Fill up to 4KiB boundary */

    .data :
    {
        *(.data .data.*)
    }

    .bss ALIGN(8):
    {
        __bss_beg = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /DISCARD/ : { *(.comment) *(.gnu*) *(.note*) *(.eh_frame*) }
}
