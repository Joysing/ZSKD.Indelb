using Kingdee.BOS.WebApi.Client;
using log4net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ZSKD.Indelb.ReciveBill
{
    /// <summary>
    /// 收料通知单
    /// </summary>
    public class PUR_ReceiveBill
    {
        private static ILog log = LogManager.GetLogger("PUR_ReceiveBill");
        private static string FormID = "PUR_ReceiveBill";
        
        public static string PushToInspectBill(ApiClient client,string EntryIds)
        {
            object[] paramInfo = new object[]
            {
                FormID,
               "{"+
                //"\"Ids\":0,"+
                //"\"Numbers\":[],"+
                "\"EntryIds\":\""+EntryIds+"\","+
                //"\"RuleId\":\"\","+
                //"\"TargetBillTypeId\":\"" +
                "\"TargetOrgId\":100102," + //固定广东英得尔 100.1
                "\"TargetFormId\":\"QM_InspectBill\"," +
                "\"IsEnableDefaultRule\":true," +
                "\"IsDraftWhenSaveFail\":false" +
                "}"
            };
            string responseStatus = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Push", paramInfo);
            JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(responseStatus);

            if (Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString()))
            {
                log.Info("所有单据下推成功！");
                string NewBillID = jsonResponseStatus["Result"]["ResponseStatus"]["SuccessEntitys"][0]["Id"].ToString();
                string NewBillNumber = jsonResponseStatus["Result"]["ResponseStatus"]["SuccessEntitys"][0]["Number"].ToString();
                return NewBillID;
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine(" 单据下推失败!");
                List<string> errorsFIDIndex = new List<string>();
                JArray errorsJson = JArray.Parse(Convert.ToString(jsonResponseStatus["Result"]["ResponseStatus"]["Errors"]));
                for (int i = 0; i < errorsJson.Count; i++)
                {
                    string Message = errorsJson[i]["Message"].ToString();//错误信息
                    string FieldName = errorsJson[i]["FieldName"].ToString();//出错的字段

                    if (!"".Equals(FieldName)) sb.Append(" 出错字段：").Append(FieldName);
                    sb.Append(" 错误信息：").AppendLine(Message);
                }
                log.Error(sb);
                return "";
            }
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
                "\"FieldKeys\":\"FID,FBillNo,FMaterialID.FNumber,FMaterialID.FName,FMaterialID.FSpecification,FSUPPLIERID.FNumber,FSUPPLIERID.FName,FActReceiveQty" +
                ",FDetailEntity_FEntryID,FCheckJoinQty,FBillTypeID,FDetailEntity_FSeq,F_ora_MatGroup" +
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
            }
            return null;
        }

        /// <summary>
        /// 调用ExportedToQIS操作
        /// </summary>
        /// <param name="Numbers">需要被操作的单据</param>
        public static bool ExportedToQIS(K3CloudApiClient client, StringBuilder Numbers)
        {
            log.Info("正在修改单据已导出QIS状态：" + Numbers);

            string sContent = "{\"Numbers\":[" + Numbers + "]}";
            //string responseStatus = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.ExportedToQIS", new object[] { FormID, sContent });
            string responseStatus=client.ExcuteOperation("PUR_ReceiveBill", "ExportedToQIS", sContent);
            JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(responseStatus);

            if (Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString()))
            {
                log.Info("修改单据已导出QIS状态成功！");
                return true;
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine(" 修改单据已导出QIS状态失败!");
                List<string> errorsFIDIndex = new List<string>();
                JArray errorsJson = JArray.Parse(Convert.ToString(jsonResponseStatus["Result"]["ResponseStatus"]["Errors"]));
                for (int i = 0; i < errorsJson.Count; i++)
                {
                    string Message = errorsJson[i]["Message"].ToString();//错误信息
                    string FieldName = errorsJson[i]["FieldName"].ToString();//出错的字段

                    if (!"".Equals(FieldName)) sb.Append(" 出错字段：").Append(FieldName);
                    sb.Append(" 错误信息：").AppendLine(Message);
                }
                log.Error(sb);
                return false;
            }

        }
    }
}
