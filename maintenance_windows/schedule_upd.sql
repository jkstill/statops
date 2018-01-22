

declare

	type winrec is record (
		window_name varchar2(30),
		day_name varchar2(15),
		start_hour integer,
		start_minute integer,
		duration_hours integer,
		repeat_interval varchar2(200)
	);

	type tabtyp is table of winrec index by pls_integer;

	t_windows tabtyp;

	v_repeat_interval varchar2(200);
begin

	null;

	-- Monday
	t_windows(1).window_name := 'MONDAY_WINDOW';
	t_windows(1).day_name := 'MON';

	-- Tuesday
	t_windows(2).window_name := 'TUESDAY_WINDOW';
	t_windows(2).day_name := 'TUE';

	-- Wednesday
	t_windows(3).window_name := 'WEDNESDAY_WINDOW';
	t_windows(3).day_name := 'WED';

	-- Thursday
	t_windows(4).window_name := 'THURSDAY_WINDOW';
	t_windows(4).day_name := 'THU';

	-- Friday
	t_windows(5).window_name := 'FRIDAY_WINDOW';
	t_windows(5).day_name := 'FRI';

	-- Saturday
	t_windows(6).window_name := 'SATURDAY_WINDOW';
	t_windows(6).day_name := 'SAT';

	-- Sunday
	t_windows(7).window_name := 'SUNDAY_WINDOW';
	t_windows(7).day_name := 'SUN';

	-- Mon-Thu all the same
	for i in 1..4
	loop
		t_windows(i).start_hour := 20;
		t_windows(i).start_minute := 0;
		t_windows(i).duration_hours := 6;
	end loop;

	-- shorter window on Friday to avoid overlap
	t_windows(5).start_hour := 20;
	t_windows(5).start_minute := 0;
	t_windows(5).duration_hours := 4;

	-- Sat-Sun - 23 hrs each
	for i in 6..7
	loop
		t_windows(i).start_hour := 0;
		t_windows(i).start_minute := 10;
		t_windows(i).duration_hours := 23;
	end loop;

	-- set the repeat interval values
	for i in t_windows.first .. t_windows.last
	loop
		t_windows(i).repeat_interval := 'freq=daily;byday=' || t_windows(i).day_name || ';byhour=' || t_windows(i).start_hour || ';byminute='  || t_windows(i).start_minute || ';bysecond=0';
	end loop;


	-- dump the contents
	for i in t_windows.first .. t_windows.last
	loop
		dbms_output.put_line('----------------------------');
		dbms_output.put_line('Window    : ' || t_windows(i).window_name);
		dbms_output.put_line('Day Name  : ' || t_windows(i).day_name);

		dbms_output.put_line('Start Time: ' || lpad(t_windows(i).start_hour,2,'0') || ':' ||  lpad(t_windows(i).start_minute,2,'0'));
		--dbms_output.put_line('Start Hour: ' || t_windows(i).start_hour);
		--dbms_output.put_line('Start Min : ' || t_windows(i).start_minute);
		dbms_output.put_line('Duration  : ' || t_windows(i).duration_hours);
		dbms_output.put_line('Interval  : ' || t_windows(i).repeat_interval);
	end loop;


	for i in t_windows.first .. t_windows.last
	loop

		dbms_scheduler.set_attribute(
			name      => t_windows(i).window_name,
			attribute => 'REPEAT_INTERVAL',
			value     => t_windows(i).repeat_interval
		);

		dbms_scheduler.set_attribute(
			name      => t_windows(i).window_name,
			attribute => 'DURATION',
			value     => numtodsinterval(t_windows(i).duration_hours, 'hour')
		);

	end loop;


end;
/

