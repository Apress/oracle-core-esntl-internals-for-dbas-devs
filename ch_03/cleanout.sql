rem
rem	Script:		cleanout.sql
rem	Author:		Jonathan Lewis
rem	Dated:		February 2003
rem	Purpose:	Latching occurs on block cleanout but no gets are recorded
rem
rem	Last tested
rem		11.1.0.6
rem		10.2.0.3
rem		10.1.0.4
rem	 	 9.2.0.6
rem		 8.1.7.4 
rem
rem	Depends on
rem		c_mystats.sql
rem		snap_myst.sql
rem		snap_9_latch.sql (snap_11_latch.sql)
rem		snap_9_buffer.sql
rem		snap_9_kcbsw.sql (snap_11_kcbsw.sql)
rem		
rem	Notes:
rem	We create a table with one row per block and then
rem	update every block, forcing an indexed access to get
rem	all the blocks in the buffer. Note, commit cleanout
rem	applies only to a number of buffers limited by a 
rem	percentage of the buffer size, and the buffers have to
rem	be in memory still. (A recent (10/2007) experiment on 10g 
rem	suggested that the block could have been written, cleared
rem	from memory, and re-read by another process and still get
rem	a commit cleanout.
rem
rem	On the commit we take a snapshot of session stats,
rem	buffer pool stats, and latches. The critical numbers
rem	are:
rem		session stats	logical I/O (any type)
rem				commit cleanouts
rem		buffer pool	logical I/O
rem		latches		cache buffers chains latch
rem		
rem
rem	My best result was:
rem		session logical reads            1
rem		commit cleanouts               180
rem
rem		cache buffers chains           183 gets
rem
rem		buffer pool			1 CU 
rem
rem	So we see no logical I/O recorded, but the latch
rem	activity suggests that we have hit the latch chain
rem	to clean the block. We can pursue this further to
rem	the v$latch_children to show that the bulk of the
rem	latching was one latch access per child - covering
rem	all the blocks in the table.
rem
rem	For cleanest numbers, run the script twice so that
rem	the cost of loading the snapshot code doesn't obscure
rem	the figures.
rem
rem	A snapshot of kcbsw shows very few calls as well -
rem	largely related to the undo segments
rem
rem	Results from 11.1.0.6 - with 500 blocks which all stayed 
rem	in the cache, I got 500 cleanouts reported but only 13 
rem	session logical I/Os (one was the db block get for the
rem	transaction table update, of course).
rem
rem	With a "flush buffer cache", though, I only got 100
rem	attempts and 100 failures.
rem

start setenv

drop table t1;

create table t1 (
	id		number,
	small_no	number(5,2),
	small_vc	varchar2(10),
	padding		varchar2(1000),
	constraint t1_pk primary key (id)
)
pctfree 90
pctused 10
;

insert into t1
select 
	rownum,
	1+ trunc(rownum/10),
	lpad(rownum,10),
	rpad('x',1000)
from
	all_objects
where
	rownum <= 500
;

commit;

select small_no from t1
where small_no < 0;

update /*+ index(t1) */ t1
set
	small_vc = small_vc + 1
;

--
--	Do this to see commit cleanout failures
--

alter system flush buffer_cache;

execute snap_latch.start_snap
execute snap_buffer.start_snap
execute snap_my_stats.start_snap
execute snap_kcbsw.start_snap

commit;

spool cleanout

execute snap_kcbsw.end_snap	-- no useful results from 11g
execute snap_my_stats.end_snap
execute snap_buffer.end_snap
execute snap_latch.end_snap(10)

spool off
