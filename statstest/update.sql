
prompt
prompt ==============================
prompt == UPDATE
prompt ==============================
prompt


set serveroutput on size 1000000
set line 200

@@redo_size

set echo on
declare
	v_sql varchar2(1000);
	v_stale_percent integer;
begin

	for prec in (
		select partition_name
		from user_tab_partitions
		where table_name = 'STATSTEST'
		and partition_name != 'P0'
		and rownum <= 3
	)
	loop
		v_sql := 'update statstest partition(' || prec.partition_name || ') set d1=d1+1 where pk in (select pk from  statstest partition(' || prec.partition_name || ') where rownum <= 150000)';
		--v_sql := 'update statstest partition(' || prec.partition_name || ') set d1=d1+1 where pk in (select pk from  statstest partition(' || prec.partition_name || ') )';
		dbms_output.put_line(v_sql);
		execute immediate v_sql;
	end loop;
	commit;
end;
/

set echo off

@@redo_size

