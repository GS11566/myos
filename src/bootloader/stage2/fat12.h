#pragma once

#define BYTES_PER_SECTOR    512
#define SECTORS_PER_FAT     9
#define RESERVED_SECTORS    1
#define FAT_COUNT           2
#define ROOT_DIR_ENTRIES    224
#define SECTORS_PER_CLUSTER 1

#define KERNEL_LOAD_SEG 0x1000
#define KERNEL_LOAD_OFF 0x0000

static int bios_read_sectors(uint16_t seg_val, uint16_t off_val, uint8_t ch_reg, uint8_t cl_reg, uint8_t dh_reg, uint8_t dl_reg);
static void lba_to_chs(uint16_t lba, uint16_t *cyl, uint16_t *head, uint16_t *sect);
static int read_disk(uint8_t drive, uint16_t lba, uint8_t count, void __far *buffer);
static int match_name(const uint8_t *entry, const char *target);
static uint16_t get_next_cluster(uint16_t current);
int fat12_load_file(uint8_t drive, const char *filename_11);
