
clear columns
clear break
clear computes

set line 200
set pagesize 60
-- comment this line to see variable subtitution
set verify off

col name format a30 head 'S=STATUS O=NAME' 
col partition format a30 head 'S=TIMESTAMP O=PARTITION'

-- get level and object name

col table_owner new_value table_owner noprint
col stats_table new_value stats_table noprint
col get_object new_value get_object noprint
col dlevel new_value dlevel noprint
col schema_name new_value schema_name noprint

set term on
prompt Stats Table Owner:
set term off feed off
select '&1' table_owner from dual;
set term on

prompt Stats Table Name:
set term off feed off
select '&2' stats_table from dual;
set term on


prompt 
prompt  1=statid only
prompt  2=statid and owners only
prompt  3=statid, owners, type and name 
prompt  4=statid, owners, type, name and partition
prompt  5=statid, owners, type, name and column
prompt
prompt Level of Detail?

set term off feed off
select '&3' dlevel from dual;
set term on

prompt Schema Name (wildcards OK) ?
set term off
select '&4' schema_name from dual;
set term on feed on

prompt Object Name (wildcards OK) ?
set term off
select '&5' get_object from dual;
set term on feed on

var object_name varchar2(30)
var schema_name varchar2(30)
begin
	:object_name := upper('&&get_object');
	:schema_name := upper('&&schema_name');
end;
/


-- setup conditional processing

col skip_owner new_value skip_owner noprint
col skip_object new_value skip_object noprint
col skip_column new_value skip_column noprint
col skip_partition new_value skip_partition noprint
col skip_type new_value skip_type noprint

--define dlevel=5

set term off feed off
select decode('&&dlevel',1,'--','') skip_owner from dual;
select decode('&&dlevel',1,'--',2,'--','') skip_object from dual;
select decode('&&dlevel',4,'','--' ) skip_partition from dual;
select decode('&&dlevel',5,'','--' ) skip_column from dual;
select decode('&&dlevel',1,'--',2,'--','' ) skip_type from dual;
set term on feed on


select 
	st.statid
	&&skip_owner , st.c5 owner
	&&skip_type , st.type type
	&&skip_object , st.c1 name
	&&skip_partition , st.c2 partition 
	&&skip_column , st.c4 column_name
from &&table_owner..&&stats_table st
where
	-- column stats?
	st.type in (
		select decode('&&skip_column','--','I','C') from dual
		union all
		select decode('&&skip_column','--','T','C') from dual
		union all
		select decode('&&skip_column','--','S','C') from dual
	)
	-- check st.type and st.c5 so that SYSTEM statistics will be listed
	&&skip_partition and st.c2 is not null or ( st.type = 'S' and st.c5 is null )
	&&skip_owner and st.c5 like :schema_name  or ( st.type = 'S' and st.c5 is null )
	&&skip_object and st.c1 like :object_name  or ( st.type = 'S' and st.c5 is null )
group by st.statid
	&&skip_owner , st.c5
	&&skip_type , st.type
	&&skip_object , st.c1
	&&skip_partition , st.c2
	&&skip_column , st.c4
order by st.statid
	&&skip_owner , st.c5
	&&skip_type , st.type
	&&skip_object , st.c1
	&&skip_partition , st.c2
	&&skip_column , st.c4

/

undef 1 2 3 4
