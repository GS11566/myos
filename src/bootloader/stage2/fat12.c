#include "stdint.h"
#include "fat12.h"

#pragma pack(1)
typedef struct {
    uint8_t  name[8];
    uint8_t  ext[3];
    uint8_t  attr;
    uint8_t  reserved[10];
    uint16_t time;
    uint16_t date;
    uint16_t first_cluster;
    uint32_t size;
} FatDirEntry;
#pragma pack()

#define ROOT_DIR_LBA   (RESERVED_SECTORS + (FAT_COUNT * SECTORS_PER_FAT))
#define ROOT_DIR_SIZE  ((ROOT_DIR_ENTRIES * 32) / BYTES_PER_SECTOR)
#define DATA_AREA_LBA  (ROOT_DIR_LBA + ROOT_DIR_SIZE)

static uint8_t fat_buf[SECTORS_PER_FAT * BYTES_PER_SECTOR];
static uint8_t dir_buf[ROOT_DIR_SIZE * BYTES_PER_SECTOR];

typedef union {
    void __far *ptr;
    struct { uint16_t off; uint16_t seg; } u;
} far_ptr_t;

static int bios_read_sectors(uint16_t seg_val, uint16_t off_val, uint8_t ch_reg, uint8_t cl_reg, uint8_t dh_reg, uint8_t dl_reg) {
    int result;
    __asm {
        push ds
        mov  ax, seg_val
        mov  es, ax
        mov  bx, off_val
        mov  ch, ch_reg
        mov  cl, cl_reg
        mov  dh, dh_reg
        mov  dl, dl_reg
        mov  ah, 0x02
        mov  al, 1
        stc
        int  0x13
        mov  result, 0
        jnc  done_bios
        mov  result, 1
    done_bios:
        pop  ds
    }
    return result;
}

static void lba_to_chs(uint16_t lba, uint16_t *cyl, uint16_t *head, uint16_t *sect) {
    uint16_t tmp;
    tmp = lba / 18;
    *sect = (lba - (tmp * 18)) + 1;
    *head = tmp & 1;
    *cyl  = tmp >> 1;
}

static int read_disk(uint8_t drive, uint16_t lba, uint8_t count, void __far *buffer) {
    uint16_t cyl, head, sect;
    uint16_t seg_val, off_val;
    uint8_t cl_reg, ch_reg;
    far_ptr_t fp;

    lba_to_chs(lba, &cyl, &head, &sect);

    fp.ptr = buffer;
    seg_val = fp.u.seg;
    off_val = fp.u.off;

    cl_reg = (uint8_t)(sect | ((cyl >> 8) << 6));
    ch_reg = (uint8_t)(cyl & 0xFF);

    (void)count;
    return bios_read_sectors(seg_val, off_val, ch_reg, cl_reg, (uint8_t)head, drive);
}

static int match_name(const uint8_t *entry, const char *target) {
    int i;
    for (i = 0; i < 11; i++) {
        if (entry[i] != (uint8_t)target[i]) return 0;
    }
    return 1;
}

static uint16_t get_next_cluster(uint16_t current) {
    uint16_t offset;
    uint16_t entry;
    offset = current + (current / 2);
    entry = *((uint16_t*)&fat_buf[offset]);
    return (current & 1) ? (entry >> 4) : (entry & 0x0FFF);
}

int fat12_load_file(uint8_t drive, const char *filename_11) {
    FatDirEntry *entries;
    uint16_t start_cluster;
    uint16_t cluster;
    uint16_t lba;
    uint16_t cur_seg;
    uint16_t cur_off;
    far_ptr_t load_fp;
    int i;

    if (read_disk(drive, ROOT_DIR_LBA, ROOT_DIR_SIZE, dir_buf) != 0) return -1;

    start_cluster = 0;
    entries = (FatDirEntry *)dir_buf;
    for (i = 0; i < ROOT_DIR_ENTRIES; i++) {
        if (entries[i].name[0] == 0x00 || entries[i].name[0] == 0xE5) continue;
        if (entries[i].attr & 0x10) continue;
        if (match_name(entries[i].name, filename_11)) {
            start_cluster = entries[i].first_cluster;
            break;
        }
    }
    if (start_cluster == 0) return -2;

    if (read_disk(drive, RESERVED_SECTORS, SECTORS_PER_FAT, fat_buf) != 0) return -3;

    cur_seg = KERNEL_LOAD_SEG;
    cur_off = KERNEL_LOAD_OFF;
    cluster = start_cluster;

    while (cluster < 0xFF8) {
        load_fp.u.seg = cur_seg;
        load_fp.u.off = cur_off;

        lba = DATA_AREA_LBA + (cluster - 2) * SECTORS_PER_CLUSTER;
        if (read_disk(drive, lba, SECTORS_PER_CLUSTER, load_fp.ptr) != 0) return -4;

        cur_off += BYTES_PER_SECTOR;
        if (cur_off < BYTES_PER_SECTOR) {
            cur_seg += 0x1000;
        }

        cluster = get_next_cluster(cluster);
    }

    return 0;
}
