
-- import_schema_stats.sql
-- import statistics for a schema

-- comment this line to see variable subtitution
set verify off

col stattab_owner new_value stattab_owner noprint
col stat_table new_value stat_table noprint
col schema new_value schema noprint
col noinvalidate new_value noinvalidate noprint
col statid new_value statid noprint
col force_import new_value force_import noprint

prompt Import Stats Table Owner: 
set feed off term off
select upper('&1') stattab_owner from dual;
set term on

prompt Statistics Table Name:
set feed off term off
select upper('&2') stat_table from dual;
set term on

prompt Import Stats for Schema: 
set feed off term off
select upper('&3') schema from dual;
set term on

prompt Import Stats for StatID: 
set feed off term off
select upper('&4') statid from dual;
set term on

prompt NOINVALIDATE? YES/NO:
set feed off term off
select upper('&5') noinvalidate from dual;
set term on

prompt FORCE IMPORT? YES/NO:
set feed off term off
select upper('&6') force_import from dual;
set term on

set term on feed on

declare
	v_noinvalidate boolean := true;
	v_force_import boolean := false;
begin

	case '&&noinvalidate'
	when 'YES' then v_noinvalidate := true;
	else v_noinvalidate := false;
	end case;

	case '&&force_import'
	when 'YES' then v_force_import := true;
	else v_force_import := false;
	end case;

	dbms_output.put_line('=======================');
	dbms_output.put_line('schema  : &&schema');
	dbms_output.put_line('stattab : &&stat_table'); 
	dbms_output.put_line('statid  : &&statid');

	if v_noinvalidate then
		dbms_output.put_line('noinvalidate  : TRUE' );
	else
		dbms_output.put_line('noinvalidate  : FALSE' );
	end if;

	if v_force_import then
		dbms_output.put_line('force_import  : TRUE');
	else
		dbms_output.put_line('force_import  : FALSE');
	end if;

	DBMS_STATS.IMPORT_SCHEMA_STATS (
		ownname	=> '&&schema',
		stattab	=> '&&stat_table', 
		statid	=> '&&statid',
		statown	=> '&&stattab_owner',
		force		=> v_force_import, 
		no_invalidate => v_noinvalidate
	);

end;
/

