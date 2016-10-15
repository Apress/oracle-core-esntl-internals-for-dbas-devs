rem
rem	Script:		snap_9_kcbsw.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of cache usage
rem
rem	Notes
rem	8i has column 'OTHER WAIT'	which needs double quotes.
rem	9i has column 'OTHER_WAIT'
rem
rem	 8.1.7.4 has 458 routines listed in x$kcbsw
rem	 9.2.0.3 has 675
rem	 9.2.0.6 has 677
rem	 9.2.0.6 has 694
rem	10.1.0.1 has 773
rem	10.1.0.4 has 782
rem	10.2.0.1 has 802
rem	10.2.0.3 has 806
rem
rem	Some actions seem to change their choice of call as
rem	you go through different versions of Oracle - so 
rem	perhaps many of the calls are there for historical
rem	reasons and 'just in case'.
rem
rem	Has to be run by SYS to create the package
rem	According to a note on RAC, 
rem		WHY2 is 'waits'
rem		OTHER_WAITS is 'caused waits'
rem
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_kcbsw.start_snap
rem		-- do something
rem		execute snap_kcbsw.end_snap
rem
rem		kdiwh15: kdifxs		Index FULL / RANGE scan	(?? leaf ??)
rem		kdiwh16: kdifxs		Index unique scan scan (?? leaf ??)
rem		kdiwh17: kdifind	Leaf in CU mode
rem		kdiwh18: kdifind	Branch for update 
rem
rem		ktuwh27: kturbk		Acquiring undo records for rolling back.
rem
rem		kduwh01: kdusru		Single row-piece update 
rem
rem		ktuwh03: ktugnb		Rollback segment header update for next undo block ??
rem		ktuwh01: ktugus		Rollback segment header  ??
rem		ktuwh02: ktugus		Rollback segment header acquire for commit ??
rem
rem		ktuwh20: ktuabt		Updating rollback segment headers on rollback ??
rem		ktuwh23: ktubko		Reading rollback records to apply ??
rem		ktuwh24: ktubko		Reading rollback blocks to apply ??
rem		kdowh00: kdoiur		Applying rollback records to data blocks ??
rem
rem		ktuwh05: ktugct		Acquiring undo segment header to get control table
rem
rem		ktswh39: ktsrsp		Space management ?? Block on free list ?
rem		
rem		kddwh01: kdddel		Delete row
rem
rem	Simple update using a one block tablescan and no indexes
rem	--------------------------------------------------------
rem             1             ktuwh01: ktugus		-- undo segment header
rem             1             ktewh25: kteinicnt
rem             1             ktewh26: kteinpscan
rem             1             kdswh01: kdstgr		-- tablescan get row
rem             1             kduwh01: kdusru		-- single row-piece update
rem
rem	100 index fast full scans for count(*)
rem	--------------------------------------
rem           200             ktewh26: kteinpscan
rem         1,000             ktewh27: kteinmap
rem       143,300             kdiwh100: kdircys
rem
rem	10,000 queries into secondary index of IOT followed by IOT block guess
rem	----------------------------------------------------------------------
rem        10,015             kdiwh08: kdiixs		-- range scan leaf ?
rem        10,015             kdiwh09: kdiixs		-- range scan branch ?
rem        10,000             kdiwh68: kdifbk		-- jump to guessed block ? 
rem
rem	10,000 select single row by rowid.
rem	----------------------------------
rem	   10,000             kdswh05: kdsgrp		-- table block by rowid
rem
rem	10,000 select single row by PK - with BLEVEL = 2 (non-unique index ?)
rem	---------------------------------------------------------------------
rem        10,000             kdswh05: kdsgrp		-- table block by rowid
rem        10,006             kdiwh08: kdiixs		-- leaf block
rem        20,006             kdiwh09: kdiixs		-- branch block
rem
rem	100 tablescans for count(*)
rem	---------------------------
rem           100             ktewh25: kteinicnt
rem           100             ktewh26: kteinpscan
rem           100             ktewh27: kteinmap
rem        28,600             kdswh01: kdstgr
rem
rem	20,000 unique scan on a compressed index to get row
rem	---------------------------------------------------
rem        20,000             kdswh02: kdsgrp		-- gets - examination (table)
rem        20,000             kdiwh06: kdifbk		-- gets - examination (leaf)	
rem        20,000             kdiwh07: kdifbk		-- gets - examination (branch)
rem
rem	20,000 RI checks against height = 1 index plus
rem	20,000 RI checks against height = 2 index
rem	---------------------------------------------------
rem        40,000             kdiwh17: kdifind		Current mode seek on leaf
rem        20,000             kdiwh22: kdifind		Current mode seek on branch
rem
rem	10,000 inserts into empty table
rem	-------------------------------
rem        10,007             kdiwh17: kdifind		Current mode seek on leaf ?
rem           580             kdiwh18: kdifind		Current mode on branch ?
rem         9,427             kdiwh22: kdifind		Current mode on branch ?
rem
rem	10,000 nested loop into single table hash cluster
rem	-------------------------------------------------
rem        10,000             kdswh04: kdscgr		(10,000 examinations)
rem
rem	Possibly associated with index coalesce
rem	---------------------------------------
rem            27             kdiwh154: kdi2merge
rem            22             kdiwh155: kdi2merge
rem            22             kdiwh156: kdi2merge
rem            20             kdiwh157: kdi2merge
rem
rem	FK index check on delete from parent (1M child rows, 2491 leafs exist)
rem	----------------------------------------------------------------------
rem             1             kdiwh24: kdiexi
rem             1             kdiwh25: kdiexi
rem         2,489             kdiwh26: kdiexi
rem
rem
rem	Relating to insert as select - due to space extension, next free block
rem	in freelist managed tablespaces
rem
rem         1,463             ktswh14: ktsnbk
rem         1,359             ktswh23: ktsfbkl
rem        13,290             ktswh28: ktsgsp		6,600 block growth
rem        13,288             ktswh72: ktsbget
rem         1,359             ktswh83: ktsfblink	5 blocks at a time
rem         1,359             ktswh85: ktsfblink
rem
rem	Relate to flashback query (10g) - there were 30 blocks in the table that
rem	had to be flashed back. There were 9,042 non-null versions_xids produced
rem	by the query (9,042 rows updated in 500 transaction on a table of 2000 rows)
rem	
rem         9,042             ktrvwh02: ktrvtgr
rem            30             ktrvwh03: ktrvtgr
rem
rem	And when I created an index on the table, and Oracle used that during 
rem	the flashback query.  (2,000 rows in the table ?)
rem         2,000             ktrvwh01: ktrvfbr
rem
rem	Buffer Busy Waits:
rem	------------------
rem	The OTHER_WAIT column sums (very nearly) to the total of v$waitstat.
rem	(see Metalink note 34405.1)
rem	For example, when waiting because of a discrete transaction, we saw
rem		"kduwh01: kdusru" incrementing at the same rate as
rem		"data block" in v$waitstat (NB not undo block).
rem

