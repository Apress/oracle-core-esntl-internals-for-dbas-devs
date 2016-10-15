rem
rem	Script:		snap_events.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of v$session_event
rem			of the current session.
rem
rem	Notes
rem		Has to be run by SYS to create the package
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_events.start_snap
rem		-- do something
rem		execute snap_events.end_snap
rem
rem	Note - there is a bug in Oracle 9.2.0.1/2, which records events against
rem	the wrong sid in v$session_event.  This code has been patched to work
rem	around this bug.  (Fixed in 9.2.0.3) See the cursor definition below.
rem

create or replace package snap_events as
	procedure start_snap;
	procedure end_snap;
end;
.
/


create or replace package body snap_events as

	cursor c1(i_time_factor in number, i_sid in number) is
		select 
			s.indx				indx,	
			d.kslednam			event, 
			s.ksleswts			total_waits, 
			s.kslestmo			time_outs,
			s.kslestim/i_time_factor	time_waited,
			s.kslesmxt/i_time_factor	max_time
		from
			x$ksles s,
			x$ksled d 
		where	s.kslesenm = d.indx
		and	s.ksleswts != 0
/*
	use the following line for Oracle 8 and 9.2.0.3/4 and 10g
*/
		and	s.kslessid = i_sid
/*
	Use the following line for Oracle 9.2.0.1 and 9.2.0.2
		and	s.kslessid = i_sid - 1
*/
		order by
			d.indx
	;

	type w_type is table of c1%rowtype index by binary_integer;
	w_list 		w_type;
	w_empty_list	w_type;

	g_time_factor	number(10,0);
	g_curr_sid	number(4,0);

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;

procedure start_snap is

begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list := w_empty_list;

	for r in c1(g_time_factor, g_curr_sid) loop
		w_list(r.indx).total_waits := r.total_waits;
		w_list(r.indx).time_waited := r.time_waited;
		w_list(r.indx).time_outs := r.time_outs;
	end loop;

end start_snap;


procedure end_snap is

	m_sid_name	varchar2(255);

begin
	m_end_time := sysdate;

	select	username || ' - ' || osuser
	into	m_sid_name
	from	v$session
	where	sid = g_curr_sid;

	dbms_output.put_line('---------------------------------------------------------');

	dbms_output.put_line(
		'SID: ' || to_char(g_curr_sid,'9999') || ':' ||
		m_sid_name
	);

	dbms_output.put_line('Session Events - ' || 
				to_char(m_end_time,'dd-Mon hh24:mi:ss') 
	);

	if m_start_flag = 'U' then
		dbms_output.put_line('Interval:-      '  || 
				trunc(86400 * (m_end_time - m_start_time)) ||
				' seconds'
		);
	else
		dbms_output.put_line('Since Startup:- ' || 
				to_char(m_start_time,'dd-Mon hh24:mi:ss')
		);
	end if;

	dbms_output.put_line('---------------------------------------------------------');

	dbms_output.put_line(
		rpad('Event',43) ||
		lpad('Waits',12) ||
		lpad('Time_outs',12) ||
		lpad('Csec',12) ||
		lpad('Avg Csec',12) ||
		lpad('Max Csec',12)
	);

	dbms_output.put_line(
		rpad('-----',43) ||
		lpad('-----',12) ||
		lpad('---------',12) ||
		lpad('----',12) ||
		lpad('--------',12) ||
		lpad('--------',12)
	);


	for r in c1(g_time_factor, g_curr_sid) loop

		if (not w_list.exists(r.indx)) then
		    w_list(r.indx).total_waits := 0;
		    w_list(r.indx).time_waited := 0;
		    w_list(r.indx).time_outs := 0;
		end if;

		if (
			   (w_list(r.indx).total_waits != r.total_waits)
			or (w_list(r.indx).time_waited != r.time_waited)
		) then


			dbms_output.put(rpad( substr(r.event,1,43),43));
			dbms_output.put(to_char( 
				r.total_waits - w_list(r.indx).total_waits,
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.time_outs - w_list(r.indx).time_outs,
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.time_waited - w_list(r.indx).time_waited,
					'999,999,990'));
			dbms_output.put(to_char( 
				(r.time_waited - w_list(r.indx).time_waited)/
				greatest(
					r.total_waits - w_list(r.indx).total_waits,
					1
				),
					'999,999.990'));
			dbms_output.put_line(to_char( 
				r.max_time,'999,999,990')
			);
		end if;

	end loop;

end end_snap;

begin
	select	decode(substr(version,1,1),'8',1,'7',1,10000)
	into	g_time_factor
	from	v$instance;

	select	sid
	into	g_curr_sid
	from	v$mystat
	where	rownum = 1;

	select
		logon_time, 'S'
	into
		m_start_time, m_start_flag
	from
		v$session
	where
		sid = 	g_curr_sid;

end snap_events;
.
/


drop public synonym snap_events;
create public synonym snap_events for snap_events;
grant execute on snap_events to public;

