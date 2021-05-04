
--��;��=�ɹ�����δ�������
select t2.FMaterialID,sum(t3.FREMAINSTOCKINQTY) FQTY
into #POOrderNoInStock from t_PUR_POOrder t1 
join T_PUR_POORDERENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
and t1.FCANCELSTATUS='A' and t1.FCHANGESTATUS='A'
join T_PUR_POORDERENTRY_R t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--������=MTA�������� δ�������
select t2.FMaterialID,sum(t3.FNOSTOCKINQTY) FQTY
into #MONoInStock from t_PRD_MO t1 
join t_PRD_MOENTRY t2 on t1.FID=t2.FID and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A' and t1.FDOCUMENTSTATUS='C' 
join t_PRD_MOENTRY_Q t3 on t2.FENTRYID=t3.FENTRYID
group by t2.FMaterialID

--ȡMTA���вֿ�Ŀ����
select o1t1.FMaterialID,sum(FSECQTY - FSECLOCKQTY) FAvbQty
into #Inventory from T_STK_INVENTORY o1t1 
join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT4='MTA' 
group by o1t1.FMaterialID

--ȡMTA�ɹ�����δ���������
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
--����MTA�ֿ�������
--��ɫ�����ڰ�ȫ���ֵ100%
--��ɫ�����ڰ�ȫ���ֵ99-66%����
--��ɫ�����ڰ�ȫ���ֵ65-35%����
--��ɫ�����ڰ�ȫ���ֵ34-0%����
--��ɫ�����ڰ�ȫ���ֵ
select 
t11.FQTY as 'MTA������'
,isnull(t10.FAvbQty,0) as '�ڿ⣨MTA�ֿ������'
,case when t12.FSAFESTOCK<>0 then (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK else 0 end as '�ڿ�BP'
,case when t12.FSAFESTOCK+t9.FQTY+����<>0 then
		case when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=1 then '��ɫ'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<1 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0.66 then '��ɫ'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<0.66 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0.35 then '��ɫ'
			when (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK<0.35 and (t12.FSAFESTOCK-isnull(t10.FAvbQty,0))/t12.FSAFESTOCK>=0 then '��ɫ'
			else '��ɫ' end
	else '��ɫ' end as '��ɫ'
,t9.FQTY as ';��'
,t5.FNAME as '�ɹ�Ա_MTSSKU'
,t6.FNAME as '����Ӧ��_MTSSKU'
,t8.FCAPTION as 'ԭ���������'
,t1.FNUMBER as '�����SKU'
,t2.FNAME as 'SKU����'
,t2.FSPECIFICATION as '���Spec'
,t12.FSAFESTOCK as '�����С����ȫ��棩'
,t12.FSAFESTOCK as '��������' --MTA�������� δ�������
from T_BD_MATERIAL t1
left join T_BD_MATERIAL_L t2 on t1.FMaterialID=t2.FMaterialID
join t_bd_Materialbase t3 on t3.fmaterialid=t1.fmaterialid
left join T_BD_MATERIALPURCHASE t4 on t1.FMaterialID=t4.FMATERIALID
left join V_BD_BUYER_L t5 on t4.FPURCHASERID=t5.FID  and t5.FLOCALEID=2052
left join T_BD_SUPPLIER_L t6 on t4.FDEFAULTVENDORID=t6.FSUPPLIERID and t6.FLOCALEID=2052
join T_META_FORMENUMITEM t7 on t7.FID='ac14913e-bd72-416d-a50b-2c7432bbff63' and t7.FVALUE=t3.FERPCLSID --BD_��������
join T_META_FORMENUMITEM_L t8 on t7.FENUMID=t8.FENUMID and t8.FLOCALEID=2052 AND (T8.FCAPTION='�⹺' or T8.FCAPTION='ί��' or T8.FCAPTION='����')
left join #POOrderNoInStock t9 on t9.FMaterialID=t1.FMaterialID
left join #Inventory t10 on t1.FMasterID=t10.FMaterialID
left join #POOrderNoCheck t11 on t1.FMaterialID=t11.FMaterialID
left join T_BD_MATERIALSTOCK t12 on t12.FMATERIALID=t1.FMATERIALID
where t1.FUseOrgID=100102 and t12.FSAFESTOCK>0

drop table #POOrderNoInStock,#Inventory,#POOrderNoCheck
