using Kingdee.BOS.WebApi.Client;
using log4net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace ZSKD
{
    /// <summary>
    /// 公共操作：提交、审核
    /// </summary>
    public class CommonOperate
    {
        private static ILog log = LogManager.GetLogger("CommonOperate");

        /// <summary>
        /// 提交单据
        /// </summary>
        /// <param name="Numbers">需要被提交的单据</param>
        public bool SubmitBill(ApiClient client, string FormId, StringBuilder Numbers)
        {
            log.Info("正在提交单据：" + Numbers);

            string sContent = "{\"Numbers\":[" + Numbers + "]}";
            string responseStatus = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Submit", new object[] { FormId, sContent });
            JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(responseStatus);

            if (Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString()))
            {
                log.Info("所有单据提交成功！");

                return true;
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine(" 单据提交失败!");
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

        /// <summary>
        /// 审核单据
        /// </summary>
        /// <param name="Numbers">需要被审核的单据</param>
        public bool AuditBill(ApiClient client, string FormId, StringBuilder Numbers)
        {
            log.Info("正在审核单据：" + Numbers);

            string sContent = "{\"Numbers\":[" + Numbers + "],\"InterationFlags\":\"STK_InvCheckResult\"}";
            string responseStatus = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.Audit", new object[] { FormId, sContent });
            JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(responseStatus);

            if (Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString()))
            {
                log.Info("所有单据审核成功！");
                return true;
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine(" 单据审核失败!");
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
