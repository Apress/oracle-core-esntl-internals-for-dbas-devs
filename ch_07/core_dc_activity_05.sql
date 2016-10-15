rem
rem	July 2011
rem	core_dc_activity_05.sql
rem
rem	Holding a cursor in pl/sql
rem
rem	Privileges required
rem		Execute on
rem			dbms_stats
rem			dbms_sql
rem		alter session
rem		alter system
rem	
rem	Depends on
rem		setenv.sql
rem		snap_9_latch.sql (snap_11_latch.sql)
rem		c_mystats.sql
rem		snap_myst.sql
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

spool core_dc_activity_05.lst

prompt	===========================================
prompt	dbms_sql: session_cached_cursors at default
prompt	===========================================

alter session set session_cached_cursors = 50;
alter system flush shared_pool;

select n1 priming from t1 where id = 1;

execute snap_my_stats.start_snap
execute snap_latch.start_snap

execute snap_my_stats.start_snap
execute snap_latch.start_snap

declare
	m_cursor		integer;
	m_n			number;
	m_rows_processed 	number;

begin
	m_cursor := dbms_sql.open_cursor;
	dbms_sql.parse(
		m_cursor,
		'select n1 from t1 where id = :n',
		dbms_sql.native
	);
	dbms_sql.define_column(m_cursor,1,m_n);

	for i in 1..1000 loop

		dbms_sql.bind_variable(m_cursor, ':n', i);
		m_rows_processed := dbms_sql.execute(m_cursor);

		if dbms_sql.fetch_rows(m_cursor) > 0 then
			dbms_sql.column_value(m_cursor, 1, m_n);
		end if;


	end loop;

	dbms_sql.close_cursor(m_cursor);

end;
/

execute snap_latch.end_snap
execute snap_my_stats.end_snap

prompt	========================================
prompt	dbms_sql: session_cached_cursors at zero
prompt	========================================

alter session set session_cached_cursors = 0;
alter system flush shared_pool;

select n1 priming from t1 where id = 1;

execute snap_my_stats.start_snap
execute snap_latch.start_snap

execute snap_my_stats.start_snap
execute snap_latch.start_snap

declare
	m_cursor		integer;
	m_n			number;
	m_rows_processed 	number;

begin
	m_cursor := dbms_sql.open_cursor;
	dbms_sql.parse(
		m_cursor,
		'select n1 from t1 where id = :n',
		dbms_sql.native
	);
	dbms_sql.define_column(m_cursor,1,m_n);

	for i in 1..1000 loop

		dbms_sql.bind_variable(m_cursor, ':n', i);
		m_rows_processed := dbms_sql.execute(m_cursor);

		if dbms_sql.fetch_rows(m_cursor) > 0 then
			dbms_sql.column_value(m_cursor, 1, m_n);
		end if;


	end loop;

	dbms_sql.close_cursor(m_cursor);
end;
/

execute snap_latch.end_snap
execute snap_my_stats.end_snap

alter session set session_cached_cursors = 50;

spool off

set doc off
doc

===========================================
dbms_sql: session_cached_cursors at default
===========================================

