
-- system_stats_pop.sql
-- !! IMPORTANT
-- !! Backup SYSTEM Stats with export_stats.sh before running this
-- !!
-- create a table from which to populate system stats
-- populate it with values from previously collected stats
-- use dbms_stats.

col statid format a30
col start_time format a16
col end_time format a16
col sreadtim format 90.99990 head 'SREADTIM|ms'
col mreadtim format 90.99990 head 'MREADTIM|ms'
col cpuspeed format 999999 head 'CPUSPEED|MHZ'
col mbrc format 9999 head 'MBRC|BLOCKS'

set serveroutput on size 1000000

prompt !!
prompt !! Have you backed up SYSTEM Statistics with export_stats.sh?
prompt !!

accept bkup_answer char

whenever sqlerror exit
begin
	if upper('&bkup_answer') != 'Y' then
		raise_application_error(-20000,'Backups not made');
	end if;
end;
/
whenever sqlerror continue

alter session set nls_date_format='mm/dd/yyyy hh24:mi:ss';

-- get stats source table
-- defaults to system_stats
col source_stats_tab noprint new_value source_stats_tab

prompt Name of Stats Source Table? - default is system_stats: 

accept acc_source_stats_tab char

set feed off term off
select decode('&&acc_source_stats_tab',
	null,'system_stats',
	'','system_stats',
	'&&acc_source_stats_tab'
) source_stats_tab
from dual
/
set feed on term on

--select '&&source_stats_tab' from dual;

drop table system_populate;

begin 
	dbms_stats.create_stat_table (
		ownname => user,
		stattab => 'SYSTEM_POPULATE'
	);
end;
/

-- check for sreadtim > mreadtim and give a warning if necessary
prompt
set head off feed off term on

with serio as (
	select 
		avg(n1) sreadtim
		, avg(n2) mreadtim
		, avg(n3) cpuspeed
	from &&source_stats_tab
	where c4 = 'CPU_SERIO'
	and to_number(to_char(to_date(c2,'mm-dd-yyyy hh24:mi'),'hh24')) between 8 and 17 -- 08:00 to 17:00
),
mbrc as (
	select  max(n11) mbrc
	from &&source_stats_tab
	where c4 = 'CPU_SERIO'
),
parallel_io as(
	select statid
	, n1 maxthr
	, n2 slavethr
	from &&source_stats_tab
	where c4 = 'PARIO'
)
select  
	case when s.mreadtim <= s.sreadtim or s.mreadtim is null
	then  '!! WARNING - MREADTIM is being populated with Derived Values !!'
	else ''
	end mreadtim_warn
from serio s
union 
	select
	case when s.cpuspeed is null 
	then '!! WARNING - CPU Speed is NULL in table &&source_stats_tab'
	else ''
	end cpuspeed_warn
from serio s
union
select
	case when m.mbrc is null 
	then '!! WARNING - MBRC is NULL in table &&source_stats_tab'
	else ''
	end mbrc_warn
from mbrc m
union
select
	case when  p.maxthr is null
	then '!! WARNING - MAXTHR is NULL in table &&source_stats_tab'
	else ''
	end maxthr_warn
from parallel_io p
union
select
	case when  p.slavethr is null
	then '!! WARNING - SLAVETHR is NULL in table &&source_stats_tab'
	else ''
	end slavethr_warn
from parallel_io p
/

set head on feed on
prompt


insert into system_populate (
	statid, type, version, flags,
	c1, c2, c3, c4, 
	n1, n2, n3
)
select  
	'LOAD_SYSTEM_STATS','S',5,1,
	'COMPLETED',to_char(sysdate,'mm-dd-yyyy hh24:mi'), to_char(sysdate,'mm-dd-yyyy hh24:mi'), 'CPU_SERIO',
	s.sreadtim
	, case when s.mreadtim <= s.sreadtim or s.mreadtim is null
		then  s.sreadtim * 1.5
		else s.mreadtim
	end mreadtim
	, s.cpuspeed
