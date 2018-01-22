

declare

	type tabtyp is table of varchar2(30) index by pls_integer;

	t_weekdays tabtyp;
	t_weekenddays tabtyp;

	t_weekdaynames tabtyp;
	t_weekenddaynames tabtyp;

begin

	t_weekdays(1) := 'MONDAY_WINDOW';
	t_weekdays(2) := 'TUESDAY_WINDOW';
	t_weekdays(3) := 'WEDNESDAY_WINDOW';
	t_weekdays(4) := 'THURSDAY_WINDOW';
	t_weekdays(5) := 'FRIDAY_WINDOW';

	t_weekdaynames(1) := 'MON';
	t_weekdaynames(2) := 'TUE';
	t_weekdaynames(3) := 'WED';
	t_weekdaynames(4) := 'THU';
	t_weekdaynames(5) := 'FRI';

	t_weekenddaynames(1) := 'SAT';
	t_weekenddaynames(2) := 'SUN';

	t_weekenddays(1) := 'SATURDAY_WINDOW';
	t_weekenddays(2) := 'SUNDAY_WINDOW';

	for i in t_weekdays.first .. t_weekdays.last
	loop

		dbms_scheduler.set_attribute(
			name      => t_weekdays(i),
			attribute => 'DURATION',
			value     => numtodsinterval(4, 'hour')
		);

		dbms_scheduler.set_attribute(
			name      => t_weekdays(i),
			attribute => 'REPEAT_INTERVAL',
			value     => 'freq=daily;byday=' || t_weekdaynames(i) || ';byhour=20;byminute=0; bysecond=0'
		);

	end loop;

	for i in t_weekenddays.first .. t_weekenddays.last
	loop

		dbms_scheduler.set_attribute(
			name      => t_weekenddays(i),
			attribute => 'DURATION',
			value     => numtodsinterval(20, 'hour')
		);

		dbms_scheduler.set_attribute(
			name      => t_weekenddays(i),
			attribute => 'REPEAT_INTERVAL',
			value     => 'freq=daily;byday=' || t_weekenddaynames(i) || ';byhour=4;byminute=0; bysecond=0'
		);

	end loop;


end;
/

