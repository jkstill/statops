
# Scripts for maintaing Oracle Statistics

These are scripts I developed some years ago and have just added to my Github Repo.

There are a things that need to be changed to start using them again, but not too much

- remove references to pwc.pl - was once password retrieval
- remove references in shell scripts to db/server names

There is a dependency on the shell scripts in this repo [functions.sh repo](https://github.com/jkstill/shell-functions "functions.sh repo")

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

