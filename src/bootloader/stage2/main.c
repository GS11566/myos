#include "stdint.h"
#include "stdio.h"
#include "fat12.h"

void _cdecl cstart_(uint16_t bootDrive)
{
    char* kernel_filename = "KERNEL  BIN";
    int res;

    puts("Stage2 booted successfully!\n\r");
    puts("Loading kernel...\n\r");
    res = fat12_load_file(bootDrive, kernel_filename);
    if (res != 0) {
        puts("Loading kernel failed! Code (+6): ");
        putc(48 + 6 + res);
        for (;;);
    }
    puts("Kernel loaded! Jumping...\n\r");

    __asm {
        mov ax, KERNEL_LOAD_SEG
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, 0xFFFE      /* Reset stack to top of segment */
        push KERNEL_LOAD_SEG
        push KERNEL_LOAD_OFF
        retf                /* Far jump to KERNEL_SEG:KERNEL_OFF */
    }

    for (;;);
}
