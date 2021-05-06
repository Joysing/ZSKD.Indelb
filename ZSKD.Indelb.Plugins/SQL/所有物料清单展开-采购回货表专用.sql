alter Procedure zskd_sp_InsertBOMExpandTemp_CGHHB
as
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB]') AND type in (N'U'))
begin
	--drop table ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB
	create table ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB(
		FLevelNumber VARCHAR(100) NULL,
		FBOMLevel VARCHAR(100) NULL,
		��ƷID INT NULL,
		FTopID INT NULL,--��ǰչ���Ķ���BOM
		FBOMID INT NULL,--��ǰ��ε�BOM
		FREPLACEGROUP INT NULL, 
		BOM�汾 VARCHAR(100) NULL, --��ǰ��ε�BOM
		��������ID INT NULL,
		�������ϱ��� VARCHAR(100) NULL,
		��������ID INT NULL,
		�������ϱ��� VARCHAR(100) NULL,
		���� DECIMAL(28,10) NULL,
		��ĸ DECIMAL(28,10) NULL,
		����� DECIMAL(28,10) NULL,
		��׼���� DECIMAL(28,10) NULL,
		ʵ����������� DECIMAL(28,10) NULL,
		FRowID VARCHAR(100) NULL,
		FParentRowID VARCHAR(100) NULL,
		�Ƿ���ײ����� INT NULL, 
		FModifyDate datetime null
	)
	CREATE NONCLUSTERED INDEX ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB_Index_ProductID ON ZSKD_T_ENG_BOMEXPANDRESULT
	(
		��ƷID ASC,
		��������ID ASC,
		FTopID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

end
--declare @FUseOrg int = 1 --ʹ����֯ 
declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --ʹ����֯ �㶫Ӣ�ö�
declare @OldDataMaxModifyDate datetime=(select max(FModifyDate) from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB)--��չ����BOM�����µ�����

select '��������' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.FNOSTOCKINQTY FRemainOutQty
,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber,t2.FSALEORDERENTRYID
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FBillType='6078fc63c1d3ba'
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID and t3.FNOSTOCKINQTY>0

select  '���۶���' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FREMAINOUTQTY FRemainOutQty
,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber,0 FSALEORDERENTRYID
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FSALEORGID=@FUseOrg
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID and t4.FREMAINOUTQTY>0
left join #SCDD on #SCDD.FSALEORDERENTRYID=t2.FENTRYID
where #SCDD.FSALEORDERENTRYID is null --ȥ����������������������

--��߰汾BOM��ʱ��
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* 
	from T_ENG_BOM 
	where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

--��Ҫչ�������ϣ������޸ĵ�������������
select distinct FMATERIALID into #NeedExpandMat from #HigherBOM t1
join (select FProductID from #SCDD union all select FProductID from #XSDD) t2 on t1.FMATERIALID=t2.FProductID
where FMODIFYDATE>isnull(@OldDataMaxModifyDate,'1900-01-01')
--δչ���İ汾
insert into #NeedExpandMat(FMATERIALID)select t1.FMATERIALID from #HigherBOM t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.FMATERIALID=t2.FProductID
left join ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t3 on t1.FID=t3.FTopID where t3.FTopID is null
--�����ڵģ�����˻���û�ɾ������BOMҲ��������
insert into #NeedExpandMat(FMATERIALID)select ��������ID from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.��ƷID=t2.FProductID
left join #HigherBOM t3 on t1.FTopID=t3.FID where t1.FBOMLevel=0 and t3.FID is null
--���飬����������ϵ�BOMҲҪ����
insert into #NeedExpandMat(FMATERIALID)select ��ƷID from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB t1 
join (select distinct FProductID from (select FProductID from #SCDD union all select FProductID from #XSDD) dd) t2 on t1.��ƷID=t2.FProductID
join #NeedExpandMat t3 on t1.��������ID=t3.FMATERIALID

declare @NowIndex int =(select min(FMATERIALID) from #NeedExpandMat)
declare @MaxIndex int =(select max(FMATERIALID) from #NeedExpandMat)
WHILE @NowIndex<=@MaxIndex
BEGIN --begin1
	print @NowIndex
	/*
		������ǿ������嵥����
	**/
	declare @FMaterialID int
	declare @FBOMID int
	declare @FQty decimal(28,10)=1
	set @FMaterialID=@NowIndex;
	--ɾ��������
	delete from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB where ��ƷID=@FMaterialID;

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
	select t.*,GETDATE() FModifyDate into #T_ENG_BOMEXPANDRESULTInOne from CET t order by t.FLevelNumber;

	--���붥��������
	insert into #T_ENG_BOMEXPANDRESULTInOne (FLevelNumber,FBOMLevel,FTopID,FBOMID,FREPLACEGROUP, BOM�汾, ��������ID,�������ϱ���,��������ID,�������ϱ���,����,��ĸ,��׼����,ʵ�����������,FRowID,FParentRowID,FModifyDate)
	select top 1 '000' as FLevelNumber,0 as FBOMLevel,FTopID,FBOMID,0 FREPLACEGROUP,'',0,'',@FMaterialID,'',0,0,@FQty,@FQty,NEWID(),'',GETDATE()
	from #T_ENG_BOMEXPANDRESULTInOne 

	update t1 set FParentRowID=t2.FRowID from #T_ENG_BOMEXPANDRESULTInOne t1 join #T_ENG_BOMEXPANDRESULTInOne t2 on t1.��������ID=t2.��������ID
	update t1 set FModifyDate=t2.FModifyDate from #T_ENG_BOMEXPANDRESULTInOne t1 join T_ENG_BOM t2 on t1.FTopID=t2.FID
	--�ݹ�չ�������嵥���� end

	insert into ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB(FLevelNumber,FBOMLevel,��ƷID,FTopID,FBOMID,FREPLACEGROUP, BOM�汾, ��������ID,�������ϱ���,��������ID,�������ϱ���,����,��ĸ
	,�����,��׼����,ʵ�����������,FRowID,FParentRowID,�Ƿ���ײ�����,FModifyDate)
	select t1.FLevelNumber,t1.FBOMLevel,@NowIndex,t1.FTopID,t1.FBOMID,t1.FREPLACEGROUP
	, t1.BOM�汾, t1.��������ID,t1.�������ϱ���,t1.��������ID,t1.�������ϱ���,t1.����,t1.��ĸ,�����,t1.��׼����,t1.ʵ�����������,t1.FRowID,t1.FParentRowID
		,case when t2.FMATERIALID is null then 1 else 0 end �Ƿ���ײ�����,t1.FModifyDate
	from #T_ENG_BOMEXPANDRESULTInOne t1 left join #HigherBOM t2 on t1.��������ID=t2.FMATERIALID
	
	order by FLevelNumber;
	drop table #T_ENG_BOMEXPANDRESULTInOne

	set @NowIndex=(select min(FMATERIALID) from #NeedExpandMat where FMATERIALID>@NowIndex)
END --begin1

--select * from ZSKD_T_ENG_BOMEXPANDRESULT_CGHHB where FBOMLevel=0  ORDER BY ��ƷID,FLevelNumber
drop table #HigherBOM,#NeedExpandMat,#SCDD,#XSDD

go

exec zskd_sp_InsertBOMExpandTemp_CGHHB