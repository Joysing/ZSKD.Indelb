alter Procedure zskd_sp_CGHHDTGJB(@StartDay datetime,@Leadtime int,@UserId int,@filterStr varchar(max)='',@MaterialID int=0,@Purchaser int=0,@Supplier int=0)
as
--�ɹ��ػ���̬������

--declare @StartDay datetime='2017-01-06' --��1��  2014-09-12 2017-01-06
declare @FSUPPLIERID int =( select top 1 FSUPPLIERID from T_SCP_USERDATA where FUSERID=@UserId)--�����˺Ų鹩Ӧ�̣������ǲ��ǹ�Ӧ��Эͬ�˺�

-- create table #T_ENG_BOMEXPANDRESULT(
	-- FLevelNumber VARCHAR(100) NULL,
	-- FBOMLevel VARCHAR(100) NULL,
	-- ��ƷID INT NULL,
	-- FTopID INT NULL,
	-- FBOMID INT NULL,
	-- FREPLACEGROUP INT NULL, 
	-- BOM�汾 VARCHAR(100) NULL, 
	-- ��������ID INT NULL,
	-- �������ϱ��� VARCHAR(100) NULL,
	-- ��������ID INT NULL,
	-- �������ϱ��� VARCHAR(100) NULL,
	-- ���� DECIMAL(28,10) NULL,
	-- ��ĸ DECIMAL(28,10) NULL,
	-- ����� DECIMAL(28,10) NULL,
	-- ��׼���� DECIMAL(28,10) NULL,
	-- ʵ����������� DECIMAL(28,10) NULL,
	-- FRowID VARCHAR(100) NULL,
	-- FParentRowID VARCHAR(100) NULL,
	-- �Ƿ���ײ����� INT NULL, 
-- )
declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --ʹ����֯ �㶫Ӣ�ö�
exec zskd_sp_InsertBOMExpandTemp_CGHHB

select '��������' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.FNOSTOCKINQTY FRemainOutQty
,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber,t2.FSALEORDERENTRYID
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID and t3.FNOSTOCKINQTY>0
join T_BD_MATERIAL mat on t2.FMATERIALID=mat.FMATERIALID
-- join T_BD_MATERIALGROUP matg on mat.FMATERIALGROUP=matg.FID and matg.FNUMBER in ('2','3','4','5','6','7')

