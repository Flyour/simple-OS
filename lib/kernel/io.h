/*--------------------机器模式--------------------------
 *  HImode
 *      "Half-Integer"模式，表示一个两字节的整数
 *
 *  QImode
 *      "Quarter-Integer"模式，表示一个一字节的整数
-------------------------------------------------------*/

#ifndef __LIB_IO_H
#define __LIB_IO_H
#include "stdint.h"

/*向端口port写入一个字节*/
static inline void outb(uint16_t port, uint8_t data){
    /*
     * 对端口指定N表示0～255,d表示用dx存储端口号
     * %b0表示对应al, %w1表示对应dx
     */
    asm volatile ("outb %b0, %w1" : : "a"(data), "Nd" (port));
}

/* 将addr处起始的word_cnt 个字写入端口port */
static inline void outsw (uint16_t port, const void* addr, uint32_t word_cnt){
    /*
     * +表示操作数是可读写，告诉gcc所约束的寄存器先被读入，再被写入
     * outsb,outsw,outsd 都是端口输出命令，把DS:(E)SI指定的内存单元中的
     * 字节，字或双字，输出到DX指定的I/O端口,(E)SI进行自动变换
     * 我们在设置段描述符时，已经将ds,ex,ss段的选择子都设置为相同的值了，
     * 不用担心数据错乱
     */
    asm volatile ("cld; rep outsw":"+S"(addr),"+c"(word_cnt):"d" (port));
}

/* 将从端口port读入的一个字节返回 */
static inline uint8_t inb(uint16_t port){
    uint8_t data;
    asm volatile ("inb %w1, %b0" : "=a" (data) : "Nd" (port));
    return data;
}

/*将从端口port读入的word_cnt个字写入addr */
static inline void insw(uint16_t port, void* addr, uint32_t word_cnt){
    /*
     * insw是将从端口port(dx存放)处读入的16位内容写入es:edi指向的内存
     */
    asm volatile ("cld; rep insw" : "+D"(addr), "+c"(word_cnt) : "d"(port) : "memory");
}

#endif
