rem
rem	Script:		core_demo_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Feb 2011
rem	Purpose:	
rem
rem	Last tested 
rem		10.2.0.3
rem		 9.2.0.8
rem	Not tested
rem		11.2.0.2
rem		11.1.0.7
rem	Not considered
rem		 8.1.7.4
rem
rem	Depends on
rem		c_dump_seg.sql
rem		c_dump_undo_block.sql
rem		c_dump_log.sql
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
rem	Notes:
rem	Construct example to dump consistent undo / redo
rem	for a single row change that does not involve any
rem	index maintenance.
rem
rem	Uses 1MB uniform extents, 8KB blocks, 
rem	locally managed tablespace
rem	freelist management.
rem
rem	We need to update three rows in a single block, and
rem	we should not visit those three rows in order, as 
rem	we want to pick the third update and show the undo
rem	pointers in various ways:
rem
rem	a) undo record pointing to previous undo record for
rem	   rollback which we want to be for a different block
rem	b) undo record holding the contents of the previous 
rem	   version of the ITL record for this transaction
rem
rem	This code produces 60 rows per block, and updates
rem	five rows going from block 1 to 2 to 1 to 2 to 1
rem

start setenv
set timing off

execute dbms_random.seed(0)

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin
		dbms_stats.set_system_stats('MBRC',8);
		dbms_stats.set_system_stats('MREADTIM',26);
		dbms_stats.set_system_stats('SREADTIM',12);
		dbms_stats.set_system_stats('CPUSPEED',800);
	exception
		when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;
end;
/


create table t1
as
select
	2 * rownum - 1			id,
	rownum				n1,
	cast('xxxxxx' as varchar2(10))	v1,
	rpad('0',100,'0')		padding
from
	all_objects
where
	rownum <= 60
union all
select
	2 * rownum			id,
	rownum				n1,
	cast('xxxxxx' as varchar2(10))	v1,
	rpad('0',100,'0')		padding
from
	all_objects
where
	rownum <= 60
;

create index t1_i1 on t1(id);

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		method_opt 	 => 'for all columns size 1'
	);
end;
/


select 
	dbms_rowid.rowid_block_number(rowid)	block_number, 
	count(*)				rows_per_block
from 
	t1 
group by 
	dbms_rowid.rowid_block_number(rowid)
order by
	block_number
;


alter system switch logfile;
execute dbms_lock.sleep(2)

spool core_demo_02.lst

execute dump_seg('t1')

update
	/*+ index(t1 t1_i1) */
	t1
set
	v1 = 'YYYYYYYYYY'
where
	id between 5 and 9
;

pause Query the IMU structures now  (@core_imu_01.sql)

execute dump_seg('t1')
execute dump_undo_block

rollback;
commit;

execute dump_log

spool off



set doc off
doc


Table block before update - row [4]
-----------------------------------

scn: 0x0000.03ee4843 seq: 0x02 flg: 0x04 tail: 0x48430602
frmt: 0x02 chkval: 0x6b62 type: 0x06=trans data
Block header dump:  0x02c0018a
 Object id on Block? Y
 seg/obj: 0xb2f2  csc: 0x00.3ee4842  itc: 3  flg: -  typ: 1 - DATA
     fsl: 0  fnx: 0x0 ver: 0x01
 
 Itl           Xid                  Uba         Flag  Lck        Scn/Fsc
0x01   0xffff.000.00000000  0x00000000.0000.00  C---    0  scn 0x0000.03ee4842
0x02   0x0000.000.00000000  0x00000000.0000.00  ----    0  fsc 0x0000.00000000
0x03   0x0000.000.00000000  0x00000000.0000.00  ----    0  fsc 0x0000.00000000
 
data_block_dump,data header at 0x3397074
===============
tsiz: 0x1f88
hsiz: 0x8a
pbl: 0x03397074
bdba: 0x02c0018a
     76543210
flag=--------
ntab=1
nrow=60
frre=-1
fsbo=0x8a
fseo=0x412
avsp=0x388
tosp=0x388
0xe:pti[0]	nrow=60	offs=0
0x12:pri[0]	offs=0x1f13
0x14:pri[1]	offs=0x1e9e
0x16:pri[2]	offs=0x1e29
0x18:pri[3]	offs=0x1db4
0x1a:pri[4]	offs=0x1d3f

