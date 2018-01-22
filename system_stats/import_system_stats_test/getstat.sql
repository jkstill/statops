
@show_os_stats

declare
   v_statid stat_table.statid%type;
begin
   select distinct statid into v_statid
   from stat_table;

   dbms_stats.import_system_stats(
      stattab => 'STAT_TABLE',
      statid => v_statid,
      statown => user
   );

end;
/

@show_os_stats
