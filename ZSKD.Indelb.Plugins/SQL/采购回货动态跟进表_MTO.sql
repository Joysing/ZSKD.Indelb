alter Procedure zskd_sp_CGHHDTGJB(@StartDay datetime,@Leadtime int,@UserId int,@filterStr varchar(max)='',@MaterialID int=0,@Purchaser int=0,@Supplier int=0)
as
--采购回货动态跟进表

--declare @StartDay datetime='2017-01-06' --第1天  2014-09-12 2017-01-06
declare @FSUPPLIERID int =( select top 1 FSUPPLIERID from T_SCP_USERDATA where FUSERID=@UserId)--根据账号查供应商，看看是不是供应商协同账号

-- create table #T_ENG_BOMEXPANDRESULT(
	-- FLevelNumber VARCHAR(100) NULL,
	-- FBOMLevel VARCHAR(100) NULL,
	-- 产品ID INT NULL,
	-- FTopID INT NULL,
	-- FBOMID INT NULL,
	-- FREPLACEGROUP INT NULL, 
	-- BOM版本 VARCHAR(100) NULL, 
	-- 父项物料ID INT NULL,
	-- 父项物料编码 VARCHAR(100) NULL,
	-- 子项物料ID INT NULL,
	-- 子项物料编码 VARCHAR(100) NULL,
	-- 分子 DECIMAL(28,10) NULL,
	-- 分母 DECIMAL(28,10) NULL,
	-- 损耗率 DECIMAL(28,10) NULL,
	-- 标准用量 DECIMAL(28,10) NULL,
	-- 实际算损耗用量 DECIMAL(28,10) NULL,
	-- FRowID VARCHAR(100) NULL,
	-- FParentRowID VARCHAR(100) NULL,
	-- 是否最底层物料 INT NULL, 
-- )
declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --使用组织 广东英得尔
exec zskd_sp_InsertBOMExpandTemp_CGHHB

select '生产订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.FNOSTOCKINQTY FRemainOutQty
,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber,t2.FSALEORDERENTRYID
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID and t3.FNOSTOCKINQTY>0
join T_BD_MATERIAL mat on t2.FMATERIALID=mat.FMATERIALID
-- join T_BD_MATERIALGROUP matg on mat.FMATERIALGROUP=matg.FID and matg.FNUMBER in ('2','3','4','5','6','7')

