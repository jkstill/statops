:

. koraenv dv11

unset SQLPATH

for db in sapdev sapqas sapprd bisbx biqas biprd pr08 pr02 pr09 dv07 qa01 pr18
do

USERNAME=js001292
PASSWORD=$(pwc.pl -instance $db -username $USERNAME)

$OH/bin/sqlplus /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$db as sysdba
@sys_grants
EOF

USERNAME=system
PASSWORD=$(pwc.pl -instance $db -username $USERNAME)

$OH/bin/sqlplus /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$db
@gather_system_stats_sp
EOF

done
