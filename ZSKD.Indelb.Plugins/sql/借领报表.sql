
----��ȡδ�黹����Ϣ
--select FBILLNO as ���충����,t6.FNAME as FSalName,FQTY,F_ZSKD_ALREADYOUTQTY ,F_ZSKD_DELAYTME,F_ZSKD_RETURNDATE,t6.FPHONE
--from T_STK_STKTRANSFERIN t1 
--join T_STK_STKTRANSFERINENTRY t2 on t1.FID=t2.FID
--join T_BD_OPERATORENTRY t3 on t3.FOPERATORTYPE='XSY' and t3.FENTRYID=t1.FSALERID
--join T_BD_STAFF t4 on t3.FSTAFFID = t4.FSTAFFID 
--join t_BD_Person t5 on t5.FPERSONID = t4.FPERSONID
--join T_SEC_USER t6 on  t6.FLINKOBJECT = t5.FPERSONID
--join T_BAS_BILLTYPE t7 on t7.FBILLTYPEID=t1.FBILLTYPEID  
--where FSALERID!=0   and FQTY!=F_ZSKD_ALREADYOUTQTY and t7.FNUMBER='ZJDBD_JCDB' 
--and (case when isnull(F_ZSKD_DELAYTME,'')!=''   or F_ZSKD_DELAYTME >F_ZSKD_RETURNDATE then F_ZSKD_DELAYTME else F_ZSKD_RETURNDATE end<GetDate())

--616896
--select * from T_BD_OPERATORENTRY
--6063d3c62aaa23
--select * from T_BAS_BILLTYPE where  FNUMBER='ZJDBD_JCDB' 
----D:\Program Files (x86)\Kingdee\K3Cloud\WebSite\bin\
----C:\Users\an\Source\Repos\ZSKD.Indelb\ZSKD.Indelb.Plugins\bin\debug\
----select * from T_SEC_USER_L where FNAME like '%��%'
--update T_SEC_USER set FPHONE='182008095831' where  FUSERID=  349464
--select top(1) FAGENTID as FAGENTID,FAPPKEY as FAPPKEY,FAPPSECRET as FAPPSECRET from T_MOB_DDAppInfo where FAPPNAME='������Ϣ'

 
declare @FMatCode varchar(100) =ltrim('') 
--���챨�����ȡ������֡��Ŀ�棬���ֽ������ڡ����첿�š������ˡ������ˡ���;��Ԥ�ƹ黹���ڡ�����ʱ���
select 
FBILLNO as ���충����,t8.FNUMBER as ���ϱ���,t1.FDATE ��������,t12.FNAME as  ���첿��,t6.FNAME as ������,t11.FNAME as ������,t1.FNOTE as ��;,F_ZSKD_RETURNDATE as �����黹���� 
,F_ZSKD_DELAYTME as �ӳ�����,t9.FQTY as ����ֵĿ��
from T_STK_STKTRANSFERIN t1 
join T_STK_STKTRANSFERINENTRY t2 on t1.FID=t2.FID
join T_BD_OPERATORENTRY t3 on t3.FOPERATORTYPE='XSY' and t3.FENTRYID=t1.FSALERID
join T_BD_STAFF t4 on t3.FSTAFFID = t4.FSTAFFID
join t_BD_Person t5 on t5.FPERSONID = t4.FPERSONID
join T_SEC_USER t6 on  t6.FLINKOBJECT = t5.FPERSONID
join T_BAS_BILLTYPE t7 on t7.FBILLTYPEID=t1.FBILLTYPEID
join T_BD_MATERIAL t8 on t8.FMATERIALID=t2.FMATERIALID
left join T_STK_INVENTORY t9 on t9.FMATERIALID=t2.FMATERIALID 
left join T_BD_STOCK_L t10 on t10.FSTOCKID=t9.FSTOCKID and t10.FLOCALEID=2052 and t10.FNAME='�����'
join T_SEC_USER t11 on t11.FUSERID=t1.FAPPROVERID --FAPPROVERID
join T_BD_DEPARTMENT_L t12 on t12.FDEPTID= t1.FSALEDEPTID and t12.FLOCALEID=2052 
where t1.FSALERID!=0   and t2.FQTY!=t2.F_ZSKD_ALREADYOUTQTY and t7.FNUMBER='ZJDBD_JCDB' 
and (case when isnull(F_ZSKD_DELAYTME,'')!=''   or F_ZSKD_DELAYTME >F_ZSKD_RETURNDATE then F_ZSKD_DELAYTME else F_ZSKD_RETURNDATE end<GetDate())
 and t8.FNUMBER=CASE WHEN @FMatCode <> '' THEN @FMatCode ELSE t8.FNUMBER end  


 --�Ʒ�����sql

 declare @create_ varchar(10) = 'create'
declare @alter_ varchar(10) = 'alter'
declare @drop_ varchar(10) = 'drop'
declare @insert_ varchar(10) = 'insert'
declare @delete_ varchar(10) = 'delete'
declare @update_ varchar(10) = 'update'
declare @MASTERdot varchar(10) = 'master'+'.'
declare @SYSdot varchar(10) = 'sys'+'.'
exec('declare @FMatCode varchar(100) =ltrim(''#FMaterialId#'')  
select 
FBILLNO as ���충����,t8.FNUMBER as ���ϱ���,t1.FDATE ��������,t12.FNAME as  ���첿��,t6.FNAME as ������,t11.FNAME as ������,t1.FNOTE as ��;,F_ZSKD_RETURNDATE as �����黹���� 
,F_ZSKD_DELAYTME as �ӳ�����,t9.FQTY as ����ֵĿ��
from T_STK_STKTRANSFERIN t1 
join T_STK_STKTRANSFERINENTRY t2 on t1.FID=t2.FID
join T_BD_OPERATORENTRY t3 on t3.FOPERATORTYPE=''XSY'' and t3.FENTRYID=t1.FSALERID
join T_BD_STAFF t4 on t3.FSTAFFID = t4.FSTAFFID
join t_BD_Person t5 on t5.FPERSONID = t4.FPERSONID
join T_SEC_U'+'SER t6 on  t6.FLINKOBJECT = t5.FPERSONID
join T_BAS_BILLTYPE t7 on t7.FBILLTYPEID=t1.FBILLTYPEID
join T_BD_MATERIAL t8 on t8.FMATERIALID=t2.FMATERIALID
left join T_STK_INVENTORY t9 on t9.FMATERIALID=t2.FMATERIALID 
left join T_BD_STOCK_L t10 on t10.FSTOCKID=t9.FSTOCKID and t10.FLOCALEID=2052 and t10.FNAME=''�����''
join T_SEC_U'+'SER t11 on t11.FUSERID=t1.FAPPROVERID --FAPPROVERID
join T_BD_DEPARTMENT_L t12 on t12.FDEPTID= t1.FSALEDEPTID and t12.FLOCALEID=2052 
where t1.FSALERID!=0   and t2.FQTY!=t2.F_ZSKD_ALREADYOUTQTY and t7.FNUMBER=''ZJDBD_JCDB'' 
and (case when isnull(F_ZSKD_DELAYTME,'''')!=''''   or F_ZSKD_DELAYTME >F_ZSKD_RETURNDATE then F_ZSKD_DELAYTME else F_ZSKD_RETURNDATE end<GetDate())
 and t8.FNUMBER=CASE WHEN @FMatCode <> '''' THEN @FMatCode ELSE t8.FNUMBER end ')
