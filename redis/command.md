# Redis命令参数

只有String类型可以在添加的时候直接设置过期时间,其他类型都需要通过EXPIRE key seconds/EXPIREAT key timestamp命令设置过期时间

## String

SET命令
    
    参数:
    EX seconds      将键的过期时间设置为seconds秒。 执行SET key value EX seconds的效果等同于执行SETEX key seconds value。
    PX milliseconds 将键的过期时间设置为 milliseconds 毫秒。 
                    执行SET key value PX milliseconds的效果等同于执行PSETEX key milliseconds value。
    NX              只在键不存在时，才对键进行设置操作。 执行SET key value NX 的效果等同于执行 SETNX key value。
    XX              只在键已经存在时，才对键进行设置操作。
    代码示例:
        SET key "value"
        GET key
        使用EX过期时间:
        SET key "value" EX 100
        GET key
        TTL key
        使用PX过期时间:
        SET key "value" PX 10000
        GET key
        PTTL key
        使用NX参数:
        SET key "value" NX
        GET key
        使用XX选项
        SET key "value" XX
  
GET命令

    返回值:
        如果键key不存在， 那么返回特殊值nil； 否则， 返回键key的值。
        如果键key的值并非字符串类型，那么返回一个错误，因为GET命令只能用于字符串值。
    
GETSET命令            将键 key 的值设为 value ， 并返回键 key 在被设置之前的旧值

    返回值
        返回给定键 key 的旧值。
        如果键key没有旧值， 也即是说，键key在被设置之前并不存在，那么命令返回 nil 。
        当键key存在但不是字符串类型时，命令返回一个错误。
    代码示例:
        redis> GETSET key "new_value"
        "old_value"
    
INCR命令

    为键key储存的数字值加上一。
    如果键 key 不存在， 那么它的值会先被初始化为 0 ， 然后再执行 INCR 命令。
    如果键 key 储存的值不能被解释为数字， 那么 INCR 命令将返回一个错误。
    返回值
        INCR命令会返回键key在执行加一操作之后的值
    
INCRBY命令 (INCRBY key increment)

    为键key存储的数字值加上增量increment
    如果键key不存在， 那么键key的值会先被初始化为0 ， 然后再执行INCRBY命令。
    如果键key储存的值不能被解释为数字， 那么INCRBY命令将返回一个错误。
    返回值
        在加上增量increment之后，键key当前的值。
    代码示例:
        INCRBY key 20
        
INCRBYFLOAT命令 (INCRBYFLOAT key increment)

    为键key储存的值加上浮点数增量increment。
    如果键key不存在，那么INCRBYFLOAT会先将键key的值设为0，然后再执行加法操作。
    如果命令执行成功，那么键key的值会被更新为执行加法计算之后的新值，并且新值会以字符串的形式返回给调用者。
    返回同INCR
    代码示例:
        INCRBYFLOAT key 2.56
        
DECR命令

    为键key储存的数字值减去一。
    返回值
        DECR命令会返回键key在执行减一操作之后的值
    代码示例:
        DECR key
        
DECRBY命令 (DECRBY key decrement)

    将键key储存的整数值减去减量decrement。
    返回值
        DECRBY命令会返回键在执行减法操作之后的值。
    代码示例:
        DECRBY key 20
    
## Hash

HSET命令 (HSET hash field value)

    将哈希表hash中域field的值设置为value
    如果给定的哈希表并不存在，那么一个新的哈希表将被创建并执行HSET操作。
    如果域field已经存在于哈希表中，那么它的旧值将被新值value覆盖。
    返回值
        当HSET命令在哈希表中新创建field域并成功为它设置值时，命令返回1；
        如果域field已经存在于哈希表，并且HSET命令成功使用新值覆盖了它的旧值，那么命令返回0。
    代码示例:
        HSET website google "www.google.com"
        
HSETNX命令 (HSETNX hash field value)

    当且仅当域field尚未存在于哈希表的情况下，将它的值设置为value。
    
HGET命令 (HGET hash field)

    返回哈希表中给定域的值。
    代码示例:
        HGET website google
        
## List
    
LPUSH命令 (LPUSH key value [value …])

    将一个或多个值value插入到列表key的表头
    返回值
        执行LPUSH命令后，返回列表的长度
    代码示例:
        LPUSH myList a b c d e
        
RPUSH命令 (RPUSH key value [value …])

    将一个或多个值value插入到列表key的表尾(最右边)。
    返回值
        表的长度
    代码示例:
        RPUSH myList f g
        
LPOP命令 (LPOP key)

    移除并返回列表key的头元素
    代码示例:
        LPOP myLisit
    
RPOP命令 (RPOP key)

    移除并返回列表key的尾元素
    
LSET命令 (LSET key index value)

    将列表key下标为index的元素的值设置为value
    返回值
        操作成功返回ok，否则返回错误信息
    代码示例:
        LSET list 3 "a"
        
LRANGE命令 (LRANGE key start stop)

    返回列表key中指定区间内的元素，区间以偏移量start和stop指定
    代码示例:
        LRANGE myList 0 2
        
