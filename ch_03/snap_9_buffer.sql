rem
rem	Script:		snap_9_buffer.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of v$buffer_pool_statistics
rem
rem	Notes
rem		Has to be run by SYS to create the package
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 180
rem		set trimspool on
rem		execute snap_buffer.start_snap
rem		-- do something
rem		execute snap_buffer.end_snap
rem

create or replace package snap_buffer as
	procedure start_snap;
	procedure end_snap;
end;
/

create or replace package body snap_buffer as

cursor c1 is
	select 
		id,
		name,
		block_size,
		set_msize,
		cnum_repl,
		cnum_write,
		cnum_set,
		buf_got,
		sum_write,
		sum_scan,
		free_buffer_wait,
		write_complete_wait,
		buffer_busy_wait,
		free_buffer_inspected,
		dirty_buffers_inspected,
		db_block_change,
		db_block_gets,
		consistent_gets,
		physical_reads,
		physical_writes
	from 
		v$buffer_pool_statistics
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
		w_list(r.id).name			:= r.name;
		w_list(r.id).block_size			:= r.block_size;
		w_list(r.id).set_msize			:= r.set_msize;
		w_list(r.id).cnum_repl			:= r.cnum_repl;
		w_list(r.id).cnum_write			:= r.cnum_write;
		w_list(r.id).cnum_set			:= r.cnum_set;
		w_list(r.id).buf_got			:= r.buf_got;
		w_list(r.id).sum_write			:= r.sum_write;
		w_list(r.id).sum_scan			:= r.sum_scan;
		w_list(r.id).free_buffer_wait		:= r.free_buffer_wait;
		w_list(r.id).write_complete_wait	:= r.write_complete_wait;
		w_list(r.id).buffer_busy_wait		:= r.buffer_busy_wait;
		w_list(r.id).free_buffer_inspected	:= r.free_buffer_inspected;
		w_list(r.id).dirty_buffers_inspected	:= r.dirty_buffers_inspected;
		w_list(r.id).db_block_change		:= r.db_block_change;
		w_list(r.id).db_block_gets		:= r.db_block_gets;
		w_list(r.id).consistent_gets		:= r.consistent_gets;
		w_list(r.id).physical_reads		:= r.physical_reads;
		w_list(r.id).physical_writes		:= r.physical_writes;
	end loop;

end start_snap;


procedure end_snap is
begin

	m_end_time := sysdate;

	dbms_output.put_line('-----------------------------------');
	dbms_output.put_line('Buffer pool stats - ' ||
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

	dbms_output.put_line('-----------------------------------');

	dbms_output.put_line(
		rpad('Name',12) ||
		lpad('Blk Size',8) ||
		lpad('CU Gets',14) ||
		lpad('CR Gets',14) ||
		lpad('Blk Change',14) ||
		lpad('Reads',14) ||
		lpad('Writes',14) ||
		lpad('fb waits',14) ||
		lpad('Wc waits',14) ||
		lpad('bb waits',14) ||
		lpad('free insp',14) ||
		lpad('dirty insp',14)
	);

	dbms_output.put_line(
		rpad('-',12,'-') ||
		lpad('--------',8) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14) ||
		lpad('----------',14)
	);

	for r in c1 loop
		if (not w_list.exists(r.id)) then
		    w_list(r.id).db_block_gets := 0;
		    w_list(r.id).db_block_change := 0;
		    w_list(r.id).consistent_gets := 0;
		    w_list(r.id).physical_reads := 0;
		    w_list(r.id).physical_writes := 0;
		    w_list(r.id).free_buffer_wait := 0;
		    w_list(r.id).write_complete_wait := 0;
		    w_list(r.id).buffer_busy_wait := 0;
		    w_list(r.id).free_buffer_inspected := 0;
		    w_list(r.id).dirty_buffers_inspected := 0;
		end if;

		if (
		       (w_list(r.id).db_block_gets != r.db_block_gets)
		    or (w_list(r.id).db_block_change != r.db_block_change)
		    or (w_list(r.id).consistent_gets != r.consistent_gets)
		    or (w_list(r.id).physical_reads != r.physical_reads)
		    or (w_list(r.id).physical_writes != r.physical_writes)
		    or (w_list(r.id).free_buffer_wait != r.free_buffer_wait)
		    or (w_list(r.id).write_complete_wait != r.write_complete_wait)
		    or (w_list(r.id).buffer_busy_wait != r.buffer_busy_wait)
		    or (w_list(r.id).free_buffer_inspected != r.free_buffer_inspected)
		    or (w_list(r.id).dirty_buffers_inspected != r.dirty_buffers_inspected)
		) then
			dbms_output.put(rpad(r.name,12));
			dbms_output.put(lpad(r.block_size,8));
			dbms_output.put(to_char(
				r.db_block_gets - w_list(r.id).db_block_gets,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.consistent_gets - w_list(r.id).consistent_gets,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.db_block_change - w_list(r.id).db_block_change,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.physical_reads - w_list(r.id).physical_reads,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.physical_writes - w_list(r.id).physical_writes,
					'9,999,999,990'));

			dbms_output.put(to_char(
				r.free_buffer_wait - w_list(r.id).free_buffer_wait,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.write_complete_wait - w_list(r.id).write_complete_wait,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.buffer_busy_wait - w_list(r.id).buffer_busy_wait,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.free_buffer_inspected - w_list(r.id).free_buffer_inspected,
					'9,999,999,990'));
			dbms_output.put(to_char(
				r.dirty_buffers_inspected - w_list(r.id).dirty_buffers_inspected,
					'9,999,999,990'));

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

end snap_buffer;
/


drop public synonym snap_buffer;
create public synonym snap_buffer for snap_buffer;
grant execute on snap_buffer to public;
