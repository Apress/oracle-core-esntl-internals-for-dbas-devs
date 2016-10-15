rem
rem	Script:		snap_rollstat.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2002
rem	Purpose:	Package to get snapshot start and delta of v$rollstat
rem
rem	Notes
rem		Has to be run by SYS to create the package
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_rollstats.start_snap
rem		-- do something
rem		execute snap_rollstats.end_snap
rem

create or replace package snap_rollstats as
	procedure start_snap;
	procedure end_snap;
end;
/

create or replace package body snap_rollstats as

	cursor c1 is
		select 
			usn,
			extents,
			rssize/1024		rssize,
			hwmsize/1024		hwmsize,
			nvl(optsize,0)/1024	optsize,
			writes,
			gets,
			waits,
			shrinks,
			extends,
			aveshrink/1024		aveshrink,
			aveactive/1024		aveactive
		from 
			v$rollstat
		order by
			usn
	;

	type w_type is table of c1%rowtype index by binary_integer;
	w_list 		w_type;
	w_empty_list	w_type;

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;

procedure start_snap is
begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list := w_empty_list;

	for r in c1 loop
		w_list(r.usn).extents := r.extents;
		w_list(r.usn).rssize := r.rssize;
		w_list(r.usn).hwmsize := r.hwmsize;
		w_list(r.usn).writes := r.writes;
		w_list(r.usn).gets := r.gets;
		w_list(r.usn).waits := r.waits;
		w_list(r.usn).shrinks := r.shrinks;
		w_list(r.usn).extends := r.extends;
		w_list(r.usn).aveshrink := r.aveshrink;
		w_list(r.usn).aveactive := r.aveactive;
	end loop;

end start_snap;


procedure end_snap is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('Rollback stats - ' ||
				to_char(m_end_time,'dd-Mon hh24:mi:ss')
	);

	if m_start_flag = 'U' then
		dbms_output.put_line('Interval:-       '  || 
				trunc(86400 * (m_end_time - m_start_time)) ||
				' seconds'
		);
	else
		dbms_output.put_line('Since Startup:-  ' || 
				to_char(m_start_time,'dd-Mon hh24:mi:ss')
		);
	end if;
		
	dbms_output.put_line('---------------------------------');

	dbms_output.put_line(
		'USN ' ||
		lpad('Ex',4) ||
		lpad('Size K',7) ||
		lpad('HWM K',7) ||
		lpad('Opt K',7) ||
		lpad('Writes',12) ||
		lpad('Gets',9) ||
		lpad('Waits',7) ||
		lpad('Shr',4) ||
		lpad('Grow',5) ||
		lpad('Shr K',6) ||
		lpad('Act K',7)
	);

	dbms_output.put_line(
		'----' ||
		lpad('--',4) ||
		lpad('------',7) ||
		lpad('-----',7) ||
		lpad('-----',7) ||
		lpad('------',12) ||
		lpad('----',9) ||
		lpad('-----',7) ||
		lpad('---',4) ||
		lpad('----',5) ||
		lpad('-----',6) ||
		lpad('------',7)
	);

	for r in c1 loop
		if (not w_list.exists(r.usn)) then
			w_list(r.usn).extents := 0;
			w_list(r.usn).rssize := 0;
			w_list(r.usn).hwmsize := 0;
			w_list(r.usn).writes := 0;
			w_list(r.usn).gets := 0;
			w_list(r.usn).waits := 0;
			w_list(r.usn).shrinks := 0;
			w_list(r.usn).extends := 0;
			w_list(r.usn).aveshrink := 0;
			w_list(r.usn).aveactive := 0;
		end if;

		if (
			   (w_list(r.usn).extents != r.extents)
			or (w_list(r.usn).rssize != r.rssize)
			or (w_list(r.usn).hwmsize != r.hwmsize)
			or (w_list(r.usn).writes != r.writes)
			or (w_list(r.usn).gets != r.gets)
			or (w_list(r.usn).waits != r.waits)
			or (w_list(r.usn).shrinks != r.shrinks)
			or (w_list(r.usn).extends != r.extends)
			or (w_list(r.usn).aveshrink != r.aveshrink)
			or (w_list(r.usn).aveactive != r.aveactive)
		) then
			dbms_output.put(to_char(r.usn,'990'));
			dbms_output.put(to_char( 
				r.extents - w_list(r.usn).extents,
					'990')
			);
			dbms_output.put(to_char( 
				r.rssize - w_list(r.usn).rssize,
					'999990')
			);
			dbms_output.put(to_char( 
				r.hwmsize - w_list(r.usn).hwmsize,
					'999990')
			);
			dbms_output.put(to_char(r.optsize,'999990')
			);
			dbms_output.put(to_char( 
				r.writes - w_list(r.usn).writes,
					'99999999990')
			);
			dbms_output.put(to_char( 
				r.gets - w_list(r.usn).gets,
					'99999990')
			);
			dbms_output.put(to_char( 
				r.waits - w_list(r.usn).waits,
					'999990')
			);
			dbms_output.put(to_char( 
				r.shrinks - w_list(r.usn).shrinks,
					'990')
			);
			dbms_output.put(to_char( 
				r.extends - w_list(r.usn).extends,
					'9990')
			);
			dbms_output.put(to_char( 
				r.aveshrink - w_list(r.usn).aveshrink,
					'99990')
			);
			dbms_output.put_line(to_char( 
				r.aveactive - w_list(r.usn).aveactive,
					'999990')
			);
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

end snap_rollstats;
/


drop public synonym snap_rollstats;
create public synonym snap_rollstats for snap_rollstats;
grant execute on snap_rollstats to public;



