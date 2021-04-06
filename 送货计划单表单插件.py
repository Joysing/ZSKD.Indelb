import clr
clr.AddReference("Kingdee.BOS")
clr.AddReference("Kingdee.BOS.App")
clr.AddReference("Kingdee.BOS.Core")
clr.AddReference("Kingdee.BOS.DataEntity")
clr.AddReference("Kingdee.BOS.ServiceHelper")
clr.AddReference("Kingdee.K3.FIN.Core")
clr.AddReference("Kingdee.K3.FIN.Business.PlugIn")
clr.AddReference("Kingdee.K3.FIN.CA.Common.BusinessEntity")
clr.AddReference("Kingdee.BOS.App")
clr.AddReference("System.Data")
clr.AddReference("Kingdee.BOS.VerificationHelper")
clr.AddReference("Kingdee.BOS.ProductModel")
clr.AddReference('Kingdee.BOS.WebApi.FormService')
from Kingdee.BOS.App.Data import *
from Kingdee.BOS.Util import *
from Kingdee.BOS.Core.CommonFilter import *
from Kingdee.BOS.Core.DynamicForm import *
from Kingdee.BOS.Core.DynamicForm.PlugIn import *
from Kingdee.BOS.Core.DynamicForm.PlugIn.Args import *
from Kingdee.BOS.Core.DynamicForm.PlugIn.ControlModel import *
from System import *
from System.ComponentModel import *
from Kingdee.BOS.Core.Metadata.EntityElement import *
from Kingdee.BOS.Orm.DataEntity import *
from Kingdee.K3.FIN.Business.PlugIn import *
from Kingdee.K3.FIN.CA.Common.BusinessEntity.FilterCondition import *
from System.Collections.Generic import *
from System.Data import *
from Kingdee.K3.FIN.Core import *
from Kingdee.BOS.VerificationHelper import *
from Kingdee.BOS.ProductModel import *
from Kingdee.BOS.VerificationHelper.Verifiers import *
import Kingdee.BOS.Core.DynamicForm as df
import Kingdee.BOS.Orm.DataEntity as de
import Kingdee.BOS.Core.CommonFilter.FilterParameter as fp
import Kingdee.BOS.Core.DynamicForm.FormResult as fr
from Kingdee.BOS.WebApi.FormService import *
from Kingdee.BOS.ServiceHelper import *
from Kingdee.BOS import *
from Kingdee.BOS.Core.Metadata import *
from Kingdee.BOS.Core.Metadata.ControlElement import *
from Kingdee.BOS.Core.Metadata.FieldElement import *
from Kingdee.BOS.ServiceHelper import *

# global FilterCondition
# FilterCondition=ProductCostMultiCondition();
#送货计划单表单插件

def AfterBarItemClick(e):
    if e.BarItemKey=="ora_tbCreateRecNotice":
        CreateRecNotice();

