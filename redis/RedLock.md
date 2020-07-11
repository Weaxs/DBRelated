> # RedLock

一种权威的基于 Redis 实现分布式锁的方式名叫 Redlock (官方地址：https://redis.io/topics/distlock)

> Redlock特性
  
    安全特性：互斥访问，即永远只有一个 client 能拿到锁
    避免死锁：最终 client 都可能拿到锁，不会出现死锁的情况，即使原本锁住某资源的 client crash 了或者出现了网络分区
    容错性：只要大部分 Redis 节点存活就可以正常提供服务   
    
> 在单机中获取锁

    使用以下命令获取锁(To acquire the lock, the way to go is the following)
    SET resource_name my_random_value NX PX 30000
    The command will set the key only if it does not already exist (NX option), with an expire of 30000 milliseconds (PX option).
    这个randow_value必须是所有 client 和所有锁请求发生期间唯一的。原因如下：
    如果client1拿到lock1后因为执行时间太长超过了过期时间30000毫秒，此时lock1会被释放并分配给client2。当client1执行完毕后，会造成client2获得到的锁被释放。
    所以为每个client分配唯一一个value值可以避免上述问题。
    但是匹配 value 和删除 key 在 Redis 中并不是一个原子性的操作，也没有类似保证原子性的指令，所以可能需要使用像 Lua 这样的脚本来处理了，因为 Lua 脚本可以 保证多个指令的原子性执行。
    
    
> Redlock算法

    在Redis的分布式环境中，我们假设有N个Redis master。这些节点完全互相独立，不存在主从复制或者其他集群协调机制。
    我们确保将在N个实例上使用与在Redis单实例下相同方法获取和释放锁。
    现在我们假设有5个Redis master节点，同时我们需要在5台服务器上面运行这些Redis实例，这样保证他们不会同时都宕掉。
    1. 到当前的时间，微秒单位
    2. 尝试顺序地在 5 个实例上申请锁，当然需要使用相同的 key 和 random value。
       这里一个 client 需要合理设置与 master 节点沟通的 timeout 大小，避免长时间和一个 fail 了的节点浪费时间
    3. 当 client 在大于等于 3 个 master 上成功申请到锁的时候，且它会计算申请锁消耗了多少时间，这部分消耗的时间采用获得锁的当下时间减去第一步获得的时间戳得。
       如果锁的持续时长（lock validity time）比流逝的时间多的话，那么锁就真正获取到了。
    4. 如果锁申请到了，那么锁真正的 lock validity time 应该是 origin（lock validity time） - 申请锁期间流逝的时间
    5. 如果 client 申请锁失败了，那么它就会在少部分申请成功锁的 master 节点上执行释放锁的操作，重置状态
    
    Redlock锁解决的问题：
        
        服务A申请到一把锁后，作为主机的Redis宕机了，则服务B在申请锁的时候会从从机那里获取这把锁，为了解决这个问题，提出了Redlock的算法，进行多点SET
    
> 失败重试
    
    如果一个 client 申请锁失败了，那么它需要稍等一会在重试避免多个 client 同时申请锁的情况。
    最好的情况是一个 client 需要几乎同时向 5 个 master 发起锁申请。
    另外就是如果 client 申请锁失败了它需要尽快在它曾经申请到锁的 master 上执行 unlock 操作，便于其他 client 获得这把锁，避免这些锁过期造成的时间浪费。
    当然如果这时候网络分区使得 client 无法联系上这些 master，那么这种浪费就是不得不付出的代价了。

> 放锁
    
    放锁操作很简单，就是依次释放所有节点上的锁就行了
    
> Redlock存在的问题
    
    1. 时间的不可靠
        例：① client1从A B C三个节点处申请到了锁，D E由于网络原因请求没有到达
            ② C 节点的时钟往前推了(服务器的时间回溯)，导致lock提前过期
            ③ client2在C D E处获得了锁，A B由于网络请求原因没有到达
            ④ 此时client1 和 client2都获取到了锁
    2. 进程 Pause
        例：① client1从A B C D E处获得了锁
            ② 当获得锁的response还没到达client1时client1进入GC停顿(STW, stop the world)
            ③ 停顿期间导致锁过期了
            ④ client2在A B C D E处获得了锁
            ⑤ client1 GC完成收到了获得所的response，此时两个client拿到了同一把锁
    
    这些例子说明了，仅有在你假设了一个同步性系统模型的基础上，Redlock 才能正常工作，也就是系统能满足以下属性：
        网络延时边界，即假设数据包一定能在某个最大延时之内到达
        进程停顿边界，即进程停顿一定在某个最大时间之内
        时钟错误边界，即不会从一个坏的 NTP 服务器处取得时间
   
