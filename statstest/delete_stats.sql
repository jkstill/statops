


prompt
prompt ==============================
prompt == DELETE STATS
prompt ==============================
prompt


set echo on timing on
exec dbms_stats.delete_table_stats(user, tabname=>'STATSTEST', force=>true, cascade_indexes=>true, cascade_parts=>true, cascade_columns=>true)
set echo off

