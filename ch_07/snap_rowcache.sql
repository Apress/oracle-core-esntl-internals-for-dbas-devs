rem
rem	Script:		snap_rowcache.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of rowcache
rem
rem	Notes
rem		Has to be run by SYS to create the package
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_rowcache.start_snap
rem		-- do something
rem		execute snap_rowcache.end_snap
rem
rem	To be enhanced -
rem	There are several caches with the same cache#, but
rem	different subordinate#. Should show the subordinate#
rem	to emphasize the difference
rem

create or replace package snap_rowcache as
	procedure start_snap;
	procedure end_snap;
end;
/

create or replace package body snap_rowcache as

	cursor c1 is
		select
			indx						indx,
			inst_id						instance,
			kqrstcid					cache#,
			decode(kqrsttyp,1,'PARENT','SUBORDINATE')	dc_type, 
			decode(kqrsttyp,2,kqrstsno,null)		subordinate#,
			kqrsttxt					parameter,
			kqrstcsz					dc_count,
			kqrstosz					o_size,
			kqrstusg					usage,
			kqrstfcs					fixed, 
			kqrstgrq					gets,
			kqrstgmi					misses,
			kqrstsrq					scans,
			kqrstsmi					scanmisses,
			kqrstsco					scancompletes,
			kqrstmrq					modifications,
			kqrstmfl					flushes,
			kqrstilr					dlm_requests,
			kqrstifr					dlm_conflicts,
			kqrstisr					dlm_releases 
		from 
			x$kqrst
	;


	type w_type1 is table of c1%rowtype index by binary_integer;
	w_list1 	w_type1;
	w_empty_list	w_type1;

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;

procedure start_snap is
begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list1 := w_empty_list;

	for r in c1 loop
		w_list1(r.indx).usage := r.usage;
		w_list1(r.indx).fixed := r.fixed;
		w_list1(r.indx).gets := r.gets;
		w_list1(r.indx).misses := r.misses;
		w_list1(r.indx).scans := r.scans;
		w_list1(r.indx).scanmisses := r.scanmisses;
		w_list1(r.indx).scancompletes := r.scancompletes;
		w_list1(r.indx).modifications := r.modifications;
		w_list1(r.indx).flushes := r.flushes;
	end loop;

end start_snap;


procedure end_snap is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('Dictionary Cache - ' || 
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
		rpad('Parameter',25) ||
		lpad('Usage',6) ||
		lpad('Fixed',6) ||
		lpad('Gets',8) ||
		lpad('Misses',8) ||
		lpad('Scans',8) ||
		lpad('Misses',8) ||
		lpad('Comp',8) ||
		lpad('Mods',8) ||
		lpad('Flushes',8)
	);

	dbms_output.put_line(
		rpad('---------',25) ||
		lpad('-----',6) ||
		lpad('-----',6) ||
		lpad('----',8) ||
		lpad('------',8) ||
		lpad('-----',8) ||
		lpad('------',8) ||
		lpad('--------',8) ||
		lpad('----',8) ||
		lpad('-------',8)
	);

	for r in c1 loop
		if (not w_list1.exists(r.indx)) then
			w_list1(r.indx).usage := 0;
			w_list1(r.indx).fixed := 0;
			w_list1(r.indx).gets := 0;
			w_list1(r.indx).misses := 0;
			w_list1(r.indx).scans := 0;
			w_list1(r.indx).scanmisses := 0;
			w_list1(r.indx).scancompletes := 0;
			w_list1(r.indx).modifications := 0;
			w_list1(r.indx).flushes := 0;
		end if;

		if (
			   w_list1(r.indx).usage != r.usage
			or w_list1(r.indx).fixed != r.fixed
			or w_list1(r.indx).gets != r.gets
			or w_list1(r.indx).misses != r.misses
			or w_list1(r.indx).scans != r.scans
			or w_list1(r.indx).scanmisses != r.scanmisses
			or w_list1(r.indx).scancompletes != r.scancompletes
			or w_list1(r.indx).modifications != r.modifications
			or w_list1(r.indx).flushes != r.flushes
		) then

			dbms_output.put(rpad(substr(r.parameter,1,25),25));
			dbms_output.put(to_char( 
				r.usage - w_list1(r.indx).usage,
					'9,990')
			);
			dbms_output.put(to_char( 
				r.fixed - w_list1(r.indx).fixed,
					'9,990')
			);
			dbms_output.put(to_char( 
				r.gets - w_list1(r.indx).gets,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.misses - w_list1(r.indx).misses,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.scans - w_list1(r.indx).scans,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.scanmisses - w_list1(r.indx).scanmisses,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.scancompletes - w_list1(r.indx).scancompletes,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.modifications - w_list1(r.indx).modifications,
					'999,990')
			);
			dbms_output.put(to_char( 
				r.flushes - w_list1(r.indx).flushes,
					'999,990')
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

end snap_rowcache;
/


drop public synonym snap_rowcache;
create public synonym snap_rowcache for snap_rowcache;
grant execute on snap_rowcache to public;
