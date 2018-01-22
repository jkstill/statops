
define v_tablespace=USERS

drop table statstest purge;

create table statstest ( id number, pk number, d1 timestamp )
partition by range (id)
(
	partition p0 values less than (1),
	partition p1 values less than (2),
	partition p2 values less than (3),
	partition p3 values less than (4)
)
tablespace &&v_tablespace
nologging
/

create unique index statstest_idx_unq on statstest (id,pk)
pctfree 10 initrans 2 maxtrans 255
tablespace &&v_tablespace
local 
/


