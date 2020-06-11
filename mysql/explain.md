> # Explain 详解

    EXPLAIN SELECT 1;
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra          |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
    |  1 | SIMPLE      | NULL  | NULL       | NULL | NULL          | NULL | NULL    | NULL | NULL |     NULL | No tables used |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
    1 row in set, 1 warning (0.01 sec)

    id              在一个大的查询语句中每个SELECT关键字都对应一个唯一的id
    select_type     SELECT关键字对应的那个查询的类型
    table           表名
    partitions      匹配的分区信息
    type	        针对单表的访问方法
    possible_keys	可能用到的索引
    key             实际上使用的索引
    key_len	        实际使用到的索引长度(索引列可以存储NULL值的话，多1个字节)
    ref             当使用索引列等值查询时，与索引列进行等值匹配的对象信息
    rows	        预估的需要读取的记录条数
    filtered        某个表经过搜索条件过滤后剩余记录条数的百分比
    Extra	        一些额外的信息

    MySQL规定EXPLAIN语句输出的每条记录都对应着某个单表的访问方法，该条记录的table列代表着该表的表名

    select_type值:
        SIMPLE              简单的SELECT语句(不包括UNION操作或子查询操作)
        PRIMARY             查询中最外层/左边的SELECT(如两表做UNION或者存在子查询的外层的表操作为PRIMARY，内层的操作为UNION)
        UNION               UNION操作中，查询中处于内层的SELECT(内层的SELECT语句与外层的SELECT语句没有依赖关系)
        DEPENDENT UNION     UNION操作中，查询中处于内层的SELECT(内层的SELECT语句与外层的SELECT语句有依赖关系)
        UNION RESULT        UNION操作的结果，id值通常为NULL
        SUBQUERY            子查询中首个SELECT，且子查询是不相关子查询(如果有多个子查询存在) 
        DEPENDENT SUBQUERY  子查询中首个SELECT，但依赖于外层的表，即相关子查询(如果有多个子查询存在) 相关子查询
        DEPENDENT UNION     在包含UNION或者UNION ALL的大查询中，如果各个小查询都依赖于外层查询的话，那除了最左边的那个小查询之外，其余的小查询的select_type的值就是DEPENDENT UNION。
        DERIVED             被驱动的SELECT子查询(子查询位于FROM子句)
        MATERIALIZED        被物化的子查询(将子查询物化之后与外层查询进行连接查询)

    type值:
        system          当表中只有一条记录并且该表使用的存储引擎的统计数据是精确的，比如MyISAM、Memory。
        const           据主键或者唯一二级索引列与常数进行等值匹配时，对单表的访问方法就是const。
        eq_ref          在连接查询时，如果被驱动表是通过主键或者唯一二级索引列等值匹配的方式进行访问的(如果该主键或者唯一二级索引是联合索引的话，所有的索引列都必须进行等值比较)。
        ref             通过普通的二级索引列与常量进行等值匹配时来查询某个表
        fulltext        全文索引
        ref_or_null     对普通二级索引进行等值匹配查询，该索引列的值也可以是NULL值
        index_merge     索引合并的方式来执行查询
        unique_subquery 针对在一些包含IN子查询的查询语句中，如果查询优化器决定将IN子查询转换为EXISTS子查询，而且子查询可以使用到主键进行等值匹配
        index_subquery  与unique_subquery类似，只不过访问子查询中的表时使用的是普通的索引
        range           使用索引获取某些范围区间的记录
        index           使用索引覆盖，但需要扫描全部的索引记录
        ALL             全表扫描



    在连接查询的执行计划中，每个表都会对应一条记录，这些记录的id列的值是相同的，出现在前边的表表示驱动表，出现在后边的表表示被驱动表。如下:
    mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2;
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                                 |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
    |  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL                                  |
    |  1 | SIMPLE      | s2    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |   100.00 | Using join buffer (Block Nested Loop) |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
    2 rows in set, 1 warning (0.01 sec)
    

    在嵌套查询的执行计划中，每个表会涉及多个SELECT关键字，所以在嵌套查询语句的执行计划中，每个SELECT关键字都会对应一个唯一的id值。如下:
    mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2) OR key3 = 'a';
    +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
    | id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
    +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
    |  1 | PRIMARY     | s1    | NULL       | ALL   | idx_key3      | NULL     | NULL    | NULL | 9688 |   100.00 | Using where |
    |  2 | SUBQUERY    | s2    | NULL       | index | idx_key1      | idx_key1 | 303     | NULL | 9954 |   100.00 | Using index |
    +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
    2 rows in set, 1 warning (0.02 sec)
    但是，查询优化器可能对设计子表查询的查询语句进行重写，将其转换为连接查询,使其具有相同的id值。例如:
    mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key3 FROM s2 WHERE common_field = 'a');
    +----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
    | id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra                        |
    +----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
    |  1 | SIMPLE      | s2    | NULL       | ALL  | idx_key3      | NULL     | NULL    | NULL              | 9954 |    10.00 | Using where; Start temporary |
    |  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s2.key3 |    1 |   100.00 | End temporary                |
    +----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
    2 rows in set, 1 warning (0.00 sec)

    对于包含UNION子句的查询语句来说，每个SELECT关键字对应一个id值也是没错的，但是如果UNION需要去重时会在内部创建一个名字类似于<union1,2>的临时表，id为NULL表明这个临时表是为了合并两个查询的结果集而创建的。具体执行方案表现如下:
    mysql> EXPLAIN SELECT * FROM s1  UNION SELECT * FROM s2;
    +----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
    | id | select_type  | table      | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra           |
    +----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
    |  1 | PRIMARY      | s1         | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL            |
    |  2 | UNION        | s2         | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |   100.00 | NULL            |
    | NULL | UNION RESULT | <union1,2> | NULL       | ALL  | NULL          | NULL | NULL    | NULL | NULL |     NULL | Using temporary |
    +----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
    3 rows in set, 1 warning (0.00 sec)
    但是跟UNION对比起来，UNION ALL就不需要为最终的结果集进行去重，它只是单纯的把多个查询的结果集中的记录合并成一个并返回给用户，所以也就不需要使用临时表。所以在包含UNION ALL子句的查询的执行计划中，就没有那个id为NULL的记录，如下所示：
    mysql> EXPLAIN SELECT * FROM s1  UNION ALL SELECT * FROM s2;
    +----+-------------+-------+------------+------+--------------- +------+---------+------+------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------+
    |  1 | PRIMARY     | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL  |
    |  2 | UNION       | s2    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------+
    2 rows in set, 1 warning (0.01 sec)

