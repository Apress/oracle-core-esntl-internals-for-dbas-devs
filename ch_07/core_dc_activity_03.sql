rem
rem	July 2011
rem	core_dc_activity_03.sql
rem
rem	Session stats - comparing parse counts between 
rem	literal string approach and bind variable approach
rem	Execute the start procedures twice to eliminate their
rem	impact on row cache activity
rem
rem	Depends on
rem		setenv.sql
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

spool core_dc_activity_03.lst

execute snap_my_stats.start_snap

prompt	=======================
prompt	Literal string approach
prompt	=======================

execute snap_my_stats.start_snap

declare
	m_n	number;
	m_v	varchar2(10);
begin
	for i in 1..1000 loop

		execute immediate
			'select n1 from t1 where id = ' || i
			into m_n;

	end loop;
end;
/

execute snap_my_stats.end_snap


prompt	======================
prompt	Bind Variable approach
prompt	======================

execute snap_my_stats.start_snap

declare
	m_n	number;
begin
	for i in 1..1000 loop

		execute immediate
			'select n1 from t1 where id = :n'
			into m_n using i;
/*
		execute immediate
			'select n1 from t1 where padding = rpad(''x'',100) and id = :n'
			into m_n using i;
*/
	end loop;
end;
/

execute snap_my_stats.end_snap

spool off

set doc off
doc


#
	