rem
rem	Script:		snap_9_latch_parent.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of latch child stats
rem
rem	Notes
rem	Has to be run by SYS to create the package
rem	Version 9/10 specific - remove references to wait_time for version 8
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_latch.start_snap_cbc
rem		-- do something
rem		execute snap_latch.end_snap_cbc
rem
rem	Optionally capture sleep1, sleep2, sleep3. The rest (4 - 11)
rem	are fake columns, not populated by Oracle
rem

create or replace package snap_latch_parent as

	procedure start_snap;
	procedure end_snap(i_all_sleeps in boolean default false);

end;
/

create or replace package body snap_latch_parent as

	cursor c1 is
		select
			la.name,
			la.latch#	indx,
			la.gets,
			la.misses,
			la.sleeps,
			la.sleep1,
			la.sleep2,
			la.sleep3,
			la.immediate_gets,
			la.immediate_misses,
			la.spin_gets,
			la.waits_holding_latch,
			la.waiters_woken,
			round(la.wait_time/1000,3) wait_time
		from 
			v$latch_parent	la
		order by
			latch#
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
		w_list(r.indx).gets := r.gets;
		w_list(r.indx).misses := r.misses;
		w_list(r.indx).sleeps := r.sleeps;
		w_list(r.indx).sleep1 := r.sleep1;
		w_list(r.indx).sleep2 := r.sleep2;
		w_list(r.indx).sleep3 := r.sleep3;
		w_list(r.indx).spin_gets := r.spin_gets;
		w_list(r.indx).immediate_gets := r.immediate_gets;
		w_list(r.indx).immediate_misses := r.immediate_misses;
		w_list(r.indx).waits_holding_latch := r.waits_holding_latch;
		w_list(r.indx).waiters_woken := r.waiters_woken;
		w_list(r.indx).wait_time := r.wait_time;
	end loop;


end start_snap;


procedure end_snap(i_all_sleeps in boolean default false) is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------------------------------');
	dbms_output.put_line('Parent latch waits - ' || 
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

	dbms_output.put(
		rpad('Name',24) ||
		lpad('Gets',15) ||
		lpad('Misses',12) ||
		lpad('Spins',11) ||
		lpad('Sleeps',11)
	);

	if (i_all_sleeps) then
		dbms_output.put(
			lpad('Sleep1',11) ||
			lpad('Sleep2',11) ||
			lpad('Sleep3',11)
		);
	end if;

	dbms_output.put_line(
		lpad('Im_Gets',14) ||
		lpad('Im_Miss',12) ||
		lpad('Holding',8) ||
		lpad('Woken',6) ||
		lpad('Time m/s',12)
	);

	dbms_output.put(
		rpad('----',24) ||
		lpad('----',15) ||
		lpad('------',12) ||
		lpad('------',11) ||
		lpad('-----',11)
	);

	if (i_all_sleeps) then
		dbms_output.put(
			lpad('-----',11) ||
			lpad('-----',11) ||
			lpad('------',11)
		);
	end if;

	dbms_output.put_line(
		lpad('-------',14) ||
		lpad('-------',12) ||
		lpad('-------',8) ||
		lpad('-----',6) ||
		lpad('--------',12)
	);

	for r in c1 loop
		if (not w_list.exists(r.indx)) then
			w_list(r.indx).gets := 0;
			w_list(r.indx).misses := 0;
			w_list(r.indx).sleeps := 0;
			w_list(r.indx).sleep1 := 0;
			w_list(r.indx).sleep2 := 0;
			w_list(r.indx).sleep3 := 0;
			w_list(r.indx).spin_gets := 0;
			w_list(r.indx).immediate_gets := 0;
			w_list(r.indx).immediate_misses := 0;
			w_list(r.indx).waits_holding_latch := 0;
			w_list(r.indx).waiters_woken := 0;
			w_list(r.indx).wait_time := 0;
		end if;

		if (
			   w_list(r.indx).gets != r.gets
			or w_list(r.indx).misses != r.misses
			or w_list(r.indx).sleeps != r.sleeps
			or w_list(r.indx).sleep1 != r.sleep1
			or w_list(r.indx).sleep2 != r.sleep2
			or w_list(r.indx).sleep3 != r.sleep3
			or w_list(r.indx).spin_gets != r.spin_gets
			or w_list(r.indx).immediate_gets != r.immediate_gets
			or w_list(r.indx).immediate_misses != r.immediate_misses
			or w_list(r.indx).waits_holding_latch != r.waits_holding_latch
			or w_list(r.indx).waiters_woken != r.waiters_woken
			or w_list(r.indx).wait_time != r.wait_time
		) then

			dbms_output.put(rpad(r.name,24));

			dbms_output.put(to_char( 
				r.gets - w_list(r.indx).gets,
					'99,999,999,990')
			);
			dbms_output.put(to_char( 
				r.misses - w_list(r.indx).misses,
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.spin_gets - w_list(r.indx).spin_gets,
					'99,999,990')
			);
			dbms_output.put(to_char( 
				r.sleeps - w_list(r.indx).sleeps,
					'99,999,990')
			);

			if (i_all_sleeps) then
				dbms_output.put(to_char( 
					r.sleep1 - w_list(r.indx).sleep1,
						'99,999,990')
				);
				dbms_output.put(to_char( 
					r.sleep2 - w_list(r.indx).sleep2,
						'99,999,990')
				);
				dbms_output.put(to_char( 
					r.sleep3 - w_list(r.indx).sleep3,
						'99,999,990')
				);
			end if;

			dbms_output.put(to_char( 
				r.immediate_gets - w_list(r.indx).immediate_gets,
					'9,999,999,990')
			);
			dbms_output.put(to_char( 
				r.immediate_misses - w_list(r.indx).immediate_misses,
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.waits_holding_latch - w_list(r.indx).waits_holding_latch,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.waiters_woken - w_list(r.indx).waiters_woken,
					'9,990')
			);
			dbms_output.put(to_char( 
				r.wait_time - w_list(r.indx).wait_time,
					'999,999.990')
			);
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

end snap_latch_parent;
/


drop public synonym snap_latch_parent;
create public synonym snap_latch_parent for snap_latch_parent;
grant execute on snap_latch_parent to public;
