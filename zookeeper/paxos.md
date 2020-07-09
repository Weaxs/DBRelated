> # Paxos算法

    Paxos算法是基于 消息传递 且 具有高度容错特性的一致性算法
    解决的问题就是 在分布式系统中如何就某个值(决议)达成一致
    
    Paxos算法中的三个角色：
        Proposer 提案者
        Acceptor 表决者
        Learner  学习者
    Paxos算法的两个阶段
        Prepare
        Accept
        
> Prepare 阶段

    1. 每个提案者(Proposer)在提出提案(Proposal)时会首先获取到一个 具有全局唯一性、递增的提案编号N
       提案者向所有表决者(Acceptor)发送prepare(N)的指令，将提案的编号发送给所有的表决者
    2. 表决者在收到提案后，将提案编号N记录在本地，每个表决者中保存的已经被accept的提案中会存在一个编号最大的提案(maxN)
       每个表决者只accept编号大于自己本地maxN的提案。
       表决者向提案者发送propsql(myid, maxN, value)
       myid是该表决者结点的编号   maxN为本地存储的最大提案编号(为null表示批准)   value为以前批准过的最大提案的提案内容(为null表示批准)
       
> Accept 阶段

    准备阶段后，如果提案者(Proposer)收到了超过半数的表决者(Accept)的批准，此时进入Accept阶段，非所有的表决者发送真正的提案(Proposal)
    1. 提案者向所有表决者发送proposal(myid, N, value)指令，myid是提案者结点的编号，N和value为此次提案的编号和提案内容
    2. 表决者收到提案后会再次比较本身已经批准过的最大提案编号和该提案编号
        如果 该提案编号 >= 已批准过的最大提案编号，则accep该提案并返回给提案者
        如果 该提案编号 < 已批准过的最大提案编号，则不回应或者返回NO
    3. 当提案者收到超过半数表决者的accept，此时向所有的表决者发送提案的提交请求，并让所有表决者提交执行
        对于未批准的表决者发送proposal(myid, N, value)让它无条件执行和提交
        对于批准过的表决者仅仅发送该提案的编号N
       如果 提案者如果没有收到超过半数的accept，那么它将会将递增该提案的编号，然后重新进入Prepare阶段
       
> Paxos算法存在的问题

    死循环问题：
        此时提案者P1提出一个提案M1，完成了Prepare阶段，同时提案者P2提出了一个提案M2，也完成了Prepare阶段
        提案M1在进行Accept阶段的时候将不会被批准(M2提案编号 > M1提案编号)
        提案者P1自增提案编号为M3并进入Prepare阶段
        提案M2在进行Accept阶段的时候将不会被批准(M3提案编号 > M2提案编号)