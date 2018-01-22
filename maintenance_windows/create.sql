
drop table scheduler_windows_history purge;

create table scheduler_windows_history
as
select *
from DBA_SCHEDULER_WINDOWS
where 1=0
/

alter table scheduler_windows_history add (window_group varchar2(20) );

insert into scheduler_windows_history
select d.*, 'ORIGINAL'
from DBA_SCHEDULER_WINDOWS d
where enabled = 'TRUE'
/


commit;

