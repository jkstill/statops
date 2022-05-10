
-- @list_stats_table_details.sql  JKSTILL SOE_STATS % % SOE_CDB_2205091508

clear columns
clear break
clear computes

set linesize 300 trimspool on
set pagesize 100
-- comment this line to see variable subtitution
set verify off

col name format a75 head 'OWNER.TABLE.[partition].[subpart]'

-- get level and object name

col table_owner new_value table_owner noprint
col stats_table new_value stats_table noprint
col get_object new_value get_object noprint
col schema_name new_value schema_name noprint
col owner format a30
col v_statid new_value v_statid 
col statid format a30

col blocks format 999,999,999
col avg_row_len format 999,999,999 head 'AVG ROW LEN'
col sample_size format 99,999,999,999 head 'SAMPLE SIZE'
col num_rows format 99,999,999,999 head 'NUM ROWS'

-- Current do not know range of values to expect for these
col IM_IMCU_COUNT format 999999999 head 'In Memory|Compression|Units'
col IM_BLOCK_COUNT format 99999999 head 'In Memory|Blocks'

-- external tables - not displaying
col SCANRATE format 99999999


set term on
prompt Stats Table Owner:
set term off feed off
select '&1' table_owner from dual;
set term on

prompt Stats Table Name:
set term off feed off
select '&2' stats_table from dual;
set term on


prompt Schema Name (wildcards OK) ?
set term off
select '&3' schema_name from dual;
set term on feed on

prompt Object Name (wildcards OK) ?
set term off
select '&4' get_object from dual;
set term on feed on

prompt Statid? 
set term off
select '&5' v_statid from dual;
set term on feed on

var object_name varchar2(30)
var schema_name varchar2(30)
begin
	:object_name := upper('&&get_object');
	:schema_name := upper('&&schema_name');
end;
/



select
	st.statid
	--, st.type type
	, st.c5 || '.' || st.c1 
		|| decode(st.c2,null,'','.' || st.c2)
		|| decode(st.c3,null,'','.' || st.c3) name
	, n1 num_rows
	, n2 blocks
	, n3 avg_row_len
	, n4 sample_size
	, n6 im_imcu_count  -- new in 12.2 - In Memory Compression Units in the table
	, n7 im_block_count -- new in 12.2 - In Memory Blocks
	--, n8 scanrate  -- new in 12.2 - MB per second read - for external tables
	--, n9 chncnt -- Chain Count?
	--, n10 cachedblk 
	--, n11 cachehit
	--, n12 logicalread	
from &&table_owner..&&stats_table st
where
	-- column stats?
	st.type = 'T'
	and st.statid like '&&v_statid'
	-- check st.type and st.c5 so that SYSTEM statistics will be listed
	and st.type = 'T'
	and st.c5 like :schema_name
	and st.c1 like :object_name
order by st.statid
	, st.c5
	, st.c1
	, st.c2
/


undef 1 2 3 4
