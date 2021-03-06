import clr
clr.AddReference("Kingdee.BOS")
clr.AddReference("Kingdee.BOS.App")
clr.AddReference("Kingdee.BOS.Core")
clr.AddReference("Kingdee.BOS.DataEntity")
clr.AddReference("Kingdee.BOS.ServiceHelper")
clr.AddReference("Kingdee.K3.FIN.Core")
clr.AddReference("Kingdee.K3.FIN.Business.PlugIn")
clr.AddReference("Kingdee.K3.FIN.CA.Common.BusinessEntity")
clr.AddReference("System.Data")
clr.AddReference("Kingdee.BOS.VerificationHelper")
clr.AddReference("Kingdee.BOS.ProductModel")
clr.AddReference('Kingdee.BOS.WebApi.FormService')
clr.AddReference('Kingdee.BOS.Contracts')
from Kingdee.BOS.App.Data import *
from Kingdee.BOS.Util import *
from Kingdee.BOS.Core.List import *
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
from Kingdee.BOS.Core import List
from Kingdee.BOS.App.Data import DBUtils
from Kingdee.BOS.Core.Metadata.ConvertElement.ServiceArgs import *
from Kingdee.BOS import Orm
from Kingdee.BOS import *
from Kingdee.BOS.Orm import *
from Kingdee.BOS.Core.DynamicForm.Operation import *
from Kingdee.BOS.App import *
from Kingdee.BOS.Contracts import *
from Kingdee.BOS.Util.OperateOptionUtils import *

# global FilterCondition
# FilterCondition=ProductCostMultiCondition();
#??????????????????

def AfterBarItemClick(e):
    if e.BarItemKey=="ora_tbCreateRecNotice":
        BillID=this.View.Model.DataObject["Id"]
        sql="/*dialect*/ select t1.FSeq,t1.FEntryID,t4.FBillNo,t2.FSID,t2.FSBillID,t1.FACTRECEIVEQTY,t4.FCONFIRMSTATUS,t3.FENTRYSTATUS,t1.FID from T_PUR_ReceivePlanEntry t1 "
        sql=sql+"\n join T_PUR_ReceivePlanEntry_LK t2 on t1.FEntryID=t2.FEntryID and t1.FID="+str(BillID)
        sql=sql+"\n join T_PUR_ReceivePlanEntry_R t3 on t1.FEntryID=t3.FEntryID"
        sql=sql+"\n join T_PUR_ReceivePlan t4 on t1.FID=t4.FID"
        SQLRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
        if SQLRows.Count>0:
            if SQLRows[0]["FCONFIRMSTATUS"]=="A":
                this.View.ShowMessage("????????????????????????????")
            return
        
        Message=""
        for SQLRow in SQLRows:
            if SQLRow["FENTRYSTATUS"]=="B":
                Message=Message+"??"+str(SQLRow["FSeq"])+"????????????????????????=??????"
                continue
            PushResult=PushDownRecNotice(SQLRow["FSBillID"],SQLRow["FSID"],SQLRow["FACTRECEIVEQTY"],SQLRow["FID"],SQLRow["FEntryID"],SQLRow["FBillNo"])
            if PushResult.find("????")>-1:
                Message=Message+"??"+str(SQLRow["FSeq"])+"????????????"+PushResult
            else:
                Message=Message+"??"+str(SQLRow["FSeq"])+"????????????"+PushResult
                # sql="/*dialect*/"
                # sql=sql+"\n update T_PUR_ReceivePlanEntry_R set FENTRYSTATUS='B' where FEntryID="+str(SQLRow["FEntryID"])
                # DBServiceHelper.Execute(this.Context,sql)
        if Message<>"":
            this.View.ShowMessage(Message)
        
        this.View.UpdateView("FDetailEntity")
        
