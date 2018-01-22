
prompt
prompt ==============================
prompt == SHOW STALE
prompt ==============================
prompt

set echo off
set serveroutput on size 1000000

/*

TYPE ObjectElem IS RECORD (
  ownname     VARCHAR2(30),     -- owner
  objtype     VARCHAR2(6),      -- 'TABLE' or 'INDEX'
  objname     VARCHAR2(30),     -- table/index
  partname    VARCHAR2(30),     -- partition
  subpartname VARCHAR2(30));    -- subpartition
type ObjectTab is TABLE of ObjectElem;

*/

DECLARE
	filter_lst  DBMS_STATS.OBJECTTAB := DBMS_STATS.OBJECTTAB();
	objectlist  DBMS_STATS.OBJECTTAB := DBMS_STATS.OBJECTTAB();
	i binary_integer;
BEGIN

	i := 1;
	for prec in (
		select partition_name, subpartition_name
		from user_tab_subpartitions
		where table_name = 'STATSTEST'
	)
	loop
		filter_lst.extend(1);
		filter_lst(i).ownname 		:= 'JKSTILL';
		filter_lst(i).objname 		:= 'STATSTEST';
		filter_lst(i).objtype 		:= 'TABLE';
		filter_lst(i).partname		:= prec.partition_name;
		filter_lst(i).subpartname	:= prec.subpartition_name;
	
		i := i + 1;
	end loop;

	DBMS_STATS.GATHER_SCHEMA_STATS(
		ownname => null,
		objlist => objectlist,
		options => 'LIST STALE'
	);

	if objectlist.LAST is not null
	then
		FOR n in objectlist.FIRST ..  objectlist.LAST
		LOOP
			dbms_output.put_line(objectlist(n).ownname || ' : ' || objectlist(n).ObjName || ' : ' || objectlist(n).ObjType || ' : ' || objectlist(n).partname || ' : ' || objectlist(n).subpartname);
		END LOOP;
	else
		dbms_output.put_line('No Stale Stats Found');
	end if;
	
END; 
/

