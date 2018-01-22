:

. koraenv dv11

USERNAME=system
unset SQLPATH

for db in sapdev sapqas sapprd bisbx biqas biprd pr08 pr02 pr09 dv07 qa01 pr18
do

PASSWORD=$(pwc.pl -instance $db -username $USERNAME)

$OH/bin/sqlplus /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$db
drop table system_stats;
EOF

done
