#include "interrupt.h"
#include "stdint.h"
#include "global.h"
#include "print.h"
#include "io.h"

#define IDT_DESC_CNT 0x21       //目前总共支持的中断数
#define PIC_M_CTRL 0X20         //主片的控制端口是0x20
#define PIC_M_DATA 0x21         //主片的数据端口是0x21
#define PIC_S_CTRL 0Xa0         //从片的控制端口是0xa0
#define PIC_S_DATA 0Xa1         //从片的数据端口是0xa1

/*中断门描述符结构体*/
struct gate_desc{
    uint16_t func_offset_low_word;
    uint16_t selector;
    uint8_t dcount;         //此项是双字计数字段，是门描述符中的第4字节
                            //此项固定值,不用考虑
    uint8_t attribute;      //参数
    uint16_t func_offset_high_word;
};

//静态函数声明，非必须
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function);

//定义了一个中断描述符的数组，本质上就是中断门描述符表
static struct gate_desc idt[IDT_DESC_CNT];

//intr_handler是在interrupt.h中自定义的类型，为typedef void * intr_handler
//这里声明了一个数组
extern intr_handler intr_entry_table[IDT_DESC_CNT];

/*创建中断门描述符*/
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function){
    p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000FFFF;
    p_gdesc->selector = SELECTOR_K_CODE;
    p_gdesc->dcount = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word=((uint32_t)function & 0xFFFF0000) >>16;
}

/*初始化中断描述符表*/
static void idt_desc_init(void){
    int i;
    for (i=0; i<IDT_DESC_CNT; i++){
        //调用make_idt_desc函数来填充中断门描述符表
        make_idt_desc(&idt[i], IDT_DESC_ATTR_DPL0, intr_entry_table[i]);
    }
    put_str("idt_desc_init done\n");
}


/* 初始化可编程中断控制器8259A */
static void pic_init(void){
    /* 初始化主片 */
    outb (PIC_M_CTRL, 0x11);    //ICW1：边沿触发，级联8259，需要ICW4
    outb (PIC_M_DATA, 0x20);    //ICW2：起始中断向量号为0x20
                                //也就是IR[0-7]为0x20~0x27
    outb(PIC_M_DATA, 0x04);     //ICW3：IR2接从片
    outb (PIC_M_DATA, 0x01);    //ICW4:8086模式，正常EOI

    /* 初始化从片 */
    outb (PIC_S_CTRL, 0x11);    //ICW1：边沿触发，级联8259,需要ICW4
    outb (PIC_S_DATA, 0X28);    //ICW2：起始中断向量号为0x28
                                //也就是IR[8-15]为0x28~0x2F
    outb (PIC_S_DATA, 0x02);    //ICW3：设置从片连接到主片的IR2引脚
    outb (PIC_S_DATA, 0x01);    //ICW4：8086模式，正常EOI

    /*打开主片上IR0,也就是目前只接受时钟产生的中断*/
    /* 这里是OCW1操作,对外设的中断信号进行屏蔽*/
    outb (PIC_M_DATA, 0xfe);
    outb (PIC_S_DATA, 0xff);

    put_str(" pic_init done\n");
}

/* 完成有关中断的所有初始化工作*/
void idt_init(){
    put_str("idt_init start\n");
    idt_desc_init();    //初始化中断描述符表
    pic_init();         //初始化8259A

    /* 加载idt */
    //uint64_t idt_operand = ((sizeof(idt)-1) | ((uint64_t)((uint32_t)idt<<16)));
    uint64_t idt_operand = ((sizeof(idt)-1) | (((uint64_t)((uint32_t)idt))<<16));
    asm volatile("lidt %0": : "m" (idt_operand));//‘m’是内存约束
    put_str("idt_init done\n");

}
