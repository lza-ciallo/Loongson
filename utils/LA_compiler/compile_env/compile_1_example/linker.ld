ENTRY(_start)

MEMORY
{
    ROM (rx) : ORIGIN = 0x1c000000, LENGTH = 64K
}

SECTIONS
{
    .text 0x1c000000 : {
        *(.text)
        *(.text.*)
    } > ROM
    
    /DISCARD/ : {
        *(.note*)
        *(.comment*)
        *(.eh_frame*)
    }
}
