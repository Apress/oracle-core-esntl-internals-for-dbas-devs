rem
rem	Script:		c_dump_seg.sql
rem	Author:		Jonathan Lewis
rem	Dated:		December 2002
rem	Purpose:	Create a procedure to dump blocks from a segment
rem
rem	Last tested 
rem		11.2.0.2
rem		11.1.0.7
rem		10.2.0.3
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	The code is very simple minded with no error trapping.
rem	It only covers the first extent (extent zero) of a segment
rem	Could be enhanced to use get_ev to save and restore the state 
rem	of event 10289 (the one that controls raw/cooked dumps).
rem
rem	Change in 10.2: the raw block dump always appears in 
rem	a block dump, you cannot stop it. Event 10289 blocks
rem	the appearance of the formatted dump
rem
rem	Script has to be run by a DBA who has the privileges to 
rem	view v$process, v$session, v$mystat
rem
rem	Usage
rem		-- the notes assume the tablespace is not ASSM.
rem		execute dump_seg('tablex');			-- dump first data block
rem		execute dump_seg('tablex',5)			-- dump first five data blocks
rem		execute dump_seg('indexy',1,'INDEX')		-- dump root block of index
rem		execute dump_seg('tableX',i_start_block=>0 )	-- dump seg header block
rem
rem	Various "optimizer" issues with 10g:
rem		select * from dba_extents 
rem		where segment_name = 'T1' 
rem		and extent_id = 0;
rem	vs.
rem		select * from dba_extents 
rem		where segment_name = 'T1' 
rem		order by extent_id;
rem
rem	On one system, the first query crashed with error:
rem		ORA-00379: no free buffers available in buffer pool DEFAULT for block size 2K
rem
rem	There had been an object in the 2K tablespace, 
rem	which had been dropped but not purged. There 
rem	were no buffers allocated to the 2K cache, 
rem	hence the failure.  And it was not possible
rem	to purge the recyclebin without creating the
rem	cache.
rem
rem	Clearly, the join order had changed because of
rem	the extent_id predicate - and this led to the
rem	crash
rem
rem	For this reason, I changed the code to query by
rem	segment and order by extent_id - stopping at the
rem	zero extent
rem
rem	Performance can also be affected by how many extents
rem	you have, and whether you have collected statistics
rem	(in 10g) on the fixed tables - because of the call to
rem	check the extents in the segment headers.
rem
rem	Internal enhancements in 11g
rem	You get a dump of all the copies in the buffer cache,
rem	and a copy of the version of the block on disc.
rem

start setenv

create or replace procedure dump_seg(
	i_seg_name		in	varchar2,
	i_block_count		in	number		default 1,
	i_seg_type		in	varchar2	default 'TABLE',
	i_start_block		in	number		default 1,
	i_owner			in	varchar2	default sys_context('userenv','session_user'),
	i_partition_name	in	varchar2	default null,
	i_dump_formatted	in	boolean		default true,
	i_dump_raw		in	boolean		default false
)
as
	m_file_id	number;
	m_block_min	number;
	m_block_max	number;
	m_process	varchar2(32);

begin

	for r in (
		select 
			file_id, 
			block_id + i_start_block			block_min,
			block_id + i_start_block + i_block_count - 1	block_max
		from
			dba_extents
		where
			segment_name = upper(i_seg_name)
		and	segment_type = upper(i_seg_type)
		and	owner = upper(i_owner)
		and	nvl(partition_name,'N/A') = upper(nvl(i_partition_name,'N/A'))
		order by
			extent_id
	) loop
	
		m_file_id 	:= r.file_id;
		m_block_min	:= r.block_min;
		m_block_max	:= r.block_max;
		exit;
	end loop;

	if (i_dump_formatted) then
		execute immediate 
			'alter session set events ''10289 trace name context off''';

		execute immediate
			'alter system dump datafile ' || m_file_id ||
			' block min ' || m_block_min ||
			' block max ' || m_block_max
			;
	end if;

	if (i_dump_raw) then
 		execute immediate 
			'alter session set events ''10289 trace name context forever''';

		execute immediate
			'alter system dump datafile ' || m_file_id ||
			' block min ' || m_block_min ||
			' block max ' || m_block_max
			;

	end if;

	execute immediate 
		'alter session set events ''10289 trace name context off''';

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
		se.sid = (select sid from v$mystat where rownum = 1)
	and	pr.addr = se.paddr
	;

	dbms_output.new_line;
	dbms_output.put_line(
		'Dumped ' || i_block_count || ' blocks from ' ||
		i_seg_type || ' ' || i_seg_name || 
		' starting from block ' || i_start_block
	);

	dbms_output.new_line;
	dbms_output.put_line('Trace file name includes: ' || m_process);

	dbms_output.new_line;

exception
	when others then
		dbms_output.new_line;
		dbms_output.put_line('Unspecified error.');
		dbms_output.put_line('Check syntax.');
		dbms_output.put_line('dumpseg({segment_name},[{block count}],[{segment_type}]');
		dbms_output.put_line('	[{start block (1)}],[{owner}],[{partition name}]');
		dbms_output.put_line('	[{dump formatted YES/n}],[{dump raw y/NO}]');
		dbms_output.new_line;
		raise;
end;
.
/

show errors

drop public synonym dump_seg;
create public synonym dump_seg for dump_seg;
grant execute on dump_seg to public;
