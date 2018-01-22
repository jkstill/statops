
prompt
prompt ==============================
prompt == CREATE
prompt ==============================
prompt

set timing on
define v_tablespace='USERS'

set echo on

drop table statstest purge;

create table statstest ( id number, pk number, d1 timestamp )
partition by range (id) interval (1)
subpartition by hash(id)
subpartitions 4
(
	partition p0 values less than (1)
)
tablespace &&v_tablespace
nologging
/

exec dbms_stats.lock_table_stats(user,'STATSTEST')

-- create 20 partitions, create an index, then gather stats

begin
	for i in 1..20
	loop

		insert /*+ append */
		into statstest
		select i, level * i pk, systimestamp
		from dual
		connect by level <= 100000;

		commit;
	end loop;

end;
/

create unique index statstest_idx_unq on statstest (id,pk)
pctfree 10 initrans 2 maxtrans 255
tablespace &&v_tablespace
local 
/

set echo off
