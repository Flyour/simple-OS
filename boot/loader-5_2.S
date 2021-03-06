%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR ; 0x900
LOADER_STACK_TOP equ LOADER_BASE_ADDR

; 构建gdt及其内部的描述符,一共有4个描述符，地一个为空
GDT_BASE:  dd   0x00000000
           dd   0x00000000

CODE_DESC: dd   0x0000FFFF
           dd   DESC_CODE_HIGH4

DATA_STACK_DESC: dd   0x0000FFFF
                 dd   DESC_DATA_HIGH4

VIDEO_DESC: dd  0x80000007; limit=(0xbffff-0xb8000) / 4k= 0x7
            dd  DESC_VIDEO_HIGH4 ;此时dpl为0

GDT_SIZE  equ  $ - GDT_BASE ;注意这里用equ定义一个变量，是编译器的伪指令
GDT_LIMIT equ  GDT_SIZE - 1 ;定义了段描述符表的段界限
times 60 dq 0 ;此处预留60个描述u符的空位
;total_mem_bytes 用于保存内存容量，以字节为单位，此位置比较好记 ;当前偏移loader.bin文件头0x200(512)字节，loader.bin的加载地址是0x900,所以
;total_mem_bytes在内存中的地址为0xb00，将来在内核中会引用此地址
total_mem_bytes dd 0

;下面是gdt的指针，钱2个字节是gdt界限，后4个字节是gdt的起始地址
gdt_ptr dw  GDT_LIMIT
        dd  GDT_BASE

;人工对齐：total_mem_bytes4 + gdt_ptr6 + ards_buf244 + ards_nr2, 共256字节
;256字节转换为十六进制 0x100
ards_buf times 244 db 0
ards_nr dw 0  ;用于记录ARDS结构体数量

;==================================================================
; int 15h eax = 0000E820h, edx = 534D4150h ('SMAP')获取内存布局
;==================================================================
loader_start: ;此处地址LOADER_BASE_ADDR +0X300
    xor ebx, ebx ;第一次调用时，ebx的值为0
    mov edx, 0x534d4150 ;edx只赋值一次，循环体中不会改变
    mov di, ards_buf ;di指向ards结构缓冲区

;循环获取每个ARDS内存范围描述结构
.e820_mem_get_loop:
    mov eax, 0x0000e820 ;执行int 0x15后，eax值变为0x534d4150
    mov ecx, 20 ;ARDS地址范围描述符结构大小是20字节
    int 0x15
    jc .e820_failed_so_try_e801 ;若cf位为1则有错误发生，尝试0xe801子功能
    add di, cx ;是di 增加20字节指向缓冲区中新的ARDS结构位置
    inc word [ards_nr] ;记录ARDS数量
    cmp ebx, 0 ;如果ebx为0,说明当前已是最后一个
    jnz .e820_mem_get_loop

    ;在所有ards结构中
    ;找出（base_add_low + length_low )的最大值，即内存的容量
    mov cx, [ards_nr] ;遍历每一个ARDS结构体，循环次数是ARDS的数量
    mov ebx, ards_buf
    xor edx, edx

;无需判断type 是否为1,最大的内存块一定是可被使用的
;冒泡排序，找出最大，edx寄存器始终是最大的内存容量
.find_max_mem_area:
    mov eax, [ebx]   ;base_add_low
    add eax, [ebx+8] ;length_low
    add ebx, 20      ;指向缓冲区中下一个ARDS结构
    cmp edx, eax
    jge .next_ards
    mov edx, eax

.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

;===================================================================
;int 15h ax = E801h 获取内存大小，最大支持4G
;在ax和cx中为低16MB，在bx和dx中为16MB到4GB
;===================================================================
.e820_failed_so_try_e801:
    mov ax,0xe801
    int 0x15
    jc .e801_failed_so_try88 ;若当前e801方法失败，就尝试0x88方法

    ;先算出低15MB的内存
    ;ax和cx中是以KB为单位的内存数量，将其转换为以byte为单位
    mov cx, 0x400 ;0x400转换为十进制为1024
    mul cx        ;用cx乘ax
    shl edx, 16   ;16位操作数乘法，积的高16位在DX寄存器
    and eax, 0x0000FFFF
    or edx, eax   ;把32位的积放在edx中

    add edx, 0x100000 ;ax只是15MB,所以要加上1MB
    mov esi, edx      ;先把15MB的内存容量存入esi寄存器备份

    xor eax, eax ;净化一下eax
    mov ax, bx   ; bx中放的是以64KB为单位的内存数量
    mov ecx, 0x10000 ;0x10000十进制为64K
    mul ecx ;32位乘法，默认被乘数是eax，积的高32位存入edx,低32位存入eax

    add esi, eax ;由于此方法只能测出4GB的内存，所以32位的eax足够了
    mov edx, esi
    jmp .mem_get_ok

