
prompt
prompt ==============================
prompt == RESET PREFS
prompt ==============================
prompt

set echo on

begin

	dbms_stats.set_table_prefs(
		ownname => user,
		tabname => 'STATSTEST',
		pname => 'CASCADE',
		pvalue => 'DBMS_STATS.AUTO_CASCADE'
	);

	dbms_stats.set_table_prefs(
		ownname => user,
		tabname => 'STATSTEST',
		pname => 'GRANULARITY',
		pvalue => 'AUTO'
	);

	dbms_stats.set_table_prefs(
		ownname => user,
		tabname => 'STATSTEST',
		pname => 'INCREMENTAL',
		pvalue => 'FALSE'
	);
end;
/

set echo off