select  '���۶���' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FREMAINOUTQTY FRemainOutQty
,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber,0 FSALEORDERENTRYID
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A'
and t1.FSALEORGID=@FUseOrg and t2.F_ora_OptOutPurReturn<>1
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID and t4.FREMAINOUTQTY>0
left join #SCDD on #SCDD.FSALEORDERENTRYID=t2.FENTRYID
where #SCDD.FSALEORDERENTRYID is null --ȥ����������������������
/*
--��Ҫչ��������
-- select distinct FMATERIALID into #NeedExpandMat from T_ENG_BOM where FUSEORGID=@FUseOrg
select distinct FProductID FMATERIALID into #NeedExpandMat
from (select FProductID from #SCDD union all select FProductID from #XSDD ) t

--��߰汾BOM��ʱ��
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* from T_ENG_BOM where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

declare @NowIndex int =(select min(FMATERIALID) from #NeedExpandMat)
declare @MaxIndex int =(select max(FMATERIALID) from #NeedExpandMat)
WHILE @NowIndex<=@MaxIndex
BEGIN --begin1
	print @NowIndex
	--������ǿ������嵥����
	declare @FMaterialID int
	declare @FBOMID int
	declare @FQty decimal(28,10)=1
	set @FMaterialID=@NowIndex;

	--�ݹ�չ�������嵥���� begin
	WITH CET(FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM�汾, ��������ID,�������ϱ���,��������ID,�������ϱ���,����,��ĸ,�����,��׼����,ʵ�����������,FRowID,FParentRowID)
	as (
	SELECT  
	Cast(RIGHT('000'+CAST(Row_Number() OVER (ORDER BY T1.FREPLACEGROUP ASC) AS varchar(50)),3) as varchar(max) ) as FLevelNumber,1 FBOMLevel
	,T.FID,T.FID,T1.FREPLACEGROUP,T.FNUMBER 'BOM�汾',T.FMATERIALID AS '��������ID',T3.FNumber AS '�������ϱ���',T1.FMATERIALID AS '��������ID',T2.FNumber AS '�������ϱ���'
	,FNUMERATOR,FDENOMINATOR,convert(decimal(23,10),T1.FSCRAPRATE)
	,convert(decimal(23,10),T1.FNUMERATOR/T1.FDENOMINATOR) as ��׼����
	,convert(decimal(23,10),T1.FNUMERATOR/T1.FDENOMINATOR*(1+T1.FSCRAPRATE/100)) as ʵ�����������
	,convert(varchar(50),NEWID()),convert(varchar(50),'')
	FROM #HigherBOM T
	JOIN T_ENG_BOMCHILD T1 ON T.FID = T1.FID
	LEFT JOIN T_BD_MATERIAL T2 ON T1.FMATERIALID = T2.FMATERIALID
	LEFT JOIN T_BD_MATERIAL T3 ON T.FMATERIALID = T3.FMATERIALID
	WHERE (T.FID=@FBOMID or (T.FMATERIALID = @FMaterialID and isnull(@FBOMID,0)=0)) and T.FDOCUMENTSTATUS = 'C' AND T.FFORBIDSTATUS <> 'B'
	UNION ALL
	SELECT 
	T.FLevelNumber+'.'+CAST(RIGHT('000'+CAST(Row_Number() OVER (ORDER BY T1.FREPLACEGROUP ASC) AS varchar(50)),3) AS varchar(max)) as FLevelNumber,
	T.FBOMLevel+1 as FBOMLevel,
	T.FTopID,T1.FID,T1.FREPLACEGROUP,T1.BOM�汾,T1.��������ID,T1.�������ϱ���,T1.��������ID,T1.�������ϱ���
	,T1.FNUMERATOR,T1.FDENOMINATOR,convert(decimal(23,10),T1.FSCRAPRATE)
	,convert(decimal(23,10),T.��׼����*T1.FNUMERATOR/T1.FDENOMINATOR) as ��׼����
	,convert(decimal(23,10),T.��׼����*T1.FNUMERATOR/T1.FDENOMINATOR*(1+T1.FSCRAPRATE/100)) as ʵ�����������
	,convert(varchar(50),NEWID()),convert(varchar(50),'')
	FROM CET T 
	JOIN ( 
		SELECT 
		T.FID,T.FNUMBER 'BOM�汾',T.FMATERIALID AS '��������ID',T3.FNumber AS '�������ϱ���',T1.FMATERIALID AS '��������ID',
		T2.FNumber AS '�������ϱ���',T.FFORBIDSTATUS,T.FDOCUMENTSTATUS,T1.FENTRYID,T1.FREPLACEGROUP
		,T1.FNUMERATOR,T1.FDENOMINATOR,T1.FSCRAPRATE
		FROM #HigherBOM T
		JOIN T_ENG_BOMCHILD T1 ON T.FID = T1.FID
		JOIN T_BD_MATERIAL T2 ON T1.FMATERIALID = T2.FMATERIALID
		JOIN T_BD_MATERIAL T3 ON T.FMATERIALID = T3.FMATERIALID
	) T1 ON T.��������ID = T1.��������ID AND T1.FFORBIDSTATUS <> 'B'  AND T1.FDOCUMENTSTATUS = 'C'
	)
	select t.* into #T_ENG_BOMEXPANDRESULTInOne from CET t order by t.FLevelNumber;

	--���붥��������
	insert into #T_ENG_BOMEXPANDRESULTInOne (FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM�汾, ��������ID,�������ϱ���,��������ID,�������ϱ���,����,��ĸ,��׼����,ʵ�����������,FRowID,FParentRowID)
	select top 1 '000' as FLevelNumber,0 as FBOMLevel,FTopID,FBOMID,0 FREPLACEGROUP,'',0,'',@FMaterialID,'',0,0,@FQty,@FQty,NEWID(),'' from #T_ENG_BOMEXPANDRESULTInOne 

	update t1 set FParentRowID=t2.FRowID from #T_ENG_BOMEXPANDRESULTInOne t1 join #T_ENG_BOMEXPANDRESULTInOne t2 on t1.��������ID=t2.��������ID
	--�ݹ�չ�������嵥���� end

	insert into #T_ENG_BOMEXPANDRESULT(FLevelNumber,FBOMLevel,��ƷID,FTopID,FBOMID,FREPLACEGROUP, BOM�汾, ��������ID,�������ϱ���,��������ID,�������ϱ���,����,��ĸ
	,�����,��׼����,ʵ�����������,FRowID,FParentRowID,�Ƿ���ײ�����)
	select t1.FLevelNumber,t1.FBOMLevel,@NowIndex,t1.FTopID,t1.FBOMID,t1.FREPLACEGROUP
	, t1.BOM�汾, t1.��������ID,t1.�������ϱ���,t1.��������ID,t1.�������ϱ���,t1.����,t1.��ĸ,�����,t1.��׼����,t1.ʵ�����������,t1.FRowID,t1.FParentRowID
		,case when t2.FMATERIALID is null then 1 else 0 end �Ƿ���ײ�����
	from #T_ENG_BOMEXPANDRESULTInOne t1 left join #HigherBOM t2 on t1.��������ID=t2.FMATERIALID
	
	order by FLevelNumber;
	drop table #T_ENG_BOMEXPANDRESULTInOne

	set @NowIndex=(select min(FMATERIALID) from #NeedExpandMat where FMATERIALID>@NowIndex)
END --begin1
drop table #HigherBOM
--select * from #T_ENG_BOMEXPANDRESULT
*/
--����ʾ1.60��1.57��1.56��1.52��1.51��1.50
select t3.* into #T_ENG_BOMEXPANDRESULT from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t3
join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=t3.��������ID 
join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=t3.��������ID and ((mat3b.FERPCLSID=1 and mat2b.FERPCLSID<>3) or mat3b.FERPCLSID<>1)--����Ӽ����⹺�Ҹ�����ί��������ʾ��һ��
join T_BD_MATERIALPURCHASE t4 on t3.��������ID=t4.FMATERIALID and (t4.FPURCHASERID=@Purchaser or @Purchaser=0) 
and (t4.FDEFAULTVENDORID=@Supplier or @Supplier=0)
and mat3b.FERPCLSID<>5 --����=���� ����ʾ
where 
  (t3.�������ϱ��� not like '1.60%' 
and t3.�������ϱ��� not like '1.57%' 
and t3.�������ϱ��� not like '1.56%' 
and t3.�������ϱ��� not like '1.52%'
and t3.�������ϱ��� not like '1.51%'
and t3.�������ϱ��� not like '1.50%')
and (t3.��������ID=@MaterialID or @MaterialID=0)

-- delete t3 from #T_ENG_BOMEXPANDRESULT t3
-- join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=t3.��������ID 
-- join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=t3.��������ID and (mat3b.FERPCLSID=1 and mat2b.FERPCLSID=3)--����Ӽ����⹺�Ҹ�����ί��������ʾ��һ��
-- join T_BD_MATERIALPURCHASE t4 on t3.��������ID=t4.FMATERIALID and (t4.FPURCHASERID<>@Purchaser and @Purchaser>0)
-- where 
  -- (t3.�������ϱ��� like '1.60%' 
-- or t3.�������ϱ��� like '1.57%' 
-- or t3.�������ϱ��� like '1.56%' 
-- or t3.�������ϱ��� like '1.52%'
-- or t3.�������ϱ��� like '1.51%'
-- or t3.�������ϱ��� like '1.50%')
-- and (t3.��������ID<>@MaterialID or @MaterialID>0)
-- or mat3b.FERPCLSID=5 --����=���� ����ʾ

--��������
declare @WorkCalID int =(select top 1 FID from T_ENG_WORKCAL where FFormID='ENG_WorkCal' and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FUSEORGID=@FUseOrg order by FAPPROVEDATE desc)
--declare @WorkCalID int =100653

select t1.BillType,t1.FBillNo,t1.FID,t1.FEntryID,t1.FProductID,t1.FOrderQty,isnull(t3.��������ID,t1.FProductID) FMATERIALID,isnull(t3.��׼����,1)*t1.FREMAINOUTQTY FDemandQty
,isnull(t3.�����,0) FSCRAPRATE,t1.FCalDate,t1.F_ora_PINumber,isnull(t3.��������ID,t1.FProductID) ��������ID
into #BillExpand
from (select * from #SCDD union all select * from #XSDD ) t1
left join #T_ENG_BOMEXPANDRESULT t3 on t3.��ƷID=t1.FProductID --and t3.�Ƿ���ײ�����=1

----������������������
select '��������' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FMATERIALID,t4.FMUSTQTY-t5.FPICKEDQTY FDemandQty
,t4.FSCRAPRATE,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber
into #SCDDPick
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join T_PRD_PPBOM t3 on t3.FMOENTRYID=t2.FENTRYID
join T_PRD_PPBOMENTRY t4 on t3.FID=t4.FID
join T_PRD_PPBOMENTRY_Q t5 on t4.FENTRYID=t5.FENTRYID and t4.FMUSTQTY-t5.FPICKEDQTY>0

--------------------------------------------------------��ѯ��������                                                                                                            
select 'BOM' as FDataSource,bills.BillType,bills.FBillNo,bills.F_ora_PINumber,convert(float,bills.FOrderQty) as FQTY                   
,mat1.FNUMBER as FBillMatNumber,mat1_l.FNAME as FBillMatName
,mat2.FNUMBER as FProductNumber,mat2_l.FNAME as FProductName
,mat3.FNUMBER as FMatNumber,mat3_l.FNAME as FMatName,mat3_l.FSPECIFICATION as FMatSpec,eil.FCAPTION as FMatProp                   
,convert(float,bills.FSCRAPRATE) as FScrap
,case when bills.BillType='��������' then
	#SCDDPick.FDemandQty
else
	convert(float,CEILING(bills.FDemandQty*(1+bills.FSCRAPRATE/100)))
end as FDemandQty                 
,case when bills.BillType='��������' then
	#SCDDPick.FDemandQty
else
	convert(float,CEILING(bills.FDemandQty))
end as FDemandNoScrapQty        
,@Leadtime as FTotalLeadTime,bills.FCalDate,isnull(workCal2.FDAY,DATEADD(d,-1*@Leadtime-2,bills.FCalDate)) FDemandDate
,bills.FID,bills.FEntryID,mat3.FMaterialID                                                                                        
,case when recpe.FEntryID is null then '��' else '��' end FIsComplete                                                             
into #TempResult                                                                                                                 
from #BillExpand bills  
join t_bd_material mat1 on mat1.FMaterialID=bills.FProductID --��Ʒ                                                              
join T_BD_MATERIAL_L mat1_l on mat1_l.FMaterialID=mat1.FMATERIALID and mat1_l.FLOCALEID=2052
join t_bd_material mat2 on mat2.FMaterialID=bills.��������ID
join T_BD_MATERIAL_L mat2_l on mat2_l.FMaterialID=mat2.FMATERIALID and mat2_l.FLOCALEID=2052
join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=mat2.FMaterialID    
join t_bd_material mat3 on mat3.FMaterialID=bills.FMATERIALID 
join T_BD_MATERIAL_L mat3_l on mat3_l.FMaterialID=mat3.FMATERIALID and mat3_l.FLOCALEID=2052                                
join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=mat3.FMaterialID
left join T_META_FORMENUMITEM enumitem on enumitem.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and enumitem.FVALUE=mat3b.FERPCLSID 
left join T_META_FORMENUMITEM_L eil on eil.FENUMID=enumitem.FENUMID and eil.FLOCALEID=2052                                       
left join T_ENG_WORKCALDATA workCal on workCal.FID=@WorkCalID and workCal.FDAY=bills.FCalDate
left join T_ENG_WORKCALDATA workCal2 on workCal2.FID=@WorkCalID and workCal2.FINTERID=workCal.FINTERID - @Leadtime
left join T_PUR_ReceivePlanEntry recpe on recpe.FDEMANDBILLID=bills.FID and recpe.FDemandEntryId=bills.FEntryID and recpe.FMaterialID=mat3.FMATERIALID
left join #SCDDPick on bills.BillType='��������' and bills.FEntryID=#SCDDPick.FEntryID and #SCDDPick.FMATERIALID=bills.FMATERIALID 
where bills.FDemandQty>0

drop table #XSDD,#SCDD,#BillExpand

--�������ڱ�
CREATE TABLE #AllDayTable(
	FMaterialID int Not NULL,
	FStockQty decimal(28, 10) NULL, --�������
	FStockQtyCal decimal(28, 10) NULL, --�������(���ڼ���)
	FTotalDemandQty decimal(28, 10) NULL, --��������������ë����
	FGrossDemandQty decimal(28, 10) NULL, --day1֮ǰ��ë����
	FNetDemandQty decimal(28, 10) NULL,   --day1֮ǰ�ľ�����
	FLastGrossDemandQty decimal(28, 10) NULL, --day100֮���ë����
	FDemandQtyDay1	decimal(28, 10) NULL,
	FDemandQtyDay2	decimal(28, 10) NULL,
	FDemandQtyDay3	decimal(28, 10) NULL,
	FDemandQtyDay4	decimal(28, 10) NULL,
	FDemandQtyDay5	decimal(28, 10) NULL,
	FDemandQtyDay6	decimal(28, 10) NULL,
	FDemandQtyDay7	decimal(28, 10) NULL,
	FDemandQtyDay8	decimal(28, 10) NULL,
	FDemandQtyDay9	decimal(28, 10) NULL,
	FDemandQtyDay10	decimal(28, 10) NULL,
	FDemandQtyDay11	decimal(28, 10) NULL,
	FDemandQtyDay12	decimal(28, 10) NULL,
	FDemandQtyDay13	decimal(28, 10) NULL,
	FDemandQtyDay14	decimal(28, 10) NULL,
	FDemandQtyDay15	decimal(28, 10) NULL,
	FDemandQtyDay16	decimal(28, 10) NULL,
	FDemandQtyDay17	decimal(28, 10) NULL,
	FDemandQtyDay18	decimal(28, 10) NULL,
	FDemandQtyDay19	decimal(28, 10) NULL,
	FDemandQtyDay20	decimal(28, 10) NULL,
	FDemandQtyDay21	decimal(28, 10) NULL,
	FDemandQtyDay22	decimal(28, 10) NULL,
	FDemandQtyDay23	decimal(28, 10) NULL,
	FDemandQtyDay24	decimal(28, 10) NULL,
	FDemandQtyDay25	decimal(28, 10) NULL,
	FDemandQtyDay26	decimal(28, 10) NULL,
	FDemandQtyDay27	decimal(28, 10) NULL,
	FDemandQtyDay28	decimal(28, 10) NULL,
	FDemandQtyDay29	decimal(28, 10) NULL,
	FDemandQtyDay30	decimal(28, 10) NULL,
	FDemandQtyDay31	decimal(28, 10) NULL,
	FDemandQtyDay32	decimal(28, 10) NULL,
	FDemandQtyDay33	decimal(28, 10) NULL,
	FDemandQtyDay34	decimal(28, 10) NULL,
	FDemandQtyDay35	decimal(28, 10) NULL,
	FDemandQtyDay36	decimal(28, 10) NULL,
	FDemandQtyDay37	decimal(28, 10) NULL,
	FDemandQtyDay38	decimal(28, 10) NULL,
	FDemandQtyDay39	decimal(28, 10) NULL,
	FDemandQtyDay40	decimal(28, 10) NULL,
	FDemandQtyDay41	decimal(28, 10) NULL,
	FDemandQtyDay42	decimal(28, 10) NULL,
	FDemandQtyDay43	decimal(28, 10) NULL,
	FDemandQtyDay44	decimal(28, 10) NULL,
	FDemandQtyDay45	decimal(28, 10) NULL,
	FDemandQtyDay46	decimal(28, 10) NULL,
	FDemandQtyDay47	decimal(28, 10) NULL,
	FDemandQtyDay48	decimal(28, 10) NULL,
	FDemandQtyDay49	decimal(28, 10) NULL,
	FDemandQtyDay50	decimal(28, 10) NULL,
	FDemandQtyDay51	decimal(28, 10) NULL,
	FDemandQtyDay52	decimal(28, 10) NULL,
	FDemandQtyDay53	decimal(28, 10) NULL,
	FDemandQtyDay54	decimal(28, 10) NULL,
	FDemandQtyDay55	decimal(28, 10) NULL,
	FDemandQtyDay56	decimal(28, 10) NULL,
	FDemandQtyDay57	decimal(28, 10) NULL,
	FDemandQtyDay58	decimal(28, 10) NULL,
	FDemandQtyDay59	decimal(28, 10) NULL,
	FDemandQtyDay60	decimal(28, 10) NULL,
	FDemandQtyDay61	decimal(28, 10) NULL,
	FDemandQtyDay62	decimal(28, 10) NULL,
	FDemandQtyDay63	decimal(28, 10) NULL,
	FDemandQtyDay64	decimal(28, 10) NULL,
	FDemandQtyDay65	decimal(28, 10) NULL,
	FDemandQtyDay66	decimal(28, 10) NULL,
	FDemandQtyDay67	decimal(28, 10) NULL,
	FDemandQtyDay68	decimal(28, 10) NULL,
	FDemandQtyDay69	decimal(28, 10) NULL,
	FDemandQtyDay70	decimal(28, 10) NULL,
	FDemandQtyDay71	decimal(28, 10) NULL,
	FDemandQtyDay72	decimal(28, 10) NULL,
	FDemandQtyDay73	decimal(28, 10) NULL,
	FDemandQtyDay74	decimal(28, 10) NULL,
	FDemandQtyDay75	decimal(28, 10) NULL,
	FDemandQtyDay76	decimal(28, 10) NULL,
	FDemandQtyDay77	decimal(28, 10) NULL,
	FDemandQtyDay78	decimal(28, 10) NULL,
	FDemandQtyDay79	decimal(28, 10) NULL,
	FDemandQtyDay80	decimal(28, 10) NULL,
	FDemandQtyDay81	decimal(28, 10) NULL,
	FDemandQtyDay82	decimal(28, 10) NULL,
	FDemandQtyDay83	decimal(28, 10) NULL,
	FDemandQtyDay84	decimal(28, 10) NULL,
	FDemandQtyDay85	decimal(28, 10) NULL,
	FDemandQtyDay86	decimal(28, 10) NULL,
	FDemandQtyDay87	decimal(28, 10) NULL,
	FDemandQtyDay88	decimal(28, 10) NULL,
	FDemandQtyDay89	decimal(28, 10) NULL,
	FDemandQtyDay90	decimal(28, 10) NULL,
	FDemandQtyDay91	decimal(28, 10) NULL,
	FDemandQtyDay92	decimal(28, 10) NULL,
	FDemandQtyDay93	decimal(28, 10) NULL,
	FDemandQtyDay94	decimal(28, 10) NULL,
	FDemandQtyDay95	decimal(28, 10) NULL,
	FDemandQtyDay96	decimal(28, 10) NULL,
	FDemandQtyDay97	decimal(28, 10) NULL,
	FDemandQtyDay98	decimal(28, 10) NULL,
	FDemandQtyDay99	decimal(28, 10) NULL,
	FDemandQtyDay100	decimal(28, 10) NULL,
) ON [PRIMARY]

