/*
normally there should be only 2 rows per statid with system stats
it is possible to have more than 2 if importing data, and the same
data is imported more than one time, leading to partial cartesian
joins
*/

set pagesize 100
set linesize 200 trimspool on

col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

def CSV_OUT='--'
def RPT_OUT=''

define stats_tab='avail.os_stats'

-- uncomment for CSV
--set feed off pagesize 0 timing off verify off
--prompt statid,start_time,end_time,sreadtim,mreadtim,cpuspeed,mbrc,maxtrh,slavethr

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
&&RPT_OUT select	s.statid
	&&RPT_OUT , s.start_time
	&&RPT_OUT , s.end_time
	&&RPT_OUT , s.sreadtim
	&&RPT_OUT , nvl(s.mreadtim,0) mreadtim
	&&RPT_OUT , s.cpuspeed
	&&RPT_OUT , nvl(s.mbrc,0)	mbrc
	&&RPT_OUT , nvl(p.maxthr,0)  maxtrh
	&&RPT_OUT , nvl(p.slavethr,0) slavethr
--
&&CSV_OUT select	s.statid
	&&CSV_OUT ||','|| s.start_time
	&&CSV_OUT ||','|| s.end_time
	&&CSV_OUT ||','|| s.sreadtim
	&&CSV_OUT ||','|| nvl(s.mreadtim,0) 
	&&CSV_OUT ||','|| s.cpuspeed
	&&CSV_OUT ||','|| nvl(s.mbrc,0) 
	&&CSV_OUT ||','|| nvl(p.maxthr,0) 
	&&CSV_OUT ||','|| nvl(p.slavethr,0) 
from parallel_io p, serial_io s
where p.statid = s.statid
/

-- uncomment for CSV
--set feed on pagesize 100 timing on
