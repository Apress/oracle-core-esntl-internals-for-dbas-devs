rem
rem	Script:		core_commit_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Aug 2011
rem	Purpose:	Commit in pl/sql loop
rem
rem	Last tested 
rem		11.2.0.2
rem		10.2.0.3
rem
rem	Priveleges needed
rem		Execute on
rem			dbms_random
rem			dbms_stats
rem			dbms_rowid
rem			dbms_lock
rem		alter session
rem		alter system
rem
rem	Depends on
rem		c_mystats.sql
rem		snap_myst.sql
rem		snap_9_latch.sql (snap_11_latch.sql)
rem		snap_redo.sql
rem		snap_my_redo.sql
rem		snap_events.sql
rem		snap_sysev.sql	(snap_11_sysev.sql)
rem


start setenv

set timing off
set feedback on

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;
end;
/

create table t1 (
	id,
	small_no,
	small_vc,
	padding,
	constraint t1_pk primary key (id)
)
as
select 
	rownum,
	1+ trunc(rownum/10),
	lpad(rownum,10),
	rpad('x',100)
from
	all_objects
	where
	rownum <= 500
;


begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		cascade		 => true,
		estimate_percent => null,
		granularity      => 'DEFAULT',
		method_opt 	 => 'for all columns size 1'
	);
end;
/


alter system switch logfile;

execute snap_system_events.start_snap
execute snap_redo.start_snap
execute snap_my_redo.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap
execute snap_latch.start_snap

spool core_commit_01.lst

begin

	for r in (
		select id from t1 
		where mod(id,20) = 0
	) loop
		update t1
		set small_no = small_no + .1
		where id = r.id;
--		commit comment 'In the loop';
--		commit write immediate wait;
		commit write immediate nowait;
--		commit write batch wait;
--		commit write batch nowait;
	end loop;

end;
/

execute snap_latch.end_snap
execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_my_redo.end_snap
execute snap_redo.end_snap
execute snap_system_events.end_snap

execute dump_log

spool off


set doc off
doc

Results from simple commit:
===========================
---------------------------------
Session stats - 02-Aug 14:01:39
Interval:-  0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
opened cursors cumulative                                                   15
user commits                                                                25
user calls                                                                   6
recursive calls                                                            110
session logical reads                                                      136
messages sent                                                                6
session pga memory                                                     131,072
enqueue requests                                                            53
enqueue releases                                                            53
db block gets                                                              100
db block gets from cache                                                   100
consistent gets                                                             36
consistent gets from cache                                                  36
consistent gets - examination                                               33
db block changes                                                           100
redo synch writes                                                            1
commit cleanouts                                                            25
commit cleanouts successfully completed                                     25
shared hash latch upgrades - no wait                                         2
calls to kcmgas                                                             25
calls to get snapshot scn: kcmgss                                           56
redo entries                                                                25
redo size                                                               11,132
undo change vector size                                                  3,368
no work - consistent read gets                                               1
IMU commits                                                                 25
IMU undo allocation size                                                22,700
table fetch by rowid                                                         2
cluster key scans                                                            1
cluster key scan block gets                                                  1
rows fetched via callback                                                    2
index crx upgrade (positioned)                                               2
index fetch by key                                                          28
index scans kdiixs1                                                          2
session cursor cache hits                                                    2
buffer is not pinned count                                                   5
workarea memory allocated                                                    4
workarea executions - optimal                                                2
parse count (total)                                                          9
parse count (hard)                                                           3
execute count                                                               33
bytes sent via SQL*Net to client                                           786
bytes received via SQL*Net from client                                   1,274
SQL*Net roundtrips to/from client                                            4
sorts (memory)                                                               2
sorts (rows)                                                                 4
---------------------------------------------------------
SID:    37:TEST_USER - HP-LAPTOPV1\jonathan
Session Events - 02-Aug 14:01:39
Interval:-      0 seconds
---------------------------------------------------------
Event                                             Waits   Time_outs        Csec    Avg Csec    Max Csec
-----                                             -----   ---------        ----    --------    --------
log file sync                                         1           0           0        .071           3
SQL*Net message to client                            10           0           0        .000           0
SQL*Net message from client                          10           0           3        .335     170,091
-------------------------------------
MY REDO stats - 02-Aug 14:01:39
Interval:-  0 seconds
-------------------------------------
Name                                                                     Value
----                                                                     -----
messages sent                                                                6
redo synch writes                                                            1
redo entries                                                                25
redo size                                                               11,132
-------------------------------------
System REDO stats - 02-Aug 14:01:39
Interval:-  0 seconds
-------------------------------------
Name                                                                     Value
----                                                                     -----
messages sent                                                                6
messages received                                                            6
redo synch writes                                                            1
redo entries                                                                25
redo size                                                               11,132
redo wastage                                                             1,268
redo writes                                                                  6
redo blocks written                                                         25
---------------------------------
System Waits:-  02-Aug 14:01:39
Interval:-      0 seconds
---------------------------------
Event                                             Waits   Time_outs            Csec    Avg Csec    Max Csec
-----                                             -----   ---------            ----    --------    --------
pmon timer                                            1           1         170,046 170,045.768     170,258
rdbms ipc message                                     4           2         340,097  85,024.195     170,397
log file parallel write                               6           0               0        .024           5
log file sync                                         1           0               0        .071           3
SQL*Net message to client                            22           0               0        .000           0
SQL*Net message from client                          22           0               6        .276     170,178



