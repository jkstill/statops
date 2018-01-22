
-- create_stat_table.sql
-- create the stats table


-- comment this line to see variable subtitution
set verify off

col tab_owner new_value tab_owner noprint
col stat_table new_value stat_table noprint
col tbs_name new_value tbs_name noprint

set term on
prompt Statistics Table Owner:
set feed off term off
select upper('&1') tab_owner from dual;

set term on
prompt Statistics Table Name: 
set feed off term off
select upper('&2') stat_table from dual;

set term on
prompt Tablespace Name:
set feed off term off
select upper('&3') tbs_name from dual;

set term on feed on

--select 'STAT_TABLE: &&stat_table' from dual;
--select 'TBS_NAME: &&tbs_name' from dual;

declare
	v_table_name varchar2(30);
	v_tablespace_name varchar2(30);
	v_stattab_owner varchar2(30);
begin

	v_table_name := '&&stat_table';
	v_stattab_owner := '&&tab_owner';

	if 'NULL' = '&&tbs_name' then
		select default_tablespace into v_tablespace_name
		from dba_users
		where username = v_stattab_owner;
	else
		v_tablespace_name := '&&tbs_name';
	end if;

	DBMS_STATS.CREATE_STAT_TABLE (
		ownname => v_stattab_owner,
		stattab => v_table_name,
		tblspace => v_tablespace_name
	);

end;
/



