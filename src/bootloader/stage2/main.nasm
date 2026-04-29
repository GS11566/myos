bits 16

section .bss stack align=16
    resb 0x1000          ; 4KB stack
stack_top:

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli
    mov ax, ds
    mov ss, ax
    mov sp, stack_top
    mov bp, sp
    sti

    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt

