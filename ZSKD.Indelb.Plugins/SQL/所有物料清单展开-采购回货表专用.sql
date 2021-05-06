alter Procedure zskd_sp_InsertBOMExpandTemp_CGHHB
as
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB]') AND type in (N'U'))
begin
	--drop table ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB
	create table ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB(
		FLevelNumber VARCHAR(100) NULL,
		FBOMLevel VARCHAR(100) NULL,
		产品ID INT NULL,
		FTopID INT NULL,--当前展开的顶级BOM
		FBOMID INT NULL,--当前层次的BOM
		FREPLACEGROUP INT NULL, 
		BOM版本 VARCHAR(100) NULL, --当前层次的BOM
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
		FModifyDate datetime null
	)
	CREATE NONCLUSTERED INDEX ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB_Index_ProductID ON ZSKD_T_ENG_BOMEXPANDRESULT
	(
		产品ID ASC,
		父项物料ID ASC,
		FTopID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

end
--declare @FUseOrg int = 1 --使用组织 
declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --使用组织 广东英得尔
declare @OldDataMaxModifyDate datetime=(select max(FModifyDate) from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB)--已展开的BOM，最新的日期

select '生产订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.FNOSTOCKINQTY FRemainOutQty
,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber,t2.FSALEORDERENTRYID
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID and t3.FNOSTOCKINQTY>0

select  '销售订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FREMAINOUTQTY FRemainOutQty
,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber,0 FSALEORDERENTRYID
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FSALEORGID=@FUseOrg
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID and t4.FREMAINOUTQTY>0
left join #SCDD on #SCDD.FSALEORDERENTRYID=t2.FENTRYID
where #SCDD.FSALEORDERENTRYID is null --去掉已运算生成生产订单的

--最高版本BOM临时表
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* 
	from T_ENG_BOM 
	where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

--需要展开的物料，最新修改的重新修正进来
select distinct FMATERIALID into #NeedExpandMat from #HigherBOM t1
join (select FProductID from #SCDD union all select FProductID from #XSDD) t2 on t1.FMATERIALID=t2.FProductID
where FMODIFYDATE>isnull(@OldDataMaxModifyDate,'1900-01-01')
--未展开的版本
insert into #NeedExpandMat(FMATERIALID)select t1.FMATERIALID from #HigherBOM t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.FMATERIALID=t2.FProductID
left join ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t3 on t1.FID=t3.FTopID where t3.FTopID is null
--不存在的（反审核或禁用或删除）的BOM也重新修正
insert into #NeedExpandMat(FMATERIALID)select 子项物料ID from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.产品ID=t2.FProductID
left join #HigherBOM t3 on t1.FTopID=t3.FID where t1.FBOMLevel=0 and t3.FID is null
--反查，用了这个物料的BOM也要修正
insert into #NeedExpandMat(FMATERIALID)select 产品ID from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.产品ID=t2.FProductID
join #NeedExpandMat t3 on t1.子项物料ID=t3.FMATERIALID

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
	--删除旧数据
	delete from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB where 产品ID=@FMaterialID;

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
	select t.*,GETDATE() FModifyDate into #T_ENG_BOMEXPANDRESULTInOne from CET t order by t.FLevelNumber;

	--插入顶级父物料
	insert into #T_ENG_BOMEXPANDRESULTInOne (FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM版本, 父项物料ID,父项物料编码,子项物料ID,子项物料编码,分子,分母,标准用量,实际算损耗数量,FRowID,FParentRowID,FModifyDate)
	select top 1 '000' as FLevelNumber,0 as FBOMLevel,FTopID,FBOMID,0 FREPLACEGROUP,'',0,'',@FMaterialID,'',0,0,@FQty,@FQty,NEWID(),'',GETDATE()
	from #T_ENG_BOMEXPANDRESULTInOne 

	update t1 set FParentRowID=t2.FRowID from #T_ENG_BOMEXPANDRESULTInOne t1 join #T_ENG_BOMEXPANDRESULTInOne t2 on t1.父项物料ID=t2.子项物料ID
	update t1 set FModifyDate=t2.FModifyDate from #T_ENG_BOMEXPANDRESULTInOne t1 join T_ENG_BOM t2 on t1.FTopID=t2.FID
	--递归展开物料清单正查 end

	insert into ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB(FLevelNumber,FBOMLevel,产品ID,FTopID,FBOMID,FREPLACEGROUP, BOM版本, 父项物料ID,父项物料编码,子项物料ID,子项物料编码,分子,分母
	,损耗率,标准用量,实际算损耗用量,FRowID,FParentRowID,是否最底层物料,FModifyDate)
	select t1.FLevelNumber,t1.FBOMLevel,@NowIndex,t1.FTopID,t1.FBOMID,t1.FREPLACEGROUP
	, t1.BOM版本, t1.父项物料ID,t1.父项物料编码,t1.子项物料ID,t1.子项物料编码,t1.分子,t1.分母,损耗率,t1.标准用量,t1.实际算损耗数量,t1.FRowID,t1.FParentRowID
		,case when t2.FMATERIALID is null then 1 else 0 end 是否最底层物料,t1.FModifyDate
	from #T_ENG_BOMEXPANDRESULTInOne t1 left join #HigherBOM t2 on t1.子项物料ID=t2.FMATERIALID
	
	order by FLevelNumber;
	drop table #T_ENG_BOMEXPANDRESULTInOne

	set @NowIndex=(select min(FMATERIALID) from #NeedExpandMat where FMATERIALID>@NowIndex)
END --begin1

--select * from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB where FBOMLevel=0  ORDER BY 产品ID,FLevelNumber
drop table #HigherBOM,#NeedExpandMat,#SCDD,#XSDD

go

exec zskd_sp_InsertBOMExpandTemp_CGHHB