rem
rem	July 2011
rem	core_dc_activity_02.sql
rem
rem	Row cache activity with use of bind variables
rem	Execute the start procedures twice to eliminate their
rem	impact on row cache activity
rem
rem	Depends on
rem		snap_rowcache.sql
rem		snap_9_latch.sql (snap_11_latch.sql)
rem		setenv.sql
rem		c_mystats.sql
rem		snap_myst.sql
rem		snap_9_latch_child.sql
rem

start setenv

drop table t1;
purge recyclebin;

create table t1 pctfree 99 pctused 1
as
select 
	rownum			id, 
	rownum			n1, 
	rpad('x',100)		padding
from 
	all_objects
where 
	rownum <= 10000
;


create unique index t1_pk on t1(id) pctfree 99;
alter table t1 add constraint t1_pk primary key(id);

execute dbms_stats.gather_table_stats(user,'t1')

spool core_dc_activity_02.lst

execute snap_my_stats.start_snap
execute snap_rowcache.start_snap
execute snap_latch_child.start_snap('row cache objects')

execute snap_my_stats.start_snap
execute snap_rowcache.start_snap
execute snap_latch_child.start_snap('row cache objects')

declare
	m_n	number;
begin
	for i in 1..1000 loop
		execute immediate
			'select n1 from t1 where id = :n'
			into m_n using i;
	end loop;
end;
/

execute snap_latch_child.end_snap('row cache objects')
execute snap_rowcache.end_snap
execute snap_my_stats.end_snap

spool off

set doc off
doc


Sample output from 10.2.0.3

---------------------------------------------------------
row cache objects latch waits - 31-Aug 09:00:45
Interval:-      0 seconds
---------------------------------------------------------
Address                     Gets      Misses      Spins     Sleeps       Im_Gets     Im_Miss Holding Woken    Time m/s
-------                     ----      ------     ------      -----       -------     ------- ------- -----    --------
1FE4846C                       6           0          0          0             0           0       0     0        .000
1FEC84D4                       3           0          0          0             0           0       0     0        .000
1FEC910C                      24           0          0          0             0           0       0     0        .000
1FF495DC                       3           0          0          0             0           0       0     0        .000
1FFC9644                      18           0          0          0             0           0       0     0        .000
1FFCAF14                      27           0          0          0             0           0       0     0        .000
1F8B4E48                       6           0          0          0             0           0       0     0        .000
Latches reported: 7

PL/SQL procedure successfully completed.

---------------------------------
Dictionary Cache - 31-Aug 09:00:45
Interval:-      0 seconds
---------------------------------
Parameter                 Usage Fixed    Gets  Misses   Scans  Misses    Comp    Mods Flushes
---------                 ----- -----    ----  ------   -----  --------------    ---- -------
dc_segments                   0     0       2       0       0       0       0       0       0
dc_tablespaces                0     0       2       0       0       0       0       0       0
dc_users                      0     0      15       0       0       0       0       0       0
dc_objects                    0     0       1       0       0       0       0       0       0
dc_global_oids                0     0      12       0       0       0       0       0       0
dc_object_ids                 0     0      15       0       0       0       0       0       0
dc_histogram_defs             0     0       2       0       0       0       0       0       0

PL/SQL procedure successfully completed.


11g results
---------------------------------------------------------
row cache objects latch waits - 31-Aug 09:09:24
Interval:-      0 seconds
---------------------------------------------------------
Address                     Gets      Misses      Spins     Sleeps       Im_Gets     Im_Miss Holding Woken    Time m/s
-------                     ----      ------     ------      -----       -------     ------- ------- -----    --------
2D9F08FC                      12           0          0          0             0           0       0  0   .000
2DA71804                      15           0          0          0             0           0       0  0   .000
2DAF1904                      38           0          0          0             0           0       0  0   .000
2DB71A00                      18           0          0          0             0           0       0  0   .000
2DB738F8                       6           0          0          0             0           0       0  0   .000
Latches reported: 5

PL/SQL procedure successfully completed.

---------------------------------
Dictionary Cache - 31-Aug 09:09:24
Interval:-      0 seconds
---------------------------------
Parameter                 Usage Fixed    Gets  Misses   Scans  Misses    Comp    Mods Flushes
---------                 ----- -----    ----  ------   -----  --------------    ---- -------
dc_segments                   0     0       4       0       0       0       0       0       0
dc_users                      0     0       5       0       0       0       0       0       0
dc_objects                    0     0      18       0       0       0       0       0       0
dc_global_oids                0     0      12       0       0       0       0       0       0
dc_histogram_defs             0     0       2       0       0       0       0       0       0
dc_object_grants              0     0      10       0       0       0       0       0       0

PL/SQL procedure successfully completed.
#
	