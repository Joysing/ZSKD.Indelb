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
import System.Collections.Generic as System_Collections_Generic

# global FilterCondition
# FilterCondition=ProductCostMultiCondition();
#送货通知单删除操作

def BeforeExecuteOperationTransaction(e):
    #在删除前获得送货计划单的EntryID
    global FSIDList
    FSIDList=System_Collections_Generic.List[int]();
    for item in e.SelectedRows:
        BillID=item.DataEntity["Id"]
        sql="/*dialect*/ select t2.FSID,t2.FSBillID,t1.F_ora_RecPlanEntryID from T_PUR_ReceiveEntry t1 "
        sql=sql+"\n join T_PUR_ReceiveEntry_LK t2 on t1.FEntryID=t2.FEntryID and t2.FSTableName='t_PUR_POOrderEntry' and t1.FID="+str(BillID)
        # raise NameError(sql)
        SQLRows=DBServiceHelper.ExecuteDynamicObject(this.Context,sql)
        for SQLRow in SQLRows:
            if not FSIDList.Contains(SQLRow["F_ora_RecPlanEntryID"]):
                FSIDList.Add(SQLRow["F_ora_RecPlanEntryID"])


def AfterExecuteOperationTransaction(e):
    #update送货计划单状态为未关闭
    # for FSID in FSIDList:
        # sql = "/*dialect*/"
        # sql = sql+"\n update t3 set FENTRYSTATUS = 'A' from T_PUR_ReceivePlanEntry t1 "
        # sql = sql+"\n join T_PUR_ReceivePlanEntry_R t3 on t1.FEntryID=t3.FEntryID"
        # sql = sql+"\n join T_PUR_ReceivePlanEntry_LK t2 on t1.FEntryID=t2.FEntryID and t2.FSID = "+str(FSID)
        # rows = DBUtils.Execute(this.Context, sql);
    for FSID in FSIDList:
        sql = "/*dialect*/"
        sql = sql+"\n update t3 set FENTRYSTATUS = 'A' from T_PUR_ReceivePlanEntry t1 "
        sql = sql+"\n join T_PUR_ReceivePlanEntry_R t3 on t1.FEntryID=t3.FEntryID and t3.FENTRYSTATUS = 'B' and t1.FEntryID = "+str(FSID)
        rows = DBUtils.Execute(this.Context, sql);