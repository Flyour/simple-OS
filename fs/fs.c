#include "fs.h"
#include "stdint.h"
#include "global.h"

/* 格式化分区，也就是初始化分区的元信息， 创建文件系统 */
static void partition_format(struct disk* hd, struct partition* part) {
    /* blocks_bitmap_init(为方便实现，一个块大小是一扇区) */
    uint32_t boot_sector_sects = 1;
    uint32_t super_block_sects = 1;
    uint32_t inode_bitmap_sects =   \
        DIV_ROUND_UP(MAX_FILES_PER_PART, BITS_PER_SECTOR);
    // I节点位图占用的扇区数，最多支持4096个文件
    uint32_t inode_table_sects = DIV_ROUND_UP((\
                (sizeof(struct inode) *MAX_FILES_PER_PART)), SECTOR_SIZE);
    uint32_t used_sects = boot_sector_sects + super_block_sects +\
                          inode_bitmap_sects + inode_table_sects;
    uint32_t free_sects = part->sec_cnt - used_sects;

    /************* 简单处理块位图占据的扇区数***************************/
    uint32_t block_bitmap_sects;
    block_bitmap_sects = DIV_ROUND_UP(free_sects, BITS_PER_SECTOR);
    /* block_bitmap_bit_len是位图中位的长度，也是可用块的数量 */
    uint32_t block_bitmap_bit_len = free_sects - block_bitmap_sects;
    block_bitmap_sects = DIV_ROUND_UP(block_bitmap_bit_len, \
            BITS_PER_SECTOR);
    /*****************************************************************/

    /* 超级块初始化 */
    struct super_block sb;
    sb.magic = 0x19590318;
    sb.sec_cnt = part->sec_cnt;
    sb.inode_cnt = MAX_FILES_PER_PART;
    sb.part_lba_base = part->start_lba;

    sb.block_bitmap_lba = sb.part_lba_base + 2;
    //第0块是引导块，第1块是超级块
    sb.block_bitmap_sects = block_bitmap_sects;

    sb.inode_bitmap_lba = sb.block_bitmap_lba + sb.block_bitmap_sects;
    sb.inode_bitmap_sects = inode_bitmap_sects;

    sb.inode_table_lba = sb.inode_bitmap_lba + sb.inode_bitmap_sects;
    sb.inode_table_sects = inode_table_sects;

    sb.data_start_lba = sb.inode_table_lba + sb.inode_table_sects;
    sb.root_inode_no = 0;
    sb.dir_entry_size = sizeof(struct dir_entry);

    printk("%s info:\n", part->name);
    printk("    magic:0x%x\n    part_lba_base:0x%x\n
            all_sectors:0x%x\n  inode_cnt:0x%x\nblock_bitmap_lba:0x%x\n
            block_bitmap_sectors:0x%x\n inode_bitmap_lba:0x%x\n
            inode_bitmap_sectors:0x%x\ninode_table_lba:0x%x\n
            inode_table_sectors:0x%x\ndata_start_lba:0x%x\n",
            sb.magic, sb.part_lba_base, sb.sec_cnt, sb.inode_cnt, \
            sb.block_bitmap_lba, sb.block_bitmap_sects, sb.inode_bitmap_lba, \
            sb.inode_bitmap_sects, sb.inode_table_lba,  \
            sb.inode_table_sects, sb.data_start_lba);
}
