ASM=nasm
CC=gcc
CC16=../watcom/binl/wcc
LD16=../watcom/binl/wlink
CC32=../watcom/binl/wcc386
LD32=$(LD16)

SRC_DIR=src
BUILD_DIR=build

GENERIC_CFLAGS=-fr=$(BUILD_DIR)/ -i=src/include

STAGE2_CFLAGS16=-4 -d3 -s -wx -ms -zl -zq
STAGE2_NASMFLAGS=-f obj

KERNEL_CFLAGS32=-4 -d1 -s -zl -zld -zq -wx -zp1 -zu -fpc
KERNEL_NASMFLAGS=-f obj

.PHONY: all run floppy_image kernel bootloader stage1 stage2 clean always

run: floppy_image
	#qemu-system-i386 -fda build/main_floppy.img
	qemu-system-x86_64 -drive file=$(BUILD_DIR)/main_floppy.img,format=raw,if=floppy


floppy_image: $(BUILD_DIR)/main_floppy.img
$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "MYOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"


bootloader: stage1 stage2


stage1: $(BUILD_DIR)/stage1.bin
$(BUILD_DIR)/stage1.bin: always
	$(ASM) $(SRC_DIR)/bootloader/stage1/boot.nasm -f bin -o $(BUILD_DIR)/stage1.bin


stage2: $(BUILD_DIR)/stage2.bin
STAGE2_SOURCES_C=$(wildcard $(SRC_DIR)/bootloader/stage2/*.c)
STAGE2_SOURCES_ASM=$(wildcard $(SRC_DIR)/bootloader/stage2/*.nasm)
STAGE2_OBJECTS_C=$(patsubst %.c, $(BUILD_DIR)/stage2/c/%.obj, $(notdir $(STAGE2_SOURCES_C)))
STAGE2_OBJECTS_ASM=$(patsubst %.nasm, $(BUILD_DIR)/stage2/nasm/%.obj, $(notdir $(STAGE2_SOURCES_ASM)))

$(BUILD_DIR)/stage2.bin: $(STAGE2_OBJECTS_ASM) $(STAGE2_OBJECTS_C)
	$(LD16) NAME $@ FILE \{ $(STAGE2_OBJECTS_ASM) $(STAGE2_OBJECTS_C) \} OPTION MAP=$(BUILD_DIR)/stage2.map @$(SRC_DIR)/bootloader/stage2/build_stage2.lnk

$(BUILD_DIR)/stage2/c/%.obj: $(SRC_DIR)/bootloader/stage2/%.c always
	$(CC16) $(STAGE2_CFLAGS16) $(GENERIC_CFLAGS) -fo=$@ $<

$(BUILD_DIR)/stage2/nasm/%.obj: $(SRC_DIR)/bootloader/stage2/%.nasm always
	$(ASM) $(STAGE2_NASMFLAGS) -o $@ $<


kernel: $(BUILD_DIR)/kernel.bin
KERNEL_SOURCES_C=$(wildcard $(SRC_DIR)/kernel/*.c)
KERNEL_SOURCES_ASM=$(wildcard $(SRC_DIR)/kernel/*.nasm)
KERNEL_OBJECTS_C=$(patsubst %.c, $(BUILD_DIR)/kernel/c/%.obj, $(notdir $(KERNEL_SOURCES_C)))
KERNEL_OBJECTS_ASM=$(patsubst %.nasm, $(BUILD_DIR)/kernel/nasm/%.obj, $(notdir $(KERNEL_SOURCES_ASM)))

$(BUILD_DIR)/kernel.bin: $(KERNEL_OBJECTS_ASM) $(KERNEL_OBJECTS_C)
	$(LD32) NAME $@ FILE \{ $(KERNEL_OBJECTS_ASM) $(KERNEL_OBJECTS_C) \} OPTION MAP=$(BUILD_DIR)/kernel.map @$(SRC_DIR)/kernel/build_kernel.lnk

$(BUILD_DIR)/kernel/c/%.obj: $(SRC_DIR)/kernel/%.c always
	$(CC32) $(KERNEL_CFLAGS32) $(GENERIC_CFLAGS) -fo=$@ $<

$(BUILD_DIR)/kernel/nasm/%.obj: $(SRC_DIR)/kernel/%.nasm always
	$(ASM) $(KERNEL_NASMFLAGS) -o $@ $<


always:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/stage2/c
	mkdir -p $(BUILD_DIR)/stage2/nasm
	mkdir -p $(BUILD_DIR)/kernel/c
	mkdir -p $(BUILD_DIR)/kernel/nasm

clean:
	rm -rf $(BUILD_DIR)/*

