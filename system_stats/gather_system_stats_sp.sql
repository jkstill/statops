
-- gather_systems_stats_sp.sql
-- gather workload stats

create or replace procedure gather_system_stats (
	v_statid_in varchar2,    -- ID of statistics set
	n_interval_in integer,   -- minutes
	v_statowner_in varchar2, -- stat table owner
	v_stattab_in varchar2    -- table
)
is

begin

--/* commented out for dbms_job testing

	dbms_stats.gather_system_stats(
		gathering_mode => 'START',
		statid  => v_statid_in,
		statown	=> v_statowner_in,
		stattab 	=> v_stattab_in
	); 

	dbms_lock.sleep(n_interval_in*60);
	--dbms_stats.gather_system_stats('STOP');

	dbms_stats.gather_system_stats(
		gathering_mode => 'STOP',
		statid  => v_statid_in,
		statown	=> v_statowner_in,
		stattab 	=> v_stattab_in
	); 

--*/

/* used for testing dbms_job

	insert into stats_test(timestamp, statid, statown, stattab, interval)
	values (sysdate, v_statid_in, v_statowner_in, v_stattab_in, n_interval_in);
	commit;

	null;
*/

end;
/

show error procedure gather_system_stats

