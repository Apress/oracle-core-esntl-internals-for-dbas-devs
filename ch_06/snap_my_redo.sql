rem
rem	Script:		snap_my_redo.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of redo from v$mystat
rem
rem	Notes
rem		Has to be run by SYS to create the package
rem		Reports stats containing the word 'redo'
rem		and stats starting with the word 'messages'
rem		(the latter is for messages sent to the log writer)
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_my_redo.start_snap
rem		-- do something
rem		execute snap_my_redo.end_snap
rem

create or replace package snap_my_redo as
	procedure start_snap;
	procedure end_snap;
end;
/

create or replace package body snap_my_redo as

cursor c1 is
	select 
		statistic#, 
		name,
		value
	from 
		v$my_stats
	where
		name like '%redo%'
	or	name like 'messages%'
	or	name like '%kcm%'
	;


	type w_type is table of c1%rowtype index by binary_integer;
	w_list		w_type;
	empty_list	w_type;

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;


procedure start_snap is
begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list := empty_list;

	for r in c1 loop
		w_list(r.statistic#).value := r.value;
	end loop;

end start_snap;


procedure end_snap is
begin

	m_end_time := sysdate;

	dbms_output.put_line('-------------------------------------');
	dbms_output.put_line('MY REDO stats - ' ||
				to_char(sysdate,'dd-Mon hh24:mi:ss')
	);
	if m_start_flag = 'U' then
		dbms_output.put_line('Interval:-  '  || 
				trunc(86400 * (m_end_time - m_start_time)) ||
				' seconds'
		);
	else
		dbms_output.put_line('Since Startup:- ' || 
				to_char(m_start_time,'dd-Mon hh24:mi:ss')
		);
	end if;

	dbms_output.put_line('-------------------------------------');

	dbms_output.put_line(
		rpad('Name',60) ||
		lpad('Value',18)
	);

	dbms_output.put_line(
		rpad('----',60) ||
		lpad('-----',18)
	);

	for r in c1 loop
		if (not w_list.exists(r.statistic#)) then
		    w_list(r.statistic#).value := 0;
		end if;

		if (
		       (w_list(r.statistic#).value != r.value)
		) then
			dbms_output.put(rpad(r.name,60));
			dbms_output.put_line(to_char(
				r.value - w_list(r.statistic#).value,
					'9,999,999,999,990'));
		end if;
	end loop;

end end_snap;

begin
	select
		logon_time, 'S'
	into
		m_start_time, m_start_flag
	from
		v$session
	where
		sid = 	(
				select /*+ no_unnest */ sid 
				from v$mystat 
				where rownum = 1
			);

end snap_my_redo;
/


drop public synonym snap_my_redo;
create public synonym snap_my_redo for snap_my_redo;
grant execute on snap_my_redo to public;
