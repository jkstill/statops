
-- @list_stats_index_details.sql  JKSTILL SOE_STATS % % SOE_CDB_2205091508

clear columns
clear break
clear computes

set linesize 300 trimspool on
set pagesize 100
-- comment this line to see variable subtitution
set verify off

col name format a75 head 'OWNER.TABLE.INDEX.[partition].[subpart]'

-- get level and object name

col stats_table new_value stats_table noprint
col get_object new_value get_object noprint
col schema_name new_value schema_name noprint
col owner format a30
col v_statid new_value v_statid 
col statid format a30

col table_owner new_value table_owner noprint
col leaf_blocks format 999,999,999
col distinct_keys format 999,999,999 head 'DISTINCT|KEYS'
col leaf_blocks_per_key format 99,999,999,999 head 'LEAF BLOCKS|PER KEY'
col data_blocks_per_key format 99,99,999,999 head 'DATA BLOCKS|PER KEY'
col num_rows format 99,999,999,999 head 'NUM ROWS'
col clustering_factor format 999,999,999.99 head 'CLUSTERING|FACTOR'
col sample_size format 999,999,999 head 'SAMPLE SIZE'
col blevel format 99999 head 'BLEVEL'

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
	, st.c5 || '.' || st.c4 || '.' || st.c1 
		|| decode(st.c2,null,'','.' || st.c2)
		|| decode(st.c3,null,'','.' || st.c3) name
	, n1 num_rows
	, n2 leaf_blocks
	, n3 distinct_keys
	, n4 leaf_blocks_per_key
	, n5 data_blocks_per_key
	, n6 clustering_factor 
	, n7 blevel
	, n8 sample_size
from &&table_owner..&&stats_table st
where
	-- column stats?
	st.statid like '&&v_statid'
	-- check st.type and st.c5 so that SYSTEM statistics will be listed
	and st.type = 'I'
	and st.c5 like :schema_name
	and st.c4 like :object_name
order by st.statid
	, st.c5
	, st.c4
	, st.c1
	, st.c2
/


undef 1 2 3 4
