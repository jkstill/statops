
for schema in aml dmr macaddr macproto mai_meta ptd ptd_web
do

./gather_schema_stats.sh -o pr08 -d pr08 -s $schema -u js001292 -t 0.0007 

done

