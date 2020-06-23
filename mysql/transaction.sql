# 测试 脏读/不可重复读/幻读 
## console_1

SELECT @@tx_isolation;

set session transaction isolation level read committed;
set session transaction isolation level repeatable read ;

# start transaction ;
begin ;
update transaction_test_db set field=2222 where id = 1;
insert transaction_test_db(id, field) value (2,2222);
commit ;

begin ;
update transaction_test_db set field=3333 where id = 1;
commit ;
rollback ;

## console_2

SELECT @@tx_isolation;

set session transaction isolation level read committed;
set session transaction isolation level repeatable read ;

# start transaction ;
begin ;
select field from transaction_test_dbt where  id in (1,2);
select field from transaction_test_db where  id in (1,2);
commit ;
