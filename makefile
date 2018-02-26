BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I kernel/ -I device/ -I thread/ -I userprog/
ASFLAGS = -f elf
# -fno-builtin告诉编译器不要采用内部函数，因为以后实现中会自定义与内部函数
#  同名的函数; -Wstrict-prototypes 要求函数声明中必须有参数类型;
#  -Wmissing-prototypes 要求函数必须有声明
CFLAGS = -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes \
		 -Wmissing-prototypes -m32
LDFLAGS = -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map \
		  -m elf_i386
OBJS = $(BUILD_DIR)/main.o  $(BUILD_DIR)/init.o   $(BUILD_DIR)/interrupt.o\
       $(BUILD_DIR)/timer.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o \
	   $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o $(BUILD_DIR)/bitmap.o \
	   $(BUILD_DIR)/memory.o $(BUILD_DIR)/thread.o $(BUILD_DIR)/list.o \
	   $(BUILD_DIR)/list.o $(BUILD_DIR)/switch.o $(BUILD_DIR)/sync.o \
	   $(BUILD_DIR)/console.o $(BUILD_DIR)/ioqueue.o $(BUILD_DIR)/tss.o \
       $(BUILD_DIR)/keyboard.o $(BUILD_DIR)/process.o \
	   $(BUILD_DIR)/syscall.o $(BUILD_DIR)/syscall_init.o \
       $(BUILD_DIR)/stdio.o $(BUILD_DIR)/ide.o $(BUILD_DIR)/stdio-kernel.o

##################  c代码编译 ##############################
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h lib/stdint.h \
	kernel/init.h device/console.h kernel/interrupt.h \
	device/timer.h device/ide.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h \
	lib/stdint.h kernel/interrupt.h device/timer.h device/console.h \
	userprog/tss.h device/keyboard.h kernel/memory.h thread/thread.h \
	userprog/syscall_init.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h \
	lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/stdint.h \
	lib/kernel/io.h lib/kernel/print.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h\
	lib/kernel/print.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/string.o: lib/string.c lib/string.h\
	kernel/global.h lib/stdint.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/bitmap.o: lib/kernel/bitmap.c lib/kernel/bitmap.h lib/stdint.h\
	lib/kernel/print.h kernel/debug.h kernel/interrupt.h lib/string.h \
	kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/memory.o: kernel/memory.c kernel/memory.h kernel/global.h \
	lib/kernel/print.h lib/stdint.h lib/kernel/bitmap.h kernel/debug.h \
	lib/string.h lib/kernel/list.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/thread.o: thread/thread.c thread/thread.h kernel/global.h \
	lib/stdint.h lib/string.h kernel/memory.h kernel/interrupt.h	\
	lib/kernel/print.h lib/kernel/list.h kernel/debug.h thread/sync.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/list.o: lib/kernel/list.c kernel/interrupt.h \
	lib/kernel/list.h lib/stdint.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/sync.o: thread/sync.c thread/sync.h lib/stdint.h \
	kernel/debug.h kernel/interrupt.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/console.o: device/console.c device/console.h \
	lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/keyboard.o: device/keyboard.c device/keyboard.h \
	lib/kernel/print.h kernel/interrupt.h lib/kernel/io.h \
	kernel/global.h lib/stdint.h device/ioqueue.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/ioqueue.o: device/ioqueue.c device/ioqueue.h \
	kernel/interrupt.h	kernel/global.h lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/tss.o: userprog/tss.c userprog/tss.h \
	lib/stdint.h thread/thread.h kernel/global.h lib/kernel/print.h \
	lib/string.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/process.o: userprog/process.c userprog/process.h \
	lib/stdint.h thread/thread.h kernel/global.h kernel/memory.h \
	kernel/debug.h userprog/tss.h device/console.h lib/string.h \
	userprog/userprog.h kernel/interrupt.h lib/kernel/list.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/syscall.o: lib/user/syscall.c lib/user/syscall.h \
	lib/stdint.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/syscall_init.o: userprog/syscall_init.c  \
	userprog/syscall_init.h lib/stdint.h thread/thread.h \
	lib/kernel/print.h lib/user/syscall.h lib/string.h \
	device/console.h kernel/memory.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/stdio.o: lib/stdio.c lib/stdio.h lib/stdint.h  \
	lib/string.h kernel/global.h lib/user/syscall.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/ide.o: device/ide.c device/ide.h lib/kernel/stdio-kernel.h \
	lib/stdint.h kernel/debug.h kernel/global.h lib/stdio.h thread/sync.h\
	lib/kernel/list.h lib/kernel/io.h device/timer.h lib/string.h \
	kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/stdio-kernel.o: lib/kernel/stdio-kernel.c device/console.h \
	lib/kernel/stdio-kernel.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

################## 汇编代码编译 ##############################
$(BUILD_DIR)/kernel.o: kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/print.o: lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/mbr.bin: boot/mbr.S boot/include/boot.inc
	$(AS) $< -o $@ -I boot/include/

$(BUILD_DIR)/loader.bin: boot/loader.S
	$(AS) $< -o $@ -I boot/include/

$(BUILD_DIR)/switch.o: thread/switch.S
	$(AS) $(ASFLAGS) $< -o $@

################## 链接所有目标文件 #############################
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

.PHONY: mk_dir hd clean all prepare pd
mkdir:
	if [[ ! -d $(BUILDL_DIR) ]]; then mkdir $(BUILD_DIR);fi

hd:
	dd  if=$(BUILD_DIR)/kernel.bin \
		of=/root/linuxmaker/hd60M.img \
		bs=512 count=200 seek=9 conv=notrunc
pd:
	dd  if=$(BUILD_DIR)/mbr.bin \
		of=/root/linuxmaker/hd60M.img \
		bs=512 count=1 conv=notrunc
	dd  if=$(BUILD_DIR)/loader.bin \
		of=/root/linuxmaker/hd60M.img \
		bs=512 count=4 seek=2 conv=notrunc

clean:
	cd $(BUILD_DIR) && rm -f ./*

build: $(BUILD_DIR)/kernel.bin

buildpd: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/loader.bin

all: mk_dir build hd

prepare: mk_dir clean buildpd  pd