## Set

SADD命令 (SADD key member [member …])

    将一个或多个member元素加入到集合key中，已经存在于集合的member元素将被忽略。
    返回值
        被添加到集合中的新元素的数量，不包括被忽略的元素
    代码示例:
        SADD bbs "123.cn" "baidu.com"
    
SISMEMBER key member

    判断member元素是否集合key的成员
    返回值
        如果member元素是集合的成员，返回1。 
        如果member元素不是集合的成员，或key不存在，返回0。
    
SREM命令 (SREM key member [member …])

    移除集合key中的一个或多个member元素，不存在的member元素会被忽略
    返回值
        返回被成功移除的元素的数量，不包括被忽略的元素
    代码示例:
        SREM languages python c
        
SCARD命令 (SCARD key)

    返回集合key的基数(集合中元素的数量)
    
SMEMBERS命令 (SMEMBERS key)

    返回集合key中的所有成员
    不存在的key被视为空集合
    
SINTER命令 (SINTER key [key …])

    返回一个集合的全部成员，该集合是所有给定集合的交集
    不存在的key被视为空集
    在给定集合当中有一个空集时，结果也是空集
    代码示例:
        SINTER group_1 group_2
        
SINTERSTORE命令 (SINTERSTORE destination key [key …])

    将SINTER命令得出的交集，保存到destination集合中
    返回值
        结果集中的成员数量
        
SUNION命令 (SUNION key [key …])

    返回一个集合的全部成员，该集合是所有给定集合的并集
    不存在的key被视为空集
    代码示例:
        SUNION group_1 group_2
        
SUNIONSTORE命令 (SUNIONSTORE destination key [key …])

    将SUNION命令得出的并集，保存到destination集合中
    返回值
        结果集中的元素数量
        
SDIFF命令 (SDIFF key [key …])

    返回一个集合的全部成员，该集合是所有给定集合之间的差集
    不存在的key被视为空集
    代码示例:
        SDIFF group_1 group_2
        
SDIFFSTORE命令 (SDIFFSTORE destination key [key …])

    将SDIFF命令得出的差集，保存到destination集合中
    返回值
        结果集中的元素数量
    
## ZSET
    
ZADD命令 (ZADD key score member [[score member] [score member] …])

    将一个或多个member元素及其score值加入到有序集key当中。
    如果某个member已经是有序集的成员，那么更新这个member的score值，并通过重新插入这个member元素，来保证该member在正确的位置上
    score值可以是整数值或双精度浮点数
    如果key不存在，则创建一个空的有序集合并执行ZADD操作
    返回值
        被成功添加的新成员的数量，不包括那些被更新的、已经存在的成员
    代码示例:
        ZADD key 1 value_1 0.5 value_2
    
ZSCORE命令 (ZSCORE key member)

    返回有序集key中，成员member的score值(以字符串形式表示)
    代码示例:
        ZSCORE key value_1
        
ZCARD命令 (ZCARD key)

    返回有序集key的基数(有序集合元素的数量)，key不存在时返回0。
    
ZCOUNT命令 (ZCOUNT key min max)

    返回有序集key中，score值在min和max之间(默认包括min和max的值)的成员的数量
    
ZRANGE命令 (ZRANGE key start stop [WITHSCORES])

    返回有序集key中，指定区间内的成员
    其中成员位置按scoer值递增(从小到大)来排序，具有相同score值的成员按字段序来排序
    返回值
        指定区间内，带有score值(可选)的有序集成员的列表
    代码示例:
        ZRANGE salary 200000 3000000 WITHSCORES
        ZRANGE salary 200000 3000000
        
ZREVRANGE命令 (ZREVRANGE key start stop [WITHSCORES])

    返回有序集key中，指定区间内的成员
    其中成员的位置按score递减(从大到小)来排序，具有相同score值的成员按字段序的逆序来排序
    返回值
        指定区间内，带有score值(可选)的有序集成员的列表
    代码示例:
        ZREVRANGE salary 200000 3000000 WITHSCORES
        ZREVRANGE salary 200000 3000000
        
ZRANK命令 (ZRANK key member)

    返回有序集key中成员member的排名。其中有序集成员按score值递增(从小到大)顺序排列。
    返回值
        如果member是有序集key的成员，返回member的排名。如果member不是有序集key的成员，返回nil。
    代码示例:
        ZRANK salary tom
        
ZREVRANK命令 (ZREVRANK key member)

    返回有序集key中成员member的排名。其中有序集成员按score值递减(从大到小)排序。
    返回值
        如果member是有序集key的成员，返回member的排名。如果member不是有序集key的成员，返回nil。
    代码示例:
        ZREVRANK salary tom
        
ZREM命令 (ZREM key member [member …])

    移除有序集key中的一个或多个成员，不存在的成员将被忽略。
    返回值
        被成功移除的成员数量，不包括被忽略的成员。
    代码示例:
        ZREM website baidu.com bing.com