create or replace package snap_kcbsw as
	procedure start_snap;
	procedure end_snap(i_limit in number default 0);
end;
/

create or replace package body snap_kcbsw as

	cursor c1 is
		select
			indx,
			why0,
			why1,
			why2,
--			"OTHER WAIT" other_wait		-- v8
			other_wait			-- v9
		from
			x$kcbsw
		;

	type w_type1 is table of c1%rowtype index by binary_integer;
	w_list1		w_type1;
	empty_list 	w_type1;

	w_sum1	c1%rowtype;
	w_count	number(6);

	cursor c2(i_task number) is
		select 
			kcbwhdes
		from 	x$kcbwh
		where
			indx = i_task
		;

	r2	c2%rowtype;

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;

procedure start_snap is
begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list1 := empty_list;

	for r in c1 loop
		w_list1(r.indx).why0 := r.why0;
		w_list1(r.indx).why1 := r.why1;
		w_list1(r.indx).why2 := r.why2;
		w_list1(r.indx).other_wait := r.other_wait;
	end loop;

end start_snap;


procedure end_snap(i_limit in number default 0) is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('Buffer Cache - ' || 
				to_char(m_end_time,'dd-Mon hh24:mi:ss')
	);

	if m_start_flag = 'U' then
		dbms_output.put_line('Interval:-  '  || 
				trunc(86400 * (m_end_time - m_start_time)) ||
				' seconds'
		);
	else
		dbms_output.put_line('Since Startup:- ' || 
				to_char(m_start_time,'dd-Mon hh24:mi:ss')
		);
	end if;

	if (i_limit != 0) then
		dbms_output.put_line('Lower limit:-  '  || i_limit);
	end if;

	dbms_output.put_line('---------------------------------');


	dbms_output.put_line(
		lpad('Why0',14) ||
		lpad('Why1',14) ||
		lpad('Why2',14) ||
		lpad('Other Wait',14)
	);

	dbms_output.put_line(
		lpad('----',14) ||
		lpad('----',14) ||
		lpad('----',14) ||
		lpad('----------',14)
	);

	w_sum1.why0 := 0;
	w_sum1.why1 := 0;
	w_sum1.why2 := 0;
	w_sum1.other_wait := 0;
	w_count := 0;

	for r in c1 loop
		if (not w_list1.exists(r.indx)) then
			w_list1(r.indx).why0 := 0;
			w_list1(r.indx).why1 := 0;
			w_list1(r.indx).why2 := 0;
			w_list1(r.indx).other_wait := 0;
		end if;

		if (
			   r.why0 > w_list1(r.indx).why0 + i_limit
			or r.why1 > w_list1(r.indx).why1 + i_limit
			or r.why2 > w_list1(r.indx).why2 + i_limit
			or r.other_wait > w_list1(r.indx).other_wait + i_limit
		) then

			dbms_output.put(to_char( 
				r.why0 - w_list1(r.indx).why0,
					'9,999,999,990')
			);
			dbms_output.put(to_char( 
				r.why1 - w_list1(r.indx).why1,
					'9,999,999,990')
			);
			dbms_output.put(to_char( 
				r.why2 - w_list1(r.indx).why2,
					'9,999,999,990')
			);
			dbms_output.put(to_char( 
				r.other_wait - w_list1(r.indx).other_wait,
					'9,999,999,990')
			);

			open c2 (r.indx);
			fetch c2 into r2;
			close c2;
			dbms_output.put(' '|| r2.kcbwhdes);

			dbms_output.new_line;

			w_sum1.why0 := w_sum1.why0 + r.why0 - w_list1(r.indx).why0;
			w_sum1.why1 := w_sum1.why1 + r.why1 - w_list1(r.indx).why1;
			w_sum1.why2 := w_sum1.why2 + r.why2 - w_list1(r.indx).why2;
			w_sum1.other_wait := w_sum1.other_wait + r.other_wait - w_list1(r.indx).other_wait;
			w_count := w_count + 1;

		end if;

	end loop;

	dbms_output.put_line(
		lpad('----',14) ||
		lpad('----',14) ||
		lpad('----',14) ||
		lpad('----------',14)
	);

	dbms_output.put(to_char(w_sum1.why0,'9,999,999,990'));
	dbms_output.put(to_char(w_sum1.why1,'9,999,999,990'));
	dbms_output.put(to_char(w_sum1.why2,'9,999,999,990'));
	dbms_output.put(to_char(w_sum1.other_wait,'9,999,999,990'));
	dbms_output.put(' Total: ' || w_count || ' rows');
	dbms_output.new_line;

end end_snap;

begin
	select
		startup_time, 'S'
	into
		m_start_time, m_start_flag
	from
		v$instance
	;

end snap_kcbsw;
/


drop public synonym snap_kcbsw;
create public synonym snap_kcbsw for snap_kcbsw;
grant execute on snap_kcbsw to public;


set doc off
doc

First ever example of WHY1 being non-zero, from 10.2.0.3

          Why0          Why1          Why2    Other Wait
          ----          ----          ----    ----------
             0            12             0             0 kdiwh122: kdisfind
             0            12             0             0 kdiwh123: kdisfind
             0            27             0             0 kdiwh126: kdisparent



#