select  '销售订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FREMAINOUTQTY FRemainOutQty
,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber,0 FSALEORDERENTRYID
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A'
and t1.FSALEORGID=@FUseOrg and t2.F_ora_OptOutPurReturn<>1
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID and t4.FREMAINOUTQTY>0
left join #SCDD on #SCDD.FSALEORDERENTRYID=t2.FENTRYID
where #SCDD.FSALEORDERENTRYID is null --去掉已运算生成生产订单的
/*
--需要展开的物料
-- select distinct FMATERIALID into #NeedExpandMat from T_ENG_BOM where FUSEORGID=@FUseOrg
select distinct FProductID FMATERIALID into #NeedExpandMat
from (select FProductID from #SCDD union all select FProductID from #XSDD ) t

--最高版本BOM临时表
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* from T_ENG_BOM where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

declare @NowIndex int =(select min(FMATERIALID) from #NeedExpandMat)
declare @MaxIndex int =(select max(FMATERIALID) from #NeedExpandMat)
WHILE @NowIndex<=@MaxIndex
BEGIN --begin1
	print @NowIndex
	--金蝶云星空物料清单正查
	declare @FMaterialID int
	declare @FBOMID int
	declare @FQty decimal(28,10)=1
	set @FMaterialID=@NowIndex;

	--递归展开物料清单正查 begin
	WITH CET(FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM版本, 父项物料ID,父项物料编码,子项物料ID,子项物料编码,分子,分母,损耗率,标准用量,实际算损耗数量,FRowID,FParentRowID)
	as (
	SELECT  
	Cast(RIGHT('000'+CAST(Row_Number() OVER (ORDER BY T1.FREPLACEGROUP ASC) AS varchar(50)),3) as varchar(max) ) as FLevelNumber,1 FBOMLevel
	,T.FID,T.FID,T1.FREPLACEGROUP,T.FNUMBER 'BOM版本',T.FMATERIALID AS '父项物料ID',T3.FNumber AS '父项物料编码',T1.FMATERIALID AS '子项物料ID',T2.FNumber AS '子项物料编码'
	,FNUMERATOR,FDENOMINATOR,convert(decimal(23,10),T1.FSCRAPRATE)
	,convert(decimal(23,10),T1.FNUMERATOR/T1.FDENOMINATOR) as 标准用量
	,convert(decimal(23,10),T1.FNUMERATOR/T1.FDENOMINATOR*(1+T1.FSCRAPRATE/100)) as 实际算损耗数量
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
	T.FTopID,T1.FID,T1.FREPLACEGROUP,T1.BOM版本,T1.父项物料ID,T1.父项物料编码,T1.子项物料ID,T1.子项物料编码
	,T1.FNUMERATOR,T1.FDENOMINATOR,convert(decimal(23,10),T1.FSCRAPRATE)
	,convert(decimal(23,10),T.标准用量*T1.FNUMERATOR/T1.FDENOMINATOR) as 标准用量
	,convert(decimal(23,10),T.标准用量*T1.FNUMERATOR/T1.FDENOMINATOR*(1+T1.FSCRAPRATE/100)) as 实际算损耗数量
	,convert(varchar(50),NEWID()),convert(varchar(50),'')
	FROM CET T 
	JOIN ( 
		SELECT 
		T.FID,T.FNUMBER 'BOM版本',T.FMATERIALID AS '父项物料ID',T3.FNumber AS '父项物料编码',T1.FMATERIALID AS '子项物料ID',
		T2.FNumber AS '子项物料编码',T.FFORBIDSTATUS,T.FDOCUMENTSTATUS,T1.FENTRYID,T1.FREPLACEGROUP
		,T1.FNUMERATOR,T1.FDENOMINATOR,T1.FSCRAPRATE
		FROM #HigherBOM T
		JOIN T_ENG_BOMCHILD T1 ON T.FID = T1.FID
		JOIN T_BD_MATERIAL T2 ON T1.FMATERIALID = T2.FMATERIALID
		JOIN T_BD_MATERIAL T3 ON T.FMATERIALID = T3.FMATERIALID
	) T1 ON T.子项物料ID = T1.父项物料ID AND T1.FFORBIDSTATUS <> 'B'  AND T1.FDOCUMENTSTATUS = 'C'
	)
	select t.* into #T_ENG_BOMEXPANDRESULTInOne from CET t order by t.FLevelNumber;

	--插入顶级父物料
	insert into #T_ENG_BOMEXPANDRESULTInOne (FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM版本, 父项物料ID,父项物料编码,子项物料ID,子项物料编码,分子,分母,标准用量,实际算损耗数量,FRowID,FParentRowID)
	select top 1 '000' as FLevelNumber,0 as FBOMLevel,FTopID,FBOMID,0 FREPLACEGROUP,'',0,'',@FMaterialID,'',0,0,@FQty,@FQty,NEWID(),'' from #T_ENG_BOMEXPANDRESULTInOne 

	update t1 set FParentRowID=t2.FRowID from #T_ENG_BOMEXPANDRESULTInOne t1 join #T_ENG_BOMEXPANDRESULTInOne t2 on t1.父项物料ID=t2.子项物料ID
	--递归展开物料清单正查 end

	insert into #T_ENG_BOMEXPANDRESULT(FLevelNumber,FBOMLevel,产品ID,FTopID,FBOMID,FREPLACEGROUP, BOM版本, 父项物料ID,父项物料编码,子项物料ID,子项物料编码,分子,分母
	,损耗率,标准用量,实际算损耗用量,FRowID,FParentRowID,是否最底层物料)
	select t1.FLevelNumber,t1.FBOMLevel,@NowIndex,t1.FTopID,t1.FBOMID,t1.FREPLACEGROUP
	, t1.BOM版本, t1.父项物料ID,t1.父项物料编码,t1.子项物料ID,t1.子项物料编码,t1.分子,t1.分母,损耗率,t1.标准用量,t1.实际算损耗数量,t1.FRowID,t1.FParentRowID
		,case when t2.FMATERIALID is null then 1 else 0 end 是否最底层物料
	from #T_ENG_BOMEXPANDRESULTInOne t1 left join #HigherBOM t2 on t1.子项物料ID=t2.FMATERIALID
	
	order by FLevelNumber;
	drop table #T_ENG_BOMEXPANDRESULTInOne

	set @NowIndex=(select min(FMATERIALID) from #NeedExpandMat where FMATERIALID>@NowIndex)
END --begin1
drop table #HigherBOM
--select * from #T_ENG_BOMEXPANDRESULT
*/
--不显示1.60；1.57；1.56；1.52；1.51；1.50
select t3.* into #T_ENG_BOMEXPANDRESULT from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t3
join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=t3.父项物料ID 
join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=t3.子项物料ID and ((mat3b.FERPCLSID=1 and mat2b.FERPCLSID<>3) or mat3b.FERPCLSID<>1)--如果子件是外购且父件是委外则不用显示这一行
join T_BD_MATERIALPURCHASE t4 on t3.子项物料ID=t4.FMATERIALID and (t4.FPURCHASERID=@Purchaser or @Purchaser=0) 
and (t4.FDEFAULTVENDORID=@Supplier or @Supplier=0)
and mat3b.FERPCLSID<>5 --属性=虚拟 不显示
where 
  (t3.子项物料编码 not like '1.60%' 
and t3.子项物料编码 not like '1.57%' 
and t3.子项物料编码 not like '1.56%' 
and t3.子项物料编码 not like '1.52%'
and t3.子项物料编码 not like '1.51%'
and t3.子项物料编码 not like '1.50%')
and (t3.子项物料ID=@MaterialID or @MaterialID=0)

