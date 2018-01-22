
-- see SAP note 838725 for info on system stats

begin
	--dbms_stats.gather_system_stats( GATHERING_MODE => 'INTERVAL', INTERVAL => 10);
	--dbms_stats.gather_system_stats( INTERVAL => 10);
	dbms_stats.gather_system_stats('START');
	dbms_lock.sleep(600);
	dbms_stats.gather_system_stats('STOP');
end;
/