from 
(
	select 
		avg(n1) sreadtim
		, avg(n2) mreadtim
		, avg(n3) cpuspeed
	from &&source_stats_tab
	where c4 = 'CPU_SERIO'
	and to_number(to_char(to_date(c2,'mm-dd-yyyy hh24:mi'),'hh24')) between 8 and 17 -- 08:00 to 17:00
)  s
/

update system_populate set n11 =
(
	select max(n11) mbrc
	from &&source_stats_tab
	where c4 = 'CPU_SERIO'
)  
/

insert into system_populate (
	statid, type, version, flags,
	c4, 
	n1, n2
)
select  
	'LOAD_SYSTEM_STATS','S',5,1,
	'PARIO',
	s.maxthr, s.slavethr
from 
(
	select 
		max(n1) maxthr
		, max(n2) slavethr
	from &&source_stats_tab
	where c4 = 'PARIO'
	--and to_number(to_char(to_date(c2,'mm-dd-yyyy hh24:mi'),'hh24')) between 8 and 17 -- 08:00 to 17:00
)  s
/

-- now actually populate the system statistics
declare

	v_stattab varchar2(30) := 'SYSTEM_POPULATE';
	v_statid varchar2(30) := 'LOAD_SYSTEM_STATS';
	v_statown varchar2(30) := user; 

	cursor sstat is
	with parallel_io as(
		select statid
			, n1 maxthr
			, n2 slavethr
		from system_populate
		where c4 = 'PARIO'
	),
	serial_io as (
		select statid
			, n1 sreadtim
			, n2 mreadtim
			, n3 cpuspeed
			, n11 mbrc
		from system_populate
		where c4 = 'CPU_SERIO'
	)
	select  s.statid
		, s.sreadtim
		, s.mreadtim
		, s.cpuspeed
		, s.mbrc
		, p.maxthr
		, p.slavethr
	from parallel_io p, serial_io s
	where s.statid = v_statid
	and p.statid = s.statid;

	srec sstat%rowtype;

	v_mbrc number(3,0);

begin

	open sstat;

	begin
		fetch sstat into srec;
	exception
	when no_data_found then
		raise_application_error(-20001,'No data found in ' || v_statown || '.' || v_stattab);
	when others then raise;
	end;

	close sstat;

	-- sreadtim
	if srec.sreadtim is not null then
		dbms_stats.set_system_stats (
			pname		=> 'sreadtim',
			pvalue	=> srec.sreadtim
		);
	else
		dbms_output.put_line('!Warning - not setting NULL sreadtim!');
	end if;

	-- mreadtim
	if srec.mreadtim is not null then
		dbms_stats.set_system_stats (
			pname		=> 'mreadtim',
			pvalue	=> srec.mreadtim
		);
	else
		dbms_output.put_line('!Warning - not setting NULL mreadtim!');
	end if;

	-- cpuspeed
	if srec.cpuspeed is not null then
		dbms_stats.set_system_stats (
			pname		=> 'cpuspeed',
			pvalue	=> srec.cpuspeed
		);
	else
		dbms_output.put_line('!Warning - not setting NULL cpuspeed!');
	end if;

	-- mbrc
	with pwrof2 as (
   	select rownum rowno
   	from dual
   	connect by level <= 8
	)
	select max(power2) into v_mbrc
	from (
		select power(2,rowno) power2 from pwrof2
	)
	where power2 < srec.mbrc;

	if srec.mbrc is not null then
		dbms_stats.set_system_stats (
			pname		=> 'mbrc',
			pvalue	=> v_mbrc
		);
	else
		dbms_output.put_line('!Warning - not setting NULL mbrc!');
	end if;

	-- maxthr
	if srec.maxthr is not null then
		dbms_stats.set_system_stats (
			pname		=> 'maxthr',
			pvalue	=> srec.maxthr
		);
	else
		dbms_output.put_line('!Warning - not setting NULL maxthr!');
	end if;

	-- slavethr
	if srec.slavethr is not null then
		dbms_stats.set_system_stats (
			pname		=> 'slavethr',
			pvalue	=> srec.slavethr
		);
	else
		dbms_output.put_line('!Warning - not setting NULL slavethr!');
	end if;

	commit;

end;
/

