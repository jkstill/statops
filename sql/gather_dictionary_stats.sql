
-- see SAP note 838725 for info on system stats

begin
	-- disable the built in system stats job
   dbms_stats.gather_dictionary_stats (
      ESTIMATE_PERCENT => NULL,
      METHOD_OPT => 'FOR ALL COLUMNS SIZE AUTO',
      GRANULARITY => 'ALL',
      CASCADE => TRUE,
      OPTIONS => 'GATHER',
      NO_INVALIDATE => FALSE
   );
   dbms_stats.gather_fixed_objects_stats(NO_INVALIDATE => FALSE);
end;
/

