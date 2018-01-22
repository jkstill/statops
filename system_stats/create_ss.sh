:

. koraenv dv11

USERNAME=system
unset SQLPATH

for db in sapdev sapqas sapprd bisbx biqas biprd pr08 pr02 pr09 dv07 qa01 pr18
do

create_stats_table.sh \
	-o dv11 \
	-d $db \
	-u system \
	-n system \
	-t system_stats \
	-s sysaux

done
