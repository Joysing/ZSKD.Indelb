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

namespace ZSKD.Indelb.Plugins
{
    [Kingdee.BOS.Util.HotUpdate]
    [Description("发送未归还信息")]
    public class STK_ReturnScheduleMessage: IScheduleService
    {
        
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

            System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, JToken>> enumerator = json_token.GetEnumerator();
            //if (Convert.ToBoolean(json_token["Result"]["errcode"]["IsSuccess"].ToString()))
            //{ 
            //    string NewBillID = json_token["Result"]["errcode"]["SuccessEntitys"][0]["Id"].ToString();
            //    string NewBillNumber = json_token["Result"]["errcode"]["SuccessEntitys"][0]["Number"].ToString();

            //}

            string errcode_token = Convert.ToString(json_token["errcode"].ToString());
            string access_token = Convert.ToString(json_token["access_token"].ToString());

            //JObject modelJson = JObject.Parse(Convert.ToString(response_token));
            //modelJson
            //得到未归还的信息
            string STK_SqlStr = " select FBILLNO,FBILLTYPEID,FSALERID,FQTY,F_ZSKD_ALREADYOUTQTY ,F_ZSKD_DELAYTME,F_ZSKD_RETURNDATE,t6.FPHONE as FPHONE \n" +
                                    "from T_STK_STKTRANSFERIN t1 \n" +
                                    "join T_STK_STKTRANSFERINENTRY t2 on t1.FID=t2.FID\n" +
                                    "join T_BD_OPERATORENTRY t3 on t3.FOPERATORTYPE='XSY' and t3.FENTRYID=t1.FSALERID\n" +
                                    "join T_BD_STAFF t4 on t3.FSTAFFID = t4.FSTAFFID \n" +
                                    "join t_BD_Person t5 on t5.FPERSONID = t4.FPERSONID\n" +
                                    "join T_SEC_USER t6 on  t6.FLINKOBJECT = t5.FPERSONID\n" +
                                    "where FSALERID!=0   and FQTY!=F_ZSKD_ALREADYOUTQTY and FBILLTYPEID='606d2d51151e28' \n" +
                                    "and (case when isnull(F_ZSKD_DELAYTME,'')!=''   or F_ZSKD_DELAYTME >F_ZSKD_RETURNDATE then F_ZSKD_DELAYTME else F_ZSKD_RETURNDATE end<GetDate())";
            Kingdee.BOS.Orm.DataEntity.DynamicObjectCollection STK_rows = DBUtils.ExecuteDynamicObject(ctx, STK_SqlStr);

            //遍历结果集，发送 信息
            if (STK_rows.Count > 0)
            {
                string MessageId = "";
                for (int i = 0; i < STK_rows.Count; i++)
                {
                    MessageId = Convert.ToString(SequentialGuid.NewGuid());
                    DynamicObject dynamicObject = STK_rows[i];
                    //获取用户ID
                    string mobile = Convert.ToString(dynamicObject["FPHONE"]);//电话号码
                    string httpsUserID = "https://oapi.dingtalk.com/user/get_by_mobile?access_token=" + access_token + "&mobile=" + mobile;
                    var client_userid = new RestClient(httpsUserID);
                    client_userid.Timeout = -1;
                    var requestt_userid = new RestRequest(Method.GET);
                    IRestResponse responset_userid = client_userid.Execute(requestt_userid);

                    JObject json_userid = (JObject)JsonConvert.DeserializeObject(Convert.ToString(responset_userid.Content));
                    string errcode_userid = Convert.ToString(json_userid["errcode"].ToString());
                    string access_userid = Convert.ToString(json_userid["userid"].ToString());


                    //Console.WriteLine(responset_userid.Content);

                    string FBILLNO = Convert.ToString(dynamicObject["FBILLNO"]);//订单号

                    string content = Convert.ToString("你好，借出调拨单 的 单据编号为： " + FBILLNO + "您未归还,麻烦您下推销售出库单或归还调拨单进行归还操作，或者修改延长日期");
                
                    string http_mess = "https://oapi.dingtalk.com/topapi/message/corpconversation/asyncsend_v2?access_token=" + access_token;

                    var client_mess = new RestClient(http_mess);
                    client_mess.Timeout = -1;
                    var request_mess = new RestRequest(Method.POST);
                    request_mess.AddHeader("Content-Type", "text/plain");
                    string Parameter = "{\r\n\t\"agent_id\":" + agent_id + ",\r\n\t\"msg\":{\r\n\t\t\"msgtype\":\"text\",\r\n\t\t\"text\":{\r\n\t\t\t\"content\":\"" + content + "\"\r\n\t\t}\r\n\t},\r\n\t\"userid_list\":\"" + access_userid + "\"\r\n}";
                    request_mess.AddParameter("text/plain", Parameter  , ParameterType.RequestBody);
                    IRestResponse response_mess = client_mess.Execute(request_mess);

                    JObject json_mess = (JObject)JsonConvert.DeserializeObject(Convert.ToString(response_mess.Content));
                    string errcode_mess = Convert.ToString(json_mess["errcode"].ToString());









                    //string access_mess = json_token["userid"].ToString();
                    //Console.WriteLine(response_Mess.Content);


                    //double FQTY = Convert.ToDouble(dynamicObject["FQTY"]);
                    //double F_ZSKD_ALREADYOUTQTY = Convert.ToDouble(dynamicObject["F_ZSKD_ALREADYOUTQTY"]);
                    //string Title = Convert.ToString("借出调拨未归还");
                    //string Content = Convert.ToString("你好，借出调拨单 的 单据编号为： "+ FBILLNO+ "您未归还麻烦请下推销售出库单或归还调拨单或修改延长日期"); 


                    //string access_token = "asgas";
                    //var client = new RestClient("https://oapi.dingtalk.com/robot/send?access_token=bcbada02e519d5bce29ce72452835c3b42d66a8f37b48374ac18f6e14f08f97d");
                    //client.Timeout = -1;
                    //var request = new RestRequest(Method.POST);
                    //request.AddHeader("Content-Type", "application/json");
                    //request.AddHeader("msgtype", "text");
                    //request.AddParameter("application/json", "{\"msgtype\": \"text\",\"text\": {\"content\": \"啊刚刚四大, 是不一35324234样1111111111111的烟火\"}}", ParameterType.RequestBody);
                    //IRestResponse response = client.Execute(request);
                    //Console.WriteLine(response.Content);

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
}
