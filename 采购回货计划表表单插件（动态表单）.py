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
from Kingdee.BOS.Core.Bill import *
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

# global FilterCondition
# FilterCondition=ProductCostMultiCondition();
#采购回货计划表表单插件（动态表单）
def __init__(self):
    OpenFilterFormByClick();
def PreOpenForm(e):
    productModelContainer = ProductModelContainerFactory.TryGetCurrent(e.Context);
    kDProduct = productModelContainer.KDProduct;
    if kDProduct <> None and not kDProduct.BOS.IsDemoVersion:
        FeatureVerifier.CheckFeature(e.Context, "k3347c823ccae4c25849180f2a083464b");
def OnInitializeService(e):
    global _serviceProvider
    _serviceProvider = e.ServiceProvider;
def CreateNewData(e):
    OpenFilterFormByClick();
def AfterCreateModelData(e):
    nextEntrySchemeFilter = BaseFunction.GetNextEntrySchemeFilter(this.Context, _serviceProvider, "ka1d615ce32084b5fae179583e5977281", "k3347c823ccae4c25849180f2a083464b");
    if nextEntrySchemeFilter <> None:
        OpenFilterFormByClick();

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

def OpenFilterFormByClick():
    #全局变量
    global FOrdDefStockID1
    global FOrdDefStockID2
    global FOrdDefStockID3

    FOrdDefStockID1="0"
    FOrdDefStockID2="0"
    FOrdDefStockID3="0"
    #读取系统参数数据包
    parameterData=SystemParameterServiceHelper.Load(this.Context,1,0,"SAL_SystemParameter")
    #从系统参数数据包中获取某一个参数
    if parameterData<>None:
        if parameterData.DynamicObjectType.Properties.ContainsKey("FOrdDefStockID1") and parameterData["FOrdDefStockID1"]<>None:
            FOrdDefStockID1=str(parameterData["FOrdDefStockID1"]["Id"])
        if parameterData.DynamicObjectType.Properties.ContainsKey("FOrdDefStockID2") and parameterData["FOrdDefStockID2"]<>None:
            FOrdDefStockID2=str(parameterData["FOrdDefStockID2"]["Id"])
        if parameterData.DynamicObjectType.Properties.ContainsKey("FOrdDefStockID3") and parameterData["FOrdDefStockID3"]<>None:
            FOrdDefStockID3=str(parameterData["FOrdDefStockID3"]["Id"])
            
    #打开过滤框
    listpara = FilterShowParameter();
    listpara.FormId = "ora_CGHHJHBFilter"; #打开所需要单据的唯一标示
    listpara.ParentPageId = this.View.PageId;
    listpara.MultiSelect = False; # 是否多选
    listpara.OpenStyle.CacheId = listpara.PageId;
    this.View.ShowForm(listpara,FilterFormCallBack);


def AfterBarItemClick(e):
    if e.BarItemKey=="PAEZ_tbnGenerateMPSPlan":
        GenerateMPSPlan();