tab 0, row 4, @0x1d3f
tl: 117 fb: --H-FL-- lb: 0x0  cc: 4
col  0: [ 2]  c1 0a
col  1: [ 2]  c1 06
col  2: [ 6]  78 78 78 78 78 78
col  3: [100]
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30


Table block after update - row 4
--------------------------------
scn: 0x0000.03ee485a seq: 0x03 flg: 0x00 tail: 0x485a0603
frmt: 0x02 chkval: 0x0000 type: 0x06=trans data
Block header dump:  0x02c0018a
 Object id on Block? Y
 seg/obj: 0xb2f2  csc: 0x00.3ee4842  itc: 3  flg: -  typ: 1 - DATA
     fsl: 0  fnx: 0x0 ver: 0x01
 
 Itl           Xid                  Uba         Flag  Lck        Scn/Fsc
0x01   0xffff.000.00000000  0x00000000.0000.00  C---    0  scn 0x0000.03ee4842
0x02   0x000a.01a.0000255b  0x0080009a.09d4.0f  ----    3  fsc 0x0000.00000000
0x03   0x0000.000.00000000  0x00000000.0000.00  ----    0  fsc 0x0000.00000000
 
data_block_dump,data header at 0x3397074
===============
tsiz: 0x1f88
hsiz: 0x8a
pbl: 0x03397074
bdba: 0x02c0018a
     76543210
flag=--------
ntab=1
nrow=60
frre=-1
fsbo=0x8a
fseo=0x2a7
avsp=0x37c
tosp=0x37c
0xe:pti[0]	nrow=60	offs=0
0x12:pri[0]	offs=0x1f13
0x14:pri[1]	offs=0x1e9e
0x16:pri[2]	offs=0x399
0x18:pri[3]	offs=0x320
0x1a:pri[4]	offs=0x2a7


tab 0, row 4, @0x2a7
tl: 121 fb: --H-FL-- lb: 0x2  cc: 4
col  0: [ 2]  c1 0a
col  1: [ 2]  c1 06
col  2: [10]  59 59 59 59 59 59 59 59 59 59
col  3: [100]
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30


Undo header:
------------
------------
scn: 0x0000.03ee485a seq: 0x01 flg: 0x00 tail: 0x485a2601
frmt: 0x02 chkval: 0x0000 type: 0x26=KTU SMU HEADER BLOCK
  Extent Control Header
  -----------------------------------------------------------------
  Extent Header:: spare1: 0      spare2: 0      #extents: 5      #blocks: 39    
                  last map  0x00000000  #maps: 0      offset: 4080  
      Highwater::  0x0080009a  ext#: 0      blk#: 0      ext size: 7     
  #blocks in seg. hdr's freelists: 0     
  #blocks below: 0     
  mapblk  0x00000000  offset: 0     
                   Unlocked
     Map Header:: next  0x00000000  #extents: 5    obj#: 0      flag: 0x40000000
  Extent Map
  -----------------------------------------------------------------
   0x0080009a  length: 7     
   0x00800081  length: 8     
   0x008000c1  length: 8     
   0x008000f1  length: 8     
   0x008000e1  length: 8     
  
 Retention Table 
  -----------------------------------------------------------
 Extent Number:0  Commit Time: 1300038179
 Extent Number:1  Commit Time: 1299512180
 Extent Number:2  Commit Time: 1299512190
 Extent Number:3  Commit Time: 1299951292
 Extent Number:4  Commit Time: 1300038179
  
  TRN CTL:: seq: 0x09d4 chd: 0x0025 ctl: 0x0017 inc: 0x00000000 nfb: 0x0000
            mgc: 0x8201 xts: 0x0068 flg: 0x0001 opt: 2147483646 (0x7ffffffe)
            uba: 0x0080009a.09d4.0b scn: 0x0000.03ee398c
