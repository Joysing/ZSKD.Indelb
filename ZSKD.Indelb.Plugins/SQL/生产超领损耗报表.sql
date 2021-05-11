declare @OverScrap varchar(2)='#OverScrap#' --������Ĵ���0[��,��]  #OverScrap#
declare @Date datetime='#FDate#' --�·� #FDate#
declare @FirstDay datetime=DATEADD(mm,DATEDIFF(mm,0,@Date),0) --�µ�һ��
declare @LastDay datetime=DATEADD(mm,1,@FirstDay) --���µ�һ��

--�Ӳɹ�������ȡ����
select * into #PriceTable from(
select 
ROW_NUMBER() over(partition by t2.FMATERIALID order by t1.FDATE desc,t2.FENTRYID desc) mat_no
,t1.FDATE,t2.FMATERIALID,t3.FTAXPRICE 
from T_PUR_POORDER t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A' and t1.FDATE<@LastDay 
join T_PUR_POORDERENTRY_F t3 on t2.FENTRYID=t3.FENTRYID) t where mat_no=1

------------------------------------------------����
--����������ϵ��ı�ע���������������飩
select a.FMATERIALID
,(select c.FDESCRIPTION+';' from T_PRD_FEEDMTRLDATA b
left join T_PRD_FEEDMTRLDATA_L c on b.FENTRYID=c.FENTRYID and c.FLOCALEID=2052
join T_PRD_FEEDMTRL d on d.FID=b.FID
where b.FMATERIALID=a.FMATERIALID and len(c.FDESCRIPTION)>0
and d.FDATE>=@FirstDay and d.FDATE<@LastDay 
FOR XML PATH('')) as ��ע 
into #SCNoteTable
from T_PRD_FEEDMTRLDATA a

select t4.FBILLNO+t5.FNUMBER as '�������������ϴ���'
,t4.FBILLNO as '����/ί�ⶩ����'
,t5.FNUMBER as '���ϴ���'
,t6.FNAME as '��������'
,t6.FSPECIFICATION as '����ͺ�'
,t7.FNAME as '��λ'
,t2.FMustQty as '��������'
,t8.FPICKEDQTY+t8.FREPICKEDQTY as 'ʵ������'
,t8.FREPICKEDQTY as '��������'
,t2.FSCRAPRATE as '��׼���%'
,case when (t8.FPICKEDQTY+t8.FREPICKEDQTY)<>0 then t8.FREPICKEDQTY/(t8.FPICKEDQTY+t8.FREPICKEDQTY)*100 else 0 end as 'ʵ�����%'
,(case when (t8.FPICKEDQTY+t8.FREPICKEDQTY)<>0 then t8.FREPICKEDQTY/(t8.FPICKEDQTY+t8.FREPICKEDQTY)*100 else 0 end)-t2.FSCRAPRATE as '�������%'
,t10.FTAXPRICE as '����'
,t10.FTAXPRICE*t8.FREPICKEDQTY as '���Ͻ��'
,(t8.FREPICKEDQTY-t2.FSCRAPRATE*(t8.FPICKEDQTY+t8.FREPICKEDQTY))*t10.FTAXPRICE as '������'
,t9.FSPECIFICATION as '��Ʒ�ͺ�'
,t11.��ע
into #SCDD
from T_PRD_PPBOM t1
join T_PRD_PPBOMENTRY t2 on t1.FID=t2.FID and t1.FDOCUMENTSTATUS='C'
join T_PRD_MOENTRY t3 on t3.FENTRYID=t2.FMOENTRYID and t3.FID=t2.FMOID
join T_PRD_MO t4 on t3.FID=t4.FID
join T_BD_MATERIAL t5 on t5.FMATERIALID=t2.FMATERIALID
join T_BD_MATERIAL_L t6 on t6.FMATERIALID=t2.FMATERIALID and t6.FLOCALEID=2052
join T_BD_UNIT_L t7 on t7.FUnitID=t2.FUnitID and t7.FLOCALEID=2052
join T_PRD_PPBOMENTRY_Q t8 on t8.FENTRYID=t2.FENTRYID
join T_BD_MATERIAL_L t9 on t9.FMATERIALID=t3.FMATERIALID and t9.FLOCALEID=2052
left join #PriceTable t10 on t10.FMATERIALID=t2.FMATERIALID
left join #SCNoteTable t11 on t11.FMATERIALID=t2.FMATERIALID
where t4.FDATE>=@FirstDay and t4.FDATE<@LastDay 
and ((len(@OverScrap)>0 and @OverScrap='��' and t8.FREPICKEDQTY>t2.FSCRAPRATE*(t8.FPICKEDQTY+t8.FREPICKEDQTY)) or len(@OverScrap)=0 or @OverScrap='��')

