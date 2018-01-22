select * from v$mystat where statistic#=(select statistic# from v$statname where name = 'redo size')
/
