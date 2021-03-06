alter Procedure zskd_sp_PMCColorReport(@IsUpdate int=0,@PINumber varchar(100)='')
as
--MTO
--黑色：已过交货日期
--红色：交货日期当天
--黄色：交货日期前1和2天
--绿色：交货日期前3和4天
--蓝色：交货日期前5天以上
--MTA:
--按照MTA仓库库存区分
--黑：低于安全库存值1%
--红：低于安全库存值99-66%区间
--黄：低于安全库存值65-35%区间
--绿：低于安全库存值34-0%区间
--蓝：大于安全库存值

--取最新工作日历
declare @WorkCalID int =(select top 1 FID from T_ENG_WORKCAL where FFormID='ENG_WorkCal' and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FUSEORGID=100102 order by FAPPROVEDATE desc)

--取MTA所有仓库的库存数
select o1t1.FMaterialID,sum(FBASEQTY - FBASElockQTY) FAvbQtyinto #Inventory from T_STK_INVENTORY o1t1 join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT4='MTA' group by o1t1.FMaterialID

select * into #T_PRD_MOENTRY from T_PRD_MOENTRY
declare @update_ varchar(10) = 'update'
exec(''+ @update_ +' t2 set FSALEORDERENTRYID=t1.FENTRYID,FSALEORDERID=t1.FID
 from T_SAL_ORDERENTRY t1 join #T_PRD_MOENTRY t2 on t1.F_ora_PINumber=t2.F_ora_PINumber and t2.FSALEORDERENTRYID=0 and t2.FSALEORDERID=0')

select * into #ResultTable from(
--销售订单-MTO
select t7.F_ora_PINumber as '加工单号F_ORA_PINUMBER'
,t2.FQTY as '计划数量OriginQty'
,t3.FSTOCKINQUAAUXQTY as '完工数量PrtdQty'
,t2.FQTY-t3.FSTOCKINQUAAUXQTY as '未完工数量'
,t4.FSPECIFICATION as 'SKU描述'
,t4.FName as '物料名称'
,t7.F_ora_ProdFinishDate as '交货日期'
,case when convert(date,isnull(t3.FFINISHDATE,GETDATE()))>t7.F_ora_ProdFinishDate then '黑色'
	when convert(date,isnull(t3.FFINISHDATE,GETDATE()))=t7.F_ora_ProdFinishDate then '红色'
	when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t7.F_ora_ProdFinishDate) between 1 and 2 then '黄色'
	when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t7.F_ora_ProdFinishDate) between 3 and 4 then '绿色'
	when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t7.F_ora_ProdFinishDate)>=5 then '蓝色'
	else '' end as '缓冲侵蚀颜色'
,workCal2.FDAY as '建议投料日' --交货日期减去5天，只计算工作日
,t3.FSTARTDATE as '实际投料日'
,t3.FFINISHDATE as '实际完工日期'
,DATEDIFF(d,t3.FSTARTDATE,t3.FFINISHDATE) as 'PLT'
,t5.FMEMO as '备注'
,t9.FNAME as '客户'
,t6.FNUMBER as 'SKU'
,case when t7.F_ora_TOCType='MTA' then '库存' when t7.F_ora_TOCType='MTO' then 'Order' end as '订单类型'  --F_ora_TOCType  库存=MTA  Order=MTO  
,DATEDIFF(d,convert(date,GETDATE()),t7.F_ora_ProdFinishDate) as '离交货期天数'
from T_PRD_MO t1
join #T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C'
join T_PRD_MOENTRY_A t3 on t3.FENTRYID=t2.FENTRYID --and t3.FCreateType<>'7' --生成方式不等于“订单展开”，即不需要通过“生成下级生产订单”生成的
left join T_BD_MATERIAL_L t4 on t4.FMATERIALID=t2.FMATERIALID and t4.FLOCALEID=2052
left join T_PRD_MOENTRY_L t5 on t5.FENTRYID=t2.FENTRYID and t5.FLOCALEID=2052
join T_BD_MATERIAL t6 on t6.FMATERIALID=t2.FMATERIALID
join T_SAL_ORDERENTRY t7 on t7.FENTRYID=t2.FSALEORDERENTRYID and t7.FID=t2.FSALEORDERID
join T_SAL_ORDER t8 on t8.FID=t7.FID --and t7.F_ora_OptOutPurReturn<>1
left join T_BD_CUSTOMER_L t9 on t9.FCUSTID=t8.FCUSTID and t9.FLOCALEID=2052
left join T_ENG_WORKCALDATA workCal on workCal.FID=@WorkCalID and workCal.FDAY=t7.F_ora_ProdFinishDate
left join T_ENG_WORKCALDATA workCal2 on workCal2.FID=@WorkCalID and workCal2.FINTERID=workCal.FINTERID - 5
join T_BD_MATERIALGROUP matg on t6.FMATERIALGROUP=matg.FID and matg.FNUMBER in ('2','3','4','5','6','7')
where (len(@PINumber)=0 or @PINumber=t7.F_ora_PINumber)
union all
--预测单-MTO
select t7.F_ora_PINumber as '加工单号F_ORA_PINUMBER'
,t2.FQTY as '计划数量OriginQty'
,t3.FSTOCKINQUAAUXQTY as '完工数量PrtdQty'
,t2.FQTY-t3.FSTOCKINQUAAUXQTY as '未完工数量'
,t4.FSPECIFICATION as 'SKU描述'
,t4.FName as '物料名称'
,t2.FPLANFINISHDATE as '交货日期'
,case when t7.F_ora_TOCType='MTA' then 
	case when t10.FSAFESTOCK<>0 then
		case when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=1 then '黑色'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<1 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0.66 then '红色'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<0.66 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0.35 then '黄色'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<0.35 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0 then '绿色'
			else '蓝色' end
	else '蓝色' end
	when t7.F_ora_TOCType='MTO' then 
		(case when convert(date,isnull(t3.FFINISHDATE,GETDATE()))>t2.FPLANFINISHDATE then '黑色'
		when convert(date,isnull(t3.FFINISHDATE,GETDATE()))=t2.FPLANFINISHDATE then '红色'
		when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t2.FPLANFINISHDATE) between 1 and 2 then '黄色'
		when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t2.FPLANFINISHDATE) between 3 and 4 then '绿色'
		when DATEDIFF(d,convert(date,isnull(t3.FFINISHDATE,GETDATE())),t2.FPLANFINISHDATE)>=5 then '蓝色'
		end)
	end as '缓冲侵蚀颜色' --F_ora_PMCColor  UpdateAllPMCColor
