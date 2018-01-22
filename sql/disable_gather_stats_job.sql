
-- see SAP note 838725 for info on system stats
-- the built in GATHER_STATS_JOB is not supported for SAP

begin
	-- disable the built in system stats job
   dbms_scheduler.disable('GATHER_STATS_JOB');
end;
/

