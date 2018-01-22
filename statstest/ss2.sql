
col v_stale_threshold new_value v_stale_threshold noprint

select dbms_stats.get_prefs(ownname=>'JKSTILL',tabname=>'STATSTEST',pname=>'STALE_PERCENT')  v_stale_threshold from dual;

select 
	partition_name
	, subpartition_name
	--, inserts
	, updates
	--, deletes
from user_tab_modifications
where table_name = 'STATSTEST'
and updates >= &&v_stale_threshold
/
