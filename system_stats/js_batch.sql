


-- job_submit.sql
-- example of submitting a job to run
-- daily at 01:00

VARIABLE jobno number;
BEGIN
	DBMS_JOB.SUBMIT(
		:jobno,
		'gather_system_stats(''BATCH'',120,''SYSTEM'',''SYSTEM_STATS'');',
		-- setup far in the future - this is scheduled on demand
		sysdate + 10000,		
		'sysdate + 10000'
	);
	commit;
END;
/

print :jobno


