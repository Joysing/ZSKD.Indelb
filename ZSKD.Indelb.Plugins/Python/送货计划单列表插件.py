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
clr.AddReference("Kingdee.BOS.ServiceHelper")
from Kingdee.BOS.ServiceHelper import *
from Kingdee.BOS.App.Data import *
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

#送货计划单列表插件
def PrepareFilterParameter(e):
    UserId = this.Context.UserId;
    if UserId>0:
        sql = "/*dialect*/select FUSERID,FSUPPLIERID from T_SCP_USERDATA where FUSERID=" + str(UserId);
        dt=DBServiceHelper.ExecuteDynamicObject(this.Context,str(sql))
        if dt.Count>0: #如果是供应商用户，只能查看自己供应商的单据
            if e.FilterString == None or e.FilterString == "":
                e.FilterString = e.FilterString + " (FSupplierId =" + str(dt[0]["FSUPPLIERID"]) + ")";
            else :
                e.FilterString = e.FilterString + " and (FSupplierId =" + str(dt[0]["FSUPPLIERID"]) + ")";