-- delete t3 from #T_ENG_BOMEXPANDRESULT t3
-- join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=t3.父项物料ID 
-- join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=t3.子项物料ID and (mat3b.FERPCLSID=1 and mat2b.FERPCLSID=3)--如果子件是外购且父件是委外则不用显示这一行
-- join T_BD_MATERIALPURCHASE t4 on t3.子项物料ID=t4.FMATERIALID and (t4.FPURCHASERID<>@Purchaser and @Purchaser>0)
-- where 
  -- (t3.子项物料编码 like '1.60%' 
-- or t3.子项物料编码 like '1.57%' 
-- or t3.子项物料编码 like '1.56%' 
-- or t3.子项物料编码 like '1.52%'
-- or t3.子项物料编码 like '1.51%'
-- or t3.子项物料编码 like '1.50%')
-- and (t3.子项物料ID<>@MaterialID or @MaterialID>0)
-- or mat3b.FERPCLSID=5 --属性=虚拟 不显示

--工作日历
declare @WorkCalID int =(select top 1 FID from T_ENG_WORKCAL where FFormID='ENG_WorkCal' and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FUSEORGID=@FUseOrg order by FAPPROVEDATE desc)
--declare @WorkCalID int =100653

select t1.BillType,t1.FBillNo,t1.FID,t1.FEntryID,t1.FProductID,t1.FOrderQty,isnull(t3.子项物料ID,t1.FProductID) FMATERIALID,isnull(t3.标准用量,1)*t1.FREMAINOUTQTY FDemandQty
,isnull(t3.损耗率,0) FSCRAPRATE,t1.FCalDate,t1.F_ora_PINumber,isnull(t3.父项物料ID,t1.FProductID) 父项物料ID
into #BillExpand
from (select * from #SCDD union all select * from #XSDD ) t1
left join #T_ENG_BOMEXPANDRESULT t3 on t3.产品ID=t1.FProductID --and t3.是否最底层物料=1

----生产订单已领料数量
select '生产订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FMATERIALID,t4.FMUSTQTY-t5.FPICKEDQTY FDemandQty
,t4.FSCRAPRATE,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber
into #SCDDPick
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join T_PRD_PPBOM t3 on t3.FMOENTRYID=t2.FENTRYID
join T_PRD_PPBOMENTRY t4 on t3.FID=t4.FID
join T_PRD_PPBOMENTRY_Q t5 on t4.FENTRYID=t5.FENTRYID and t4.FMUSTQTY-t5.FPICKEDQTY>0

--------------------------------------------------------查询最终数据                                                                                                            
select 'BOM' as FDataSource,bills.BillType,bills.FBillNo,bills.F_ora_PINumber,convert(float,bills.FOrderQty) as FQTY                   
,mat1.FNUMBER as FBillMatNumber,mat1_l.FNAME as FBillMatName
,mat2.FNUMBER as FProductNumber,mat2_l.FNAME as FProductName
,mat3.FNUMBER as FMatNumber,mat3_l.FNAME as FMatName,mat3_l.FSPECIFICATION as FMatSpec,eil.FCAPTION as FMatProp                   
,convert(float,bills.FSCRAPRATE) as FScrap
,case when bills.BillType='生产订单' then
	#SCDDPick.FDemandQty
else
	convert(float,CEILING(bills.FDemandQty*(1+bills.FSCRAPRATE/100)))
end as FDemandQty                 
,case when bills.BillType='生产订单' then
	#SCDDPick.FDemandQty
else
	convert(float,CEILING(bills.FDemandQty))
end as FDemandNoScrapQty        
,@Leadtime as FTotalLeadTime,bills.FCalDate,isnull(workCal2.FDAY,DATEADD(d,-1*@Leadtime-2,bills.FCalDate)) FDemandDate
,bills.FID,bills.FEntryID,mat3.FMaterialID                                                                                        
,case when recpe.FEntryID is null then '否' else '是' end FIsComplete                                                             
into #TempResult                                                                                                                 
from #BillExpand bills  
join t_bd_material mat1 on mat1.FMaterialID=bills.FProductID --成品                                                              
join T_BD_MATERIAL_L mat1_l on mat1_l.FMaterialID=mat1.FMATERIALID and mat1_l.FLOCALEID=2052
join t_bd_material mat2 on mat2.FMaterialID=bills.父项物料ID
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
left join #SCDDPick on bills.BillType='生产订单' and bills.FEntryID=#SCDDPick.FEntryID and #SCDDPick.FMATERIALID=bills.FMATERIALID 
where bills.FDemandQty>0

drop table #XSDD,#SCDD,#BillExpand

--创建日期表
CREATE TABLE #AllDayTable(
	FMaterialID int Not NULL,
	FStockQty decimal(28, 10) NULL, --库存数量
	FStockQtyCal decimal(28, 10) NULL, --库存数量(用于计算)
	FTotalDemandQty decimal(28, 10) NULL, --所有日期总需求（毛需求）
	FGrossDemandQty decimal(28, 10) NULL, --day1之前的毛需求
	FNetDemandQty decimal(28, 10) NULL,   --day1之前的净需求
	FLastGrossDemandQty decimal(28, 10) NULL, --day100之后的毛需求
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

--查询日期之前的需求总和
select FMaterialID,sum(FDemandQty) 毛需求数,sum(FDemandNoScrapQty) 净需求数 into #TempResultForPrevDayTotal from #TempResult where FDemandDate<@StartDay group by FMaterialID

--按物料汇总 case when t1.FStockQtyCal>=t2.总需求数 then 0 else t1.FStockQtyCal-t2.总需求数
insert into #AllDayTable(FMaterialID,FStockQty,FStockQtyCal,FTotalDemandQty,FGrossDemandQty,FNetDemandQty)
select t1.FMaterialID,inv.FAvbQty
,case when isnull(inv.FAvbQty,0)-isnull(t2.毛需求数,0)<0 then 0 else isnull(inv.FAvbQty,0)-isnull(t2.毛需求数,0) end --isnull(inv.FAvbQty,0)
,sum(t1.FDemandQty)
,case when inv.FAvbQty>=isnull(t2.毛需求数,0) then isnull(t2.毛需求数,0) else isnull(inv.FAvbQty,0)-isnull(t2.毛需求数,0) end
,case when inv.FAvbQty>=isnull(t2.净需求数,0) then isnull(t2.净需求数,0) else isnull(inv.FAvbQty,0)-isnull(t2.净需求数,0) end
from #TempResult t1 
left join #TempResultForPrevDayTotal t2 on t1.FMATERIALID=t2.FMATERIALID 
left join T_BD_MATERIAL t3 on t1.FMATERIALID=t3.FMATERIALID
outer apply (select sum(FBaseQTY - FBaseLOCKQTY) FAvbQty from T_STK_INVENTORY o1t1 
	join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT3='MTO'/* 仓库标识“TOC属性”=MTO仓库*/
	where FBaseQTY - FBaseLOCKQTY>0 and o1t1.FMaterialID=t3.FMASTERID 
) inv 
group by t1.FMaterialID,inv.FAvbQty,t2.毛需求数,t2.净需求数

--按物料+日期汇总
select FMaterialID,FDemandDate,sum(FDemandQty) 总需求数
into #TempResultForDayTotal from #TempResult group by FMaterialID,FDemandDate

declare @NowDay datetime=@StartDay
declare @IndexDay int=1
--while(@NowDay<='2020-12-16')
while(DATEDIFF(d, @StartDay,@NowDay)<100) --小于3：共3天，小于等于3：共4天
begin --begin1
	--负数代表缺多少，正数代表不缺
	--if 前面日期计算剩余库存>=11月6号的毛需求总和
	--then 11月6号的毛需求总和
	--else 前面日期计算剩余库存-11月6号的毛需求总和
	--剩余库存-11月6号的毛需求总和
	exec('update t1 set FDemandQtyDay'+@IndexDay+'=(case when t1.FStockQtyCal>=t2.总需求数 then t2.总需求数 else t1.FStockQtyCal-t2.总需求数 end),FStockQtyCal=(case when t1.FStockQtyCal-t2.总需求数<0 then 0 else t1.FStockQtyCal-t2.总需求数 end) from #AllDayTable t1 join #TempResultForDayTotal t2 on t1.FMaterialID=t2.FMATERIALID and t2.FDemandDate='''+@NowDay+'''')

	--if @IndexDay=1
	--	set @NowDay='2017-01-06'
	--if @IndexDay=2
	--	set @NowDay='2020-12-16'
	--if @IndexDay>2
	--	set @NowDay='2020-12-17'
	set @NowDay=DATEADD(d,1,@NowDay)--日期加一
	set @IndexDay=@IndexDay+1
end --begin1

--查询最后的日期之后的需求总和
select FMaterialID,sum(FDemandQty) 总需求数 into #TempResultForNextDayTotal from #TempResult where FDemandDate>DATEADD(d,99,@StartDay) group by FMaterialID
update t1 set FLastGrossDemandQty=(case when t1.FStockQtyCal>=t2.总需求数 then t2.总需求数 else t1.FStockQtyCal-t2.总需求数 end)
	,FStockQtyCal=(case when t1.FStockQtyCal-t2.总需求数<0 then 0 else t1.FStockQtyCal-t2.总需求数 end)
	from #AllDayTable t1 join #TempResultForNextDayTotal t2 on t1.FMaterialID=t2.FMATERIALID

--在途数=采购订单未入库数量
select t2.FMaterialID,sum(t3.FREMAINSTOCKINQTY) FQTY
into #POOrderNoInStock from t_PUR_POOrder t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A'
join T_PUR_POORDERENTRY_R t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--在途数=委外订单未入库数量
select t2.FMaterialID,sum(t3.FNOSTOCKINQTY) FQTY
into #ReqOrderNoInStock from T_SUB_REQORDER t1 
join T_SUB_REQORDERENTRY t2 on t1.FID=t2.FID and t2.FSTATUS<>'6' and t2.FSTATUS<>'7' and t1.FDOCUMENTSTATUS='C' and t1.FCANCELSTATUS='A'
join T_SUB_REQORDERENTRY_A t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--VMI待检数（收料通知单类型=VMI收料单）未入库数量
--select * from t_BAS_BILLTYPE_L where FNAME='VMI收料单'
select t2.FMATERIALID,sum(t2.FACTRECEIVEQTY-t3.FINSTOCKQTY) FNoStockInQty into #VMIWaitCheck from T_PUR_Receive t1 
join T_PUR_ReceiveEntry t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t1.FDocumentStatus='C' and t1.FCANCELSTATUS='A' and t2.FMRPCLOSESTATUS='A' 
and t1.FBillTypeID='0023240234df807511e3089ad113642a'
join T_PUR_ReceiveEntry_S t3 on t2.FEntryID=t3.FEntryID
group by t2.FMATERIALID

--待检数（收料通知单类型=MTO标准收料+MTO委外收料+标准收料单）未入库数量
select t2.FMATERIALID,sum(t2.FACTRECEIVEQTY-t3.FINSTOCKQTY) FNoStockInQty into #WaitCheck from T_PUR_Receive t1 
join T_PUR_ReceiveEntry t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t1.FDocumentStatus='C' and t1.FCANCELSTATUS='A' and t2.FMRPCLOSESTATUS='A' 
and (
t1.FBillTypeID='607e7efa17f76b' or --MTO标准收料
t1.FBillTypeID='607e804017faff' or --MTO委外收料
t1.FBillTypeID='7cd93c259999489c97798063f2f7bd70' --标准收料单
)
join T_PUR_ReceiveEntry_S t3 on t2.FEntryID=t3.FEntryID
where t2.FACTRECEIVEQTY-t3.FINSTOCKQTY>0
group by t2.FMATERIALID

--VMI原材料库存（仓库属性=供应商仓库）库存数量
select o1t1.FMaterialID,sum(FBaseQTY - FBaseLOCKQTY) FAvbQty into #VMIInventory from T_STK_INVENTORY o1t1 
	join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.FSTOCKPROPERTY='3'--仓库属性=供应商仓库
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
,convert(float,t1.FDemandQtyDay1 )	第1天
,convert(float,t1.FDemandQtyDay2 )	第2天
,convert(float,t1.FDemandQtyDay3 )	第3天
,convert(float,t1.FDemandQtyDay4 )	第4天
,convert(float,t1.FDemandQtyDay5 )	第5天
,convert(float,t1.FDemandQtyDay6 )	第6天
,convert(float,t1.FDemandQtyDay7 )	第7天
,convert(float,t1.FDemandQtyDay8 )	第8天
,convert(float,t1.FDemandQtyDay9 )	第9天
,convert(float,t1.FDemandQtyDay10 )	第10天
,convert(float,t1.FDemandQtyDay11 )	第11天
,convert(float,t1.FDemandQtyDay12 )	第12天
,convert(float,t1.FDemandQtyDay13 )	第13天
,convert(float,t1.FDemandQtyDay14 )	第14天
,convert(float,t1.FDemandQtyDay15 )	第15天
,convert(float,t1.FDemandQtyDay16 )	第16天
,convert(float,t1.FDemandQtyDay17 )	第17天
,convert(float,t1.FDemandQtyDay18 )	第18天
,convert(float,t1.FDemandQtyDay19 )	第19天
,convert(float,t1.FDemandQtyDay20 )	第20天
,convert(float,t1.FDemandQtyDay21 )	第21天
,convert(float,t1.FDemandQtyDay22 )	第22天
,convert(float,t1.FDemandQtyDay23 )	第23天
,convert(float,t1.FDemandQtyDay24 )	第24天
,convert(float,t1.FDemandQtyDay25 )	第25天
,convert(float,t1.FDemandQtyDay26 )	第26天
,convert(float,t1.FDemandQtyDay27 )	第27天
,convert(float,t1.FDemandQtyDay28 )	第28天
,convert(float,t1.FDemandQtyDay29 )	第29天
,convert(float,t1.FDemandQtyDay30 )	第30天
,convert(float,t1.FDemandQtyDay31 )	第31天
,convert(float,t1.FDemandQtyDay32 )	第32天
,convert(float,t1.FDemandQtyDay33 )	第33天
,convert(float,t1.FDemandQtyDay34 )	第34天
,convert(float,t1.FDemandQtyDay35 )	第35天
,convert(float,t1.FDemandQtyDay36 )	第36天
,convert(float,t1.FDemandQtyDay37 )	第37天
,convert(float,t1.FDemandQtyDay38 )	第38天
,convert(float,t1.FDemandQtyDay39 )	第39天
,convert(float,t1.FDemandQtyDay40 )	第40天
,convert(float,t1.FDemandQtyDay41 )	第41天
,convert(float,t1.FDemandQtyDay42 )	第42天
,convert(float,t1.FDemandQtyDay43 )	第43天
,convert(float,t1.FDemandQtyDay44 )	第44天
,convert(float,t1.FDemandQtyDay45 )	第45天
,convert(float,t1.FDemandQtyDay46 )	第46天
,convert(float,t1.FDemandQtyDay47 )	第47天
,convert(float,t1.FDemandQtyDay48 )	第48天
,convert(float,t1.FDemandQtyDay49 )	第49天
,convert(float,t1.FDemandQtyDay50 )	第50天
,convert(float,t1.FDemandQtyDay51 )	第51天
,convert(float,t1.FDemandQtyDay52 )	第52天
,convert(float,t1.FDemandQtyDay53 )	第53天
,convert(float,t1.FDemandQtyDay54 )	第54天
,convert(float,t1.FDemandQtyDay55 )	第55天
,convert(float,t1.FDemandQtyDay56 )	第56天
,convert(float,t1.FDemandQtyDay57 )	第57天
,convert(float,t1.FDemandQtyDay58 )	第58天
,convert(float,t1.FDemandQtyDay59 )	第59天
,convert(float,t1.FDemandQtyDay60 )	第60天
,convert(float,t1.FDemandQtyDay61 )	第61天
,convert(float,t1.FDemandQtyDay62 )	第62天
,convert(float,t1.FDemandQtyDay63 )	第63天
,convert(float,t1.FDemandQtyDay64 )	第64天
,convert(float,t1.FDemandQtyDay65 )	第65天
,convert(float,t1.FDemandQtyDay66 )	第66天
,convert(float,t1.FDemandQtyDay67 )	第67天
,convert(float,t1.FDemandQtyDay68 )	第68天
,convert(float,t1.FDemandQtyDay69 )	第69天
,convert(float,t1.FDemandQtyDay70 )	第70天
,convert(float,t1.FDemandQtyDay71 )	第71天
,convert(float,t1.FDemandQtyDay72 )	第72天
,convert(float,t1.FDemandQtyDay73 )	第73天
,convert(float,t1.FDemandQtyDay74 )	第74天
,convert(float,t1.FDemandQtyDay75 )	第75天
,convert(float,t1.FDemandQtyDay76 )	第76天
,convert(float,t1.FDemandQtyDay77 )	第77天
,convert(float,t1.FDemandQtyDay78 )	第78天
,convert(float,t1.FDemandQtyDay79 )	第79天
,convert(float,t1.FDemandQtyDay80 )	第80天
,convert(float,t1.FDemandQtyDay81 )	第81天
,convert(float,t1.FDemandQtyDay82 )	第82天
,convert(float,t1.FDemandQtyDay83 )	第83天
,convert(float,t1.FDemandQtyDay84 )	第84天
,convert(float,t1.FDemandQtyDay85 )	第85天
,convert(float,t1.FDemandQtyDay86 )	第86天
,convert(float,t1.FDemandQtyDay87 )	第87天
,convert(float,t1.FDemandQtyDay88 )	第88天
,convert(float,t1.FDemandQtyDay89 )	第89天
,convert(float,t1.FDemandQtyDay90 )	第90天
,convert(float,t1.FDemandQtyDay91 )	第91天
,convert(float,t1.FDemandQtyDay92 )	第92天
,convert(float,t1.FDemandQtyDay93 )	第93天
,convert(float,t1.FDemandQtyDay94 )	第94天
,convert(float,t1.FDemandQtyDay95 )	第95天
,convert(float,t1.FDemandQtyDay96 )	第96天
,convert(float,t1.FDemandQtyDay97 )	第97天
,convert(float,t1.FDemandQtyDay98 )	第98天
,convert(float,t1.FDemandQtyDay99 )	第99天
,convert(float,t1.FDemandQtyDay100) 	第100天
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