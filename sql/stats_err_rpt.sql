col owner format a15
col object_type format a20
col object_name format a30
col error_msg format a50
col error_date format a20

set feed on term on pause off

set line 150

alter session set nls_date_format = 'mm/dd/yyyy hh24:mi:ss';

prompt
prompt Reporting DBMS_STATS errors
prompt

select owner, object_type, object_name, error_msg, error_date
from dbms_stats_errors
order by error_date
/