def CreateRecNotice():
    entity = this.View.BillBusinessInfo.GetEntity("FEntity"); #Entity
    rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
    materialStr=""
    
    ErrMessage=""
    for row in rows:
        if row["F_ora_CheckBox"] and row["FDemandQty"]>0:
            #查询所有该物料的未收料且未送货的采购订单数量，先循环采购订单计算合计数量，如果合计数量小于row["FDemandQty"]，提示数量不足。如果数量足够，循环下推每一行
            #todo 送货计划单添加按钮一键下推（取采购订单to收料通知单）
            sql="/*dialect*/"
            sql=sql+"\n select t2.FID,t2.FEntryID,t2.F_ORA_JOINDELVPLANQTY 送货计划关联数量,t2.FQTY-t2.F_ORA_JOINDELVPLANQTY 剩余送货数量,t3.FREMAINRECEIVEQTY 剩余收料数量 "
            sql=sql+"\n ,case when t2.FQTY-t2.F_ORA_JOINDELVPLANQTY>t3.FREMAINRECEIVEQTY then t3.FREMAINRECEIVEQTY else t2.FQTY-t2.F_ORA_JOINDELVPLANQTY end 可送货数量"
            sql=sql+"\n from t_PUR_POOrder t1 "
            sql=sql+"\n join t_PUR_POOrderEntry t2 on t1.FID=t2.FID and t1.FDOCUMENTSTATUS='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A'"
            sql=sql+"\n join t_PUR_POOrderEntry_R t3 on t2.FEntryID=t3.FEntryID and t3.FREMAINRECEIVEQTY>0"
            sql=sql+"\n where t2.FQTY-t2.F_ORA_JOINDELVPLANQTY>0 --and t2.FMaterialID="+row["FMaterialID"]
            
            PurchaseOrderRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
            
            #循环采购订单计算合计数量
            PurchaseOrderQty=0
            for PurchaseOrderRow in PurchaseOrderRows:
                PurchaseOrderQty=PurchaseOrderQty+PurchaseOrderRow["可送货数量"]
            
            if PurchaseOrderQty<row["FDemandQty"]:
                ErrMessage=ErrMessage+"单据"+row["FBillNo"]+"物料"+row["FMatNumber"]+"生成送货计划失败，采购订单剩余收料数量不足或送货计划关联数量超额\n"
                continue
            
            NoDemandQty=row["FDemandQty"] #剩余需求数量
            NeedPushEntryIds = ""
            for PurchaseOrderRow in PurchaseOrderRows:
                FQty = 0
                SrcEntryID = PurchaseOrderRow["FEntryID"]
                SrcQty = PurchaseOrderRow["可送货数量"]
                NeedPushEntryIds = NeedPushEntryIds + SrcEntryID + ","
                if SrcQty>NoDemandQty:
                    FQty=NoDemandQty
                else:
                    FQty=SrcQty
                NoDemandQty=NoDemandQty-FQty
                if FQty<=0:
                    break;
                #一行采购订单下推成一单
                # PushDownResult=PushDown(0,SrcEntryID)
                # if PushDownResult<>"":
                    # ErrMessage=ErrMessage+"单据"+row["FBillNo"]+"物料"+row["FMatNumber"]+"生成送货计划失败:"+PushDownResult+"\n"
            #多行采购订单合并成一个单
            if NeedPushEntryIds<>"":
                NeedPushEntryIds=NeedPushEntryIds[:-1]#删除最后一位逗号
            PushDownResult=PushDown(0,NeedPushEntryIds)
            if PushDownResult<>"":
                ErrMessage=ErrMessage+"单据"+row["FBillNo"]+"物料"+row["FMatNumber"]+"生成送货计划失败:"+PushDownResult+"\n"
            
    if ErrMessage<>"":
        this.View.ShowMessage(ErrMessage)
        
    #todo使用单据编号匹配update语句，给已生成送货计划的销售订单和生产订单添加标识
    
def PushDown(fid,EntryIds):
    rules = ConvertServiceHelper.GetConvertRules(this.Context, "PUR_PurchaseOrder", "ora_ReceivePlanBill");
    rule=rules[0];
    selectedrows=[];
    primarykey=str(fid);
    row=ListSelectedRow(0,EntryIds,0,"PUR_PurchaseOrder");
    selectedrows.append(row);
    selectedrows=tuple(selectedrows);
    pushargs=PushArgs(rule,selectedrows);
    # pushargs.TargetBillTypeId="ce8f49055c5c4782b65463a3f863bb4a";
    # pushargs.TargetOrgId=0;
    PushResult=ConvertServiceHelper.Push(this.Context,pushargs,OperateOption.Create());
    SuccessFlag=PushResult.IsSuccess;
    if str(SuccessFlag)=="False":
        Errmsg="";
        if PushResult.OperateResult.Count>0:
            Errmsg=PushResult.OperateResult[0].Message;
        if PushResult.ValidationErrors.Count>0:
            Errmsg=Errmsg+","+PushResult.ValidationErrors[0].Message;
            Errmsg=Errmsg+","+str(PushResult.InteractionContext);
        # raise NameError("下推失败:"+Errmsg);
        return Errmsg
    else:
        return ""