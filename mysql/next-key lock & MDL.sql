## next-key lock两个“原则”、两个“优化”和一个“bug”。
# 1.原则 1：加锁的基本单位是 next-key lock。前开后闭区间。
# 2.原则 2：查找过程中访问到的对象才会加锁。
# 3.优化 1：索引上的等值查询，给唯一索引加锁的时候，next-key lock 退化为行锁。
# 4.优化 2：索引上的等值查询，向右遍历时且最后一个值不满足等值条件的时候，next-key lock 退化为间隙锁。
# 5.一个 bug：唯一索引上的范围查询会访问到不满足条件的第一个值为止。
# 共享锁：lock in shrae mode    排他锁：for update

create table cpu_pubapp.example
(
    id    int not_null primary key,
    value int         null,
    text  varchar(10) null
);
create index example_value_index on cpu_pubapp.example (value);
insert into example values(0,0,'零'),(5,5,'五'),(10,10,'十'),(15,15,'十五'),(20,20,'二十'),(25,25,'二五');
# 间隙(id)：(-∞ - 0),(0 - 5),(5 - 10),(10 - 15),(15 - 20),(20 - 25),(25 - ∞)
# 间隙(value)：(-∞ - 0),(0 - 5),(5 - 10),(10 - 15),(15 - 20),(20 - 25),(25 - ∞)



#   ------  等值条件操作间隙  ------
# console_1
begin ;
update example set text = '柒' where id = 7;
# console_2
insert into example value (8,8,'八');                # blocked & waiting
# console_3
update example set text = '十十' where id = 10;      # OK
# 根据原则1，console_1加next-key lock的范围是(5,10];根据优化2，id=7不满足索引上的等值条件,退化为间隙锁(5,10)。故2被锁住，3执行成功。

#   ------  非唯一索引等值锁  ------
# console_1
begin;
select id from example where value = 5 lock in share mode; # 覆盖索引 (查询条件是二级索引/辅助索引/非聚合索引，select后面是id)
# console_2
update example set text = '柒' where value = 7;      # OK    未被加锁个人认为：先通过value=7的辅助索引树+聚合索引获取该条记录的位置select(因为是读锁所以未锁)，查不出来数据所以没加锁
update example set text = '五五' where id = 5;       # OK    读锁在索引覆盖情况下，只给辅助索引B+树加锁
update example set value = 6 where value = 4;        # OK
update example set text = '五五' where value > 4;    # OK
# console_3
insert into example value (7,7,'柒');                # blocked & waiting    
insert into example value (3,3,'三');                # blocked & waiting
update example set text = '五五' where value = 5;    # blocked & waiting      被锁个人认为：先通过value=5的辅助索引+聚合索引获取记录位置(此时不加锁)，然后尝试获取路径上的X锁时被阻塞
update example set text = '五五' where value > 4 and value < 15;      # blocked & waiting
# 根据原则1，next-key lock加锁范围为(0,5];因为value是普通索引，需要向右遍历，查到value=10。根据原则2+优化2，加锁范围为(5,10)  加锁范围(0,10)
# lock in share mode 在索引覆盖的情况下，只锁辅助索引B+树;for update 时，系统会认为你接下来要更新数据，因此会顺便给主键索引上满足条件的行加上行锁，即锁辅助索引和聚合索引的B+树
# lock in share mode 来给行加读锁避免数据被更新的话，就必须得绕过覆盖索引的优化，在查询字段中加入索引中不存在的字段
# 锁是在加在索引上的

#   ------  主键索引范围锁  ------
# console_1
begin;
select * from example where id >= 10 and id < 11 for update;
# console_2
insert into example value (8,8,'八');             # OK
insert into example value (13,13,'十三');         # blocked & waiting   
# console_3
update example set text='十五一' where id = 15;   # blocked & waiting
# 根据原则1，加锁(5,10]，根据优化1，id=10退化成行锁;根据范围查询，继续往后到id=15，因此加锁(10,15]，因为非等值查询，所以不走优化  加锁范围[10,15]
                                                         


                                                         
      
                                                         
## metadata lock
#console_1
begin;
select * from example;
#commit;
#console_2
alter table example alter column text set default 'default';     # blocked & waiting 
begin;                                                           # blocked & waiting 
select * from example;                                           # blocked & waiting 
commit;                                                          # blocked & waiting 
