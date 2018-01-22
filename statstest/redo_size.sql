

col redo_size format 999,999,999,999
--set echo on
select sid, value redo_size from v$mystat where statistic#=(select statistic# from v$statname where name = 'redo size');
set echo off


