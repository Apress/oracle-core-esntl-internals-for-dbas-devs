rem
rem	Script:		core_cleanout_3.sql
rem	Author:		Jonathan Lewis
rem	Dated:		February 2003
rem	Purpose:	
rem
rem	Last tested
rem		11.1.0.6
rem		10.2.0.1
rem		10.1.0.4
rem	 	 9.2.0.6
rem		 8.1.7.4 
rem
rem	Notes:
rem	Parallel query (serial direct path) don't do delayed block cleanout.
rem
rem	Depends on
rem		snap_stat.sql
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

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		estimate_percent => 100,
		method_opt	 => 'for all columns size 1'
	);
end;
/

select 
	small_no 
from 
	t1
where 
	small_no < 0
;

update /*+ index(t1) */ t1
set
	small_vc = small_vc + 1
;

spool core_cleanout_3

alter system flush buffer_cache;
commit;

execute snap_stats.start_snap

select 
	/*+ parallel(t1 2) full(t1) */
	count(*)
from
	t1
;

execute snap_stats.end_snap

execute snap_stats.start_snap

select 
	/*+ parallel(t1 2) full(t1) */
	count(*)
from
	t1
;

execute snap_stats.end_snap

execute snap_stats.start_snap

select 
	/*+ parallel(t1 2) full(t1) */
	count(*)
from
	t1
;

execute snap_stats.end_snap


spool off
