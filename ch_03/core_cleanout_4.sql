rem
rem	Script:		core_cleanout_4.sql
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
rem	Transaction Table consistent reads
rem
rem	Privileges needed
rem		alter system
rem	Execute on 
rem		dbms_lock
rem		dbms_stats
rem		dbms_cdc_utility
rem
rem	Depends on
rem		c_mystats.sql
rem		snap_myst.sql
rem		snap_rollstat.sql
rem		c_dump_seg.sql
rem

start setenv

drop table t2;
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

create table t2 ( n1 number);
insert into t2 values (0);
commit;

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		estimate_percent => 100,
		method_opt	 => 'for all columns size 1'
	);
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T2',
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

update 
	/*+ index(t1) */
	t1
set
	small_vc = small_vc + 1
;

alter system checkpoint;
alter system flush buffer_cache;

execute dbms_lock.sleep(2)

execute dump_seg('t1')

alter system checkpoint;
alter system flush buffer_cache;

commit;

spool core_cleanout_4

select 
	sys.dbms_cdc_utility.get_current_scn post_commit_scn
from 
	dual
;

--	
--	First test, comment out the "set transaction read only"
--	Run the whole code path from a single session.
--
--	Second test, comment out the "set transaction read only"
--	comment out the snapshot and pl/sql loop from this session
--	and run them from another session before pressing return.
--
--	Third test, run the snapshot and loop from a second session
--	as for the second test, but allow the set transaction to
--	run in this session first.
--

-- set transaction read only;

pause Press return to continue

execute snap_rollstats.start_snap

begin
	for i in 1..17000 loop
		update t2 set n1 = i;
		commit;
	end loop;
end;
/

execute snap_rollstats.end_snap

select 
	sys.dbms_cdc_utility.get_current_scn after_batch_scn
from 
	dual
;

execute snap_my_stats.start_snap

select 
	/*+ full(t1) */
	count(*)
from
	t1
;

execute snap_my_stats.end_snap

select 
	ora_rowscn, count(*) 
from 
	t1
group by 
	ora_rowscn
order by
	count(*)
;

spool off
