
/*
normally there should be only 2 rows per statid with system stats
it is possible to have more than 2 if importing data, and the same
data is imported more than one time, leading to partial cartesian
joins
*/

col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

define stats_tab='jkstill.system_stats'
--define stats_tab='js001292.system_stats'
--define stats_tab='js001292.dal3_system_stats'

set line 200

with parallel_io as(
	select statid
		, n1 maxthr
		, n2 slavethr
	from &&stats_tab
	where c4 = 'PARIO'
),
serial_io as (
	select statid
		, c2 start_time
		, c3 end_time
		, n1 sreadtim
		, n2 mreadtim
		, n3 cpuspeed
		, n11 mbrc
	from &&stats_tab
	where c4 = 'CPU_SERIO'
)
select  s.statid
	, s.start_time
	, s.end_time
	, s.sreadtim
	, s.mreadtim
	, s.cpuspeed
	, s.mbrc
	, p.maxthr
	, p.slavethr
from parallel_io p, serial_io s
where p.statid = s.statid
/


