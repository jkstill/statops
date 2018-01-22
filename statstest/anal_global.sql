

prompt
prompt ==============================
prompt == GLOBAL_STATS
prompt ==============================
prompt

set timing on echo on
exec dbms_stats.gather_table_stats( ownname => 'JKSTILL', tabname => 'STATSTEST', granularity=>'GLOBAL', force=>true)
set echo off