;====================================================================
;int 15h  ah = 0x88 获取内存大小,只能获取64MB之内
;int 15h后，ax存入的是以KB为单位的内存容量
;===================================================================
.e801_failed_so_try88:
    mov ah, 0x88
    int 0x15
    jc .error_hlt

    and eax, 0x0000FFFF
    mov cx, 0x400
    mul cx ;16位乘法，积的高16位放在dx中
    shl edx, 16
    or edx, eax
    add edx, 0x100000 ;0x88子功能只返回1MB以上的内存,所以实际内存要加上1MB

.mem_get_ok:
    mov [total_mem_bytes], edx

.error_hlt: ;该定义目前无用

 ;定义了三个选择子
SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

    in al, 0x92
    or al, 0000_0010B
    out 0x92, al  ;修改0x92端口的数据，打开A20
    lgdt [gdt_ptr] ;加载gdt

    ;将cr0的pe位置1
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start ;通过jmp指令刷新流水线

;通过选择子初始化各个段寄存器
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

    ;创建页目录及页表并初始化页内存位图
    call setup_page

    ;要将描述符表地址及偏移量写入内存gdt_ptr, 一会用新地址重新加载
    sgdt [gdt_ptr] ;存储到原来gdt所在的位置

    ;将gdt描述符中视频段描述符中的段基址+0xc0000000
    mov ebx, [gdt_ptr + 2]
    or dword [ebx + 0x18 + 4], 0xc0000000

    ;将gddt的基址加上0xc0000000是其成为内核所在的高地址
    add dword [gdt_ptr + 2], 0xc0000000
    add esp, 0xc0000000 ;将栈地址同样映射到内核地址

    ;把页目录地址赋给cr3
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

    ;打开cr0的pg位（第31位）
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ;在开启分页后，用gdt新的地址重新加载
    lgdt [gdt_ptr]

    mov byte [gs:160], 'V'
    jmp $


;创建页目录及页表
setup_page:
    mov ecx, 4096
    mov esi, 0

;通过遍历循环的方式把页目录占用的空间逐字清0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS +esi], 0
    inc esi
    loop .clear_page_dir

;开始创建页目录项（PDE）
.create_pde:
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x1000 ;eax中存放的是第一个页表的对应的目录项
    mov ebx, eax ;在ebx中备份，是为.create_pte做准备,ebx为基地址

    or eax, PG_US_U | PG_RW_W | PG_P ;定义目录项中的属性位
    mov [PAGE_DIR_TABLE_POS + 0x0], eax ;将目录项存入页目录表第0项中
    mov [PAGE_DIR_TABLE_POS + 0xc00], eax ;将目录项存入页目录表第768项中

    ;使最后一个目录项指向页目录表自己的地址
    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_POS + 4092 ], eax

    ;下面创建页表项
    ;0～1M的虚存空间对应0～1M的物理地址空间
    mov ecx, 256 ;1M低端内存对应的页表项的个数
    mov esi, 0
    mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx+esi*4], edx
    add edx, 4096 ;一个页表大小为4KB
    inc esi
    loop .create_pte

    ;创建内核其他页表的PDE
    ;0~767目录项对应的虚存空间0~3G,768~1023目录项对应虚存空间3G~4G
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000 ;此时eax为第二个页表的位置
    or eax, PG_US_U | PG_RW_W | PG_P
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254 ;范围为第769～1022的所有目录项数量
    mov esi, 769

.create_kernel_pde:
    mov [ebx+esi*4], eax
    inc esi
    add eax, 0x1000 ;eax中存放目录项的内容
    loop .create_kernel_pde
    ret

