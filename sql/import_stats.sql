
-- import_stats.sql
-- import stats for dictioary, fixed_objects and system

-- if an argument has a value of 'NULL', then convert it to null

-- comment this line to see variable subtitution
set verify off

col stattab new_value stattab noprint
col stattab_owner new_value stattab_owner noprint
col stats_type new_value stats_type noprint
col noinvalidate new_value noinvalidate noprint
col statid new_value statid noprint
col force_import new_value force_import noprint

prompt Stats Table Owner: 
set feed off term off
select upper('&1') stattab_owner from dual;
set term on

prompt Statistics Table Name:
set feed off term off
select upper('&2') stattab from dual;
set term on

prompt Import StatID: 
set feed off term off
select upper('&3') statid from dual;
set term on

prompt  Import Stats Type: valid values are SYSTEM_STATS DICTIONARY_STATS FIXED_OBJECTS_STATS
set feed off term off
select upper('&4') stats_type from dual;
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
set serveroutput on size 1000000

declare
	v_stattab_owner varchar2(30);
	v_stattab varchar2(30);
	v_statid varchar2(30);
	v_noinvalidate boolean := true;
	v_force_import boolean := false;
begin

	case '&&stattab_owner' 
	when 'NULL' then v_stattab_owner := null;
	else v_stattab_owner := '&&stattab_owner';
	end case;

	case '&&stattab' 
	when 'NULL' then v_stattab := null;
	else v_stattab := '&&stattab';
	end case;

	case '&&statid' 
	when 'NULL' then v_statid := null;
	else v_statid := '&&statid';
	end case;

	case '&&noinvalidate' 
	when 'YES' then v_noinvalidate := true;
	else v_noinvalidate := false;
	end case;

	dbms_output.put_line('=======================');
	dbms_output.put_line('stattab_owner : ' || v_stattab_owner);
	dbms_output.put_line('stattab : ' || v_stattab);
	dbms_output.put_line('statid  : ' || v_statid);
	dbms_output.put_line('stats type  : ' || '&&stats_type');

	if v_noinvalidate then
		dbms_output.put_line('noinvalidate  : TRUE');
	else
		dbms_output.put_line('noinvalidate  : FALSE');
	end if;
	
	if v_force_import then
		dbms_output.put_line('force_import  : TRUE');
	else
		dbms_output.put_line('force_import  : FALSE');
	end if;
	
	if '&&stats_type' = 'SYSTEM_STATS' then
		DBMS_STATS.IMPORT_SYSTEM_STATS (
			stattab			=> v_stattab,
			statid			=> v_statid,
			statown			=> v_stattab_owner
		); 
	elsif '&&stats_type' = 'DICTIONARY_STATS' then
		DBMS_STATS.IMPORT_DICTIONARY_STATS (
			stattab			=> v_stattab,
			statid			=> v_statid,
			statown			=> v_stattab_owner,
			no_invalidate	=> v_noinvalidate,
			force				=> v_force_import
		); 
	elsif '&&stats_type' = 'FIXED_OBJECTS_STATS' then
		DBMS_STATS.IMPORT_FIXED_OBJECTS_STATS (
			stattab			=> v_stattab,
			statid			=> v_statid,
			statown			=> v_stattab_owner,
			no_invalidate	=> v_noinvalidate,
			force				=> v_force_import
		); 
	end if;

end;
/


