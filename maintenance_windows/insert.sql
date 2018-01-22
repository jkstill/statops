insert into scheduler_windows_history
select d.*, 'NEW-LONGER-WINDOW'
from DBA_SCHEDULER_WINDOWS d
where enabled = 'TRUE'
/

commit;