--��ѯ����֮ǰ�������ܺ�
select FMaterialID,sum(FDemandQty) ë������,sum(FDemandNoScrapQty) �������� into #TempResultForPrevDayTotal from #TempResult where FDemandDate<@StartDay group by FMaterialID

--�����ϻ��� case when t1.FStockQtyCal>=t2.�������� then 0 else t1.FStockQtyCal-t2.��������
insert into #AllDayTable(FMaterialID,FStockQty,FStockQtyCal,FTotalDemandQty,FGrossDemandQty,FNetDemandQty)
select t1.FMaterialID,inv.FAvbQty
,case when isnull(inv.FAvbQty,0)-isnull(t2.ë������,0)<0 then 0 else isnull(inv.FAvbQty,0)-isnull(t2.ë������,0) end --isnull(inv.FAvbQty,0)
,sum(t1.FDemandQty)
,case when inv.FAvbQty>=isnull(t2.ë������,0) then isnull(t2.ë������,0) else isnull(inv.FAvbQty,0)-isnull(t2.ë������,0) end
,case when inv.FAvbQty>=isnull(t2.��������,0) then isnull(t2.��������,0) else isnull(inv.FAvbQty,0)-isnull(t2.��������,0) end
from #TempResult t1 
left join #TempResultForPrevDayTotal t2 on t1.FMATERIALID=t2.FMATERIALID 
left join T_BD_MATERIAL t3 on t1.FMATERIALID=t3.FMATERIALID
outer apply (select sum(FBaseQTY - FBaseLOCKQTY) FAvbQty from T_STK_INVENTORY o1t1 
	join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT3='MTO'/* �ֿ��ʶ��TOC���ԡ�=MTO�ֿ�*/
	where FBaseQTY - FBaseLOCKQTY>0 and o1t1.FMaterialID=t3.FMASTERID 
) inv 
group by t1.FMaterialID,inv.FAvbQty,t2.ë������,t2.��������

