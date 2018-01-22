
-- export.sql
-- export current production stats to stats table

col stat_table new_value stat_table noprint
col stats_type new_value stats_type noprint
col stattab_owner new_value stattab_owner noprint

-- comment this line to see variable subtitution
set verify off

prompt Stats Table Owner:
set feed off term off
select upper('&1') stattab_owner from dual;
set term on

prompt Statistics Table Name:
set feed off term off
select upper('&2') stat_table from dual;

set term on
prompt Statistics Type: valid values - SYSTEM_STATS DICTIONARY_STATS FIXED_OBJECTS_STATS
set feed off term off
select upper('&3') stats_type from dual;

set term on feed on
set serveroutput on size 1000000

declare
	v_database_name varchar2(8 char);
	v_statid varchar2(30);
begin

	select substr(name,1,8) into v_database_name from v$database;
	v_statid	:= substr('&&stats_type',1,4) || '_' || v_database_name || '_' || to_char(sysdate,'yymmddhh24mi');

	dbms_output.put_line('Table Owner: &&stattab_owner');
	dbms_output.put_line('Table Name : &&stat_table');
	dbms_output.put_line('Stat ID    : ' || v_statid);
	dbms_output.put_line('Database   : ' || v_database_name);

	DBMS_STATS.EXPORT_&&stats_type (
		stattab	=> '&&stat_table', 
		statid	=> v_statid,
		statown	=> '&&stattab_owner'
	);

end;
/

