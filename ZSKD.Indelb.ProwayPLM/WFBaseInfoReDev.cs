using ProwayPLM.Workflow;
using System;

namespace ZSKD.Indelb.ProwayPLM
{
    /// <summary>
    /// 界面二开：启动流程界面
    /// D:\Program Files (x86)\kingdee\K3PLM\web\WorkflowView\WFBaseInfo.ascx
    /// </summary>
    public class WFBaseInfoReDev : Kingdee.K3.PLM.WorkflowView.WFBaseInfo
    {
        protected System.Web.UI.WebControls.Button btnTest;
        protected new void Page_Load(object sender, EventArgs e)
        {
            base.Page_Load(sender,e);
        }
        protected void btnTest_Click(object sender, EventArgs e)
        {
            new Exception("hhhhhhhhhhhhh");
        }
    }
}
