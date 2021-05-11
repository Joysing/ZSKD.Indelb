alter Procedure zskd_sp_CGHHDTGJBYSJ(@Leadtime int,@filterStr varchar(max))
as
--@Leadtime 提前期
--采购回货动态跟进表元数据

--------------------------------------------------------展开物料（销售订单）
create table #T_ENG_BOMEXPANDRESULT(
	FLevelNumber VARCHAR(100) NULL,
	FBOMLevel VARCHAR(100) NULL,
	产品ID INT NULL,
	FTopID INT NULL,
	FBOMID INT NULL,
	FREPLACEGROUP INT NULL, 
	BOM版本 VARCHAR(100) NULL, 
	父项物料ID INT NULL,
	父项物料编码 VARCHAR(100) NULL,
	子项物料ID INT NULL,
	子项物料编码 VARCHAR(100) NULL,
	分子 DECIMAL(28,10) NULL,
	分母 DECIMAL(28,10) NULL,
	损耗率 DECIMAL(28,10) NULL,
	标准用量 DECIMAL(28,10) NULL,
	实际算损耗用量 DECIMAL(28,10) NULL,
	FRowID VARCHAR(100) NULL,
	FParentRowID VARCHAR(100) NULL,
	是否最底层物料 INT NULL, 
)
declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --使用组织 广东英得尔

--需要展开的物料
-- select distinct FMATERIALID into #NeedExpandMat from T_ENG_BOM where FUSEORGID=@FUseOrg
select distinct t2.FMATERIALID into #NeedExpandMat
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FSALEORGID=@FUseOrg

--最高版本BOM临时表
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* from T_ENG_BOM where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

declare @NowIndex int =(select min(FMATERIALID) from #NeedExpandMat)
declare @MaxIndex int =(select max(FMATERIALID) from #NeedExpandMat)
WHILE @NowIndex<=@MaxIndex
BEGIN --begin1
	print @NowIndex
	/*
		金蝶云星空物料清单正查
	**/
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

--工作日历
declare @WorkCalID int =(select top 1 FID from T_ENG_WORKCAL where FFormID='ENG_WorkCal' and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FUSEORGID=@FUseOrg order by FAPPROVEDATE desc)
--declare @WorkCalID int =100653

select  '销售订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.子项物料ID FMATERIALID,t3.标准用量*t4.FREMAINOUTQTY FDemandQty
,t3.损耗率 FSCRAPRATE,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber 
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FSALEORGID=@FUseOrg
join #T_ENG_BOMEXPANDRESULT t3 on t3.产品ID=t2.FMATERIALID and t3.是否最底层物料=1
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID

--------------------------------------------------------展开物料（生产订单）
select '生产订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FMATERIALID,t4.FMUSTQTY-t5.FPICKEDQTY FDemandQty
,t4.FSCRAPRATE,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C'  --todo 加条件单据类型
join T_PRD_PPBOM t3 on t3.FMOENTRYID=t2.FENTRYID
join T_PRD_PPBOMENTRY t4 on t3.FID=t4.FID
join T_PRD_PPBOMENTRY_Q t5 on t4.FENTRYID=t5.FENTRYID and t4.FMUSTQTY-t5.FPICKEDQTY>0

----------------------------------------------------------已生成送货计划单的物料数量
select FDEMANDBILLID,FDemandEntryId,FMaterialID,sum(FACTRECEIVEQTY) FACTRECEIVEQTY 
into #T_PUR_ReceivePlanEntry from T_PUR_ReceivePlanEntry where FDEMANDBILLID>0 and FDemandEntryId>0 and FMaterialID>0 
group by FDEMANDBILLID,FDemandEntryId,FMaterialID

--------------------------------------------------------查询最终数据                                                                                                            
select 'BOM' as FDataSource,bills.BillType,bills.FBillNo,bills.F_ora_PINumber,convert(float,bills.FOrderQty) as FQTY                   
,mat1.FNUMBER as FBillMatNumber,mat1_l.FNAME as FBillMatName                                                                      
--,mat2.FNUMBER as FProductNumber,mat2_l.FNAME as FProductName                                                                      
,mat3.FNUMBER as FMatNumber,mat3_l.FNAME as FMatName,mat3_l.FSPECIFICATION as FMatSpec,eil.FCAPTION as FMatProp                   
,convert(float,bills.FSCRAPRATE) as FScrap                          
,convert(float,CEILING(bills.FDemandQty*(1+bills.FSCRAPRATE/100))) as FDemandQty                 
,convert(float,CEILING(bills.FDemandQty)) as FDemandNoScrapQty          
,@Leadtime as FTotalLeadTime,bills.FCalDate,isnull(workCal2.FDAY,DATEADD(d,@Leadtime+2,bills.FCalDate)) FDemandDate
,bills.FID,bills.FEntryID,mat3.FMaterialID                                                                                        
,case when recpe.FMaterialID is null then '否' else '是' end FIsComplete        
,isnull(recpe.FACTRECEIVEQTY,0) FACTRECEIVEQTY
into #ResultTable                                                                                                                 
from(select * from #SCDD union all select * from #XSDD  ) bills                               
join t_bd_material mat1 on mat1.FMaterialID=bills.FProductID --成品                                                              
join T_BD_MATERIAL_L mat1_l on mat1_l.FMaterialID=mat1.FMATERIALID and mat1_l.FLOCALEID=2052
join t_BD_MaterialPlan mat1p on mat1p.FMATERIALID=mat1.FMATERIALID
join t_bd_material mat3 on mat3.FMaterialID=bills.FMATERIALID
left join T_BD_MATERIAL_L mat3_l on mat3_l.FMaterialID=bills.FMATERIALID and mat3_l.FLOCALEID=2052                                
left join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=mat3.FMaterialID                                                           
left join T_META_FORMENUMITEM enumitem on enumitem.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and enumitem.FVALUE=mat3b.FERPCLSID 
left join T_META_FORMENUMITEM_L eil on eil.FENUMID=enumitem.FENUMID and eil.FLOCALEID=2052                                       
left join T_ENG_WORKCALDATA workCal on workCal.FID=@WorkCalID and workCal.FDAY=bills.FCalDate
left join T_ENG_WORKCALDATA workCal2 on workCal2.FID=@WorkCalID and workCal2.FINTERID=workCal.FINTERID - @Leadtime
left join #T_PUR_ReceivePlanEntry recpe on recpe.FDEMANDBILLID=bills.FID and recpe.FDemandEntryId=bills.FEntryID and recpe.FMaterialID=mat3.FMATERIALID
where bills.FDemandQty>0

declare @sqlStr varchar(max) ='select * from #ResultTable'
if @filterStr<>'' and @filterStr is not null
begin
	set @sqlStr=@sqlStr+' where '+@filterStr
end
exec(@sqlStr)

drop table #NeedExpandMat,#T_ENG_BOMEXPANDRESULT,#XSDD,#SCDD,#ResultTable

go

--exec zskd_sp_CGHHDTGJBYSJ 9,''