rem
rem	Script:		c_dump_undo_block.sql
rem	Author:		Jonathan Lewis
rem	Dated:		December 2002
rem	Purpose:	Create a procedure to dump your CURRENT undo block
rem
rem	Last tested 
rem		11.2.0.2
rem		11.1.0.7
rem		10.2.0.3
rem		 9.2.0.8
rem	Not tested 
rem		10.1.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	The code is very simple minded with no error trapping.
rem	Has to be run by SYS to create the procedure.
rem

start setenv


create or replace procedure dump_undo_block
as
	m_xidusn		number;
	m_header_file_id	number;
	m_header_block_id	number;
	m_start_file_id		number;
	m_start_block_id	number;
	m_file_id		number;
	m_block_id		number;
	m_process		number;
begin

	select
		xidusn,
		start_ubafil,
		start_ubablk,
		ubafil, 
		ubablk
	into
		m_xidusn,
		m_start_file_id,
		m_start_block_id,
		m_file_id,
		m_block_id
	from
		v$session	ses,
		v$transaction	trx
	where
		ses.sid = (select mys.sid from V$mystat mys where rownum = 1)
	and	trx.ses_addr = ses.saddr
	;

	select 
		file_id, block_id 
	into
		m_header_file_id,
		m_header_block_id
	from 
		dba_rollback_segs 
	where 
		segment_id = m_xidusn
	;


	dbms_output.put_line('Header  File: ' || m_header_file_id || ' Header block: '  || m_header_block_id);
	dbms_output.put_line('Start   File: ' || m_start_file_id  || ' Start block: '   || m_start_block_id);
	dbms_output.put_line('Current File: ' || m_file_id        || ' Current block: ' || m_block_id);


	dbms_system.ksdwrt(1,'===================');
	dbms_system.ksdwrt(1,'Undo Segment Header');
	dbms_system.ksdwrt(1,'===================');

	execute immediate
		'alter system dump datafile ' || m_header_file_id ||' block ' || m_header_block_id;

	dbms_system.ksdwrt(1,'================');
	dbms_system.ksdwrt(1,'Undo Start block');
	dbms_system.ksdwrt(1,'================');

	execute immediate
		'alter system dump datafile ' || m_start_file_id ||' block ' || m_start_block_id;

	if m_start_block_id != m_block_id then

		dbms_system.ksdwrt(1,'==================');
		dbms_system.ksdwrt(1,'Current Undo block');
		dbms_system.ksdwrt(1,'==================');

		execute immediate
			'alter system dump datafile ' || m_file_id ||' block ' || m_block_id;

	end if;

	select
		spid
	into
		m_process
	from
		v$session	se,
		v$process	pr
	where	se.sid = (select sid from v$mystat where rownum = 1)
	and
		pr.addr = se.paddr
	;

	dbms_output.put_line('Trace file name includes: ' || m_process);

end;
/

grant execute on dump_undo_block to public;

drop   public synonym dump_undo_block; 
create public synonym dump_undo_block for dump_undo_block;


set doc off
doc


#
