import clr
clr.AddReference("System")
clr.AddReference("System.Core")
clr.AddReference("Kingdee.BOS")
clr.AddReference("Kingdee.BOS.App")
clr.AddReference("Kingdee.BOS.Core")
clr.AddReference("Kingdee.BOS.DataEntity")
clr.AddReference("Kingdee.BOS.ServiceHelper")
clr.AddReference('Kingdee.BOS.Business.DynamicForm')
clr.AddReference('Kingdee.BOS.Contracts')
clr.AddReference('Kingdee.BOS.WebApi.FormService')
import sys
from Kingdee.BOS import *
from Kingdee.BOS.Util import *
from Kingdee.BOS.Core import *
from Kingdee.BOS.Core.Bill import *
from Kingdee.BOS.Core.List import *
from Kingdee.BOS.Core.DynamicForm import *
from Kingdee.BOS.Core.DynamicForm.PlugIn import *
from Kingdee.BOS.Core.DynamicForm.PlugIn.ControlModel import *
from Kingdee.BOS.Core.DynamicForm.Operation import *
from Kingdee.BOS.Core.Metadata import *
from Kingdee.BOS.Core.Metadata.ConvertElement.ServiceArgs import *
from Kingdee.BOS.Core.Permission import *
from Kingdee.BOS.App import *
from Kingdee.BOS.App.Data import *
from Kingdee.BOS.ServiceHelper import *
from Kingdee.BOS.Contracts import *
from Kingdee.BOS.Util.OperateOptionUtils import *
from Kingdee.BOS.Orm import *
from Kingdee.BOS.WebApi.FormService import *
import Kingdee.BOS.Orm.DataEntity as de
from System import *
from System.Collections.Generic import *
#修改默认编码为utf8
reload(sys)
sys.setdefaultencoding('utf-8')
    
def AfterExecuteOperationTransaction(e):
    #销售订单保存后生成PI号
    for item in e.DataEntitys:
        FID = str(item["Id"]);
        sqlString = "/*dialect*/update t2 set F_ora_PINumber = t1.FBillNo+'-'+Convert(varchar(6),t2.FSeq) from T_SAL_ORDER t1 join T_SAL_ORDERENTRY t2 on t1.FID=t2.FID " 
        sqlString=sqlString+" and isnull(t2.F_ora_PINumber,'')='' and t1.FID = "+FID
        rows = DBUtils.Execute(this.Context, sqlString);