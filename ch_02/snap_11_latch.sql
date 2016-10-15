rem
rem	Script:		snap_11_latch.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Jan 2008
rem	Purpose:	Package to get snapshot start and delta of latch stats
rem
rem	Notes
rem	Version 11 specific 
rem	Has to be run by SYS to create the package
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 168
rem		set trimspool on
rem		execute snap_latch.start_snap
rem		-- do something
rem		execute snap_latch.end_snap
rem
rem	We only capture sleep1 to sleep3 as the rest are fake columns
rem	and do not (appear to) capture any data.
rem
rem	We could consider not selecting the latch name in the main
rem	cursor, and use the latch number to get the latch name from
rem	x$kslld at print time, as this would reduce the memory demand 
rem	of the package
rem

create or replace package snap_latch as
	procedure start_snap;
	procedure end_snap(
		i_limit		in number	default 0,
		i_all_sleeps	in boolean	default false
	);
end;
/

create or replace package body snap_latch as

	cursor c1 is
		select
			lt.kslltnum		indx,
			lt.kslltnam		name,
			lt.ksllthsh,
			lt.kslltwgt		gets,
			lt.kslltwff		misses,
			lt.kslltwsl		sleeps,
			lt.kslltngt		immediate_gets,
			lt.kslltnfa		immediate_misses,
			lt.kslltwkc		waiters_woken,
			lt.kslltwth		waits_holding_latch,
			lt.ksllthst0		spin_gets,
			lt.ksllthst1		sleep1,
			lt.ksllthst2		sleep2,
			lt.ksllthst3		sleep3,
			lt.kslltwtt/1000	wait_time		 
		from
			x$kslltr lt
		order by 
			lt.kslltnum
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


procedure end_snap(
	i_limit		in number	default 0,
	i_all_sleeps	in boolean	default false
)
is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('Latch waits:-   ' || 
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
		
	if (i_limit != 0) then
		dbms_output.put_line('Lower limit:-  '  || i_limit);
	end if;

	dbms_output.put_line('---------------------------------');

	dbms_output.put(
		rpad('Latch',24) ||
		lpad('Gets',15) ||
		lpad('Misses',12) ||
		lpad('Sp_Get',11) ||
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
		lpad('Im_Gets',12) ||
		lpad('Im_Miss',10) ||
		lpad('Holding',8) ||
		lpad('Woken',6) ||
		lpad('Time ms',8)
	);

	dbms_output.put(
		rpad('-----',24) ||
		lpad('----',15) ||
		lpad('------',12) ||
		lpad('------',11) ||
		lpad('------',11)
	);
	
	if (i_all_sleeps) then
		dbms_output.put(
			lpad('------',11) ||
			lpad('------',11) ||
			lpad('------',11)
		);
	end if;

	dbms_output.put_line(
		lpad('-------',12) ||
		lpad('-------',10) ||
		lpad('-------',8) ||
		lpad('-----',6) ||
		lpad('-------',8)
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
			   (r.gets		> w_list(r.indx).gets + i_limit)
			or (r.immediate_gets	> w_list(r.indx).immediate_gets + i_limit)
			or (r.wait_time		> w_list(r.indx).wait_time + i_limit)
/*
			or (w_list(r.indx).misses != r.misses)
			or (w_list(r.indx).sleeps != r.sleeps)
			or (w_list(r.indx).sleep1 != r.sleep1)
			or (w_list(r.indx).sleep2 != r.sleep2)
			or (w_list(r.indx).sleep3 != r.sleep3)
			or (w_list(r.indx).spin_gets != r.spin_gets)
			or (w_list(r.indx).immediate_misses != r.immediate_misses)
			or (w_list(r.indx).waits_holding_latch != r.waits_holding_latch)
			or (w_list(r.indx).waiters_woken != r.waiters_woken)
*/
		) then

			dbms_output.put(rpad(substr(r.name,1,24),24));
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
					'999,999,990')
			);
			dbms_output.put(to_char( 
				r.immediate_misses - w_list(r.indx).immediate_misses,
					'9,999,990')
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
					'9,999.0')
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

end snap_latch;
/


drop public synonym snap_latch;
create public synonym snap_latch for snap_latch;
grant execute on snap_latch to public;
