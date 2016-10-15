rem
rem	Script:		setenv.sql
rem	Author:		Jonathan Lewis
rem	Dated:		June 2002
rem	Purpose:	Set up various SQL*Plus formatting commands.
rem
rem	Notes:
rem

set pause off

rem
rem	If you want to call dbms_xplan.display_cursor() to get the
rem	place for the last statement you executed you will have to
rem	set serveroutput off
rem

set serveroutput on size 1000000 format wrapped

rem
rem	I'd like to enable java output, but it seems 
rem	to push the UGA up by about 4MB when I do it
rem

rem	execute dbms_java.set_output(1000000)

rem
rem	Reminder about DOC, and using the # to end DOC
rem	the SET command stops doc material from appearing
rem

execute dbms_random.seed(0)

set doc off
doc

end doc is marked with #

#

set linesize 120
set trimspool on
set pagesize 24
set arraysize 25

-- set longchunksize 32768
-- set long 32768

set autotrace off

clear breaks
ttitle off
btitle off

column owner format a15
column segment_name format a20
column table_name format a20
column index_name format a20
column object_name format a20
column subobject_name format a20
column partition_name format a20
column subpartition_name format a20
column column_name format a20
column column_expression format a40 word wrap
column constraint_name format a20

column referenced_name format a30

column file_name format a60

column low_value format a24
column high_value format a24

column parent_id_plus_exp	format 999
column id_plus_exp		format 990
column plan_plus_exp 		format a90
column object_node_plus_exp	format a14
column other_plus_exp		format a90
column other_tag_plus_exp	format a29

column access_predicates	format a80
column filter_predicates	format a80
column projection		format a80
column remarks			format a80
column partition_start		format a12
column partition_stop		format a12
column partition_id		format 999
column other_tag		format a32
column object_alias		format a24

column object_node		format a13
column	other			format a150

column os_username		format a30
column terminal			format a24
column userhost			format a24
column client_id		format a24

column statistic_name format a35

column namespace format a20
column attribute format a20

column hint format a40

column start_time	format a25
column end_time		format a25

column time_now noprint new_value m_timestamp

set feedback off

select to_char(sysdate,'hh24miss') time_now from dual;
commit;

set feedback on

set timing off
set verify off

alter session set optimizer_mode = all_rows;

spool log