def GenerateMPSPlan():
    entity = this.View.BillBusinessInfo.GetEntity("F_PAEZ_Entity"); #Entity
    rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
    materialStr=""
    
    for row in rows:
        if row["F_PAEZ_CheckBox"] and row["FShortageQtyM2"]>0:
            materialStr=materialStr+row["FMaterialNumber"]+"\n"
            data="{\"IsEntryBatchFill\": \"true\",\"InterationFlags\": \"\","
            data=data+"\"Model\": ["
            data=data+"{"
            data=data+"        \"FID\": 0,                                   "
            data=data+"        \"FBillTypeID\": {                            "
            data=data+"            \"FNUMBER\": \"JHDD01_SYS\"              "
            data=data+"        },                                            "
            data=data+"        \"FSupplyOrgId\": {                             "
            data=data+"            \"FNumber\": \"101\"                      "
            data=data+"        },                                            "
            data=data+"        \"FDemandOrgId\": {                            "
            data=data+"            \"FNumber\": \"101\"                 "
            data=data+"        },                                            "
            data=data+"        \"FMaterialId\": {                        "
            data=data+"            \"FNumber\": \""+row["FMaterialNumber"]+"\"       "
            data=data+"        },                                            "
            data=data+"        \"FAuxPropId\": {                            "
            data=data+"            \"FAUXPROPID__FF100019\": \"108\",                 "
            data=data+"            \"FAUXPROPID__FF100020\": \"1\"                 "
            data=data+"        },                                            "
            data=data+"        \"FReleaseType\": \"1\",                                            "
            data=data+"        \"FSupplyMaterialId\": {                        "
            data=data+"            \"FNumber\": \""+row["FMaterialNumber"]+"\"       "
            data=data+"        },                                            "
            data=data+"        \"FUnitId\": {                        "
            data=data+"            \"FNumber\": \"Pcs\"       "
            data=data+"        },                                            "
            data=data+"        \"FOrderQty\": "+str(round(row["FShortageQtyM2"]/108*100,2))+",                                            "
            data=data+"        \"FSugQty\": "+str(round(row["FShortageQtyM2"]/108*100,2))+",                                            "
            data=data+"        \"FFirmQty\": "+str(round(row["FShortageQtyM2"]/108*100,2))+",                                            "
            data=data+"        \"FInStockOrgId\": {                        "
            data=data+"            \"FNumber\": \"101\"       "
            data=data+"        },                                            "
            data=data+"        \"FOwnerTypeId\": \"BD_OwnerOrg\",                                            "
            data=data+"        \"FOwnerId\": {                            "
            data=data+"            \"FNumber\": \"101\"                 "
            data=data+"        },                                       "
            data=data+"        \"FDataSource\": \"2\",                                            "
            data=data+"        \"FBaseUnitId\": {                            "
            data=data+"            \"FNumber\": \"m2\"                 "
            data=data+"        },                                       "
            data=data+"        \"FBaseOrderQty\": "+str(row["FShortageQtyM2"])+",                                            "
            data=data+"        \"FBaseSugQty\": "+str(row["FShortageQtyM2"])+",                                            "
            data=data+"        \"FBaseFirmQty\": "+str(row["FShortageQtyM2"])+",                                            "
            data=data+"        \"FUnitArea\": 0.0108,                                            "
            data=data+"        \"FProductType\": \"DL\",                                            "
            data=data+"        \"FMtoNo\": \"米\",                                            "
            data=data+"        \"FDescription\": \"由后工序缺料统计表生成。\"                                            "
            data=data+"    }"
            data=data+"    ]}"
            if materialStr<>"":
                reqResult=WebApiServiceCall.BatchSave(this.Context, "PLN_PLANORDER",data);#Dictionary[str, object]
                IsSuccess=reqResult["Result"]["ResponseStatus"]["IsSuccess"]
                if not IsSuccess:
                    SaveErrors=reqResult["Result"]["ResponseStatus"]["Errors"] #List[object]
                    saveErrorMsg=row["FMaterialNumber"]+"生成MPS计划订单失败：\n"
                    for saveError in SaveErrors:
                        saveErrorMsg=saveErrorMsg+str(saveError["FieldName"])+","+saveError["Message"]+"\n"
                    raise NameError(saveErrorMsg)
                else:
                    SuccessBillNo=reqResult["Result"]["ResponseStatus"]["SuccessEntitys"][0]["Number"]
                    this.View.ShowMessage(row["FMaterialNumber"]+"生成MPS计划订单成功："+SuccessBillNo)

def FilterFormCallBack(formResult):
    #添加字段
    AddField("FEntity","FMaterialNumber","物料编码",150,80)
    AddField("FEntity","FMaterialName","物料名称",150,80)
        
    #根据新的元数据，重构单据体表格列
    grid=this.View.GetControl("FEntity")
    grid.SetAllowLayoutSetting(False)#列按照索引显示
    listAppearance=_currLayout.GetEntityAppearance("FEntity")
    grid.CreateDyanmicList(listAppearance)
    
    #使用最新的元数据，重新界面数据包
    _currInfo.GetDynamicObjectType(True);
    this.Model.CreateNewData();
    #/*dialect*/select FPARAMETERS.value('(//FOrdDefStockID1_Id)[1]','varchar(max)') ,FPARAMETERS.value('(//FOrdDefStockID2_Id)[1]','varchar(max)') from T_BAS_SysParameter where FPARAMETEROBJID='SAL_SystemParameter' where FORGID=1
    
    # 执行查询的sql
    sql="/*dialect*/select mat.FNUMBER 物料代码,mat_l.FNAME 物料名称"
    sql=sql+"\n from T_BD_MATERIAL mat "
    sql=sql+"\n join T_BD_MATERIAL_L mat_l on mat_l.FMATERIALID=mat.FMATERIALID and mat_l.FLOCALEID=2052"
    sql=sql+"\n join T_BD_MATERIALBASE matb on matb.FMATERIALID=mat.FMATERIALID and matb.FERPCLSID=2/*物料属性=自制*/"
    sql=sql+"\n join T_BD_MATERIALPLAN matp on matp.FMATERIALID=mat.FMATERIALID and matp.FPLANNINGSTRATEGY=0 /*计划策略=MPS*/"

    global gFormResult
    gFormResult=formResult
    if formResult <> None and formResult.ReturnData <> None :#and formResult.ReturnData is FilterParameter)
        if formResult.ReturnData.CustomFilter is not None:
            FMaterialID=formResult.ReturnData.CustomFilter["FMaterialID"];
            if FMaterialID <> None:
                sql=sql+" where mat.FMATERIALID="+str(FMaterialID["Id"])
        
    dt = DBUtils.ExecuteDataSet(this.Context,sql).Tables[0];
    if dt.Rows.Count>0:
        #this.View.ShowMessage(str(dt.Rows.Count));
        entity = this.View.BillBusinessInfo.GetEntity("FEntity"); #Entity
        rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
        rows.Clear();
        for i in range(0,dt.Rows.Count):
            row = de.DynamicObject(entity.DynamicObjectType);
            row["FMaterialNumber"] = dt.Rows[i]["物料代码"];
            row["FMaterialName"] = dt.Rows[i]["物料名称"];
          
            rows.Add(row);  
    this.View.UpdateView("FEntity");
