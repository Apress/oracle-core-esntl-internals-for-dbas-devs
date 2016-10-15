rem
rem	Script:		c_mystats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Put names to v$mystat
rem
rem	Last tested
rem		11.2.0.2
rem		10.2.0.3
rem		10.1.0.4
rem		 9.2.0.8
rem		 8.1.7.4
rem
rem	Notes:
rem	Should be run by SYS - which means it has to be re-run
rem	on a full database export/import

rem
rem	Option 1 - using v$
rem	Use first_rows and ordered to avoid a sort/merge join, and
rem	to allow faster elimination of the 'value = 0' rows.
rem

create or replace view v$my_stats
as
select
	/*+ 
		first_rows
		ordered
	*/
	ms.sid,
	sn.statistic#,
	sn.name,
	sn.class,
	ms.value
from
	v$mystat	ms,
	v$statname	sn
where
	sn.statistic# = ms.statistic#
;

rem
rem	Option 2 - using x$
rem	Avoids the filter subquery for count(*) from x$ksusd
rem	(See v$fixed_view_definition)
rem

create or replace view v$my_stats
as
select
	/*+
		first_rows
		ordered
	*/
	ms.ksusenum		sid,
	sn.indx			statistic#,
	sn.ksusdnam		name,
	sn.ksusdcls		class,
	ms.ksusestv		value
from
	x$ksumysta	ms,
	x$ksusd		sn
where
	ms.inst_id = sys_context('userenv','instance')
and	bitand(ms.ksspaflg,1)!=0 
and	bitand(ms.ksuseflg,1)!=0 
and	sn.inst_id = sys_context('userenv','instance')
and	sn.indx = ms.ksusestn
;

drop public synonym v$my_stats;
create public synonym v$my_stats for v$my_stats;
grant select on v$my_stats to public;
