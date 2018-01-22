
-- see SAP note 838725 for info on system stats

begin
	dbms_stats.gather_system_stats('START');
end;
/