---------------------------------
Latch waits:-   31-Aug 14:28:10
Interval:-      0 seconds
---------------------------------
Latch                              Gets      Misses     Sp_Get     Sleeps     Im_Gets   Im_Miss Holding Woken Time ms
-----                              ----      ------     ------     ------     -------   ------- ------- ----- -------
session allocation                  622           0          0          0           0         0       0     0      .0
session idle bit                     14           0          0          0           0         0       0     0      .0
ksuosstats global area                1           0          0          0           0         0       0     0      .0
messages                             16           0          0          0           0         0       0     0      .0
enqueues                             18           0          0          0           0         0       0     0      .0
enqueue hash chains                  16           0          0          0           2         0       0     0      .0
channel operations paren              8           0          0          0           0         0       0     0      .0
active service list                   2           0          0          0           1         0       0     0      .0
cache buffers lru chain           2,056           0          0          0           0         0       0     0      .0
active checkpoint queue               5           0          0          0           0         0       0     0      .0
checkpoint queue latch               50           0          0          0           0         0       0     0      .0
cache buffers chains              8,580           0          0          0       2,047         0       0     0      .0
simulator lru latch                  37           0          0          0         128         0       0     0      .0
simulator hash latch                183           0          0          0           0         0       0     0      .0
object queue header oper          4,106           0          0          0           0         0       0     0      .0
object queue header heap              5           0          0          0          11         0       0     0      .0
redo writing                          7           0          0          0           0         0       0     0      .0
redo copy                             0           0          0          0           4         0       0     0      .0
redo allocation                       0           0          0          0           4         0       0     0      .0
row cache objects                   371           0          0          0           0         0       0     0      .0
kks stats                            13           0          0          0           0         0       0     0      .0
shared pool                         455           0          0          0           0         0       0     0      .0
library cache                     6,393           0          0          0           0         0       0     0      .0
library cache lock                6,174           0          0          0           0         0       0     0      .0
library cache pin                   110           0          0          0           0         0       0     0      .0
library cache lock alloc              2           0          0          0           0         0       0     0      .0
library cache load lock              22           0          0          0           0         0       0     0      .0
shared pool simulator                46           0          0          0           0         0       0     0      .0
session timer                         1           0          0          0           0         0       0     0      .0
hash table column usage               0           0          0          0           6         0       0     0      .0
SQL memory manager latch              0           0          0          0           1         0       0     0      .0
SQL memory manager worka             81           0          0          0           0         0       0     0      .0
compile environment latc              2           0          0          0           0         0       0     0      .0
ASM db client latch                   2           0          0          0           0         0       0     0      .0
PL/SQL warning settings               4           0          0          0           0         0       0     0      .0

PL/SQL procedure successfully completed.

---------------------------------
Session stats - 31-Aug 14:28:10
Interval:-  0 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
opened cursors cumulative                                                1,051
user calls                                                                  13
recursive calls                                                          6,892
recursive cpu usage                                                         44
session logical reads                                                    4,331
CPU used when call started                                                  44
CPU used by this session                                                    44
DB time                                                                    138
user I/O wait time                                                         108
session uga memory                                                       7,584
session pga memory                                                     131,072
enqueue requests                                                             8
enqueue releases                                                             8
physical read total IO requests                                          2,047
physical read total bytes                                           16,769,024
consistent gets                                                          4,331
consistent gets from cache                                               4,331
consistent gets - examination                                            4,136
physical reads                                                           2,047
physical reads cache                                                     2,047
physical read IO requests                                                2,047
physical read bytes                                                 16,769,024
free buffer requested                                                    2,047
dirty buffers inspected                                                      4
free buffer inspected                                                    2,048
prefetched blocks aged out before use                                      225
shared hash latch upgrades - no wait                                     2,005
calls to get snapshot scn: kcmgss                                        1,074
no work - consistent read gets                                             194
table fetch by rowid                                                     1,118
table fetch continued row                                                   14
cluster key scans                                                            8
cluster key scan block gets                                                 10
rows fetched via callback                                                1,025
index crx upgrade (positioned)                                               1
index fetch by key                                                       1,035
index scans kdiixs1                                                         53
session cursor cache hits                                                1,050
cursor authentications                                                       9
buffer is pinned count                                                      24
buffer is not pinned count                                               2,276
workarea executions - optimal                                               23
parse time cpu                                                               2
parse time elapsed                                                           7
parse count (total)                                                      1,064
parse count (hard)                                                           8
execute count                                                            1,078
bytes sent via SQL*Net to client                                         6,248
bytes received via SQL*Net from client                                   2,781
SQL*Net roundtrips to/from client                                            9
sorts (memory)                                                              14
sorts (rows)                                                             1,571

PL/SQL procedure successfully completed.

========================================
dbms_sql: session_cached_cursors at zero
========================================