Version: 0x01
  FREE BLOCK POOL::
    uba: 0x00000000.09d4.0a ext: 0x0  spc: 0x1c02  
    uba: 0x00000000.09d2.03 ext: 0x3  spc: 0x1ea4  
    uba: 0x00000000.09cb.07 ext: 0x0  spc: 0x1dbc  
    uba: 0x00000000.0945.01 ext: 0x2  spc: 0x1fa0  
    uba: 0x00000000.0945.01 ext: 0x2  spc: 0x1fa0  
  TRN TBL::
 
  index  state cflags  wrap#    uel         scn            dba            parent-xid    nub     stmt_num
  ------------------------------------------------------------------------------------------------
   0x00    9    0x00  0x255a  0x0007  0x0000.03ee3fc0  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x01    9    0x00  0x256a  0x001e  0x0000.03ee4826  0x008000e8  0x0000.000.00000000  0x00000001   0x00000000
   0x02    9    0x00  0x2575  0x0021  0x0000.03ee3aad  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x03    9    0x00  0x2560  0x0017  0x0000.03ee4846  0x0080009a  0x0000.000.00000000  0x00000001   0x00000000
   0x04    9    0x00  0x2565  0x0024  0x0000.03ee464d  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x05    9    0x00  0x2569  0x0002  0x0000.03ee39c0  0x008000f5  0x0000.000.00000000  0x00000001   0x00000000
   0x06    9    0x00  0x256f  0x0026  0x0000.03ee39aa  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x07    9    0x00  0x2559  0x0009  0x0000.03ee3fd5  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x08    9    0x00  0x256d  0x0013  0x0000.03ee404f  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x09    9    0x00  0x1d15  0x0014  0x0000.03ee3fe7  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x0a    9    0x00  0x256b  0x0000  0x0000.03ee3c79  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x0b    9    0x00  0x2563  0x000f  0x0000.03ee4418  0x00000000  0x0000.000.00000000  0x00000000   0x00000000
   0x0c    9    0x00  0x2576  0x0027  0x0000.03ee399b  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x0d    9    0x00  0x256e  0x0012  0x0000.03ee39a1  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x0e    9    0x00  0x2566  0x002f  0x0000.03ee39bd  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x0f    9    0x00  0x2568  0x0016  0x0000.03ee45ca  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x10    9    0x00  0x2571  0x0006  0x0000.03ee39a7  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x11    9    0x00  0x2570  0x0019  0x0000.03ee3ad9  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x12    9    0x00  0x256e  0x0010  0x0000.03ee39a4  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x13    9    0x00  0x256a  0x000b  0x0000.03ee434b  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x14    9    0x00  0x2571  0x0008  0x0000.03ee3ffa  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x15    9    0x00  0x255d  0x002e  0x0000.03ee3ac4  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x16    9    0x00  0x256e  0x0004  0x0000.03ee460f  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x17    9    0x00  0x255f  0xffff  0x0000.03ee4848  0x008000e8  0x0000.000.00000000  0x00000001   0x00000000
   0x18    9    0x00  0x2567  0x0020  0x0000.03ee4720  0x008000e8  0x0000.000.00000000  0x00000001   0x00000000
   0x19    9    0x00  0x2546  0x000a  0x0000.03ee3c71  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
