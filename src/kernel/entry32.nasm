section _ENTRY16 class=ENTRY_CODE byte use16
bits 16

extern _kmain
global entry

entry:
    cli                     ; disable interrupts
    xor ax, ax
    mov ds, ax              ; set DS=0
    mov es, ax
    mov ss, ax
    mov sp, 0x9000

    ; enable A20
    in al, 0x92
    or al, 0x02
    out 0x92, al

    xor ax, ax
    mov ds, ax

    ; load GDT
    lgdt [cs:gdt_desc]

    ; enter Protected Mode
    mov eax, cr0
    or eax, 1               ; set PE bit
    mov cr0, eax

    ; far jump to flush CPU instruction queue and load 32-bit CS
    jmp CODE_SEG:pm_start

section _ENTRY32 class=ENTRY_CODE byte use32
bits 32
pm_start:
    ; set up 32-bit segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov ebp, 0x30000
    mov esp, ebp

    ; call C kernel entry point
    mov edi, 0xA8000

    ; Write "OK !" to top-left corner (white text on black: 0x0F)
    mov word [es:edi],   0x0F4F  ; 'O'
    mov word [es:edi+2], 0x0F4B  ; 'K'
    mov word [es:edi+4], 0x0F20  ; ' '
    mov word [es:edi+6], 0x0F21  ; '!'
    call _kmain
    mov word [es:edi+8], 0x0F4B  ; 'K'

    ; if kmain ever returns, halt the CPU
    cli
    hlt
    jmp $

section _GDT class=ENTRY_CODE
gdt_start:
    dq 0                          ; Null descriptor
gdt_code:
    dw 0xFFFF                     ; Limit (low)
    dw 0x0000                     ; Base (low)
    db 0x00                       ; Base (mid)
    db 10011010b                  ; Access: Present, DPL=0, Code, Executable, Readable
    db 11001111b                  ; Flags/Limit high: G=1, D=1 (32-bit), Limit=0xF
    db 0x00                       ; Base (high)
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                  ; Access: Present, DPL=0, Data, Writable
    db 11001111b
    db 0x00
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1    ; Limit (size - 1)
    dd gdt_start                  ; Base address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
