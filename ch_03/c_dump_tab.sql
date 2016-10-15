rem
rem	Script:		c_dump_tab.sql
rem	Author:		Jonathan Lewis
rem	Dated:		April 2011
rem	Purpose:	Create a procedure to dump the first used block from a table
rem
rem	Last tested 
rem		11.1.0.7
rem	Not tested
rem		10.2.0.3
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	Very simple-minded code to dump a block from a table 
rem	by finding the block id of the "first" row in the table. 
rem
rem	Assumes by default the table owner is the calling user.
rem	Assumes the table is not partitioned.
rem
rem	Select the rowid of the first row selectable, and convert
rem	to (relative) file and block number, and dump.
rem

start setenv

create or replace procedure dump_table_block(
	i_tab_name		in	varchar2,
	i_owner			in	varchar2	default sys_context('userenv','session_user')
)
as
	m_file_id	number;
	m_block		number;
	m_process	varchar2(32);

begin

	execute immediate
		' select ' ||
			' dbms_rowid.rowid_relative_fno(rowid), ' ||
			' dbms_rowid.rowid_block_number(rowid)  ' ||
		' from ' ||
			i_owner || 
			'.' ||
			i_tab_name ||
		' where ' ||
			' rownum = 1 '
		into
			m_file_id, m_block
	;

	execute immediate
		'alter system dump datafile ' || m_file_id ||
		' block ' || m_block
	;

--
--	For non-MTS, work out the trace file name
--

	select
		spid
	into
		m_process
	from
		v$session	se,
		v$process	pr
	where
--
--		The first option is the 9.2 version for checking the SID
--		The second is a quick and dirty option for 8.1.7
--		provided SYS has made v$mystat visible (or this is the sys account)
--
--		se.sid = (select dbms_support.mysid from dual)
		se.sid = (select sid from v$mystat where rownum = 1)
	and	pr.addr = se.paddr
	;

	dbms_output.new_line;
	dbms_output.put_line('Trace file name includes: ' || m_process);
	dbms_output.new_line;

exception
	when others then
		dbms_output.new_line;
		dbms_output.put_line('Unspecified error.');
		dbms_output.put_line('Check syntax.');
		dbms_output.put_line('dump_table_block({table_name},[{owner}]');
		dbms_output.new_line;
		raise;
end;
.
/

show errors

drop public synonym dump_table_block;
create public synonym dump_table_block for dump_table_block;
grant execute on dump_table_block to public;
