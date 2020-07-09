create table example
(
	id int null,
	text varchar(50) null
);


# metadata lock
#console_1
begin;
select * from example;
#commit;
#console_2
alter table example alter column text set default 'default'; # 堵塞
begin; # 堵塞
select * from example; # 堵塞
commit; # 堵塞