------------------------------------------------ί��
--����������ϵ��ı�ע���������������飩
select a.FMATERIALID
,(select c.FMEMO+';' from T_SUB_FEEDMTRLENTRY b
left join T_SUB_FEEDMTRLENTRY_L c on b.FENTRYID=c.FENTRYID and c.FLOCALEID=2052
join T_SUB_FEEDMTRL d on d.FID=b.FID
where b.FMATERIALID=a.FMATERIALID and len(c.FMEMO)>0
and d.FDATE>=@FirstDay and d.FDATE<@LastDay 
FOR XML PATH('')) as ��ע 
into #WWNoteTable
from T_SUB_FEEDMTRLENTRY a

select t4.FBILLNO+t5.FNUMBER as '�������������ϴ���'
,t4.FBILLNO as '����/ί�ⶩ����'
,t5.FNUMBER as '���ϴ���'
,t6.FNAME as '��������'
,t6.FSPECIFICATION as '����ͺ�'
,t7.FNAME as '��λ'
,t2.FMustQty as '��������'
,t8.FPICKEDQTY+t8.FREPICKEDQTY as 'ʵ������'
,t8.FREPICKEDQTY as '��������'
,t2.FSCRAPRATE as '��׼���%'
,case when (t8.FPICKEDQTY+t8.FREPICKEDQTY)<>0 then t8.FREPICKEDQTY/(t8.FPICKEDQTY+t8.FREPICKEDQTY)*100 else 0 end as 'ʵ�����%'
,(case when (t8.FPICKEDQTY+t8.FREPICKEDQTY)<>0 then t8.FREPICKEDQTY/(t8.FPICKEDQTY+t8.FREPICKEDQTY)*100 else 0 end)-t2.FSCRAPRATE as '�������%'
,t10.FTAXPRICE as '����'
,t10.FTAXPRICE*t8.FREPICKEDQTY as '���Ͻ��'
,(t8.FREPICKEDQTY-t2.FSCRAPRATE*(t8.FPICKEDQTY+t8.FREPICKEDQTY))*t10.FTAXPRICE as '������'
,t9.FSPECIFICATION as '��Ʒ�ͺ�'
,t11.��ע
into #WWDD
from T_SUB_PPBOM t1
join T_SUB_PPBOMENTRY t2 on t1.FID=t2.FID and t1.FDOCUMENTSTATUS='C'
join T_SUB_REQORDERENTRY t3 on t3.FENTRYID=t2.FSUBREQENTRYID and t3.FID=t2.FSUBREQID
join T_SUB_REQORDER t4 on t3.FID=t4.FID
join T_BD_MATERIAL t5 on t5.FMATERIALID=t2.FMATERIALID
join T_BD_MATERIAL_L t6 on t6.FMATERIALID=t2.FMATERIALID and t6.FLOCALEID=2052
join T_BD_UNIT_L t7 on t7.FUnitID=t2.FUnitID and t7.FLOCALEID=2052
join T_SUB_PPBOMENTRY_Q t8 on t8.FENTRYID=t2.FENTRYID
join T_BD_MATERIAL_L t9 on t9.FMATERIALID=t3.FMATERIALID and t9.FLOCALEID=2052
left join #PriceTable t10 on t10.FMATERIALID=t2.FMATERIALID
left join #WWNoteTable t11 on t11.FMATERIALID=t2.FMATERIALID
where t4.FDATE>=@FirstDay and t4.FDATE<@LastDay 
and ((len(@OverScrap)>0 and @OverScrap='��' and t8.FREPICKEDQTY>t2.FSCRAPRATE*(t8.FPICKEDQTY+t8.FREPICKEDQTY)) or len(@OverScrap)=0 or @OverScrap='��')

select * from #SCDD
union all
select * from #WWDD

drop table #PriceTable,#SCNoteTable,#WWNoteTable,#SCDD,#WWDD