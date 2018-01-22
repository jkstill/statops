:

. koraenv dv11

unset SQLPATH

USERNAME=system

db=$1

[ -z "$db" ] && {
	echo
	echo Please specify the db
	echo
	exit 1
}

PASSWORD=$(pwc.pl -instance $db -username $USERNAME)

$OH/bin/sqlplus /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$db
select name || '_SYS_' || to_char(sysdate,'yyyymmddhh24mi')  from v\$database;

declare
	v_statid varchar2(30);
begin
	for i in 1 .. 48
	loop
		select name || '_SYS_' || to_char(sysdate,'yyyymmddhh24mi') into v_statid from v\$database;

		begin
			gather_system_stats(v_statid,60,'SYSTEM','SYSTEM_STATS');
			--gather_system_stats(v_statid,1,'SYSTEM','SYSTEM_STATS');
		end;

	end loop;
end;
/

EOF

