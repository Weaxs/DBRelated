# Redis跳表

    level3   1                                     119   null
    level2   1            21        37             119   null
    level1   1   7        21        37   71        119   null  
    level0   1   7   14   21   32   37   71   85   119   null   

跳跃表（skiplist）是一种有序数据结构， 它通过在每个节点中维持多个指向其他节点的指针， 从而达到快速访问节点的目的。

跳跃表支持平均 O(log N) 最坏 O(N) 复杂度的节点查找， 还可以通过顺序性操作来批量处理节点。

    Redis 的跳跃表由 redis.h/zskiplistNode 和 redis.h/zskiplist 两个结构定义
    zskiplistNode 结构用于表示跳跃表节点 
    zskiplist 结构则用于保存跳跃表节点的相关信息 

redis.h/zskiplistNode 结构定义

    typedef struct zskiplistNode {
        // 后退指针
        struct zskiplistNode *backward;
        // 分值
        double score;
        // 成员对象
        robj *obj;
        // 层
        struct zskiplistLevel {
            // 前进指针
            struct zskiplistNode *forward;
            // 跨度
            unsigned int span;
        } level[];
    } zskiplistNode;
* 层(level): 节点中用L1、L2、L3等字样标记节点的各个层，L1 代表第一层，L2 代表第二层，以此类推。每个层都带有两个属性：前进指针和跨度。
* 后退(backward)指针: 节点中用BW字样标记节点的后退指针，它指向位于当前节点的前一个节点。后退指针在程序从表尾向表头遍历时使用。
* 分值(score): 在跳跃表中，节点按各自所保存的分值从小到大排列。
* 成员对象(obj): 一个指向字符串对象的指针，而字符串对象则保存着一个SDS值。
* 前进(forward)指针: 每个层都有一个指向表尾方向的前进指针(level[i].forward 属性)，用于从表头向表尾方向访问节点。
* 跨度(span): 层的跨度(level[i].span 属性)用于记录和前进节点之间的距离。
    
redis.h/zskiplist 结构定义

    typedef struct zskiplist {
        // 表头节点和表尾节点
        struct zskiplistNode *header, *tail;
        // 表中节点的数量
        unsigned long length;
        // 表中层数最大的节点的层数
        int level;
    } zskiplist;

header和tail指针分别指向跳跃表的表头和表尾节点，通过这两个指针，定位表头节点和表尾节点的复杂度为O(1)。

通过使用length属性来记录节点的数量，程序可以在O(1)复杂度内返回跳跃表的长度。
