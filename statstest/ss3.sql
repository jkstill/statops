
declare 
mystaleobjs dbms_stats.objecttab; 
begin 
-- check whether there is any stale objects 
dbms_stats.gather_schema_stats(ownname=>'JKSTILL', options=>'LIST STALE',objlist=> mystaleobjs); 
for i in 1 .. mystaleobjs.count loop 
dbms_output.put_line(mystaleobjs(i).objname); 
end loop; 
end; 
/ 
