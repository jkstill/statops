
prompt GATHER_SYSTEM_STATS
prompt

select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'GATHER_SYSTEM_STATS'
minus
select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'EXPORT_SYSTEM_STATS'
/


prompt GATHER_FIXED_OBJECTS_STATS
prompt

select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'GATHER_FIXED_OBJECTS_STATS'
minus
select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'EXPORT_FIXED_OBJECTS_STATS'
/


prompt GATHER_DICTIONARY_STATS
prompt

select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'GATHER_DICTIONARY_STATS'
minus
select  argument_name --, position, sequence
from dba_arguments
where owner = 'SYS' 
and package_name = 'DBMS_STATS'
and object_name = 'EXPORT_DICTIONARY_STATS'
/




