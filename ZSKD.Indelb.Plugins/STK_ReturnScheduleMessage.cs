using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Contracts;
using Kingdee.BOS.Core; 
using Kingdee.BOS.Util;
using System;
using System.ComponentModel; 
using Kingdee.BOS.Orm.DataEntity;
using RestSharp;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using javax.crypto;
using javax.crypto.spec;
using java.net;
using System.Text;
using System.Security.Cryptography;

namespace ZSKD.Indelb.Plugins
{
    [Kingdee.BOS.Util.HotUpdate]
    [Description("发送未归还信息")]
    public class STK_ReturnScheduleMessage: IScheduleService
    {




        public string getErrorResult(string errcode_token,string errorInfo,string solveWay) { 

            return "错误代码：" + "\\\"" + errcode_token + "\\\" ,错误信息： " + errorInfo+",解决方法："+ solveWay;
        }
        
        public void Run(Context ctx, Schedule schedule)
        {

            //钉钉参数的信息
            string DD_SqlStr = "select FAGENTID as FAGENTID,FAPPKEY as FAPPKEY,FAPPSECRET as FAPPSECRET from T_MOB_DDAppInfo where FAPPNAME='发送信息'";
            Kingdee.BOS.Orm.DataEntity.DynamicObjectCollection DD_Row = DBUtils.ExecuteDynamicObject(ctx, DD_SqlStr); 
            DynamicObject DD_dynamicObject = DD_Row[0] as DynamicObject;
            string agent_id = Convert.ToString(DD_dynamicObject["FAGENTID"]);
            string FAPPKEY=Convert.ToString(DD_dynamicObject["FAPPKEY"]);
            string FAPPSECRET = Convert.ToString(DD_dynamicObject["FAPPSECRET"]);
            string httpsAccess_token = "https://oapi.dingtalk.com/gettoken?appkey=" + FAPPKEY + "&appsecret=" + FAPPSECRET;
            //获取access_token
            var client_token = new RestClient(httpsAccess_token);
            client_token.Timeout = -1;
            var request = new RestRequest(Method.GET);
            IRestResponse response_token = client_token.Execute(request);
            //Console.WriteLine(response_token.Content);

            JObject json_token = (JObject)JsonConvert.DeserializeObject(Convert.ToString(response_token.Content));

            //System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, JToken>> enumerator = json_token.GetEnumerator();
          
            string errcode_token = Convert.ToString(json_token["errcode"].ToString());
           
            //JObject modelJson = JObject.Parse(Convert.ToString(response_token));
            //modelJson
            //得到未归还的信息
          
            if (!"0".Equals(errcode_token))
            {
                string errorInfo = "星空的钉钉设置的“发送信息”不正确";
                string solveWay = "请检查钉钉中的“发送信息”应用中的APPKEY与APPSECRET与星空的是否相同，如不相同，请将星空的钉钉设置的“发送信息”行改为与钉钉的一样,详细操作请查看中山金蝶提供的使用文档";
                ReturnError(getErrorResult(errcode_token, errorInfo, solveWay), ctx);
            }
            //遍历结果集，发送 信息
            else {    string STK_SqlStr = " select FBILLNO,t6.FNAME as FSalName,FQTY,F_ZSKD_ALREADYOUTQTY ,F_ZSKD_DELAYTME,F_ZSKD_RETURNDATE,t6.FPHONE\n" +
                                                    "from T_STK_STKTRANSFERIN t1 \n" +
                                                    "join T_STK_STKTRANSFERINENTRY t2 on t1.FID=t2.FID\n" +
                                                    "join T_BD_OPERATORENTRY t3 on t3.FOPERATORTYPE='XSY' and t3.FENTRYID=t1.FSALERID\n" +
                                                    "join T_BD_STAFF t4 on t3.FSTAFFID = t4.FSTAFFID \n" +
                                                    "join t_BD_Person t5 on t5.FPERSONID = t4.FPERSONID\n" +
                                                    "join T_SEC_USER t6 on  t6.FLINKOBJECT = t5.FPERSONID\n" +
                                                    "join T_BAS_BILLTYPE t7 on t7.FBILLTYPEID=t1.FBILLTYPEID  \n" +
                                                    "where FSALERID!=0   and FQTY!=F_ZSKD_ALREADYOUTQTY and t7.FNUMBER='ZJDBD_JCDB' \n" +
                                                    "and (case when isnull(F_ZSKD_DELAYTME,'')!=''   or F_ZSKD_DELAYTME >F_ZSKD_RETURNDATE then F_ZSKD_DELAYTME else F_ZSKD_RETURNDATE end<GetDate())";
                Kingdee.BOS.Orm.DataEntity.DynamicObjectCollection STK_rows = DBUtils.ExecuteDynamicObject(ctx, STK_SqlStr);

                if (STK_rows.Count > 0)
                {

                    string access_token = Convert.ToString(json_token["access_token"].ToString());

                    for (int i = 0; i < STK_rows.Count; i++)
                    {
                        //MessageId = Convert.ToString(SequentialGuid.NewGuid());
                        DynamicObject dynamicObject = STK_rows[i]; 
                        string mobile = Convert.ToString(dynamicObject["FPHONE"]);//电话号码
                        string FSalName= Convert.ToString(dynamicObject["FSalName"]);//销售员 
                        string FBILLNO = Convert.ToString(dynamicObject["FBILLNO"]);//订单号
                        string httpsUserID = "https://oapi.dingtalk.com/user/get_by_mobile?access_token=" + access_token + "&mobile=" + mobile;
                        var client_userid = new RestClient(httpsUserID);
                        client_userid.Timeout = -1;
                        var requestt_userid = new RestRequest(Method.GET);
                        IRestResponse responset_userid = client_userid.Execute(requestt_userid);
                        JObject json_userid = (JObject)JsonConvert.DeserializeObject(Convert.ToString(responset_userid.Content));
                        string errcode_userid = Convert.ToString(json_userid["errcode"].ToString());
                        if (!"0".Equals(errcode_userid))
                        {

                            if ("60020".Equals(errcode_userid)) {
                                string errorInfo = Convert.ToString(json_userid["errmsg"].ToString()) ;
                                string solveWay = "请检查错误信息的IP与钉钉微应用的IP是否一样，如不一样，请设置钉钉应用IP与该IP一致,详细操作请查看中山金蝶提供的使用文档";
                                ReturnError(getErrorResult(errcode_userid, errorInfo, solveWay), ctx);
                            }
                            else
                            {
                                string errorInfo = "借出调拨单单号为" + FBILLNO + "中,销售员：" + FSalName + "的电话号码星空配置不正确";
                                string solveWay = "请检查星空用户为" + FSalName + " ，是否一样，需改为钉钉的一样,详细操作请查看中山金蝶提供的使用文档";
                                ReturnError(getErrorResult(errcode_userid, errorInfo, solveWay), ctx);
                            }

                        }
                        else
                        {

                            string access_userid = Convert.ToString(json_userid["userid"].ToString());

                            string content = Convert.ToString("你好，借出调拨单 的 单据编号为： " + FBILLNO + "您未归还,麻烦您下推销售出库单或归还调拨单进行归还操作，或者修改延长日期");

                            string http_mess = "https://oapi.dingtalk.com/topapi/message/corpconversation/asyncsend_v2?access_token=" + access_token;

                            var client_mess = new RestClient(http_mess);
                            client_mess.Timeout = -1;
                            var request_mess = new RestRequest(Method.POST);
                            request_mess.AddHeader("Content-Type", "text/plain");
                            string Parameter = "{\r\n\t\"agent_id\":" + agent_id + ",\r\n\t\"msg\":{\r\n\t\t\"msgtype\":\"text\",\r\n\t\t\"text\":{\r\n\t\t\t\"content\":\"" + content + "\"\r\n\t\t}\r\n\t},\r\n\t\"userid_list\":\"" + access_userid + "\"\r\n}";
                            request_mess.AddParameter("text/plain", Parameter, ParameterType.RequestBody);
                            IRestResponse response_mess = client_mess.Execute(request_mess);

                            JObject json_mess = (JObject)JsonConvert.DeserializeObject(Convert.ToString(response_mess.Content));
                            string errcode_mess = Convert.ToString(json_mess["errcode"].ToString());
                            if (!"0".Equals(errcode_mess))
                            {
                                string errorInfo = "星空的钉钉设置的“发送信息”中的agentid不正确";
                                string solveWay = "请检查钉钉中的“发送信息”应用中的agentid与星空的是否相同，如不相同，请将星空的钉钉设置的“发送信息”行 中的 agentid 改为与钉钉的一样,详细操作请查看中山金蝶提供的使用文档";
                                ReturnError(getErrorResult(errcode_token, errorInfo, solveWay), ctx);
                            }

                        }
                        //string access_mess = json_token["userid"].ToString();
                        //Console.WriteLine(response_Mess.Content); 
                        //double FQTY = Convert.ToDouble(dynamicObject["FQTY"]);
                        //double F_ZSKD_ALREADYOUTQTY = Convert.ToDouble(dynamicObject["F_ZSKD_ALREADYOUTQTY"]);
                        //string Title = Convert.ToString("借出调拨未归还");
                        //string Content = Convert.ToString("你好，借出调拨单 的 单据编号为： "+ FBILLNO+ "您未归还麻烦请下推销售出库单或归还调拨单或修改延长日期");  
                        //string sql = "insert into T_WF_MESSAGESEND(FMESSAGEID,FTITLE,FCONTENT,FSENDERID,FCREATETIME,FRECEIVERID,FCOMPLETEDTIME,FSTATUS,FTYPE,";
                        //sql = sql + "FOBJECTTYPEID,FKEYVALUE,FSENDMSGID,FRECEIVERSDISP,FATTACHDATA,FFILEUPDATE)values(";
                        //sql = sql + "'" + MessageId + "','" + Title + "','" + Content + "'," + SenderId + ",GETDATE(),null,null,0,1,";
                        //sql = sql + "'' ," + "0" + ",'','Administrator','',null)";

                        //sql = sql + " \n ";
                        //sql = sql + "insert into T_WF_MESSAGE(FMESSAGEID,FTITLE,FCONTENT,FSENDERID,FCREATETIME,FRECEIVERID,FCOMPLETEDTIME,FSTATUS,FTYPE,";
                        //sql = sql + "FOBJECTTYPEID,FKEYVALUE,FSENDMSGID,FRECEIVERSDISP,FATTACHDATA,FFILEUPDATE,FPROCINSTID,FACTIVITYID)values(";
                        //sql = sql + "'" + MessageId + "','" + Title + "','" + Content + "'," + SenderId + ",GETDATE()," + FSALERID + ",NULL,0,1,";
                        //sql = sql + "'',0,'" + MessageId + "','" + "''" + "','',NULL,'',0)";
                    }
                }
            }



        }
        public void ReturnError(string response_messContent,Context ctx) {

            string DD_SqlStrQXX = "select   FAGENTID as FAGENTID,FAPPKEY as FAPPKEY,FAPPSECRET as FAPPSECRET from T_MOB_DDAppInfo where FAPPNAME='发送群信息'";
            Kingdee.BOS.Orm.DataEntity.DynamicObjectCollection DD_RowQXX = DBUtils.ExecuteDynamicObject(ctx, DD_SqlStrQXX);
            DynamicObject DD_dynamicObjectQXX = DD_RowQXX[0] as DynamicObject;
            string FAPPSECRET_QXX = Convert.ToString(DD_dynamicObjectQXX["FAPPSECRET"]);
            string FAPPKEY_QXX = Convert.ToString(DD_dynamicObjectQXX["FAPPKEY"]);
            //https://oapi.dingtalk.com/robot/send?access_token=XXXXXX&timestamp=XXX&sign=XXX
            var client_QXX = new RestClient("https://oapi.dingtalk.com/robot/send?access_token=" + FAPPSECRET_QXX+ GetSignParam(FAPPKEY_QXX));
            client_QXX.Timeout = -1;
            var request_QXX = new RestRequest(Method.POST);
            request_QXX.AddHeader("Content-Type", "application/json");
            request_QXX.AddHeader("msgtype", "text");

            string requestParameter = "{\"msgtype\": \"text\",\"text\": {\"content\": \"" + response_messContent + "\"}}";

            request_QXX.AddParameter("application/json", requestParameter, ParameterType.RequestBody);

            //request_QXX.AddParameter("application/json", "{\"msgtype\": \"text\",\"text\": {\"content\": \"" + response_messContent  + "\"}}", ParameterType.RequestBody);
            //request_QXX.AddParameter("application/json", reqBody, ParameterType.RequestBody);
            IRestResponse response_QXX = client_QXX.Execute(request_QXX);

            JObject json_QXX = (JObject)JsonConvert.DeserializeObject(Convert.ToString(response_QXX.Content));
            string errcode_QXX = Convert.ToString(json_QXX["errcode"].ToString());
            if (!"0".Equals(errcode_QXX)) {

                throw new Exception("星空配置钉钉的群消息assesstoken与签名不一样，请检查");

            }

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="secret">密钥，机器人安全设置页面，加签一栏下面显示的SEC开头的字符串。</param>
        /// <returns></returns>
        public static string GetSignParam(string secret)
        {
            long timestamp = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;

            string stringToSign = timestamp + "\n" + secret;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(System.Text.Encoding.Default.GetBytes(secret), "HmacSHA256"));
            byte[] signData = mac.doFinal(System.Text.Encoding.Default.GetBytes(stringToSign));
            string sign = URLEncoder.encode(Convert.ToBase64String(signData), "UTF-8");
            return "&timestamp=" + Convert.ToString(timestamp) + "&sign=" + sign;
                
        }
        //        public static void GetSign(string secret) 
        //        {

