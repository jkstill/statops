
prompt
prompt ==============================
prompt == ANALYZE STD
prompt ==============================
prompt


set echo on timing on
exec dbms_stats.gather_table_stats(user, tabname=>'STATSTEST', force=>true, cascade=>true)
set echo off

