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
#采购回货计划表表单插件（动态表单）
def PreOpenForm(e):
    productModelContainer = ProductModelContainerFactory.TryGetCurrent(e.Context);
    kDProduct = productModelContainer.KDProduct;
    if kDProduct <> None and not kDProduct.BOS.IsDemoVersion:
        FeatureVerifier.CheckFeature(e.Context, "k3347c823ccae4c25849180f2a083464b");
def OnInitializeService(e):
    global _serviceProvider
    _serviceProvider = e.ServiceProvider;

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
    
def AfterBindData(e):
    #获取单据体表格的元数据及外观
    entity=_currInfo.GetEntity("FEntity")
    entityApp=_currLayout.GetEntityAppearance("FEntity")
    OpenFilterFormByClick()

def AfterBarItemClick(e):
    if e.BarItemKey=="ora_tbRefersh":
        FilterFormCallBack(_gFormResult)
    elif e.BarItemKey=="ora_tbFilter":
        OpenFilterFormByClick()

# 清除全部字段
def ClearAllColumn():
    #获取单据体表格的元数据及外观
    entity=_currInfo.GetEntity("FEntity")
    entityApp=_currLayout.GetEntityAppearance("FEntity")
    # 清除全部字段
    oldCount = entity.Fields.Count;
    for i in range(oldCount-1,-1,-1): #逆序循环
        fld = entity.Fields[i]
        _currInfo.Remove(fld);
        fldApp = _currLayout.GetAppearance(fld.Key);
        _currLayout.Remove(fldApp);    

def OpenFilterFormByClick():
    #打开过滤框
    listpara = FilterShowParameter();
    listpara.FormId = "ora_CGHHJHBFilter"; #打开所需要单据的唯一标示
    listpara.ParentPageId = this.View.PageId;
    listpara.MultiSelect = False; # 是否多选
    listpara.OpenStyle.CacheId = listpara.PageId;
    this.View.ShowForm(listpara,FilterFormCallBack);


def FilterFormCallBack(formResult):
    global _gFormResult
    _gFormResult=formResult
    ClearAllColumn()
    AddColumns()
    FStartDateStr=str(this.View.Model.DataObject["FStartDate"])
    # 执行查询的sql
    sql="/*dialect*/"
    sql=sql+"\n zskd_sp_CGHHDTGJB '"+FStartDateStr+"',9  "
    # 条件过滤
    if formResult <> None and formResult.ReturnData <> None:
           sql=sql+",'"+formResult.ReturnData.FilterString+"'"
        
    dt = DBUtils.ExecuteDataSet(this.Context,sql).Tables[0];
    if dt.Rows.Count>0:
        entity = this.View.BillBusinessInfo.GetEntity("FEntity"); #Entity
        rows = this.Model.GetEntityDataObject(entity); #DynamicObjectCollection
        rows.Clear();
        for i in range(0,dt.Rows.Count):
            row = de.DynamicObject(entity.DynamicObjectType)
            row["FMaterialNumber"] = dt.Rows[i]["FMaterialNumber"]
            row["FMaterialName"] = dt.Rows[i]["FMaterialName"]
            row["FMaterialSpec"] = dt.Rows[i]["FMaterialSpec"]
            row["FReceiveAdvanceDays"] = dt.Rows[i]["FReceiveAdvanceDays"]
            row["FPurchaser"] = dt.Rows[i]["FPurchaser"]
            row["FPurSupplier"] = dt.Rows[i]["FPurSupplier"]
            row["FStockUnit"] = dt.Rows[i]["FStockUnit"]
            row["FStockQty"] = dt.Rows[i]["FStockQty"]
            row["FOnWayQty"] = dt.Rows[i]["FOnWayQty"]
            row["FTotalDemandQty"] = dt.Rows[i]["FTotalDemandQty"]
            row["FGrossDemandQty"] = dt.Rows[i]["FGrossDemandQty"]
            row["FNetDemandQty"] = dt.Rows[i]["FNetDemandQty"]
            for FDemandQtyDayIndex in range(1,101):
                row["FDemandQtyDay"+str(FDemandQtyDayIndex)] = dt.Rows[i]["第"+str(FDemandQtyDayIndex)+"天"]
            row["FLastGrossDemandQty"] = dt.Rows[i]["FLastGrossDemandQty"]
            rows.Add(row)
    this.View.UpdateView("FEntity")


def AddColumns():
    FStartDateStr=str(this.View.Model.DataObject["FStartDate"])
    FStartDateDt=Convert.ToDateTime(FStartDateStr)
    
    #添加字段
    AddField("FEntity","FMaterialNumber","物料编码",150,80)
    AddField("FEntity","FMaterialName","物料名称",150,80)
    AddField("FEntity","FMaterialSpec","物料规格",150,80)
    AddField("FEntity","FReceiveAdvanceDays","采购提前期",150,80)
    AddField("FEntity","FPurchaser","采购负责人",150,80)
    AddField("FEntity","FPurSupplier","采购供应商",150,80)
    AddField("FEntity","FStockUnit","库存计量单位",150,80)
    AddField("FEntity","FStockQty","库存数",80,80)
    AddField("FEntity","FOnWayQty","在途数",80,80)
    AddField("FEntity","FTotalDemandQty","总需求数",80,80)
    AddField("FEntity","FGrossDemandQty","当日毛需求",80,80)
    AddField("FEntity","FNetDemandQty","当日净需求",80,80)
    
    for FDemandQtyDayIndex in range(1,101):
        # AddField("FEntity","FDemandQtyDay"+FDemandQtyDayIndex,"第"+str(FDemandQtyDayIndex)+"天",80,80)
        AddField("FEntity","FDemandQtyDay"+str(FDemandQtyDayIndex),str(FStartDateDt.AddDays(FDemandQtyDayIndex-1)).split(" ")[0],80,80)
    AddField("FEntity","FLastGrossDemandQty","之后合计",80,80)
        
    #根据新的元数据，重构单据体表格列
    grid=this.View.GetControl("FEntity")
    grid.SetAllowLayoutSetting(False)#列按照索引显示
    listAppearance=_currLayout.GetEntityAppearance("FEntity")
    grid.CreateDyanmicList(listAppearance)
    
    #使用最新的元数据，重新界面数据包
    _currInfo.GetDynamicObjectType(True)
    this.Model.CreateNewData()
    