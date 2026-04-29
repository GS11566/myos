#include "stdint.h"

/* VGA Text Mode Buffer: 80x25, 16-bit entries (char + attribute) */
static volatile uint16_t *vga_buffer = (volatile uint16_t *)0xB8000;
static uint16_t vga_pos = 0;

static void vga_putchar(char c, uint8_t color) {
    if (c == '\n') {
        vga_pos = (vga_pos / 80 + 1) * 80;
    } else if (c == '\r') {
        vga_pos = (vga_pos / 80) * 80;
    } else {
        vga_buffer[vga_pos++] = (uint16_t)c | ((uint16_t)color << 8);
    }

    if (vga_pos >= 80 * 25) {
        vga_pos = 0;
    }
}

void vga_puts(const char *str, uint8_t color) {
    while (*str) {
        vga_putchar(*str++, color);
    }
}

void _cdecl kmain(void) {
    //vga_buffer[4] = 0x0F4B;
    //vga_puts("Kernel booted!\n", 0x0F);
    //vga_puts("Welcome!\n", 0x0A);

    //for (;;); /* Halt loop */
}
