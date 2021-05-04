create Procedure zskd_sp_CGHHDTGJBYSJ2(@Leadtime int,@filterStr varchar(max))
as
--@Leadtime 提前期
--采购回货动态跟进表元数据

declare @FUseOrg int = (select FORGID from T_ORG_ORGANIZATIONS where FNUMBER= '100.1') --使用组织 广东英得尔

--最高版本BOM临时表
select * into #HigherBOM  from (select ROW_NUMBER() over(partition by FMATERIALID order by FNumber desc) OrderIndex,* from T_ENG_BOM where FDOCUMENTSTATUS = 'C' AND FFORBIDSTATUS <> 'B' and FUSEORGID=@FUseOrg) bom 
where OrderIndex=1
CREATE CLUSTERED INDEX HigherBOM_I39cddd1a6a734e05b8bc3b80a5023 ON #HigherBOM (OrderIndex,FID);

--工作日历
declare @WorkCalID int =(select top 1 FID from T_ENG_WORKCAL where FFormID='ENG_WorkCal' and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FUSEORGID=@FUseOrg order by FAPPROVEDATE desc)
--declare @WorkCalID int =100653

select  '销售订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t4.FREMAINOUTQTY FRemainOutQty
,convert(varchar(10),t2.F_ora_ProdFinishDate,23) FCalDate,t2.F_ora_PINumber F_ora_PINumber 
into #XSDD
from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FSALEORGID=@FUseOrg
join T_SAL_ORDERENTRY_R t4 on t4.FENTRYID=t2.FENTRYID and t4.FREMAINOUTQTY>0

select '生产订单' BillType,t1.FBillNo,t1.FID,t2.FEntryID,t2.FMATERIALID FProductID,t2.FQTY FOrderQty,t3.FNOSTOCKINQTY FRemainOutQty
,t2.FPlanFinishDate FCalDate,t2.F_ora_PINumber F_ora_PINumber
into #SCDD
from T_PRD_MO t1 join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C'  --todo 加条件单据类型
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID and t3.FNOSTOCKINQTY>0

----------------------------------------------------------已生成送货计划单的物料数量
select FDEMANDBILLID,FDemandEntryId,FMaterialID,sum(FACTRECEIVEQTY) FACTRECEIVEQTY 
into #T_PUR_ReceivePlanEntry from T_PUR_ReceivePlanEntry where FDEMANDBILLID>0 and FDemandEntryId>0 and FMaterialID>0 
group by FDEMANDBILLID,FDemandEntryId,FMaterialID

--------------------------------------------------------查询最终数据                                                                                                            
select 'BOM' as FDataSource,bills.BillType,bills.FBillNo,bills.F_ora_PINumber,convert(float,bills.FOrderQty) as FQTY                   
,pro.FNUMBER as FBillMatNumber,pro_l.FNAME as FBillMatName                                                                      
,mat2.FNUMBER as FProductNumber,mat2_l.FNAME as FProductName                                                                      
,mat3.FNUMBER as FMatNumber,mat3_l.FNAME as FMatName,mat3_l.FSPECIFICATION as FMatSpec,eil.FCAPTION as FMatProp                   
,convert(float,isnull(bomc3.FSCRAPRATE,bomc2.FSCRAPRATE)) as FScrap                          
,convert(float,CEILING(bills.FRemainOutQty*(1+isnull(bomc3.FSCRAPRATE,bomc2.FSCRAPRATE)/100))) as FDemandQty                 
,convert(float,CEILING(bills.FRemainOutQty)) as FDemandNoScrapQty          
,@Leadtime as FTotalLeadTime,bills.FCalDate,isnull(workCal2.FDAY,DATEADD(d,@Leadtime+2,bills.FCalDate)) FDemandDate
,bills.FID,bills.FEntryID,isnull(mat3.FMaterialID,mat2.FMaterialID)
,case when recpe.FMaterialID is null then '否' else '是' end FIsComplete        
,isnull(recpe.FACTRECEIVEQTY,0) FACTRECEIVEQTY
into #ResultTable                                                                                                                 
from(select * from #SCDD union all select * from #XSDD  ) bills
--第一层
join t_bd_material pro on pro.FMaterialID=bills.FProductID --成品                                                              
join T_BD_MATERIAL_L pro_l on pro_l.FMaterialID=pro.FMATERIALID and pro_l.FLOCALEID=2052
--第二层
left join #HigherBOM bom1 on bom1.FMaterialID=bills.FProductID
left join T_ENG_BOMChild bomc1 on bomc1.FID=bom1.FID
left join t_bd_material mat1 on mat1.FMaterialID=bomc1.FMaterialID
left join T_BD_MATERIAL_L mat1_l on mat1_l.FMaterialID=mat1.FMATERIALID and mat1_l.FLOCALEID=2052
--第三层
left join #HigherBOM bom2 on bom2.FMaterialID=bomc1.FMaterialID
left join T_ENG_BOMChild bomc2 on bomc2.FID=bom2.FID
left join t_bd_material mat2 on mat2.FMaterialID=bomc2.FMaterialID
left join T_BD_MATERIAL_L mat2_l on mat2_l.FMaterialID=mat2.FMATERIALID and mat2_l.FLOCALEID=2052
left join T_BD_MATERIALBASE mat2b on mat2b.FMATERIALID=mat2.FMaterialID                                                           
left join T_META_FORMENUMITEM enumitem2 on enumitem2.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and enumitem2.FVALUE=mat2b.FERPCLSID 
left join T_META_FORMENUMITEM_L eil2 on eil2.FENUMID=enumitem2.FENUMID and eil2.FLOCALEID=2052        
--第四层
left join #HigherBOM bom3 on bom3.FMaterialID=bomc2.FMaterialID
left join T_ENG_BOMChild bomc3 on bomc3.FID=bom3.FID
left join t_bd_material mat3 on mat3.FMaterialID=bomc3.FMaterialID
left join T_BD_MATERIAL_L mat3_l on mat3_l.FMaterialID=mat3.FMATERIALID and mat3_l.FLOCALEID=2052
left join T_BD_MATERIALBASE mat3b on mat3b.FMATERIALID=mat3.FMaterialID                                                           
left join T_META_FORMENUMITEM enumitem3 on enumitem3.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and enumitem3.FVALUE=mat3b.FERPCLSID 
left join T_META_FORMENUMITEM_L eil3 on eil3.FENUMID=enumitem3.FENUMID and eil3.FLOCALEID=2052        
                                 
left join T_ENG_WORKCALDATA workCal on workCal.FID=@WorkCalID and workCal.FDAY=bills.FCalDate
left join T_ENG_WORKCALDATA workCal2 on workCal2.FID=@WorkCalID and workCal2.FINTERID=workCal.FINTERID - @Leadtime
left join #T_PUR_ReceivePlanEntry recpe on recpe.FDEMANDBILLID=bills.FID and recpe.FDemandEntryId=bills.FEntryID and recpe.FMaterialID=isnull(mat3.FMATERIALID,mat2.FMATERIALID)
where bills.FRemainOutQty>0

declare @sqlStr varchar(max) ='select * from #ResultTable'
if @filterStr<>'' and @filterStr is not null
begin
	set @sqlStr=@sqlStr+' where '+@filterStr
end
exec(@sqlStr)

drop table #XSDD,#SCDD,#ResultTable

go

exec zskd_sp_CGHHDTGJBYSJ2 9,''