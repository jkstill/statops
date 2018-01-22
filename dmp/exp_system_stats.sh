
for db in sapdev sapqas sapprd bisbx biqas biprd pr02 pr08 pr09 
do
	exp_stats.sh -o dv11 -d $db -u js001292 -n system -t system_stats -s system
done

