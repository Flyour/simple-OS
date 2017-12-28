#!/bin/bash

gcc -I ../lib/kernel/ -I ../lib/ -I ../kernel/ -c -fno-builtin -o main.o ../kernel/main.c -m32

nasm -f elf -o print.o ../lib/kernel/print.S

nasm -f elf -o kernel.o ../kernel/kernel.S

gcc -I ../lib/kernel/ -I ../lib/ -I ../kernel/ -c -fno-builtin -o interrupt.o ../kernel/interrupt.c -m32

gcc -I ../lib/kernel/ -I ../lib/ -I ../kernel/ -c -fno-builtin -o init.o ../kernel/init.c -m32

ld -Ttext 0xc0001500 -e main -o kernel.bin main.o init.o interrupt.o print.o kernel.o -m elf_i386

dd if=kernel.bin of=../hd60M.img bs=512 count=200 seek=9 conv=notrunc