---------------------------------
Latch waits:-   31-Aug 14:28:13
Interval:-      2 seconds
---------------------------------
Latch                              Gets      Misses     Sp_Get     Sleeps     Im_Gets   Im_Miss Holding Woken Time ms
-----                              ----      ------     ------     ------     -------   ------- ------- ----- -------
session allocation                1,206           0          0          0           0         0       0     0      .0
session idle bit                     14           0          0          0           0         0       0     0      .0
messages                             10           0          0          0           0         0       0     0      .0
enqueues                             78           0          0          0           0         0       0     0      .0
enqueue hash chains                  77           0          0          0           2         0       0     0      .0
channel operations paren              8           0          0          0           0         0       0     0      .0
active service list                   7           0          0          0           1         0       0     0      .0
cache buffers lru chain           2,049           0          0          0           0         0       0     0      .0
active checkpoint queue               1           0          0          0           0         0       0     0      .0
checkpoint queue latch               22           0          0          0           0         0       0     0      .0
cache buffers chains              8,651           0          0          0       2,049         0       0     0      .0
simulator lru latch                  33           0          0          0         128         0       0     0      .0
simulator hash latch                161           0          0          0           0         0       0     0      .0
object queue header oper          4,099           0          0          0           0         0       0     0      .0
object queue header heap              1           0          0          0           7         0       0     0      .0
redo writing                          3           0          0          0           0         0       0     0      .0
redo allocation                       2           0          0          0           0         0       0     0      .0
In memory undo latch                  2           0          0          0           1         0       0     0      .0
row cache objects                   353           0          0          0           0         0       0     0      .0
kks stats                             6           0          0          0           0         0       0     0      .0
shared pool                         522           0          0          0           0         0       0     0      .0
library cache                    10,549           1          1          0           0         0       0     0      .0
library cache lock               10,392           0          0          0           0         0       0     0      .0
library cache pin                    98           0          0          0           0         0       0     0      .0
library cache lock alloc              2           0          0          0           0         0       0     0      .0
library cache load lock              30           0          0          0           0         0       0     0      .0
shared pool simulator               125           0          0          0           0         0       0     0      .0
session timer                         1           0          0          0           0         0       0     0      .0
hash table column usage               0           0          0          0           6         0       0     0      .0
SQL memory manager latch              0           0          0          0           1         0       0     0      .0
SQL memory manager worka             83           0          0          0           0         0       0     0      .0
compile environment latc              2           0          0          0           0         0       0     0      .0
ASM db client latch                   2           0          0          0           0         0       0     0      .0
JS queue state obj latch             30           0          0          0           0         0       0     0      .0
PL/SQL warning settings               4           0          0          0           0         0       0     0      .0

PL/SQL procedure successfully completed.

---------------------------------
Session stats - 31-Aug 14:28:13
Interval:-  2 seconds
---------------------------------
Name                                                                     Value
----                                                                     -----
opened cursors cumulative                                                1,051
user calls                                                                  13
recursive calls                                                          6,920
recursive cpu usage                                                         47
session logical reads                                                    4,331
CPU used when call started                                                  48
CPU used by this session                                                    48
DB time                                                                    151
user I/O wait time                                                         116
enqueue requests                                                             6
enqueue releases                                                             6
physical read total IO requests                                          2,047
physical read total bytes                                           16,769,024
consistent gets                                                          4,331
consistent gets from cache                                               4,331
consistent gets - examination                                            4,136
physical reads                                                           2,047
physical reads cache                                                     2,047
physical read IO requests                                                2,047
physical read bytes                                                 16,769,024
free buffer requested                                                    2,047
free buffer inspected                                                    2,048
shared hash latch upgrades - no wait                                     2,005
calls to get snapshot scn: kcmgss                                        1,074
no work - consistent read gets                                             194
table fetch by rowid                                                     1,118
table fetch continued row                                                   14
cluster key scans                                                            8
cluster key scan block gets                                                 10
rows fetched via callback                                                1,025
index crx upgrade (positioned)                                               1
index fetch by key                                                       1,035
index scans kdiixs1                                                         53
cursor authentications                                                       4
buffer is pinned count                                                      24
buffer is not pinned count                                               2,276
workarea executions - optimal                                               23
parse time cpu                                                               2
parse time elapsed                                                          10
parse count (total)                                                      1,074
parse count (hard)                                                           6
execute count                                                            1,078
bytes sent via SQL*Net to client                                         6,248
bytes received via SQL*Net from client                                   2,781
SQL*Net roundtrips to/from client                                            9
sorts (memory)                                                              14
sorts (rows)                                                             1,571


#