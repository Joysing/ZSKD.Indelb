
--在途数=采购订单未入库数量
select t2.FMaterialID,sum(t3.FREMAINSTOCKINQTY) FQTY
into #POOrderNoInStock from t_PUR_POOrder t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A'
join T_PUR_POORDERENTRY_R t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--在制数=MTA生产订单 未入库数量
select t2.FMaterialID,sum(t3.FNOSTOCKINQTY) FQTY
into #MONoInStock from t_PRD_MO t1 
join t_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--取MTA所有仓库的库存数
select o1t1.FMaterialID,sum(FSECQTY - FSECLOCKQTY) FAvbQty
into #Inventory from T_STK_INVENTORY o1t1 
join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT4='MTA' 
group by o1t1.FMaterialID

--取MTA采购订单未检验的数量
select t2.FMaterialID,sum(t2.FQTY-isnull(t3.FCHECKQTY,0)) FQTY
into #POOrderNoCheck
from t_PUR_POOrder t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A' and t2.F_ora_TOCType='MTA'
left join (select t1.FSID,t1.FSBillID,sum(t2.FCHECKQTY) FCHECKQTY from T_PUR_ReceiveEntry_LK t1
join T_PUR_ReceiveEntry_S t2 on t1.FEntryID=t2.FEntryID and t1.FSTABLENAME='t_PUR_POOrderEntry'
group by t1.FSID,t1.FSBillID) t3 on t2.FENTRYID=t3.FSID and t2.FID=t3.FSBillID 
group by t2.FMaterialID

--MTA:
--按照MTA仓库库存区分
--黑色：低于安全库存值100%
--红色：低于安全库存值99-66%区间
--黄色：低于安全库存值65-35%区间
--绿色：低于安全库存值34-0%区间
--蓝色：大于安全库存值
select 
t11.FQTY as 'MTA待检数'
,isnull(t10.FAvbQty,0) as '在库（MTA仓库存数）'
,case when t12.FSAFESTOCK<>0 then (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK else 0 end as '在库BP'
,case when t12.FSAFESTOCK+t9.FQTY+在制<>0 then
		case when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=1 then '黑色'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<1 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0.66 then '红色'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<0.66 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0.35 then '黄色'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<0.35 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0 then '绿色'
			else '蓝色' end
	else '蓝色' end as '颜色'
,t9.FQTY as '途中'
,t5.FNAME as '采购员_MTSSKU'
,t6.FNAME as '主供应商_MTSSKU'
,t8.FCAPTION as '原存货点描述'
,t1.FNUMBER as '存货点SKU'
,t2.FNAME as 'SKU描述'
,t2.FSPECIFICATION as '规格Spec'
,t12.FSAFESTOCK as '缓冲大小（安全库存）'
,t12.FSAFESTOCK as '生产在制' --MTA生产订单 未入库数量
from T_BD_MATERIAL t1
left join T_BD_MATERIAL_L t2 on t1.FMaterialID=t2.FMaterialID
join t_bd_Materialbase t3 on t3.fmaterialid=t1.fmaterialid
left join T_BD_MATERIALPURCHASE t4 on t1.FMaterialID=t4.FMATERIALID
left join V_BD_BUYER_L t5 on t4.FPURCHASERID=t5.FID  and t5.FLOCALEID=2052
left join T_BD_SUPPLIER_L t6 on t4.FDEFAULTVENDORID=t6.FSUPPLIERID and t6.FLOCALEID=2052
join T_META_FORMENUMITEM t7 on t7.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and t7.FVALUE=t3.FERPCLSID --BD_物料属性
join T_META_FORMENUMITEM_L t8 on t7.FENUMID=t8.FENUMID and t8.FLOCALEID=2052 AND (T8.FCAPTION='外购' or T8.FCAPTION='委外' or T8.FCAPTION='自制')
left join #POOrderNoInStock t9 on t9.FMaterialID=t1.FMaterialID
left join #Inventory t10 on t1.FMasterID=t10.FMaterialID
left join #POOrderNoCheck t11 on t1.FMaterialID=t11.FMaterialID
left join T_BD_MATERIALSTOCK t12 on t12.FMATERIALID=t1.FMATERIALID
where t1.FUseOrgID=100102 and t12.FSAFESTOCK>0

drop table #POOrderNoInStock,#Inventory,#POOrderNoCheck
