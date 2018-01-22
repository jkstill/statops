
-- delete_schema_stats.sql
-- delete statistics for a schema

-- if stattab is null then the statistics are deleted directly from the dictionary
-- otherwise they are deleted from the stattab table
-- (statid guaranteed to be null as well when this script is called from delete_stats.sh)

-- if an argument has a value of 'NULL', then convert it to null

-- comment this line to see variable subtitution
set verify off

col stat_table new_value stat_table noprint
col schema new_value schema noprint
col statid new_value statid noprint
col noinvalidate new_value noinvalidate noprint
col force_delete new_value force_delete noprint

var v_stattab varchar2(20);
var v_statid varchar2(30);

prompt Delete Stats for Schema: 
set feed off term off
select upper('&1') schema from dual;
set term on

prompt Statistics Table Name:
set feed off term off
select upper('&2') stat_table from dual;
set term on

prompt Delete Stats for StatID: 
set feed off term off
select upper('&3') statid from dual;

prompt NOINVALIDATE? YES/NO:
set feed off term off
select upper('&4') noinvalidate from dual;
set term on

prompt FORCE DELETE? YES/NO:
set feed off term off
select upper('&5') force_delete from dual;
set term on

set term on feed on
set serveroutput on size 1000000

declare
	v_noinvalidate boolean := true;
	v_force_delete boolean := false;
begin

	case '&&stat_table' 
	when 'NULL' then :v_stattab := null;
	else :v_stattab := '&&stat_table';
	end case;

	case '&&statid' 
	when 'NULL' then :v_statid := null;
	else :v_statid := '&&statid';
	end case;

	case '&&noinvalidate'
	when 'YES' then v_noinvalidate := true;
	else v_noinvalidate := false;
	end case;

	case '&&force_delete'
	when 'YES' then v_force_delete := true;
	else v_force_delete := false;
	end case;

	dbms_output.put_line('=======================');
	dbms_output.put_line('schema  : ' || '&&schema');
	dbms_output.put_line('stattab : ' || :v_stattab);
	dbms_output.put_line('statid  : ' || :v_statid);

	if v_noinvalidate then
		dbms_output.put_line('noinvalidate  : TRUE' );
	else
		dbms_output.put_line('noinvalidate  : FALSE' );
	end if;

	if v_force_delete then
		dbms_output.put_line('force_delete  : TRUE');
	else
		dbms_output.put_line('force_delete  : FALSE');
	end if;

	DBMS_STATS.DELETE_SCHEMA_STATS (
		ownname	=> '&&schema',
		stattab	=> :v_stattab, 
		statid	=> :v_statid,
		statown	=> user,
		no_invalidate => v_noinvalidate
	);

end;
/

