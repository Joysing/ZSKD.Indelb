
--MTO
--��ɫ���ѹ���������
--��ɫ���������ڵ���
--��ɫ����������ǰ1��2��
--��ɫ����������ǰ3��4��
--��ɫ����������ǰ5������
--MTA:
--����MTA�ֿ�������
--�ڣ����ڰ�ȫ���ֵ1%
--�죺���ڰ�ȫ���ֵ99-66%����
--�ƣ����ڰ�ȫ���ֵ65-35%����
--�̣����ڰ�ȫ���ֵ34-0%����
--�������ڰ�ȫ���ֵ

--ȡ���¹�������
select t1.* into #LastWorkCalData from T_ENG_WorkCalData t1 
join T_ENG_WorkCal t2 on t1.FID=t2.FID
where t2.FID=(select top 1 FID from T_ENG_WorkCal where FUSEORGID=100003 and FDOCUMENTSTATUS='C' and FFORBIDSTATUS='A' and FFORMID='ENG_WorkCal' order by FAPPROVEDATE desc)

--ȡMTA���вֿ�Ŀ����
select o1t1.FMaterialID,sum(FSECQTY - FSECLOCKQTY) FAvbQtyinto #Inventory from T_STK_INVENTORY o1t1 join T_BD_STOCK o1t2 on o1t1.FSTOCKID=o1t2.FSTOCKID and o1t2.F_ORA_TEXT4='MTA' group by o1t1.FMaterialID

--���۶���-MTO
select t1.FBILLNO+'-'+convert(varchar(10),t2.FSeq) as '�ӹ�����F_ORA_PINUMBER'
,t2.FQTY as '�ƻ�����OriginQty'
,t3.FSTOCKINQUAAUXQTY as '�깤����PrtdQty'
,t2.FQTY-t3.FSTOCKINQUAAUXQTY as 'δ�깤����'
,t4.FSPECIFICATION as 'SKU����'
,t2.FPLANFINISHDATE as '��������'
,case when convert(date,GETDATE())>t2.FPLANFINISHDATE then '��ɫ'
	when convert(date,GETDATE())=t2.FPLANFINISHDATE then '��ɫ'
	when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) between 1 and 2 then '��ɫ'
	when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) between 3 and 4 then '��ɫ'
	when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE)>=5 then '��ɫ'
	else '' end as '������ʴ��ɫ'
,'' as '����Ͷ����' --�������ڼ�ȥ5�죬ֻ���㹤����
,t3.FSTARTDATE as 'ʵ��Ͷ����'
,t3.FFINISHDATE as 'ʵ���깤����'
,DATEDIFF(d,t3.FSTARTDATE,t3.FFINISHDATE) as 'PLT'
,t5.FMEMO as '��ע'
,'' as 'ʵ���������'
,t9.FNAME as '�ͻ�'
,t6.FNUMBER as 'SKU'
,case when t7.F_ora_TOCType='MTA' then '���' when t7.F_ora_TOCType='MTO' then 'Order' end as '��������'  --F_ora_TOCType  ���=MTA  Order=MTO  
,DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) as '�뽻��������'
from T_PRD_MO t1
join T_PRD_MOENTRY t2 on t1.FID=t2.FID
join T_PRD_MOENTRY_A t3 on t3.FENTRYID=t2.FENTRYID
left join T_BD_MATERIAL_L t4 on t4.FMATERIALID=t2.FMATERIALID and t4.FLOCALEID=2052
left join T_PRD_MOENTRY_L t5 on t5.FENTRYID=t2.FENTRYID and t5.FLOCALEID=2052
join T_BD_MATERIAL t6 on t6.FMATERIALID=t2.FMATERIALID
join T_SAL_ORDERENTRY t7 on t7.FENTRYID=t2.FSALEORDERENTRYID and t7.FID=t2.FSALEORDERID
join T_SAL_ORDER t8 on t8.FID=t7.FID
left join T_BD_CUSTOMER_L t9 on t9.FCUSTID=t8.FCUSTID and t9.FLOCALEID=2052
left join #LastWorkCalData work1 on work1.FDAY=t2.FPLANFINISHDATE 
left join #LastWorkCalData work2 on work1.FINTERID-5=work2.FINTERID and work2.FID=work1.FID
union all
--Ԥ�ⵥ-MTO
select t1.FBILLNO+'-'+convert(varchar(10),t2.FSeq) as '�ӹ�����F_ORA_PINUMBER'
,t2.FQTY as '�ƻ�����OriginQty'
,t3.FSTOCKINQUAAUXQTY as '�깤����PrtdQty'
,t2.FQTY-t3.FSTOCKINQUAAUXQTY as 'δ�깤����'
,t4.FSPECIFICATION as 'SKU����'
,t2.FPLANFINISHDATE as '��������'
,case when t7.F_ora_TOCType='MTA' then 
	case when t10.FSAFESTOCK<>0 then
		case when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=1 then '��ɫ'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<1 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0.66 then '��ɫ'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<0.66 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0.35 then '��ɫ'
			when (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK<0.35 and (t10.FSAFESTOCK-t11.FAvbQty)/t10.FSAFESTOCK>=0 then '��ɫ'
			else '��ɫ' end
	else '��ɫ' end
	when t7.F_ora_TOCType='MTO' then 
		(case when convert(date,GETDATE())>t2.FPLANFINISHDATE then '��ɫ'
		when convert(date,GETDATE())=t2.FPLANFINISHDATE then '��ɫ'
		when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) between 1 and 2 then '��ɫ'
		when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) between 3 and 4 then '��ɫ'
		when DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE)>=5 then '��ɫ'
		end)
	end as '������ʴ��ɫ' 
