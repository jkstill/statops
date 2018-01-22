

-- gather_schema_stats.sql
-- as the name implies, gather stats for a schema.
-- this script does not use the dbms_stats.gather_schema_stats 
-- procedure, but rather gets stats for an object at a time

-- oracle bug 5645718 is addressed by Patch 6637265 (Jan 15 2008 CPU)
-- this bug causes an occasional "ORA-01476: divisor is equal to zero"
-- as this patch is not yet applied to SAP databases, a workaround
-- of capturing the error is in place

-- gather table stats separately with cascade=>false, method_opt=>'for
-- all columns size 1' and, if necessary because of table size, use
--    estimate_percent=>dbms_stats.auto_sample_size
--
-- gather index stats separately with estimate_percent=>100
-- gather any column statistics separately with estimate_percent=>100
-- and of course cascade=>false
-- do any other statistics manipulation

-- comment this line to see variable subtitution
--
-- for 11g+ versions auto_sample_size will be used
-- pre earlier versions 100% will be used

set verify off

col stat_id new_value stat_id noprint
col schema new_value schema noprint
col days_old new_value days_old noprint
col degree new_value degree noprint
col oversion new_value oversion noprint
col sample_size new_value sample_size noprint

var oversion varchar2(2)
var sample_size number

prompt Gather Stats for Schema:
set feed off term off
select upper('&1') schema from dual;
set term on

prompt Gather when stats past the age of? :
set feed off term off
select '&2' days_old from dual;
set term on

prompt Parallel Degree? :
set feed off term off
select '&3' degree from dual;

-- get sample size default
select substr(version,1,instr(version,'.',1,1)-1) oversion
from product_component_version
where product like 'Oracle%';

begin
	if to_number('&&oversion') >= 11 then
		:sample_size := dbms_stats.auto_sample_size;
	else
		:sample_size := 100;
	end if;
end;
/

select :sample_size sample_size from dual;

set term on

prompt
prompt Gathering Stats for Schema: &&SCHEMA
prompt Where stats are greater than &&days_old days old
prompt Using a Sample Size of &&sample_size
prompt And a Parallel Degree of &&degree
prompt

-- create the error table
declare
	v_tab_count integer;
	v_sql varchar2(1000);
	c_tab_name varchar2(30) := 'DBMS_STATS_ERRORS';
begin
	-- assume schema of logon user
	select count(*) into v_tab_count
	from user_tables
	where table_name = c_tab_name;

	dbms_output.put_line('v_tab_count = ' || v_tab_count);

	if v_tab_count = 0 then
		v_sql := 'create table ' || c_tab_name || '('
			|| 'owner varchar2(30),'
			|| 'object_type varchar2(30),'
			|| 'object_name varchar2(30),'
			|| 'error_code number(6),'
			|| 'error_msg varchar2(50),'
			|| 'error_date date default sysdate)';

		execute immediate v_sql;
		
		dbms_output.put_line('created create_error_table ');
	end if;
		
	dbms_output.put_line('create_error_table complete');
end;
/

declare

	-- get objects that have not been analyzed in last 2 weeks
	-- should parameterize this later

	cursor gettab (v_owner_in varchar2, v_days_old_in number)
	is
	select owner,table_name
	from dba_tables
	where owner = upper(v_owner_in)
	and (
		last_analyzed < sysdate - v_days_old_in
		or
		last_analyzed is null
	);

	cursor getidx (v_owner_in varchar2, v_days_old_in number)
	is
	select owner,index_name
	from dba_indexes
	where owner = upper(v_owner_in)
	and (
		last_analyzed < sysdate - v_days_old_in
		or
		last_analyzed is null
	);

	v_errc integer;
	v_errm varchar2(50);

begin

	for tabrec in gettab('&&SCHEMA', '&&days_old')
	loop
		begin
			-- quotes are necessary around object names as 
			-- non-alphanumeric characters are used
			dbms_stats.gather_table_stats (
				ownname 				=> tabrec.owner,
				tabname 				=> '"' || tabrec.table_name || '"',
				cascade				=> false,
				--degree				=> dbms_stats.default_degree,
				degree				=> '&&degree',
				estimate_percent	=> :sample_size,
				method_opt 			=>'FOR ALL COLUMNS SIZE 1' 
			);
		exception
		when others then
			v_errm := substr(sqlerrm,1,50);
			v_errc := sqlcode;
			insert into dbms_stats_errors (owner,object_type, object_name, error_code, error_msg)
			values(tabrec.owner,'TABLE',tabrec.table_name,v_errc,v_errm);
			commit;
		end;
	end loop;

	for idxrec in getidx('&&SCHEMA', '&&days_old')
	loop
		begin
			dbms_stats.gather_index_stats (
				ownname 				=> idxrec.owner,
				indname 				=> '"' || idxrec.index_name || '"',
				--degree				=> dbms_stats.default_degree,
				degree				=> '&&degree',
				estimate_percent	=> :sample_size
			);
		exception
		when others then
			v_errm := substr(sqlerrm,1,50);
			v_errc := sqlcode;
			insert into dbms_stats_errors (owner,object_type, object_name, error_code, error_msg)
			values(idxrec.owner,'INDEX',idxrec.index_name,v_errc,v_errm);
			commit;
		end;
	end loop;

end;
/


undef 1 2

