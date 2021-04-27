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
from Kingdee.BOS.Core import *
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
#采购回货计划表元数据表单插件（动态表单）

def PreOpenForm(e):
    productModelContainer = ProductModelContainerFactory.TryGetCurrent(e.Context);
    kDProduct = productModelContainer.KDProduct;
    if kDProduct <> None and not kDProduct.BOS.IsDemoVersion:
        FeatureVerifier.CheckFeature(e.Context, "k3347c823ccae4c25849180f2a083464b");
def OnInitializeService(e):
    global _serviceProvider
    _serviceProvider = e.ServiceProvider;

def AfterCreateModelData(e):
    nextEntrySchemeFilter = BaseFunction.GetNextEntrySchemeFilter(this.Context, _serviceProvider, "ka1d615ce32084b5fae179583e5977281", "k3347c823ccae4c25849180f2a083464b");
    #if nextEntrySchemeFilter <> None:
    #    OpenFilterFormByClick();

#通常在此事件中，修改界面元数据；
#本示例，在此事件中，把界面元数据复制到本地，避免与其他实例公用元数据，造成串账
def OnSetBusinessInfo(e):
    #复制界面元数据到本地变量
    global _currInfo
    global _currLayout
    currMeta=ObjectUtils.CreateCopy(this.View.OpenParameter.FormMetaData)
    _currInfo=currMeta.BusinessInfo
    _currLayout=currMeta.GetLayoutInfo()
    #用本地的元数据，替换动态表单引擎持有的元数据
    e.BusinessInfo=_currInfo
    e.BillBusinessInfo = _currInfo
    
def OnSetLayoutInfo(e):
    e.LayoutInfo=_currLayout
    e.BillLayoutInfo=_currLayout
    
def AfterBindData(e):
    #获取单据体表格的元数据及外观
    entity=_currInfo.GetEntity("FEntity")
    entityApp=_currLayout.GetEntityAppearance("FEntity")
    AddColumns()
    OpenFilterFormByClick()

#添加字段
#entityKey=单据体标识,fieldKey=新字段标识,fieldName=新字段名称,Width=新字段宽度,LabelWidth=新字段标题宽度
def AddField(entityKey,fieldKey,fieldName,Width,LabelWidth):
    #构建文本字段
    fld=TextField()
    fld.Key=fieldKey
    fld.Name=LocaleValue(fieldName)
    fld.PropertyName=fld.Key
    fld.EntityKey=entityKey
    fld.Entity=_currInfo.GetEntity(entityKey)
    _currInfo.Add(fld)
    fldApp=TextFieldAppearance()
    fldApp.Key = fld.Key
    fldApp.Caption = fld.Name
    fldApp.EntityKey = fld.EntityKey
    fldApp.Width=LocaleValue(str(Width))
    fldApp.LabelWidth=LocaleValue(str(LabelWidth))
    fldApp.Tabindex=1
    fldApp.Field=fld
    fldApp.Locked=1
    fldApp.Visible=1
    _currLayout.Add(fldApp)

def OpenFilterFormByClick():

    #打开过滤框
    listpara = FilterShowParameter();
    listpara.FormId = "ora_CGHHJHBYSJFilter"; #打开所需要单据的唯一标示
    listpara.ParentPageId = this.View.PageId;
    listpara.MultiSelect = False; # 是否多选
    listpara.OpenStyle.CacheId = listpara.PageId;
    this.View.ShowForm(listpara,FilterFormCallBack);

def AfterBarItemClick(e):
    if e.BarItemKey=="ora_tbCreateDeliveryPlan":
        GenerateDeliveryPlan();
    elif e.BarItemKey=="ora_tbRefresh":
        FilterFormCallBack(_gFormResult)
    elif e.BarItemKey=="ora_tbFilter":
        OpenFilterFormByClick()
