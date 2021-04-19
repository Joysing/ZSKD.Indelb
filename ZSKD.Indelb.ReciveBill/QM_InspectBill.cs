using Kingdee.BOS.WebApi.Client;
using log4net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ZSKD.Indelb.ReciveBill
{
    /// <summary>
    /// 检验单
    /// </summary>
    public class QM_InspectBill
    {
        private static ILog log = LogManager.GetLogger("QM_InspectBill");
        private static string FormID = "QM_InspectBill";


        /// <summary>
        /// 保存单据
        /// </summary>
        public static Dictionary<string, object> SaveBill(ApiClient client, StringBuilder sbModel, List<string> ordenoList)
        {
            Dictionary<string, object> result = new Dictionary<string, object>();
            //Model字串 
            string sContent = "{\"NeedUpDateFields\":[]," +
                "\"IsDeleteEntry\":false," + 
                "\"IsEntryBatchFill\":true," + 
                "\"Model\":" + sbModel +
                "}";
            object[] saveInfo = new object[] { FormID, sContent };

            try
            {
                //调用保存接口 
                var reqResult = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Save", saveInfo);

                if (reqResult != null)
                {
                    JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(reqResult);
                    bool IsSuccess = Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString());
                    result.Add("IsSuccess", IsSuccess);
                    //所有订单都成功时
                    if (IsSuccess)
                    {
                        log.Info("全部单导入成功。");
                        result.Add("Info", "导入成功");
                    }
                    else//某些订单失败
                    {
                        StringBuilder sb = new StringBuilder();
                        List<string> errorsFIDIndex = new List<string>();
                        JArray errorsJson = JArray.Parse(Convert.ToString(jsonResponseStatus["Result"]["ResponseStatus"]["Errors"]));
                        for (int i = 0; i < errorsJson.Count; i++)
                        {
                            int DIndex = Convert.ToInt32(errorsJson[i]["DIndex"].ToString());//sContent的位置，即ordenoList中的索引
                            string Message = errorsJson[i]["Message"].ToString();//错误信息
                            string FieldName = errorsJson[i]["FieldName"].ToString();//出错的字段

                            sb.Append(" 导入订单出错：" + ordenoList.ElementAt(DIndex));
                            if (!"".Equals(FieldName)) sb.Append(" 出错字段：").Append(FieldName);
                            sb.Append(" 错误信息：").AppendLine(Message);
                        }
                        log.Error(sb);
                        result.Add("Info", sb);
                    }

                    JArray SuccessEntitys = jsonResponseStatus["Result"]["ResponseStatus"]["SuccessEntitys"] as JArray;
                    StringBuilder sbSuccessEntitys = new StringBuilder();

                    foreach (JObject SuccessEntity in SuccessEntitys)
                    {
                        sbSuccessEntitys.Append("\"").Append(Convert.ToString(SuccessEntity["Number"])).Append("\",");
                    }
                    if (sbSuccessEntitys.Length > 0)
                    {
                        sbSuccessEntitys.Remove(sbSuccessEntitys.Length - 1, 1); ; //移除掉最后一个","
                    }

                    //if (sbSuccessEntitys.Length > 0)
                    //{
                    //    //提交
                    //    CommonOperate commonOperate = new CommonOperate();
                    //    commonOperate.SubmitBill(client, FormID, sbSuccessEntitys);
                    //    commonOperate.AuditBill(client, FormID, sbSuccessEntitys);
                    //}

                    return result;
                }

            }
            catch (Exception e)
            {
                log.Error(e);
                Form1.Executed = true;
            }
            return result;
        }

    /// <summary>
    /// 从Cloud中获取单据
    /// </summary>
    public static List<List<object>> GetAllBill(ApiClient client, string Filter)
        {
            int Limit = 2000;
            int StartRow = 0;
            List<List<object>> Bills = new List<List<object>>();
            List<List<object>> BillsOfPage;
            do
            {
                BillsOfPage = GetBillByPage(client, Limit, StartRow, Filter);
                StartRow += Limit;
                Bills = Bills.Union(BillsOfPage).ToList();

            } while (BillsOfPage != null & BillsOfPage.Count > 0);
            return Bills;
        }

        /// <summary>
        /// 从Cloud中获取单据
        /// </summary>
        private static List<List<object>> GetBillByPage(ApiClient client, int Limit, int StartRow,string Filter)
        {
            //字段是BOS里的标识，不是数据库字段名
            object[] paramInfo = new object[]
            {
               "{\"FormId\":\""+FormID+"\","+
                "\"TopRowCount\":0,"+// 最多允许查询的数量，0或者不要此属性表示不限制
                "\"Limit\":"+ Limit + ","+// 分页取数每页允许获取的数据，最大不能超过2000
                "\"StartRow\":"+ StartRow + ","+// 分页取数开始行索引，从0开始，例如每页10行数据，第2页开始是10，第3页开始是20
                "\"FilterString\":\""+Filter+"\","+// 过滤条件 
                "\"FieldKeys\":\"FID,FBillNo,FEntity_FEntryID,FPolicyDetail_FDetailID" +
                "\"}"
            };
            try
            {
                //调用查询接口 
                List<List<object>> reqResult = client.Execute<List<List<object>>>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExecuteBillQuery"
                    , paramInfo);
                return reqResult;
            }
            catch (Exception e)
            {
                log.Error(e);
                Form1.Executed = true;
            }
            return null;
        }
    }
}
