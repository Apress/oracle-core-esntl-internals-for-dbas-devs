rem
rem	Script:		c_dump_log.sql
rem	Author:		Jonathan Lewis
rem	Dated:		December 2002
rem	Purpose:	Dump the current online redo log file.
rem
rem
rem	Last tested
rem		11.2.0.2
rem		10.2.0.3
rem		10.1.0.4
rem		 9.2.0.8
rem		 8.1.7.4
rem
rem	Notes:
rem	Must be run as a DBA
rem	Very simple minded - no error trapping
rem	

start setenv

create or replace procedure dump_log
as
	m_log_name	varchar2(255);
	m_process	varchar2(32);

begin
	select 
		lf.member
	into
		m_log_name
	from
		V$log 		lo,
		v$logfile	lf
	where 
		lo.status = 'CURRENT'
	and	lf.group# = lo.group#
	and	rownum = 1
	;

	execute immediate
	'alter system dump logfile ''' || m_log_name || '''';

	select
		spid
	into
		m_process
	from
		v$session	se,
		v$process	pr
	where
		se.sid = --dbms_support.mysid
			(select sid from v$mystat where rownum = 1)
	and	pr.addr = se.paddr
	;

	dbms_output.put_line('Trace file name includes: ' || m_process);

end;
.
/

show errors

create public synonym dump_log for dump_log;
grant execute on dump_log to public;

spool off


set doc off
doc

----------------------------------------------
 
 Skipping IMU Redo Record: cannot be filtered by XID/OBJNO 
-------------------------------------------------
----------------------------------------------
 
 Skipping IMU Redo Record: cannot be filtered by XID/OBJNO 
-------------------------------------------------
----------------------------------------------
 
 Skipping IMU Redo Record: cannot be filtered by XID/OBJNO 
-------------------------------------------------
----------------------------------------------
 
 Skipping IMU Redo Record: cannot be filtered by XID/OBJNO 
-------------------------------------------------

#