def GenerateDeliveryPlan():
    entity = this.View.BillBusinessInfo.GetEntity("FEntity"); #Entity
    rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
    
    ErrMessage=""
    for row in rows:
        FDemandQty=float(row["FDemandQty"])
        DemandBillNo=str(row["FBillNo"])
        DemandEntryID=int(row["FEntryID"])
        DemandBillID=int(row["FID"])
        
        if row["F_ora_CheckBox"] and FDemandQty>0:
            if row["FIsComplete"]=="是":
                # ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"已存在送货计划，禁止重复生成\n"
                # continue
                ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"已存在送货计划，现在正在重复生成\n"
                
            #查询所有该物料的未收料且未送货的采购订单数量，先循环采购订单计算合计数量，如果合计数量小于FDemandQty，提示数量不足。如果数量足够，循环下推每一行
            sql="/*dialect*/"
            sql=sql+"\n select t2.FID,t2.FEntryID,t2.F_ORA_JOINDELVPLANQTY 送货计划关联数量,t2.FQTY-t2.F_ORA_JOINDELVPLANQTY 剩余送货数量,t3.FREMAINRECEIVEQTY 剩余收料数量 "
            sql=sql+"\n ,case when t2.FQTY-t2.F_ORA_JOINDELVPLANQTY>t3.FREMAINRECEIVEQTY then t3.FREMAINRECEIVEQTY else t2.FQTY-t2.F_ORA_JOINDELVPLANQTY end 可送货数量     "
            sql=sql+"\n from t_PUR_POOrder t1                                                                                                                               "
            sql=sql+"\n join t_PUR_POOrderEntry t2 on t1.FID=t2.FID and t1.FDOCUMENTSTATUS='C' and t1.FCLOSESTATUS='A' and t2.FMRPCLOSESTATUS='A'                           "
            sql=sql+"\n join t_PUR_POOrderEntry_R t3 on t2.FEntryID=t3.FEntryID and t3.FREMAINRECEIVEQTY>0                                                                  "
            sql=sql+"\n where t2.FQTY-t2.F_ORA_JOINDELVPLANQTY>0 and t2.FMaterialID="+row["FMaterialID"]
            sql=sql+"\n order by case when t2.FQTY-t2.F_ORA_JOINDELVPLANQTY>t3.FREMAINRECEIVEQTY then t3.FREMAINRECEIVEQTY else t2.FQTY-t2.F_ORA_JOINDELVPLANQTY end desc"
            
            PurchaseOrderRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
            
            #循环采购订单计算合计数量
            PurchaseOrderQty=0
            for PurchaseOrderRow in PurchaseOrderRows:
                PurchaseOrderQty=PurchaseOrderQty+PurchaseOrderRow["可送货数量"]
            
            if PurchaseOrderQty<FDemandQty:
                ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"生成送货计划失败，"
                ErrMessage=ErrMessage+"采购订单剩余收料数量"+str(PurchaseOrderQty)+"不足"+str(FDemandQty)+"或送货计划关联数量超额\n"
                continue
            
            NoDemandQty=FDemandQty #剩余需求数量
            NeedPushEntryIds = ""
            for PurchaseOrderRow in PurchaseOrderRows:
                FQty = 0
                SrcEntryID = PurchaseOrderRow["FEntryID"]
                SrcQty = PurchaseOrderRow["可送货数量"]
                NeedPushEntryIds = NeedPushEntryIds + str(SrcEntryID) + ","
                if SrcQty>NoDemandQty:
                    FQty=NoDemandQty
                else:
                    FQty=SrcQty
                NoDemandQty=NoDemandQty-FQty
                if FQty<=0:
                    break;
                #一行采购订单下推成一单
                PushDownResult=PushDownDeliveryPlan(0,SrcEntryID,FQty,DemandBillID,DemandEntryID,DemandBillNo)
                if PushDownResult.find("失败")>-1:
                    ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"生成送货计划失败:"+PushDownResult+"\n"
                else:
                    ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"生成送货计划成功:"+PushDownResult+"\n"
            #多行采购订单合并成一个单
            # if NeedPushEntryIds<>"":
                # NeedPushEntryIds=NeedPushEntryIds[:-1]#删除最后一位逗号
            # PushDownResult=PushDownDeliveryPlan(0,NeedPushEntryIds,FQty,DemandBillID,DemandEntryID,DemandBillNo)
            # if str(PushDownResult).find("失败")>-1:
                # ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"生成送货计划失败:"+PushDownResult+"\n"
            # else:
                # ErrMessage=ErrMessage+"单据"+DemandBillNo+"物料"+row["FMatNumber"]+"生成送货计划成功:"+str(PushDownResult)+"\n"
    if ErrMessage<>"":
        this.View.ShowMessage(ErrMessage)
        
    FilterFormCallBack(_gFormResult)#生成后刷新数据
    
