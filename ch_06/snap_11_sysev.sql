rem
rem	Script:		snap_sysev.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of v$system_event
rem
rem	Notes
rem	Has to be run by SYS to create the package
rem	Needed particularly because PX events are not forwarded to the QC
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_system_events.start_snap
rem		-- do something
rem		execute snap_system_events.end_snap
rem

create or replace package snap_system_events as
	procedure start_snap;
	procedure end_snap;
end;
.
/


create or replace package body snap_system_events as

	cursor c1(i_time_factor in number) is
		select 
			d.indx				indx,	
			d.kslednam			event, 
/*
			s.ksleswts			total_waits, 
			s.kslestim/i_time_factor	time_waited,
			s.kslestmo			time_outs,
			s.kslesmxt/i_time_factor	max_time
*/
			(s.ksleswts_un + s.ksleswts_fg + s.ksleswts_bg)				total_waits,
			round((s.kslestim_un +s.kslestim_fg + s.kslestim_bg)/i_time_factor)	time_waited,
			(s.kslestmo_un + s.kslestmo_fg + s.kslestmo_bg)				time_outs,
			0									max_time
		from
			x$kslei s,
			x$ksled d 
		where	s.indx = d.indx
		and	(s.ksleswts_un > 0 or s.ksleswts_fg > 0 or s.ksleswts_bg > 0)
		order by
			d.indx
	;

	type w_type is table of c1%rowtype index by binary_integer;
	w_list 		w_type;
	w_empty_list	w_type;

	m_time_factor	number(10,0);

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;


procedure start_snap is

begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list := w_empty_list;

	for r in c1(m_time_factor) loop
		w_list(r.indx).total_waits := r.total_waits;
		w_list(r.indx).time_waited := r.time_waited;
		w_list(r.indx).time_outs := r.time_outs;
	end loop;

end start_snap;

procedure end_snap is

begin

	m_end_time := sysdate;
	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('System Waits:-  ' ||
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
		
	dbms_output.put_line('---------------------------------');

	dbms_output.put_line(
		rpad('Event',43) ||
		lpad('Waits',12) ||
		lpad('Time_outs',12) ||
		lpad('Csec',16) ||
		lpad('Avg Csec',12) ||
		lpad('Max Csec',12)
	);

	dbms_output.put_line(
		rpad('-----',43) ||
		lpad('-----',12) ||
		lpad('---------',12) ||
		lpad('----',16) ||
		lpad('--------',12) ||
		lpad('--------',12)
	);

	for r in c1(m_time_factor) loop

		if (not w_list.exists(r.indx)) then
		    w_list(r.indx).total_waits := 0;
		    w_list(r.indx).time_waited := 0;
		    w_list(r.indx).time_outs := 0;
		end if;

		if (
			   (w_list(r.indx).total_waits != r.total_waits)
			or (w_list(r.indx).time_waited != r.time_waited)
		) then

			dbms_output.put(rpad(substr(r.event,1,43),43));
			dbms_output.put(to_char( 
				r.total_waits - w_list(r.indx).total_waits,
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.time_outs - w_list(r.indx).time_outs,
					'999,999,990'));
			dbms_output.put(to_char( 
				r.time_waited - w_list(r.indx).time_waited,
					'999,999,999,990'));
			dbms_output.put(to_char( 
				(r.time_waited - w_list(r.indx).time_waited)/
				greatest(
					r.total_waits - w_list(r.indx).total_waits,
					1
				),
					'999,999.990'));
			dbms_output.put(to_char(r.max_time,'999,999,990'));
			dbms_output.new_line;
		end if;

	end loop;

end end_snap;

begin

	select
		startup_time, 'S'
	into
		m_start_time, m_start_flag
	from
		v$instance;

	select	decode(substr(version,1,1),'8',1,'7',1,10000)
	into	m_time_factor
	from	v$instance
	;

end snap_system_events;
.
/


drop public synonym snap_system_events;
create public synonym snap_system_events for snap_system_events;
grant execute on snap_system_events to public;
