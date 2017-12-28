#!/bin/bash

gcc -I ../lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -o 
 

gcc -c -o main.o main.c && ld main.o -Ttext 0xc0001500 -e main -o kernel.bin -m elf_i386 && dd if=kernel.bin of=../hd60M.img bs=512 count=200 seek=9 conv=notrunc