#def FilterFormCallBack(formResult):
def AddColumns():
    #添加字段
    AddField("FEntity","FDataSource","数据来源",100,80)
    AddField("FEntity","FBillType","单据类型",100,80)
    AddField("FEntity","FBillNo","单据编号",150,80)
    AddField("FEntity","FStockQty","单据数(库存单位)",100,80)
    AddField("FEntity","FBillMatNumber","单据物料编码",150,80)
    AddField("FEntity","FBillMatName","单据物料名称",150,80)
    # AddField("FEntity","FProductNumber","父件编码",150,80)
    # AddField("FEntity","FProductName","父件名称",150,80)
    AddField("FEntity","FMatNumber","物料编码",150,80)
    AddField("FEntity","FMatName","物料名称",150,80)
    AddField("FEntity","FMatSpec","物料规格",150,80)
    AddField("FEntity","FMatProp","物料属性",150,80)
    # AddField("FEntity","FUseQty","用量",100,80)
    AddField("FEntity","FScrap","损耗(%)",100,80)
    AddField("FEntity","FDemandQty","需求数",100,80)
    AddField("FEntity","FTotalLeadTime","固定提前期",150,80)
    AddField("FEntity","FCalDate","计算日期",150,80)
    AddField("FEntity","FDemandDate","需求日期",150,80)
    AddField("FEntity","FID","FID",150,80)
    AddField("FEntity","FEntryID","FEntryID",150,80)
    AddField("FEntity","FMaterialID","物料内码",150,80)
    AddField("FEntity","FIsComplete","已生成送货计划",150,80)
        
    #根据新的元数据，重构单据体表格列
    grid=this.View.GetControl("FEntity")
    grid.SetAllowLayoutSetting(False)#列按照索引显示
    listAppearance=_currLayout.GetEntityAppearance("FEntity")
    grid.CreateDyanmicList(listAppearance)
    
    #使用最新的元数据，重新界面数据包
    _currInfo.GetDynamicObjectType(True);
    this.Model.CreateNewData();

def FilterFormCallBack(formResult):
    global _gFormResult
    _gFormResult=formResult
    this.View.Model.DeleteEntryData("FEntity");#删除行
    # 执行查询的sql
    sql="/*dialect*/"
    sql=sql+"\n zskd_sp_CGHHDTGJBYSJ 9  "
    # 条件过滤
    if formResult <> None and formResult.ReturnData <> None:
           sql=sql+",'"+formResult.ReturnData.FilterString.replace("'", "''")+"'"

    dt = DBUtils.ExecuteDataSet(this.Context,sql).Tables[0];
    if dt.Rows.Count>0:
        #this.View.ShowMessage(str(dt.Rows.Count));
        entity = this.View.BillBusinessInfo.GetEntity("FEntity"); #Entity
        rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
        rows.Clear();
        for i in range(0,dt.Rows.Count):
            row = de.DynamicObject(entity.DynamicObjectType)
            row["FDataSource"] = dt.Rows[i]["FDataSource"]
            row["FBillType"] = dt.Rows[i]["BillType"]
            row["FBillNo"] = dt.Rows[i]["FBillNo"]
            row["FStockQty"] = dt.Rows[i]["FQTY"]
            row["FBillMatNumber"] = dt.Rows[i]["FBillMatNumber"]
            row["FBillMatName"] = dt.Rows[i]["FBillMatName"]
            # row["FProductNumber"] = dt.Rows[i]["父件编码"]
            # row["FProductName"] = dt.Rows[i]["父件名称"]
            row["FMatNumber"] = dt.Rows[i]["FMatNumber"]
            row["FMatName"] = dt.Rows[i]["FMatName"]
            row["FMatSpec"] = dt.Rows[i]["FMatSpec"]
            row["FMatProp"] = dt.Rows[i]["FMatProp"]
            # row["FUseQty"] = dt.Rows[i]["用量"]
            row["FScrap"] = dt.Rows[i]["FScrap"]
            row["FDemandQty"] = dt.Rows[i]["FDemandQty"]
            row["FTotalLeadTime"] = dt.Rows[i]["FTotalLeadTime"]
            row["FCalDate"] = dt.Rows[i]["FCalDate"]
            row["FDemandDate"] = dt.Rows[i]["FDemandDate"]
            row["FID"] = dt.Rows[i]["FID"]
            row["FEntryID"] = dt.Rows[i]["FEntryID"]
            row["FMaterialID"] = dt.Rows[i]["FMaterialID"]
            row["FIsComplete"] = dt.Rows[i]["FIsComplete"]
            rows.Add(row);  
    this.View.UpdateView("FEntity");