** 0x1a   10    0x80  0x255b  0x0000  0x0000.03ee485a  0x0080009a  0x0000.000.00000000  0x00000001   0x00000000
   0x1b    9    0x00  0x256f  0x002a  0x0000.03ee39b6  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x1c    9    0x00  0x2571  0x0022  0x0000.03ee39b0  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x1d    9    0x00  0x2576  0x0011  0x0000.03ee3ad2  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x1e    9    0x00  0x255a  0x002b  0x0000.03ee4842  0x0080009a  0x0000.000.00000000  0x00000001   0x00000000
   0x1f    9    0x00  0x2572  0x000c  0x0000.03ee3998  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x20    9    0x00  0x256d  0x0001  0x0000.03ee4746  0x008000e8  0x0000.000.00000000  0x00000001   0x00000000
   0x21    9    0x00  0x2486  0x0029  0x0000.03ee3ab5  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x22    9    0x00  0x2569  0x001b  0x0000.03ee39b3  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x23    9    0x00  0x256a  0x000e  0x0000.03ee39bc  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x24    9    0x00  0x2575  0x0018  0x0000.03ee4716  0x008000e8  0x0000.000.00000000  0x00000002   0x00000000
   0x25    9    0x00  0x2561  0x0028  0x0000.03ee398f  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x26    9    0x00  0x2566  0x001c  0x0000.03ee39ad  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x27    9    0x00  0x2558  0x000d  0x0000.03ee399e  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x28    9    0x00  0x2571  0x002c  0x0000.03ee3992  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x29    9    0x00  0x256e  0x0015  0x0000.03ee3abc  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x2a    9    0x00  0x2568  0x0023  0x0000.03ee39b9  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x2b    9    0x00  0x256f  0x002d  0x0000.03ee4844  0x0080009a  0x0000.000.00000000  0x00000001   0x00000000
   0x2c    9    0x00  0x256f  0x001f  0x0000.03ee3995  0x008000e6  0x0000.000.00000000  0x00000001   0x00000000
   0x2d    9    0x00  0x254a  0x0003  0x0000.03ee4845  0x0080009a  0x0000.000.00000000  0x00000001   0x00000000
   0x2e    9    0x00  0x2567  0x001d  0x0000.03ee3acc  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000
   0x2f    9    0x00  0x2553  0x0005  0x0000.03ee39be  0x008000e7  0x0000.000.00000000  0x00000001   0x00000000


Undo block:
-----------
-----------
scn: 0x0000.03ee485a seq: 0x05 flg: 0x00 tail: 0x485a0205
frmt: 0x02 chkval: 0x0000 type: 0x02=KTU UNDO BLOCK
 
********************************************************************************
UNDO BLK:  
xid: 0x000a.01a.0000255b  seq: 0x9d4 cnt: 0xf   irb: 0xf   icl: 0x0   flg: 0x0000
 
 Rec Offset      Rec Offset      Rec Offset      Rec Offset      Rec Offset
---------------------------------------------------------------------------
0x01 0x1f9c     0x02 0x1f4c     0x03 0x1ebc     0x04 0x1e88     0x05 0x1e2c     
0x06 0x1db8     0x07 0x1d40     0x08 0x1cec     0x09 0x1c84     0x0a 0x1c28     
0x0b 0x1bbc     0x0c 0x1b68     0x0d 0x1b0c     0x0e 0x1ab0     0x0f 0x1a54     


*-----------------------------
* Rec #0xb  slt: 0x1a  objn: 45810(0x0000b2f2)  objd: 45810  tblspc: 12(0x0000000c)
*       Layer:  11 (Row)   opc: 1   rci 0x00   
Undo type:  Regular undo    Begin trans    Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
rdba: 0x00000000
*-----------------------------
uba: 0x0080009a.09d4.09 ctl max scn: 0x0000.03ee3989 prv tx scn: 0x0000.03ee398c
KDO undo record:
KTB Redo 
op: 0x03  ver: 0x01  
op: Z
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
 
*-----------------------------
* Rec #0xc  slt: 0x1a  objn: 45810(0x0000b2f2)  objd: 45810  tblspc: 12(0x0000000c)
*       Layer:  11 (Row)   opc: 1   rci 0x0b   
Undo type:  Regular undo   Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
rdba: 0x00000000
*-----------------------------
KDO undo record:
KTB Redo 
op: 0x03  ver: 0x01  
op: Z
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
 
*-----------------------------
* Rec #0xd  slt: 0x1a  objn: 45810(0x0000b2f2)  objd: 45810  tblspc: 12(0x0000000c)
*       Layer:  11 (Row)   opc: 1   rci 0x0c   
Undo type:  Regular undo   Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
rdba: 0x00000000
*-----------------------------
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0b
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
 
*-----------------------------
* Rec #0xe  slt: 0x1a  objn: 45810(0x0000b2f2)  objd: 45810  tblspc: 12(0x0000000c)
*       Layer:  11 (Row)   opc: 1   rci 0x0d   
Undo type:  Regular undo   Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
rdba: 0x00000000
*-----------------------------
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0c
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78


