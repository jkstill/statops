
prompt
prompt ==============================
prompt == SET PREFS for INCREMENTAL
prompt ==============================
prompt

set echo on

begin

	dbms_stats.set_table_prefs(
		ownname => user,
		tabname => 'STATSTEST',
		pname => 'GRANULARITY',
		pvalue => 'SUBPARTITION'
	);

	dbms_stats.set_table_prefs(
		ownname => user,
		tabname => 'STATSTEST',
		pname => 'INCREMENTAL',
		pvalue => 'TRUE'
	);

		
end;
/

set echo off