Results from commit write immediate wait
========================================


commit write batch wait
-----------------------
cache buffers chains                589           0          0          0           0         0       0     0      .0

redo writing                         75           0          0          0           0         0       0     0      .0
redo copy                             0           0          0          0          25         0       0     0      .0
redo allocation                     125           0          0          0          25         0       0     0      .0

dml lock allocation                  50           0          0          0           0         0       0     0      .0

undo global data                    125           0          0          0           0         0       0     0      .0
In memory undo latch                100           0          0          0          25         0       0     0      .0


commit write immediate wait
---------------------------
cache buffers chains                540           0          0          0           1         0       0     0      .0

redo writing                         75           0          0          0           0         0       0     0      .0
redo copy                             0           0          0          0          50         0       0     0      .0
redo allocation                     125           0          0          0          50         0       0     0      .0

dml lock allocation                  50           0          0          0           0         0       0     0      .0

undo global data                    125           0          0          0           0         0       0     0      .0
In memory undo latch                125           0          0          0          25         0       0     0      .0


==========================

My redo stats (11.2.0.2)
========================
commit:
-------
Name                                                                     Value
----                                                                     -----
messages sent                                                                7
redo entries                                                                25
redo size                                                               11,500
redo synch time (usec)                                                     736
redo synch writes                                                            1

redo writing                         21           0          0          0           0         0       0     0      .0
redo copy                             1           0          0          0          25         0       0     0      .0
redo allocation                      72           0          0          0          25         0       0     0      .0
undo global data                    126           0          0          0           0         0       0     0      .0
In memory undo latch                101           0          0          0          25         0       0     0      .0

redo wastage                                                               820
redo writes                                                                  7
redo blocks written                                                         25


commit write immediate wait;
-----------------------------
Name                                                                     Value
----                                                                     -----
messages sent                                                               25
redo entries                                                                50
redo size                                                               12,752
redo subscn max counts                                                       2
redo synch time                                                              2
redo synch time (usec)                                                  15,723
redo synch writes                                                           25

redo writing                         75           0          0          0           0         0       0     0      .0
redo copy                             1           0          0          0          50         0       0     0      .0
redo allocation                     126           0          0          0          50         0       0     0      .0
undo global data                    126           0          0          0           0         0       0     0      .0
In memory undo latch                126           0          0          0          25         0       0     0      .0

redo wastage                                                            12,048
redo writes                                                                 25
redo blocks written                                                         50


commit write immediate nowait;
------------------------------
Name                                                                     Value
----                                                                     -----
messages sent                                                                7
redo entries                                                                50
redo size                                                               11,876

redo writing                         21           0          0          0           0         0       0     0      .0
redo copy                             1           0          0          0          50         0       0     0      .0
redo allocation                      72           0          0          0          50         0       0     0      .0
undo global data                    126           0          0          0           0         0       0     0      .0
In memory undo latch                126           0          0          0          25         0       0     0      .0

redo wastage                                                             1,468
redo writes                                                                  7
redo blocks written                                                         27


commit write batch wait;
------------------------
(To get 21 blocks written - instead of 50) we much have been right on the edge of a full block for the
first 18 updates, then an odd byte over for the last 7 so that they took 2 blocks each).

Name                                                                     Value
----                                                                     -----
messages sent                                                               25
redo entries                                                                25
redo size                                                               12,068
redo synch time                                                              4
redo synch time (usec)                                                  34,045
redo synch writes                                                           25
redo synch long waits                                                        1

redo writing                         75           0          0          0           0         0       0     0      .0
redo copy                             1           0          0          0          25         0       0     0      .0
redo allocation                     126           0          0          0          25         0       0     0      .0

undo global data                    126           0          0          0           0         0       0     0      .0
In memory undo latch                101           0          0          0          25         0       0     0      .0

redo wastage                                                             3,804
redo writes                                                                 25
redo blocks written                                                         32


commit write batch nowait;
--------------------------
Name                                                                     Value
----                                                                     -----
redo entries                                                                25
redo size                                                               11,012

redo copy                             1           0          0          0          25         0       0     0      .0
redo allocation                      51           0          0          0          25         0       0     0      .0

undo global data                    126           0          0          0           0         0       0     0      .0
In memory undo latch                101           0          0          0          25         0       0     0      .0


Difference between wait and nowait log trace:

(LWN RBA: 0x000052.00000002.0010 LEN: 0002 NST: 04d SCN: 0x0000.00215ac8)
More of these in the WAIT log file
	Longest LWN: 1Kb, reads: 25 
vs.
	Longest LWN: 4Kb, reads: 9 
Each one changes the record length by 0x2c bytes.
	16 * 44 = 704 ... not enough, but getting there.

#
