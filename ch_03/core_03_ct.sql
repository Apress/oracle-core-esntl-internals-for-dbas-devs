rem
rem	Script:		core_03_ct.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Apr 2011
rem	Purpose:	
rem
rem	Last tested 
rem		11.1.0.7
rem	Not tested
rem		11.2.0.2
rem		10.2.0.3
rem		 9.2.0.8
rem		 8.1.7.4
rem
rem	Depends on
rem		c_dump_tab.sql
rem
rem	Notes:
rem	Create a simple table with 4 rows for updates from three sessions
rem

start setenv

drop table t1;

create table t1(id number, n1 number);

insert into t1 values(1,1);
insert into t1 values(2,2);
insert into t1 values(3,3);

commit;

create unique index t1_i1 on t1(id);

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		estimate_percent => 100,
		method_opt	 => 'for all columns size 1'
	);
end;
/

--
--	For 11g - force to disc for the dump
--

alter system checkpoint;

--
--	Now dump the first findable block of the table
--

execute dump_table_block('t1')


set doc off
doc

#

