
col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

prompt
prompt Values used by system_stats_pop.sql
prompt

with parallel_io as(
	select statid
		, n1 maxthr
		, n2 slavethr
	from system.system_populate
	where c4 = 'PARIO'
),
serial_io as (
	select statid
		, n1 sreadtim
		, n2 mreadtim
		, n3 cpuspeed
		, n11 mbrc
	from system.system_populate
	where c4 = 'CPU_SERIO'
)
select  s.statid
	, s.sreadtim
	, s.mreadtim
	, s.cpuspeed
	, s.mbrc
	, p.maxthr
	, p.slavethr
from parallel_io p, serial_io s
where s.statid = 'LOAD_SYSTEM_STATS'
and p.statid = s.statid
/


