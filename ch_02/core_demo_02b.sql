rem
rem	Script:		core_demo_02b.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Feb 2011
rem	Purpose:	
rem
rem	Last tested 
rem		10.2.0.3
rem		 9.2.0.8
rem	Not tested
rem		11.2.0.2
rem		11.1.0.7
rem	Not considered
rem		 8.1.7.4
rem
rem	Notes:
rem	As for core_demo_02.sql, but used to show the
rem	number of redo entries and latch gets. We update
rem	50 rows to make the difference more visible.
rem
rem	Depends on
rem		c_mystats.sql
rem		snap_myst.sql
rem		snap_stat.sql
rem		snap_9_latch.sql (snap_11_latch.sql)
rem		snap_9_latch_child.sql
rem		

start setenv
set timing off

execute dbms_random.seed(0)

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin
		dbms_stats.set_system_stats('MBRC',8);
		dbms_stats.set_system_stats('MREADTIM',26);
		dbms_stats.set_system_stats('SREADTIM',12);
		dbms_stats.set_system_stats('CPUSPEED',800);
	exception
		when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;
end;
/


create table t1
as
select
	2 * rownum - 1			id,
	rownum				n1,
	cast('xxxxxx' as varchar2(10))	v1,
	rpad('0',100,'0')		padding
from
	all_objects
where
	rownum <= 60
union all
select
	2 * rownum			id,
	rownum				n1,
	cast('xxxxxx' as varchar2(10))	v1,
	rpad('0',100,'0')		padding
from
	all_objects
where
	rownum <= 60
;

create index t1_i1 on t1(id);

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		method_opt 	 => 'for all columns size 1'
	);
end;
/


select 
	dbms_rowid.rowid_block_number(rowid)	block_number, 
	count(*)				rows_per_block
from 
	t1 
group by 
	dbms_rowid.rowid_block_number(rowid)
order by
	block_number
;


alter system switch logfile;
execute dbms_lock.sleep(2)

spool core_demo_02b.lst

execute snap_my_stats.start_snap
execute snap_stats.start_snap
execute snap_latch.start_snap
execute snap_latch_child.start_snap('redo copy')
-- execute snap_latch_child.start_snap('redo allocation')
-- execute snap_latch_child.start_snap('In memory undo latch')

update
	/*+ index(t1 t1_i1) */
	t1
set
	v1 = 'YYYYYYYYYY'
where
	id between 5 and 54
;

--
--	There is an important difference in results between 
--	taking the snapshot before or after the commit.
--
--	My code only allows for reporting one child latch
--

-- execute snap_latch_child.end_snap('In memory undo latch')
-- execute snap_latch_child.end_snap('redo allocation')
execute snap_latch_child.end_snap('redo copy')
execute snap_latch.end_snap
execute snap_stats.end_snap
execute snap_my_stats.end_snap

commit;

-- execute snap_latch_child.end_snap('In memory undo latch')
-- execute snap_latch_child.end_snap('redo allocation')
execute snap_latch_child.end_snap('redo copy')
execute snap_latch.end_snap
execute snap_stats.end_snap
execute snap_my_stats.end_snap


spool off


set doc off
doc

9.2.0.8
=======
Latch                              Gets      Misses     Sp_Get     Sleeps     Im_Gets   Im_Miss Holding Woken Time ms
-----                              ----      ------     ------     ------     -------   ------- ------- ----- -------
redo copy                             0           0          0          0          51         0       0     0      .0
redo allocation                      53           0          0          0           0         0       0     0      .0

redo writing                          3           0          0          0           0         0       0     0      .0
undo global data                      3           0          0          0           0         0       0     0      .0
cache buffers chains                267           0          0          0           1         0       0     0      .0

---------------------------------
System stats:-  05-Apr 16:03:14
Interval:-      0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
redo synch writes                                                            1
redo entries                                                                51
redo size                                                               12,668
redo wastage                                                               228
redo writes                                                                  1
redo blocks written                                                         26

---------------------------------
Session stats - 05-Apr 16:03:14
Interval:-  0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
session logical reads                                                       56
db block gets                                                               54
consistent gets                                                              2
db block changes                                                           103
redo entries                                                                51
redo size                                                               12,668



10.2.0.3
========

---------------------------------
Latch waits:-   05-Apr 16:09:11
Interval:-      0 seconds
---------------------------------
Latch                              Gets      Misses     Sp_Get     Sleeps     Im_Gets   Im_Miss Holding Woken Time ms
-----                              ----      ------     ------     ------     -------   ------- ------- ----- -------
redo writing                          3           0          0          0           0         0       0     0      .0
redo copy                             0           0          0          0           1         0       0     0      .0
redo allocation                       5           0          0          0           1         0       0     0      .0
undo global data                      5           0          0          0           0         0       0     0      .0
In memory undo latch                 53           0          0          0           1         0       0     0      .0
cache buffers chains                379           0          0          0           0         0       0     0      .0


---------------------------------
System stats:-  05-Apr 16:09:11
Interval:-      0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
redo synch writes                                                            1
redo synch time                                                              1
redo entries                                                                 1
redo size                                                               12,048
redo wastage                                                               352

redo writes                                                                  1
redo blocks written                                                         25

undo change vector size                                                  4,632
IMU commits                                                                  1
IMU undo allocation size                                                43,052

---------------------------------
Session stats - 05-Apr 16:09:11
Interval:-  0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
session logical reads                                                       85
db block gets                                                               53
db block gets from cache                                                    53
consistent gets                                                             32
consistent gets from cache                                                  32
consistent gets - examination                                               30
db block changes                                                           102

redo synch writes                                                            1
redo synch time                                                              1
redo entries                                                                 1
redo size                                                               12,048

undo change vector size                                                  4,632
IMU commits                                                                  1
IMU undo allocation size                                                43,052

buffer is not pinned count                                                  20



select name, count(*) from v$latch_children group by name order by count(*)

NAME                         COUNT(*)
-------------------------- ----------
In memory undo latch               10
redo allocation                    12



Latch activity (hypothesis):
	on update:	session gets allocation latch for private thread
	on commit:	session gets allocation latch for private thread
			session gets allocation latch for a public thread - start with immediate get
			lgwr gets allocation latches for both public threads.

#

#