        //            long timestamp = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;

        //            string stringToSign = timestamp + "\n" + secret;
        //            Mac mac = Mac.getInstance("HmacSHA256");
        //            mac.init(new SecretKeySpec(System.Text.Encoding.Default.GetBytes(secret), "HmacSHA256"));
        //            //byte[] signData = mac.doFinal(System.Text.Encoding.Default.GetBytes(stringToSign));
        //            string sign = URLEncoder.encode(EncodeBase64(stringToSign), "UTF-8"); 
        //        }





        //        private static string HmacSHA256(string secret, string signKey)
        //        {
        //            string signRet = string.Empty;
        //            using (System.Security.Cryptography.HMACSHA256 mac = new HMACSHA256(Encoding.UTF8.GetBytes(signKey)))
        //            {
        //                byte[] hash = mac.ComputeHash(Encoding.UTF8.GetBytes(secret));
        //                signRet = Convert.ToBase64String(hash);
        //                //signRet = ToHexString(hash); ;
        //            }
        //            return signRet;
        //        }

        //        //byte[]转16进制格式string
        //        public static string ToHexString(byte[] bytes)
        //        {
        //            string hexString = string.Empty;
        //            if (bytes != null)
        //            {
        //                StringBuilder strB = new StringBuilder();
        //                foreach (byte b in bytes)
        //                {
        //                    strB.AppendFormat("{0:x2}", b);
        //                }
        //                hexString = strB.ToString();
        //            }
        //            return hexString;
        //        } 













        //        /// <summary>
        //                         /// Base64加密
        //                         /// </summary>
        //                         /// <param name="codeName">加密采用的编码方式</param>
        //                         /// <param name="source">待加密的明文</param>
        //                         /// <returns></returns>
        //        public static string EncodeBase64(Encoding encode, string source)
        //        {
        //            byte[] bytes = encode.GetBytes(source);
        //            try
        //            {
        //                encode = Convert.ToBase64String(bytes);
        //            }
        //            catch
        //            {
        //                encode = source;
        //            }
        //            return encode;
        //        }

        //        /// <summary>
        //                            /// Base64加密，采用utf8编码方式加密
        //                            /// </summary>
        //                            /// <param name="source">待加密的明文</param>
        //                            /// <returns>加密后的字符串</returns>
        //        public static string EncodeBase64(string source)
        //        {
        //            return EncodeBase64(Encoding.UTF8, source);
        //        }
    }
}