--������+���ڻ���
select FMaterialID,FDemandDate,sum(FDemandQty) ��������
into #TempResultForDayTotal from #TempResult group by FMaterialID,FDemandDate

declare @NowDay datetime=@StartDay
declare @IndexDay int=1
--while(@NowDay<='2020-12-16')
while(DATEDIFF(d, @StartDay,@NowDay)<100) --С��3����3�죬С�ڵ���3����4��
begin --begin1
	--��������ȱ���٣���������ȱ
	--if ǰ�����ڼ���ʣ����>=11��6�ŵ�ë�����ܺ�
	--then 11��6�ŵ�ë�����ܺ�
	--else ǰ�����ڼ���ʣ����-11��6�ŵ�ë�����ܺ�
	--ʣ����-11��6�ŵ�ë�����ܺ�
	exec('update t1 set FDemandQtyDay'+@IndexDay+'=(case when t1.FStockQtyCal>=t2.�������� then t2.�������� else t1.FStockQtyCal-t2.�������� end),FStockQtyCal=(case when t1.FStockQtyCal-t2.��������<0 then 0 else t1.FStockQtyCal-t2.�������� end) from #AllDayTable t1 join #TempResultForDayTotal t2 on t1.FMaterialID=t2.FMATERIALID and t2.FDemandDate='''+@NowDay+'''')

	--if @IndexDay=1
	--	set @NowDay='2017-01-06'
	--if @IndexDay=2
	--	set @NowDay='2020-12-16'
	--if @IndexDay>2
	--	set @NowDay='2020-12-17'
	set @NowDay=DATEADD(d,1,@NowDay)--���ڼ�һ
	set @IndexDay=@IndexDay+1
end --begin1

--��ѯ��������֮��������ܺ�
select FMaterialID,sum(FDemandQty) �������� into #TempResultForNextDayTotal from #TempResult where FDemandDate>DATEADD(d,99,@StartDay) group by FMaterialID
update t1 set FLastGrossDemandQty=(case when t1.FStockQtyCal>=t2.�������� then t2.�������� else t1.FStockQtyCal-t2.�������� end)
	,FStockQtyCal=(case when t1.FStockQtyCal-t2.��������<0 then 0 else t1.FStockQtyCal-t2.�������� end)
	from #AllDayTable t1 join #TempResultForNextDayTotal t2 on t1.FMaterialID=t2.FMATERIALID

--��;��=�ɹ�����δ�������
select t2.FMaterialID,sum(t3.FREMAINSTOCKINQTY) FQTY
into #POOrderNoInStock from t_PUR_POOrder t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A'
join T_PUR_POORDERENTRY_R t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--��;��=ί�ⶩ��δ�������
select t2.FMaterialID,sum(t3.FNOSTOCKINQTY) FQTY
into #ReqOrderNoInStock from T_SUB_REQORDER t1 
join T_SUB_REQORDERENTRY t2 on t1.FID=t2.FID and t2.FSTATUS<>'6' and t2.FSTATUS<>'7' and t1.FDOCUMENTSTATUS='C' and t1.FCANCELSTATUS='A'
join T_SUB_REQORDERENTRY_A t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--VMI������������֪ͨ������=VMI���ϵ���δ�������
--select * from t_BAS_BILLTYPE_L where FNAME='VMI���ϵ�'
select t2.FMATERIALID,sum(t2.FACTRECEIVEQTY-t3.FINSTOCKQTY) FNoStockInQty into #VMIWaitCheck from T_PUR_Receive t1 
join T_PUR_ReceiveEntry t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t1.FDocumentStatus='C' and t1.FCANCELSTATUS='A' and t2.FMRPCLOSESTATUS='A' 
and t1.FBillTypeID='0023240234df807511e3089ad113642a'
join T_PUR_ReceiveEntry_S t3 on t2.FEntryID=t3.FEntryID
group by t2.FMATERIALID

--������������֪ͨ������=MTO��׼����+MTOί������+��׼���ϵ���δ�������
select t2.FMATERIALID,sum(t2.FACTRECEIVEQTY-t3.FINSTOCKQTY) FNoStockInQty into #WaitCheck from T_PUR_Receive t1 
join T_PUR_ReceiveEntry t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t1.FDocumentStatus='C' and t1.FCANCELSTATUS='A' and t2.FMRPCLOSESTATUS='A' 
and (
t1.FBillTypeID='607e7efa17f76b' or --MTO��׼����
t1.FBillTypeID='607e804017faff' or --MTOί������
t1.FBillTypeID='7cd93c259999489c97798063f2f7bd70' --��׼���ϵ�
)
join T_PUR_ReceiveEntry_S t3 on t2.FEntryID=t3.FEntryID
where t2.FACTRECEIVEQTY-t3.FINSTOCKQTY>0
group by t2.FMATERIALID

--VMIԭ���Ͽ�棨�ֿ�����=��Ӧ�ֿ̲⣩�������
select o1t1.FMaterialID,sum(FBaseQTY - FBaseLOCKQTY) FAvbQty into #VMIInventory from T_STK_INVENTORY o1t1 
	join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.FSTOCKPROPERTY='3'--�ֿ�����=��Ӧ�ֿ̲�
	group by o1t1.FMaterialID

select t2.FNUMBER FMaterialNumber,t3.FNAME FMaterialName,t3.FSPECIFICATION FMaterialSpec,mat2p.FFIXLEADTIME FReceiveAdvanceDays
,t5.FName FPurchaser,t6.FNAME FPurSupplier,t8.FNAME FStockUnit
,convert(float,t1.FStockQty) FStockQty
,convert(float,t12.FNoStockInQty) FVMIWaitCheckQty
,convert(float,t13.FNoStockInQty) FWaitCheckQty
,convert(float,t14.FAvbQty) FVMIAvbQty
,convert(float,isnull(t9.FQTY,0)+isnull(t10.FQTY,0)) FOnWayQty
,convert(float,t1.FTotalDemandQty) FTotalDemandQty
,convert(float,t1.FGrossDemandQty) FGrossDemandQty
,convert(float,t1.FNetDemandQty) FNetDemandQty
,convert(float,t1.FDemandQtyDay1 )	��1��
,convert(float,t1.FDemandQtyDay2 )	��2��
,convert(float,t1.FDemandQtyDay3 )	��3��
,convert(float,t1.FDemandQtyDay4 )	��4��
,convert(float,t1.FDemandQtyDay5 )	��5��
,convert(float,t1.FDemandQtyDay6 )	��6��
,convert(float,t1.FDemandQtyDay7 )	��7��
,convert(float,t1.FDemandQtyDay8 )	��8��
,convert(float,t1.FDemandQtyDay9 )	��9��
,convert(float,t1.FDemandQtyDay10 )	��10��
,convert(float,t1.FDemandQtyDay11 )	��11��
,convert(float,t1.FDemandQtyDay12 )	��12��
,convert(float,t1.FDemandQtyDay13 )	��13��
,convert(float,t1.FDemandQtyDay14 )	��14��
,convert(float,t1.FDemandQtyDay15 )	��15��
,convert(float,t1.FDemandQtyDay16 )	��16��
,convert(float,t1.FDemandQtyDay17 )	��17��
,convert(float,t1.FDemandQtyDay18 )	��18��
,convert(float,t1.FDemandQtyDay19 )	��19��
,convert(float,t1.FDemandQtyDay20 )	��20��
,convert(float,t1.FDemandQtyDay21 )	��21��
,convert(float,t1.FDemandQtyDay22 )	��22��
,convert(float,t1.FDemandQtyDay23 )	��23��
,convert(float,t1.FDemandQtyDay24 )	��24��
,convert(float,t1.FDemandQtyDay25 )	��25��
,convert(float,t1.FDemandQtyDay26 )	��26��
,convert(float,t1.FDemandQtyDay27 )	��27��
,convert(float,t1.FDemandQtyDay28 )	��28��
,convert(float,t1.FDemandQtyDay29 )	��29��
,convert(float,t1.FDemandQtyDay30 )	��30��
,convert(float,t1.FDemandQtyDay31 )	��31��
,convert(float,t1.FDemandQtyDay32 )	��32��
,convert(float,t1.FDemandQtyDay33 )	��33��
,convert(float,t1.FDemandQtyDay34 )	��34��
,convert(float,t1.FDemandQtyDay35 )	��35��
,convert(float,t1.FDemandQtyDay36 )	��36��
,convert(float,t1.FDemandQtyDay37 )	��37��
,convert(float,t1.FDemandQtyDay38 )	��38��
,convert(float,t1.FDemandQtyDay39 )	��39��
,convert(float,t1.FDemandQtyDay40 )	��40��
,convert(float,t1.FDemandQtyDay41 )	��41��
,convert(float,t1.FDemandQtyDay42 )	��42��
,convert(float,t1.FDemandQtyDay43 )	��43��
,convert(float,t1.FDemandQtyDay44 )	��44��
,convert(float,t1.FDemandQtyDay45 )	��45��
,convert(float,t1.FDemandQtyDay46 )	��46��
,convert(float,t1.FDemandQtyDay47 )	��47��
,convert(float,t1.FDemandQtyDay48 )	��48��
,convert(float,t1.FDemandQtyDay49 )	��49��
,convert(float,t1.FDemandQtyDay50 )	��50��
,convert(float,t1.FDemandQtyDay51 )	��51��
,convert(float,t1.FDemandQtyDay52 )	��52��
,convert(float,t1.FDemandQtyDay53 )	��53��
,convert(float,t1.FDemandQtyDay54 )	��54��
,convert(float,t1.FDemandQtyDay55 )	��55��
,convert(float,t1.FDemandQtyDay56 )	��56��
,convert(float,t1.FDemandQtyDay57 )	��57��
,convert(float,t1.FDemandQtyDay58 )	��58��
,convert(float,t1.FDemandQtyDay59 )	��59��
,convert(float,t1.FDemandQtyDay60 )	��60��
,convert(float,t1.FDemandQtyDay61 )	��61��
,convert(float,t1.FDemandQtyDay62 )	��62��
,convert(float,t1.FDemandQtyDay63 )	��63��
,convert(float,t1.FDemandQtyDay64 )	��64��
,convert(float,t1.FDemandQtyDay65 )	��65��
,convert(float,t1.FDemandQtyDay66 )	��66��
,convert(float,t1.FDemandQtyDay67 )	��67��
,convert(float,t1.FDemandQtyDay68 )	��68��
,convert(float,t1.FDemandQtyDay69 )	��69��
,convert(float,t1.FDemandQtyDay70 )	��70��
,convert(float,t1.FDemandQtyDay71 )	��71��
,convert(float,t1.FDemandQtyDay72 )	��72��
,convert(float,t1.FDemandQtyDay73 )	��73��
,convert(float,t1.FDemandQtyDay74 )	��74��
,convert(float,t1.FDemandQtyDay75 )	��75��
,convert(float,t1.FDemandQtyDay76 )	��76��
,convert(float,t1.FDemandQtyDay77 )	��77��
,convert(float,t1.FDemandQtyDay78 )	��78��
,convert(float,t1.FDemandQtyDay79 )	��79��
,convert(float,t1.FDemandQtyDay80 )	��80��
,convert(float,t1.FDemandQtyDay81 )	��81��
,convert(float,t1.FDemandQtyDay82 )	��82��
,convert(float,t1.FDemandQtyDay83 )	��83��
,convert(float,t1.FDemandQtyDay84 )	��84��
,convert(float,t1.FDemandQtyDay85 )	��85��
,convert(float,t1.FDemandQtyDay86 )	��86��
,convert(float,t1.FDemandQtyDay87 )	��87��
,convert(float,t1.FDemandQtyDay88 )	��88��
,convert(float,t1.FDemandQtyDay89 )	��89��
,convert(float,t1.FDemandQtyDay90 )	��90��
,convert(float,t1.FDemandQtyDay91 )	��91��
,convert(float,t1.FDemandQtyDay92 )	��92��
,convert(float,t1.FDemandQtyDay93 )	��93��
,convert(float,t1.FDemandQtyDay94 )	��94��
,convert(float,t1.FDemandQtyDay95 )	��95��
,convert(float,t1.FDemandQtyDay96 )	��96��
,convert(float,t1.FDemandQtyDay97 )	��97��
,convert(float,t1.FDemandQtyDay98 )	��98��
,convert(float,t1.FDemandQtyDay99 )	��99��
,convert(float,t1.FDemandQtyDay100) 	��100��
,convert(float,t1.FLastGrossDemandQty) FLastGrossDemandQty
into #ResultTable
from #AllDayTable t1
join T_BD_MATERIAL t2 on t1.FMaterialID=t2.FMaterialID
left join T_BD_MATERIAL_L t3 on t1.FMaterialID=t3.FMaterialID and t3.FLOCALEID=2052
left join T_BD_MATERIALPURCHASE t4 on t1.FMaterialID=t4.FMATERIALID
left join t_BD_MaterialPlan mat2p on mat2p.FMATERIALID=t2.FMATERIALID    
left join V_BD_BUYER_L t5 on t4.FPURCHASERID=t5.FID  and t5.FLOCALEID=2052
left join T_BD_SUPPLIER_L t6 on t4.FDEFAULTVENDORID=t6.FSUPPLIERID and t6.FLOCALEID=2052
left join T_BD_MATERIALSTOCK t7 on t1.FMaterialID=t7.FMATERIALID
left join T_BD_UNIT_L t8 on t8.FUNITID=t7.FSTOREUNITID and t8.FLOCALEID=2052
left join #POOrderNoInStock t9 on t9.FMATERIALID=t1.FMaterialID
left join #ReqOrderNoInStock t10 on t10.FMATERIALID=t1.FMaterialID
left join #TempResultForNextDayTotal t11 on t11.FMATERIALID=t1.FMaterialID
left join #VMIWaitCheck t12 on t12.FMATERIALID=t1.FMaterialID
left join #WaitCheck t13 on t13.FMATERIALID=t1.FMaterialID
left join #VMIInventory t14 on t14.FMATERIALID=t2.FMASTERID
where ((@FSUPPLIERID>0 and t4.FDEFAULTVENDORID=@FSUPPLIERID) or (isnull(@FSUPPLIERID,0)=0))
order by t2.FNUMBER

drop table #TempResult,#AllDayTable,#TempResultForDayTotal,#TempResultForPrevDayTotal,#TempResultForNextDayTotal,#POOrderNoInStock,#ReqOrderNoInStock

declare @sqlStr varchar(max) ='select * from #ResultTable'
if @filterStr<>'' and @filterStr is not null
begin
	set @sqlStr=@sqlStr+' where '+@filterStr
end
exec(@sqlStr)

go

zskd_sp_CGHHDTGJB '2017-01-16',9,'FLastGrossDemandQty>0'