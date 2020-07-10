> # Zookeeper基础简要介绍

> 简介

    ZooKeeper是一个分布式协调服务框架
    一致性是通过基于Paxos算法的ZAB协议完成的
    
> ZAB (ZooKeeper Automic Broadcast) 原子广播协议

    ZAB中的三个角色：
        Leader      集群中唯一的写请求处理者，能发起投票 (写请求)
        Follower    能够接收客户端的请求，如果是读请求可以自己处理，写请求需要转发给Leader
        Observer    没有选举权和被选举权的Follower
    
    Zookeeper为什么推荐奇数个Server 因为投票选举需要超过半数
     
    ZAB中的两种模式：
        1.消息广播
        消息广播大体类似于Paxos算法
        在此基础上ZAB在Leader端为其他的zkServer维护了一个队列，采用先进先出的方式发送消息，保证了消息的发送顺序性和接受的顺序性
        ZAB还定义了一个全局单调递增的事务ID  ZXID  (64位long行)
        高32位表示 epoch年代  根据Leader的变化而变化， 低32位简单的递增事务id
        每个提案(proposal)在Leader中生成后需要通过ZXID来排序
        2.崩溃恢复
        两个阶段：1. Leader宕机需要重新选举  2. Zookeeper启动需要进行系统的Leader初始化选举
        对每个机器来说，都会首先投票给自己并广播，投票内容为服务器的myid和ZXID (ZXID初始均为0)  整个集群处于Looking状态
       在收到别的服务器的投票信息后与自己的作比较。首先比较ZXID，ZXID大的优先为Leader；相同则比较myid，myid大的优先为Leader
       如果发现别的服务器的投票信息比自己的大，就修改投票信息并广播，将自己的服务器设置为Follower
       当一个服务器的投票信息超过半数时，那个服务器就被选举为Leader，整个服务器从Looking变成正常状态
       当新的服务器加入发现集群没有处于Looking状态时，直接以Follower的身份加入集群
       
       保证数据一致性
       如果Follower挂了，Leader中会维护队列，不用担心不一致性
       如果Leader挂了，线暂停服务变为Looking状态然后重新选举，此时分为两种情况：
          1. 确保已经被Leader提交的提案最终能够被所有的Follower提交
             已经提交提案的Follower会被选举成Leader，同时维护队列以保证一致性
          2. 跳过那些已经被丢弃的提案
             Leader还未自身同意的时候就挂掉的提案，最终需要被抛弃掉
       
> 数据模型

    zookeeper数据存储结构与标准的Unix文件系统类似，都是在根节点下挂很多子节点 (树型)，由斜杠(/)的进行分割的路径，就是一个Znode例如/example/path1。
    zookeeper使用ZNode作为数据节点，ZNode是zookeeper中的最小数据单元，每个ZNode上都可以保存数据，同时挂载子节点
    
    znode有自己所属的 节点类型 和 节点状态
    节点类型：
        持久节点        一旦创建就一直存在，直到将其删除
        持久顺序节点     一个父节点可以为其子节点维护一个创建的先后顺序，书序体现在节点名称上，有一个10位数字组成呃数字串，从0开始计数
        临时节点        临时节点的生命周期始于客户端会话绑定，会话消失则节点消失。临时节点只能是叶子节点，不能创建子节点
        临时顺序节点     父节点可以创建一个维持了顺序的临时节点，同时生命周期与客户端会话绑定
    节点属性
        czxid           Created ZXID，创建节点时的事务ID
        mzxid           Modified ZXID，节点最后一次被更新时的事务ID
        ctime           Created Time，该节点被创建的时间
        mtime           Modified Time，该节点最后一次被修改的时间
        version         节点的版本号
        cversion        子节点的版本号
        aversion        节点的ACL版本号
        ephemeralOwner  创建该节点的会话的sessionID，如果该节点为持久节点，该值为0
        dataLength      节点数据内容的长度
        numChildre      该节点的子节点个数，如果为临时节点为0
        pzxid           该节点子节点列表最后一次被修改时的事务ID，注意是子节点的 列表 ，不是内容
        
    zk客户端和服务端通过TCP长连接维持会话机制 (保持连接状态)
    会话有对应的事件  例如 CONNECTION_LOSS 连接丢失事件 、SESSION_MOVED 会话转移事件 、SESSION_EXPIRED 会话超时失效事件
    
> ACL (Access Control Lists) 权限控制清单

    CREATE  创建子节点的权限
    READ    获取节点数据和子节点列表的权限
    WRITE   更新节点数据的权限
    DELETE  删除子节点的权限
    ADMIN   设置节点 ACL 的权限
    
> Watcher机制 事件监听器

    1. 客户端定义并生成watcher
    2. 客户端向服务端注册指定的watcher
    3. 当服务端符合了watcher的某些条件后触发watcher事件
    4. 服务端向客户端发送watcher事件通知
    5. 客户端收到通知后找到对应的watcher然后执行相应的回调
    
> 会话 (Session)
    
    Session指的是Zookeeper服务器与客户端会话。
    在Zookeeper中，一个客户端连接是指客户端和服务器之间的一个TCP长连接
    通过此TCP长连接，客户端能够通过心跳检测与服务器保持有效的会话，也能够向Zookeeper服务器发送请求并接收响应，同时能通过该连接接收来自服务器的Watch事件通知。
    Session的sessionTimeout值用来设置一个客户端会话的超时时间。
    当由于服务器压力太大、网络故障或是客户端主动断开连接等各种原因导致客户端连接断开时，只要在sessionTimeout规定的时间内能够重新连接上集群中任意一台服务器，那么之前创建的会话仍然有效。

> Zookeeper特点

    1. 顺序一致性：从同一客户端发起的事务请求，最终会严格地按照顺序被应用到Zookeeper中去。
    2. 原子性：所有事务请求的处理结果在整个集群中所有机器上的应用情况是一致的。要么整个集群中所有的机器都成功应用了某一个事务，要么都没有应用。
    3. 单一系统映像：无论客户端镰刀哪一个Zookeeper服务器上，其看到的服务端数据模型都是一致的。
    4. 可靠性：一旦一次更改请求被应用，更改的结果就会被持久化，直到被下一次更改覆盖。

> Zookeeper典型应用场景

    1. 选主
        因为Zookeeper在高并发情况下保证节点创建的全局唯一性(强一致性)，可以让多个客户端创建一个指定节点，创建成功的就是master
        利用 临时节点、节点状态和watch来实现选主功能。临时节点用于选举，节点状态和watcher用来判断master的活性并进行重新选举。
        
    2. 分布式锁
        zk在高并发的情况下保证节点创建的全局唯一性
        
    
    
    
    
    
    
    
    
    
    
    
    
          

    
    
