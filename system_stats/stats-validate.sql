-- stats-validate
-- double check some values as mreadtim is less than sreadtim

set pagesize 100
set linesize 200 trimspool on

col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col sreadtimder format 90.99990 head 'SREADTIMDER|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col mreadtimder format 90.99990 head 'MREADTIMDER|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

define stats_tab='avail.os_stats'


with data as (
	select distinct statid
		, c2 start_time
		, c3 end_time
		, n1 sreadtim
		, n2 mreadtim
		, n3 cpuspeed
		, n11 mbrc
		-- derive sreadtime with stim / sreads
		, n4 - lag(n4) over(order by statid)  sreads
		, ( n5 - lag(n5) over(order by statid))  -- stim
			/ ( n4 - lag(n4) over(order by statid))  -- sreads
			sreadtimder
		, n6 - lag(n6) over(order by statid)  mreads
		, ( n7 - lag(n7) over(order by statid)) -- mtim
			/ ( n6 - lag(n6) over(order by statid))  -- mreads
			mreadtimder
	from &&stats_tab
	where c4 = 'CPU_SERIO'
)
select *
from data
where mreads > 1E6
order by to_date(start_time,'MM-DD-YYYY HH24:MI')
/
