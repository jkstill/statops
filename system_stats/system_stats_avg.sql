

col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

set line 100

define stats_tab='system_stats'

with parallel_io as(
	select max(n1) maxthr
		, max(n2) slavethr
	from &&stats_tab
	where c4 = 'PARIO'
),
serial_io as (
	select 
		avg(n1) sreadtim
		, avg(n2) mreadtim
		, avg(n3) cpuspeed
	from &&stats_tab
	where c4 = 'CPU_SERIO'
	and to_number(to_char(to_date(c2,'mm-dd-yyyy hh24:mi'),'hh24')) between 8 and 17 -- 08:00 to 17:00
) ,
pwrof2 as (
	select rownum rowno
	from dual
	connect by level <= 8
),
mbrc as (
	select max(power2) mbrc
	from (select power(2,rowno) power2 from pwrof2)
	where power2 < (select max(n11) from &&stats_tab where c4 = 'CPU_SERIO')
)
select  
	s.sreadtim
	, s.mreadtim
	, s.cpuspeed
	, m.mbrc
	, p.maxthr
	, p.slavethr
	, case when s.mreadtim < s.sreadtim
		then  '!! Warning - MREADTIM < SREADTIM'
		else 'no problems'
	end  warning
from parallel_io p, serial_io s, mbrc m
/


