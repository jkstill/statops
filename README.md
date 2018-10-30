
# Scripts for Maintaining Oracle Statistics

These are scripts I developed some years ago and have just added to my Github Repo.

There are a things that need to be changed to start using them again, but not too much

These are relevant only for scripts in the ./system_stats directory

- remove references to pwc.pl - was once password retrieval
- remove references in shell scripts to db/server names

There is a dependency on this shell scripts [functions.sh](https://github.com/jkstill/shell-functions/blob/master/functions.sh) which should be copied or linked into the directory structure.

The FUNCTIONS_FILE variable will then need to be edited in the shell scripts in ./bin.


# directories

bin:

  contains scripts to export and import statistics

  imp/exp scripts dump and load from a file

  export/import scripts internally export and import statistics 
  to/from a statistics table created with dbms_stats.create_stat_table

## dictionary_stats

no files currently

## maintenance_windows

scripts pertaining to dbms_stats maintenance windows

## schema_stats

no files currently

## statstest

a few test scripts

## system_stats

scripts to gather/import/export/set system statistics

## sql

  SQL scripts used by shell scripts


# Export and Import DBMS_STATS

A copy of of [functions.sh](https://github.com/jkstill/shell-functions/blob/master/functions.sh) will be needed for this installation

The FUNCTIONS_FILE variable will then need to be edited in the shell scripts in ./bin.

# Export Database Statistics

## Create user for Stats table 
  or use Pythian

## Create Stats Table

```bash
cd statops/bin
```

There will be a prompt for password:

```bash
./create_stat_table.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export
```

## Export the statistics to Stats Export Table

This step copies the statistics in the source database from the data dictionary to the statistics export table created in a previous step.

This will be done for several schemas.

There will be a password prompt for each invocation

```bash
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s PM
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s HR
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s SH
```


## List the stats created

```bash

./list_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export

ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
Exporting Schema Stats for: %
  Database: examples
  Table: stats_table_export

Password:
XXX
LIST: ./../sql/list_stats.sql jkstill stats_table_export 2 %

SQL*Plus: Release 12.1.0.2.0 Production on Tue Oct 30 14:21:40 2018

Copyright (c) 1982, 2014, Oracle.  All rights reserved.

SQL> Connected.
SQL> Stats Table Owner:
Stats Table Name:

1=statid only
2=statid and owners only
3=statid, owners, type and name
4=statid, owners, type, name and partition
5=statid, owners, type, name and column

Level of Detail?
Schema Name (wildcards OK) ?
Object Name (wildcards OK) ?

PL/SQL procedure successfully completed.


STATID                         OWNER
------------------------------ ------------------------------
HR_JS122A_1810301415           HR
PM_JS122A_1810301419           PM
SH_JS122A_1810301415           SH

3 rows selected.

SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
jkstill@poirot ~/oracle/dba/statistics/statops/bin $


```

## Export the stats to a DMP file

By default all stats in the table will be exported.



```bash
cd ../dmp

 ../bin/exp_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export


ALLARGS: :JKSTILL:EXAMPLES:JKSTILL:STATS_TABLE_EXPORT:%:%:C12:
ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
export STATS_TABLE: stats_table_export
  Database: examples
  Schema: jkstill
Password:
XXX
NLS_LANG: AMERICAN_AMERICA.AL32UTF8

Export: Release 12.1.0.2.0 - Production on Tue Oct 30 14:25:46 2018

Copyright (c) 1982, 2014, Oracle and/or its affiliates.  All rights reserved.


Connected to: Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
Export done in AL32UTF8 character set and AL16UTF16 NCHAR character set
Note: grants on tables/views/sequences/roles will not be exported
Note: indexes on tables will not be exported
Note: constraints on tables will not be exported

About to export specified tables via Conventional Path ...
. . exporting table             STATS_TABLE_EXPORT       3679 rows exported
Export terminated successfully without warnings.

```

Validate that all values exp-orted.


```sql
JKSTILL@examples > select count(*) from stats_table_export;

  COUNT(*)
----------
      3679
```

# Import

Backup the current statistics in the target database.

Note: In this test the source and target database are the same.

## Create the backup table

```bash
./create_stat_table.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_backup
```

## Backup the statistics to Stats Backup Table

This step copies the statistics in the source database from the data dictionary to the statistics export table created in a previous step.

This will be done for several schemas.

There will be a password prompt for each invocation

```bash
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_backup -T schema -s PM
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_backup -T schema -s HR
./export_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_backup -T schema -s SH
```

## Validate Backup

```bash

  ./list_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_backup

ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
Exporting Schema Stats for: %
  Database: examples
  Table: stats_table_backup

Password:

LIST: ./../sql/list_stats.sql jkstill stats_table_backup 2 %

SQL*Plus: Release 12.1.0.2.0 Production on Tue Oct 30 14:33:26 2018

Copyright (c) 1982, 2014, Oracle.  All rights reserved.

SQL> Connected.
SQL> Stats Table Owner:
Stats Table Name:

1=statid only
2=statid and owners only
3=statid, owners, type and name
4=statid, owners, type, name and partition
5=statid, owners, type, name and column

Level of Detail?
Schema Name (wildcards OK) ?
Object Name (wildcards OK) ?

PL/SQL procedure successfully completed.


STATID                         OWNER
------------------------------ ------------------------------
HR_JS122A_1810301433           HR
PM_JS122A_1810301432           PM
SH_JS122A_1810301433           SH

3 rows selected.
```


## Import the stats from the DMP file to the table

Note: I have dropped my original stats_table_export table as both source and target are the same database.

```bash

 ./imp_stats.sh -o c12 -d examples -u jkstill -f ../dmp/jkstill_examples_%_%_stats.dmp -F jkstill -T jkstill

ARGS: :JKSTILL:EXAMPLES:JKSTILL:JKSTILL:../DMP/JKSTILL_EXAMPLES_%_%_STATS.DMP:C12:
ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
export STATS_TABLE:
  Database: examples
  Schema: jkstill
Password:
XXX

Import: Release 12.1.0.2.0 - Production on Tue Oct 30 14:47:36 2018

Copyright (c) 1982, 2014, Oracle and/or its affiliates.  All rights reserved.


Connected to: Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

Export file created by EXPORT:V12.01.00 via conventional path
import done in US7ASCII character set and AL16UTF16 NCHAR character set
import server uses AL32UTF8 character set (possible charset conversion)
export client uses AL32UTF8 character set (possible charset conversion)
. importing JKSTILL's objects into JKSTILL
. . importing table           "STATS_TABLE_EXPORT"       3679 rows imported
Import terminated successfully without warnings.

```

Validate that all values imp-orted.


```sql
JKSTILL@examples > select count(*) from stats_table_export;

  COUNT(*)
----------
      3679
```


## Import to the data dictionary

Most of the target tables do not have statistics
(There are some IOT tables that still have stats)

```sql

JKSTILL@examples > l
  1* select count(trunc(last_analyzed)) last_analyzed_count from dba_tab_statistics where owner in ('SH','PM','HR')
JKSTILL@examples > /

LAST_ANALYZED_COUNT
-------------------
                  3

```


### List the STATID values

The STATID values are needed for the next step

```bash

  ./list_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export

ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
Exporting Schema Stats for: %
  Database: examples
  Table: stats_table_export

Password:
XXX
LIST: ./../sql/list_stats.sql jkstill stats_table_export 2 %

SQL*Plus: Release 12.1.0.2.0 Production on Tue Oct 30 15:08:27 2018

Copyright (c) 1982, 2014, Oracle.  All rights reserved.

SQL> Connected.
SQL> Stats Table Owner:
Stats Table Name:

1=statid only
2=statid and owners only
3=statid, owners, type and name
4=statid, owners, type, name and partition
5=statid, owners, type, name and column

Level of Detail?
Schema Name (wildcards OK) ?
Object Name (wildcards OK) ?

PL/SQL procedure successfully completed.


STATID                         OWNER
------------------------------ ------------------------------
HR_JS122A_1810301415           HR
PM_JS122A_1810301419           PM
SH_JS122A_1810301415           SH

3 rows selected.

SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```


### Import to the data dictionary

```bash

  ./import_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s PM -i PM_JS122A_1810301419

ORACLE_BASE environment variable is not being set since this
information is not available for the current user ID jkstill.
You can set ORACLE_BASE manually if it is required.
Importing Schema Stats for: PM  statid:
Importing Schema Stats for: PM_JS122A_1810301419  statid:
  Database: examples
  Table: stats_table_export

Password:
XXX
IMP: ./../sql/import_schema_stats.sql PM stats_table_export PM_JS122A_1810301419

SQL*Plus: Release 12.1.0.2.0 Production on Tue Oct 30 15:10:22 2018

Copyright (c) 1982, 2014, Oracle.  All rights reserved.

SQL> Connected.
SQL> Import Stats Table Owner:
Statistics Table Name:
Import Stats for Schema:
Import Stats for StatID:
NOINVALIDATE? YES/NO:
FORCE IMPORT? YES/NO:

PL/SQL procedure successfully completed.

SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

```

Now do the same for the other 2 schemas

In this case we will  invalidate cursors

```bash

./import_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s HR -i HR_JS122A_1810301415 -v no

./import_stats.sh -o c12 -d examples -u jkstill -n jkstill -t stats_table_export -T schema -s SH -i SH_JS122A_1810301415 -v no

```

Now Validate the statistics

```sql
JKSTILL@examples > select count(trunc(last_analyzed)) last_analyzed_count from dba_tab_statistics where owner in ('SH','PM','HR');

LAST_ANALYZED_COUNT
-------------------
                 77

```
