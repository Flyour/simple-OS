%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

; 构建gdt及其内部的描述符,一共有4个描述符，地一个为空
GDT_BASE:  dd   0x00000000
           dd   0x00000000

CODE_DESC: dd   0x0000FFFF
           dd   DESC_CODE_HIGH4

DATA_STACK_DESC: dd   0x0000FFFF
                 dd   DESC_DATA_HIGH4

VIDEO_DESC: dd  0x80000007; limit=(0xbffff-0xb8000) / 4k= 0x7
            dd  DESC_VIDEO_HIGH4 ;此时dpl为0

GDT_SIZE  equ  $ - GDT_BASE
GDT_LIMIT equ  GDT_SIZE - 1 ;定义了段描述符表的段界限
times 60 dq 0 ;此处预留60个描述u符的空位
SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0003 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0 ;定义了三个选择子

;下面是gdt的指针，钱2个字节是gdt界限，后4个字节是gdt的起始地址
gdt_ptr dw  GDT_LIMIT
        dd  GDT_BASE

loadermsg  db   '2 loader in real.'

;===============================================================
;INT 0X10 功能号：0x13，功能描述：打印字符串
;===============================================================
;AH 子功能号 = 13H
;BH = 页码
;BL = 属性
;CX = 字符串长度
;（DH,DL) = 坐标（行，列）
;ES:BP = 字符串地址
;AL = 显示输入方式
loader_start:
    mov sp, LOADER_BASE_ADDR
    mov bp, loadermsg i;ES：BP = 字符串地址
    mov cx, 17
    mov ax, 0x1301
    mov bx, 0x001f
    mov dx, 0x1800
    int 0x10 ; 调用中断

    in al, 0x92
    or al, 0000_0010B
    out 0x92, al ;修改0x92端口的数据，打开A20
    lgdt [gdt_ptr] ;加载gdt

    ;将cr0的pe位置1
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start ;通过jmp指令刷新流水线

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    mov byte [gs:160], 'P'
    jmp $



