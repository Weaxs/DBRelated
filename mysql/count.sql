# 对于count(主键id)来说，InnoDB引擎会遍历整张表，把每一行的id值都取出来，返回给server层。server层拿到id后，判断是不可能为空的，就按行累加。
select count(id) from cpu_example;

# 对于count(1)来说，InnoDB引擎遍历整张表，但不取值。server层对于返回的每一行，放一个数字“1”进去，判断是不可能为空的，按行累加。
select count(1) from cpu_example;

# 如果这个“字段”是定义为not null的话，一行行地从记录里面读出这个字段，判断不能为null，按行累加
# 如果这个“字段”定义允许为null，那么执行的时候，判断到有可能是null，还要把值取出来再判断一下，不是null才累加。
select count(example) from cpu_example;

# 但是count()是例外，并不会把全部字段取出来，而是专门做了优化，不取值。count()肯定不是null，按行累加。
select count(*) from cpu_example;

# count(字段)<count(主键id)<count(1)≈count(*)
