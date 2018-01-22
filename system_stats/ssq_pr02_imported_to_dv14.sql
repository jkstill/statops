with parallel_io as(
	select statid
		, n1 maxthr
		, n2 slavethr
		, n3 IOSEEKTIM
		, n4 IOTFRSPEED
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
	, p.ioseektim
	, p.iotfrspeed
	, p.maxthr
	, p.slavethr
from parallel_io p, serial_io s
where p.statid = s.statid
--and p.maxthr = 141860864
--and p.slavethr = 698368
and s.statid = 'PR02_SYS_200909111219'
/