#????????????????????????
#fid=????????FID??EntryId=????????FEntryId??FQty=??????????RecPlanID=??????????ID??RecPlanEntryID=??????????EntryID??RecPlanBillNo=????????????
def PushDownRecNotice(fid,EntryId,FQty,RecPlanID,RecPlanEntryID,RecPlanBillNo):
    rules = ConvertServiceHelper.GetConvertRules(this.Context, "PUR_PurchaseOrder", "PUR_ReceiveBill");
    if rules.Count==0:
        return "??????????????????????????????????????????????"
    rule=rules[0];
    selectedrows=[];
    primarykey=str(fid);
    row=ListSelectedRow(primarykey,str(EntryId),0,"PUR_PurchaseOrder");
    row.EntryEntityKey="FPOOrderEntry"
    selectedrows.append(row);
    selectedrows=tuple(selectedrows);
    pushargs=PushArgs(rule,selectedrows);
    pushargs.TargetBillTypeId="7cd93c259999489c97798063f2f7bd70";#??????????
    # pushargs.TargetOrgId=0;
    try:
        PushResult=ConvertServiceHelper.Push(this.Context,pushargs,False);#False ??????????
    except:
        error="??????1.??????????????????????????????????\n"
        error=error+"2.??????????????????????????????????????????????????????????????????????????????????\n"
        error=error+"3.????????????????????????????????????\n"
        error=error+"4.????????????????????????????????????????????????????????????????????????????????????????????"
        return error
        
    SuccessFlag=PushResult.IsSuccess;
    Errmsg=""
    if str(SuccessFlag)=="False":
        Errmsg="????????:"
        if PushResult.OperateResult.Count>0:
            Errmsg=Errmsg+PushResult.OperateResult[0].Message;
        if PushResult.ValidationErrors.Count>0:
            Errmsg=Errmsg+","+PushResult.ValidationErrors[0].Message;
            Errmsg=Errmsg+","+str(PushResult.InteractionContext);
        # raise NameError(Errmsg);
    else:
        objs=[];
        for p in PushResult.TargetDataEntities:
            obj=p.DataEntity;
            # ??????????????????????
            # ActReceiveQty=obj["PUR_ReceiveEntry"][0]["ActReceiveQty"] #??????????????
            # BaseUnitQty=obj["PUR_ReceiveEntry"][0]["BaseUnitQty"] #????????????
            # ConvertRate=ActReceiveQty/BaseUnitQty #??????????????
            # obj["PUR_ReceiveEntry"][0]["ActReceiveQty"]=FQty
            # obj["PUR_ReceiveEntry"][0]["BaseUnitQty"]=FQty*ConvertRate #????????????????????????????
            objs.append(obj);
        objs=tuple(objs);
        targetBillMeta=MetaDataServiceHelper.Load(this.Context, "PUR_ReceiveBill");
        saveOption=OperateOption.Create();
        saveOption.SetVariableValue("IgnoreWarning",True);
        SaveResult=BusinessDataServiceHelper.Save(this.Context, targetBillMeta.BusinessInfo, objs, saveOption, "Save");
        SuccessFlag=SaveResult.IsSuccess;
        if str(SuccessFlag)=="False":
            Errmsg="????????:"
            if SaveResult.OperateResult.Count>0:
                Errmsg=Errmsg+SaveResult.OperateResult[0].Message;
            if SaveResult.ValidationErrors.Count>0:
                Errmsg=Errmsg+","+SaveResult.ValidationErrors[0].Message;
                Errmsg=Errmsg+","+str(SaveResult.InteractionContext);
            # raise NameError(Errmsg);
        else:
            #??????????????????????
            NewBillID = SaveResult.OperateResult[0].PKValue
            sql="/*dialect*/ select FEntryID from T_PUR_ReceiveEntry where FID="+str(NewBillID)
            SQLRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
            
            if NewBillID>0 and SQLRows.Count>0:
                data="{\"IsEntryBatchFill\": \"true\",\"IsDeleteEntry\": \"false\","
                data=data+"\"Model\": [                                         "
                data=data+"    {                                                "
                data=data+"        \"FID\": "+str(NewBillID)+",                 "
                data=data+"        \"FIsInsideBill\":1,                 "
                data=data+"        \"FDetailEntity\": [{                         "
                data=data+"            \"FEntryID\": "+str(SQLRows[0]["FEntryID"])+",        "
                data=data+"            \"FActReceiveQty\": "+str(FQty)+",        "
                data=data+"            \"F_ora_RecPlanID\": "+str(RecPlanID)+",        "
                data=data+"            \"F_ora_RecPlanEntryID\": "+str(RecPlanEntryID)+",        "
                data=data+"            \"F_ora_RecPlanBillNo\": "+str(RecPlanBillNo)+"        "
                data=data+"        }]"
                data=data+"    }"
                data=data+"]}"
                reqResult=WebApiServiceCall.BatchSave(this.Context, "SCP_ReceiveBill",data);#Dictionary[str, object]
                IsSuccess=reqResult["Result"]["ResponseStatus"]["IsSuccess"]
                if not IsSuccess:
                    SaveErrors=reqResult["Result"]["ResponseStatus"]["Errors"] #List[object]
                    Errmsg="save??????"
                    for saveError in SaveErrors:
                        Errmsg=Errmsg+str(saveError["FieldName"])+","+saveError["Message"]+"\n"
                    # raise NameError(Errmsg)
                    return Errmsg
                else:
                    SuccessBillNo=reqResult["Result"]["ResponseStatus"]["SuccessEntitys"][0]["Number"]#????????
                    return SuccessBillNo
            return str(NewBillID)
    return Errmsg