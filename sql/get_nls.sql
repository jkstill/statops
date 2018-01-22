
clear col
clear break
clear computes

btitle ''
ttitle ''

btitle off
ttitle off

set newpage 1

set pause off
set echo off
set timing off
set trimspool on
set pages 0 
set lines 200 
set term on 
set feed off 
set verify off

select l.nls_language || '_' || t.nls_territory || '.' || c.nls_characterset
from 
(
	select value nls_language
	from nls_database_parameters
	where parameter = 'NLS_LANGUAGE'
) l,
(
	select  value nls_territory
	from nls_database_parameters
	where parameter = 'NLS_TERRITORY'
) t, 
(
	select value nls_characterset
	from nls_database_parameters
	where parameter = 'NLS_CHARACTERSET'
) c
/