,'' as '����Ͷ����' --�������ڼ�ȥ5�죬ֻ���㹤����
,t3.FSTARTDATE as 'ʵ��Ͷ����'
,t3.FFINISHDATE as 'ʵ���깤����'
,DATEDIFF(d,t3.FSTARTDATE,t3.FFINISHDATE) as 'PLT'
,t5.FMEMO as '��ע'
,'' as 'ʵ���������'
,t9.FNAME as '�ͻ�'
,t6.FNUMBER as 'SKU'
,case when t7.F_ora_TOCType='MTA' then '���' when t7.F_ora_TOCType='MTO' then 'Order' end as '��������' --F_ora_TOCType  ���=MTA  Order=MTO  
,DATEDIFF(d,convert(date,GETDATE()),t2.FPLANFINISHDATE) as '�뽻��������'
from T_PRD_MO t1
join T_PRD_MOENTRY t2 on t1.FID=t2.FID
join T_PRD_MOENTRY_A t3 on t3.FENTRYID=t2.FENTRYID
left join T_BD_MATERIAL_L t4 on t4.FMATERIALID=t2.FMATERIALID and t4.FLOCALEID=2052
left join T_PRD_MOENTRY_L t5 on t5.FENTRYID=t2.FENTRYID and t5.FLOCALEID=2052
join T_BD_MATERIAL t6 on t6.FMATERIALID=t2.FMATERIALID
join T_PRD_MOENTRY_LK t2_lk on t2_lk.FENTRYID=t2.FENTRYID
join T_PLN_FORECASTENTRY t7 on t7.FENTRYID=t2_lk.FSID and t7.FID=t2_lk.FSBillID and t2_lk.FSTABLENAME='T_PLN_FORECASTENTRY'
join T_PLN_FORECAST t8 on t8.FID=t7.FID
left join T_BD_CUSTOMER_L t9 on t9.FCUSTID=t7.FCUSTID and t9.FLOCALEID=2052
join T_BD_MATERIALSTOCK t10 on t10.FMATERIALID=t2.FMATERIALID
left join #Inventory t11 on t11.FMATERIALID=t6.FMASTERID
left join #LastWorkCalData work1 on work1.FDAY=t2.FPLANFINISHDATE 
left join #LastWorkCalData work2 on work1.FINTERID-5=work2.FINTERID and work2.FID=work1.FID

drop table #Inventory,#LastWorkCalData