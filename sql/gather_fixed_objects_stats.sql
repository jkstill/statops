
-- gather_fixed_objects_stats.sql
-- gather statistics for fixed objects

-- dbms_stats.gather_fixed_objects_stats is unlike gathering
-- schema stats in that stats may be saved either in the dictionary
-- or in a stat table.

-- I do not know why export_fixed_objects_stats is also necessary

-- if stattab is null then the stats are saved to the dictionary
-- otherwise they are saved to the stattab table
-- (statid guaranteed to be null as well when this script is called from gather_fixed_objects_stats.sh)

-- if an argument has a value of 'NULL', then convert it to null

-- comment this line to see variable subtitution
set verify off

col stattab new_value stattab noprint
col stattab_owner new_value stattab_owner noprint
col noinvalidate new_value noinvalidate noprint
col statid new_value statid noprint

prompt Stats Table Owner for Schema: 
set feed off term off
select upper('&1') stattab_owner from dual;
set term on

prompt Statistics Table Name:
set feed off term off
select upper('&2') stattab from dual;
set term on

prompt Gather Fixed StatID: 
set feed off term off
select upper('&3') statid from dual;
set term on

prompt NOINVALIDATE? YES/NO:
set feed off term off
select upper('&4') noinvalidate from dual;
set term on

set term on feed on
set serveroutput on size 1000000

declare
	v_stattab_owner varchar2(30);
	v_stattab varchar2(30);
	v_statid varchar2(30);
	v_owner varchar2(30);
	v_noinvalidate boolean := true;
	v_database_name varchar2(8 char);
begin

   select substr(name,1,8) into v_database_name from v$database;

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
	else v_statid := substr('&&statid',1,4) || '_' || v_database_name || '_' || to_char(sysdate,'yymmddhh24mi');
	end case;

	case '&&noinvalidate' 
	when 'YES' then v_noinvalidate := true;
	else v_noinvalidate := false;
	end case;

	dbms_output.put_line('=======================');
	dbms_output.put_line('stattab_owner : ' || v_stattab_owner);
	dbms_output.put_line('stattab : ' || v_stattab);
	dbms_output.put_line('statid  : ' || v_statid);
	if v_noinvalidate then
		dbms_output.put_line('noinvalidate  : TRUE');
	else
		dbms_output.put_line('noinvalidate  : FALSE');
	end if;
	
	DBMS_STATS.GATHER_FIXED_OBJECTS_STATS (
		stattab			=> v_stattab,
		statid			=> v_statid,
		statown			=> v_stattab_owner,
		no_invalidate	=> v_noinvalidate
	); 

end;
/