*********************
This one
********************* 
 
*-----------------------------
* Rec #0xf  slt: 0x1a  objn: 45810(0x0000b2f2)  objd: 45810  tblspc: 12(0x0000000c)
*       Layer:  11 (Row)   opc: 1   rci 0x0e   
Undo type:  Regular undo   Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
rdba: 0x00000000
*-----------------------------
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0d
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 4(0x4) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78





Redo Record / Changes
*********************

REDO RECORD - Thread:1 RBA: 0x00036f.00000003.0010 LEN: 0x0174 VLD: 0x01
SCN: 0x0000.03ee485a SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:35 AFN:2 DBA:0x00800099 SCN:0x0000.03ee4848 SEQ:  1 OP:5.2
ktudh redo: slt: 0x001a sqn: 0x0000255b flg: 0x0012 siz: 108 fbi: 0
            uba: 0x0080009a.09d4.0b    pxid:  0x0000.000.00000000
CHANGE #2 TYP:0 CLS:36 AFN:2 DBA:0x0080009a SCN:0x0000.03ee4845 SEQ:  2 OP:5.1
ktudb redo: siz: 108 spc: 7170 flg: 0x0012 seq: 0x09d4 rec: 0x0b
            xid:  0x000a.01a.0000255b  
ktubl redo: slt: 26 rci: 0 opc: 11.1 objn: 45810 objd: 45810 tsn: 12
Undo type:  Regular undo        Begin trans    Last buffer split:  No 
Temp Object:  No 
Tablespace Undo:  No 
             0x00000000  prev ctl uba: 0x0080009a.09d4.09 
prev ctl max cmt scn:  0x0000.03ee3989  prev tx cmt scn:  0x0000.03ee398c 
KDO undo record:
KTB Redo 
op: 0x03  ver: 0x01  
op: Z
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
CHANGE #3 TYP:0 CLS: 1 AFN:11 DBA:0x02c0018a SCN:0x0000.03ee4843 SEQ:  2 OP:11.5
KTB Redo 
op: 0x01  ver: 0x01  
op: F  xid:  0x000a.01a.0000255b    uba: 0x0080009a.09d4.0b
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 2 ckix: 16
ncol: 4 nnew: 1 size: 4
col  2: [10]  59 59 59 59 59 59 59 59 59 59
CHANGE #4 MEDIA RECOVERY MARKER SCN:0x0000.00000000 SEQ:  0 OP:5.20
session number   = 9
serial  number   = 9
transaction name = 


REDO RECORD - Thread:1 RBA: 0x00036f.00000003.0184 LEN: 0x00f8 VLD: 0x01
SCN: 0x0000.03ee485a SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:36 AFN:2 DBA:0x0080009a SCN:0x0000.03ee485a SEQ:  1 OP:5.1
ktudb redo: siz: 84 spc: 7060 flg: 0x0022 seq: 0x09d4 rec: 0x0c
            xid:  0x000a.01a.0000255b  
ktubu redo: slt: 26 rci: 11 opc: 11.1 objn: 45810 objd: 45810 tsn: 12
Undo type:  Regular undo       Undo type:  Last buffer split:  No 
Tablespace Undo:  No 
             0x00000000
KDO undo record:
KTB Redo 
op: 0x03  ver: 0x01  
op: Z
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
CHANGE #2 TYP:0 CLS: 1 AFN:11 DBA:0x02c0018b SCN:0x0000.03ee4843 SEQ:  2 OP:11.5
KTB Redo 
op: 0x01  ver: 0x01  
op: F  xid:  0x000a.01a.0000255b    uba: 0x0080009a.09d4.0c
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 2(0x2) flag: 0x2c lock: 2 ckix: 16
ncol: 4 nnew: 1 size: 4
col  2: [10]  59 59 59 59 59 59 59 59 59 59
 
REDO RECORD - Thread:1 RBA: 0x00036f.00000004.008c LEN: 0x00f8 VLD: 0x01
SCN: 0x0000.03ee485a SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:36 AFN:2 DBA:0x0080009a SCN:0x0000.03ee485a SEQ:  2 OP:5.1
ktudb redo: siz: 92 spc: 6974 flg: 0x0022 seq: 0x09d4 rec: 0x0d
            xid:  0x000a.01a.0000255b  
