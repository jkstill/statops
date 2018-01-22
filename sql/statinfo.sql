set feed on

select distinct statid, count(*)
from system.stats_table
group by statid
order by statid
/

col bytes format 999,999,999,999
col segment_type format a15
col segment_name format a30

select segment_name, segment_type, bytes
from dba_segments
where owner  = 'SYSTEM'
and segment_name = 'STATS_TABLE'
order by 1,2
/