#采购订单下推到送货计划单
#fid=采购订单FID，EntryId=采购订单FEntryId，FQty=下推数量，DemandFID=销售订单FID，DemandFEntryId=销售订单FEntryId，DemandFBillNo=销售订单号
def PushDownDeliveryPlan(fid,EntryId,FQty,DemandFID,DemandFEntryId,DemandFBillNo):
    rules = ConvertServiceHelper.GetConvertRules(this.Context, "PUR_PurchaseOrder", "ora_ReceivePlanBill");
    if rules.Count==0:
        return "采购订单下推到送货计划单失败，未找到转换规则。"
    rule=rules[0];
    selectedrows=[];
    primarykey=str(fid);
    row=ListSelectedRow(primarykey,str(EntryId),0,"PUR_PurchaseOrder");
    row.EntryEntityKey="FPOOrderEntry"
    selectedrows.append(row);
    selectedrows=tuple(selectedrows);
    pushargs=PushArgs(rule,selectedrows);
    # pushargs.TargetBillTypeId="ce8f49055c5c4782b65463a3f863bb4a";
    # pushargs.TargetOrgId=0;
    PushResult=None
    try:
        PushResult=ConvertServiceHelper.Push(this.Context,pushargs,OperateOption.Create());
    except:
        return "采购订单下推到送货计划单失败，不符合下推条件或数量超额。"
    SuccessFlag=PushResult.IsSuccess;
    
    Errmsg=""
    if str(SuccessFlag)=="False":
        Errmsg="下推失败:"
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
            # 在此修改生成后的数据包
            # ActReceiveQty=obj["PUR_ReceiveEntry"][0]["ActReceiveQty"] #供应商送货数量
            # BaseUnitQty=obj["PUR_ReceiveEntry"][0]["BaseUnitQty"] #基本单位数量
            # ConvertRate=ActReceiveQty/BaseUnitQty #基本单位转换率
            # obj["PUR_ReceiveEntry"][0]["ActReceiveQty"]=FQty
            # obj["PUR_ReceiveEntry"][0]["BaseUnitQty"]=FQty*ConvertRate #根据交货数量计算基本单位数量
            obj["PUR_ReceiveEntry"][0]["FDemandBillID"]=DemandFID
            obj["PUR_ReceiveEntry"][0]["FDemandEntryID"]=DemandFEntryId
            obj["PUR_ReceiveEntry"][0]["FDemandBillNo"]=DemandFBillNo
            objs.append(obj);
        objs=tuple(objs);
        targetBillMeta=MetaDataServiceHelper.Load(this.Context, "ora_ReceivePlanBill");
        saveOption=OperateOption.Create();
        saveOption.SetVariableValue("IgnoreWarning",True);
        SaveResult=BusinessDataServiceHelper.Save(this.Context, targetBillMeta.BusinessInfo, objs, saveOption, "Save");
        SuccessFlag=SaveResult.IsSuccess;
        if str(SuccessFlag)=="False":
            Errmsg="保存失败:"
            if SaveResult.OperateResult.Count>0:
                Errmsg=Errmsg+SaveResult.OperateResult[0].Message;
            if SaveResult.ValidationErrors.Count>0:
                Errmsg=Errmsg+","+SaveResult.ValidationErrors[0].Message;
                Errmsg=Errmsg+","+str(SaveResult.InteractionContext);
            # raise NameError(Errmsg);
        else:
            #单据下推成功！修改数量
            NewBillID = SaveResult.OperateResult[0].PKValue
            sql="/*dialect*/ select FEntryID from T_PUR_ReceivePlanEntry where FID="+str(NewBillID)
            SQLRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
            
            if NewBillID>0 and SQLRows.Count>0:
                data="{\"IsEntryBatchFill\": \"true\",\"IsDeleteEntry\": \"false\","
                data=data+"\"Model\": [                                         "
                data=data+"    {                                                "
                data=data+"        \"FID\": "+str(NewBillID)+",                 "
                data=data+"        \"FDetailEntity\": [{                         "
                data=data+"            \"FEntryID\": "+str(SQLRows[0]["FEntryID"])+",        "
                data=data+"            \"FActReceiveQty\": "+str(FQty)+",        "
                data=data+"            \"FConfirmDeliQty\": "+str(FQty)+"        "
                data=data+"        }]"
                data=data+"    }"
                data=data+"]}"
                reqResult=WebApiServiceCall.BatchSave(this.Context, "ora_ReceivePlanBill",data);#Dictionary[str, object]
                IsSuccess=reqResult["Result"]["ResponseStatus"]["IsSuccess"]
                if not IsSuccess:
                    SaveErrors=reqResult["Result"]["ResponseStatus"]["Errors"] #List[object]
                    Errmsg="save失败："
                    for saveError in SaveErrors:
                        Errmsg=Errmsg+str(saveError["FieldName"])+","+saveError["Message"]+"\n"
                    # raise NameError(Errmsg)
                    return Errmsg
                else:
                    SuccessBillNo=reqResult["Result"]["ResponseStatus"]["SuccessEntitys"][0]["Number"]#保存成功
                    return SuccessBillNo
            return str(NewBillID)
    return Errmsg