ktubu redo: slt: 26 rci: 12 opc: 11.1 objn: 45810 objd: 45810 tsn: 12
Undo type:  Regular undo       Undo type:  Last buffer split:  No 
Tablespace Undo:  No 
             0x00000000
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0b
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
CHANGE #2 TYP:0 CLS: 1 AFN:11 DBA:0x02c0018a SCN:0x0000.03ee485a SEQ:  1 OP:11.5
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0d
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 2 ckix: 16
ncol: 4 nnew: 1 size: 4
col  2: [10]  59 59 59 59 59 59 59 59 59 59
 
REDO RECORD - Thread:1 RBA: 0x00036f.00000004.0184 LEN: 0x00f8 VLD: 0x01
SCN: 0x0000.03ee485a SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:36 AFN:2 DBA:0x0080009a SCN:0x0000.03ee485a SEQ:  3 OP:5.1
ktudb redo: siz: 92 spc: 6880 flg: 0x0022 seq: 0x09d4 rec: 0x0e
            xid:  0x000a.01a.0000255b  
ktubu redo: slt: 26 rci: 13 opc: 11.1 objn: 45810 objd: 45810 tsn: 12
Undo type:  Regular undo       Undo type:  Last buffer split:  No 
Tablespace Undo:  No 
             0x00000000
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0c
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78
CHANGE #2 TYP:0 CLS: 1 AFN:11 DBA:0x02c0018b SCN:0x0000.03ee485a SEQ:  1 OP:11.5
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0e
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018b  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 3(0x3) flag: 0x2c lock: 2 ckix: 16
ncol: 4 nnew: 1 size: 4
col  2: [10]  59 59 59 59 59 59 59 59 59 59
 
*********************
This one
*********************
 
REDO RECORD - Thread:1 RBA: 0x00036f.00000005.008c LEN: 0x00f8 VLD: 0x01
SCN: 0x0000.03ee485a SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:36 AFN:2 DBA:0x0080009a SCN:0x0000.03ee485a SEQ:  4 OP:5.1
ktudb redo: siz: 92 spc: 6786 flg: 0x0022 seq: 0x09d4 rec: 0x0f
            xid:  0x000a.01a.0000255b  
ktubu redo: slt: 26 rci: 14 opc: 11.1 objn: 45810 objd: 45810 tsn: 12
Undo type:  Regular undo       Undo type:  Last buffer split:  No 
Tablespace Undo:  No 
             0x00000000
KDO undo record:
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0d
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 4(0x4) flag: 0x2c lock: 0 ckix: 16
ncol: 4 nnew: 1 size: -4
col  2: [ 6]  78 78 78 78 78 78

CHANGE #2 TYP:0 CLS: 1 AFN:11 DBA:0x02c0018a SCN:0x0000.03ee485a SEQ:  2 OP:11.5
KTB Redo 
op: 0x02  ver: 0x01  
op: C  uba: 0x0080009a.09d4.0f
KDO Op code: URP row dependencies Disabled
  xtype: XA  bdba: 0x02c0018a  hdba: 0x02c00189
itli: 2  ispac: 0  maxfr: 4863
tabn: 0 slot: 4(0x4) flag: 0x2c lock: 2 ckix: 16
ncol: 4 nnew: 1 size: 4
col  2: [10]  59 59 59 59 59 59 59 59 59 59


*********************
COMMIT
*********************
 
REDO RECORD - Thread:1 RBA: 0x00036f.00000005.0184 LEN: 0x0054 VLD: 0x01
SCN: 0x0000.03ee485b SUBSCN:  1 03/13/2011 17:43:01
CHANGE #1 TYP:0 CLS:35 AFN:2 DBA:0x00800099 SCN:0x0000.03ee485a SEQ:  1 OP:5.4
ktucm redo: slt: 0x001a sqn: 0x0000255b srt: 0 sta: 9 flg: 0x2 
ktucf redo: uba: 0x0080009a.09d4.0f ext: 0 spc: 6692 fbi: 0 

#