,workCal2.FDAY as '建议投料日' --交货日期减去5天，只计算工作日
,t3.FSTARTDATE as '实际投料日'
,t3.FFINISHDATE as '实际完工日期'
,DATEDIFF(d,t3.FSTARTDATE,t3.FFINISHDATE) as 'PLT'
,t5.FMEMO as '备注'
,t9.FNAME as '客户'
,t6.FNUMBER as 'SKU'
,case when t7.F_ora_TOCType='MTA' then '库存' when t7.F_ora_TOCType='MTO' then 'Order' end as '订单类型' --F_ora_TOCType  库存=MTA  Order=MTO  
,DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) as '离交货期天数'
from T_PRD_MO t1
join T_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FDocumentStatus='C'
join T_PRD_MOENTRY_A t3 on t3.FENTRYID=t2.FENTRYID --and t3.FCreateType<>'7' --生成方式不等于“订单展开”，即不需要通过“生成下级生产订单”生成的
left join T_BD_MATERIAL_L t4 on t4.FMATERIALID=t2.FMATERIALID and t4.FLOCALEID=2052
left join T_PRD_MOENTRY_L t5 on t5.FENTRYID=t2.FENTRYID and t5.FLOCALEID=2052
join T_BD_MATERIAL t6 on t6.FMATERIALID=t2.FMATERIALID
join T_PRD_MOENTRY_LK t2_lk on t2_lk.FENTRYID=t2.FENTRYID
join T_PLN_FORECASTENTRY t7 on t7.FENTRYID=t2_lk.FSID and t7.FID=t2_lk.FSBillID and t2_lk.FSTABLENAME='T_PLN_FORECASTENTRY'
join T_PLN_FORECAST t8 on t8.FID=t7.FID
left join T_BD_CUSTOMER_L t9 on t9.FCUSTID=t7.FCUSTID and t9.FLOCALEID=2052
join T_BD_MATERIALSTOCK t10 on t10.FMATERIALID=t2.FMATERIALID
left join #Inventory t11 on t11.FMATERIALID=t6.FMASTERID
left join T_ENG_WORKCALDATA workCal on workCal.FID=@WorkCalID and workCal.FDAY=t2.FPLANFINISHDATE 
left join T_ENG_WORKCALDATA workCal2 on workCal2.FID=@WorkCalID and workCal2.FINTERID=workCal.FINTERID - 5
join T_BD_MATERIALGROUP matg on t6.FMATERIALGROUP=matg.FID and matg.FNUMBER in ('2','3','4','5','6','7')
where (len(@PINumber)=0 or @PINumber=t7.F_ora_PINumber)
) t
if @IsUpdate=1 
BEGIN
	update t1 set F_ora_PMCColor=t2.缓冲侵蚀颜色 from T_PRD_MOENTRY t1 join #ResultTable t2 on t1.F_ora_PINumber=t2.加工单号F_ORA_PINUMBER
END
select * from #ResultTable
