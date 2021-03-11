using Kingdee.BOS.WebApi.Client;
using log4net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using static Kingdee.BOS.WebApi.Client.WebRequestHelper;
using MSExcel = Microsoft.Office.Interop.Excel;

namespace ZSKD.Indelb.ReciveBill
{
    public partial class Form1 : Form
    {
        private static ILog log = LogManager.GetLogger("MainForm");
        public ApiClient client;//连接
        public Form1()
        {
            InitializeComponent();
            log4net.Config.XmlConfigurator.Configure();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            Login();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            outPutReciveBill();
        }
        public void Login()
        {
            log.Info("登录中...");
            try
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)SecurityProtocolTypeEnum.Ssl3 | (SecurityProtocolType)SecurityProtocolTypeEnum.Tls | (System.Net.SecurityProtocolType)SecurityProtocolTypeEnum.Tls11 | (SecurityProtocolType)SecurityProtocolTypeEnum.Tls12;

                string result;
                string sSERVER = ConfigurationManager.ConnectionStrings["SERVER"].ToString().Trim();
                string sDBID = ConfigurationManager.ConnectionStrings["DBID"].ToString().Trim();
                string sUserName = ConfigurationManager.ConnectionStrings["UID"].ToString().Trim();
                string sPassword = ConfigurationManager.ConnectionStrings["PWD"].ToString().Trim();
                string sAppId = ConfigurationManager.ConnectionStrings["AppId"].ToString().Trim();
                string sAppSecret = ConfigurationManager.ConnectionStrings["AppSecret"].ToString().Trim();
                if (!sSERVER.Equals("") && !sDBID.Equals("") && !sUserName.Equals("") && !sPassword.Equals(""))
                {
                    client = new ApiClient(sSERVER);
                    object[] _objInfo = new object[] { sDBID, sUserName, sPassword, 2052 };

                    var ret = client.LoginByAppSecret(sDBID, sUserName, sAppId, sAppSecret, 2052);
                    //var ret = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.AuthService.ValidateUser", _objInfo);
                    result = JObject.Parse(ret)["LoginResultType"].Value<string>();

                    switch (result)
                    {
                        case "0":
                            log.Info("登录失败，请检查与站点地址、数据中心Id，用户名及密码！");
                            //textBox_log.AppendText(Utils.getNowTime() + " 登录失败，请检查与站点地址、数据中心Id，用户名及密码！\r\n");
                            break;
                        case "1":
                            JObject jsonRoot = new JObject();
                            string DataCenterName = JObject.Parse(ret)["Context"]["DataCenterName"].Value<string>();
                            log.Info("登录成功！账套名称："+ DataCenterName);
                            //textBox_log.AppendText(Utils.getNowTime() + " 登录成功！\r\n");
                            break;
                        case "-1":
                            log.Info("登录失败！");
                            log.Info(JObject.Parse(ret)["Message"].Value<string>());
                            //textBox_log.AppendText(Utils.getNowTime() + " 登录失败！\r\n");
                            break;
                    }

                }
            }
            catch (Exception exp)
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("程序运行遇到了未知的错误：");
                sb.Append("错误提示：").AppendLine(exp.Message);
                sb.Append("错误堆栈：").AppendLine(exp.StackTrace);
                //textBox_log.AppendText(Utils.getNowTime() + sb + " \r\n");
                log.Error(sb);
            }
        }
        private void outPutReciveBill()
        {
            List<List<object>> Bills = PUR_ReceiveBill.GetAllBill(client, "FDocumentStatus = 'C' and FCheckInComing = 1");//todo F_PAEZ_Exported=0 未导出
            MSExcel.Application excelApp = new MSExcel.Application
            {
                Visible = false//是打开可见
            };
            MSExcel.Workbooks _workbooks = excelApp.Workbooks;
            //MSExcel._Workbook _workbook = _workbooks.Add(AppDomain.CurrentDomain.BaseDirectory+"\\DD_20200901084512--ERP输出模板.XLS");
            MSExcel._Workbook _workbook = _workbooks.Add(System.Reflection.Missing.Value);
            MSExcel._Worksheet whs = _workbook.Sheets[1];//获取第1张工作表

            whs.Name = "Sheet1";
            //headline
//            进货单号 产品编号    物料名称 物料规格    厂商 报检数量    厂商编码 物料分类名称  实收数量 不良数 QIS报检单号
//DD20200901 - 001  1.10.035 - 1053   灯盒 ABS，84 * 58 * 13，白色（同顺德环威XC - 40J - 06 - 06)	顺德区容桂广大塑料制品厂    157 2.0085  塑料件 0   0   20200901084512001
            whs.Cells[1, 1] = "进货单号";
            whs.Cells[1, 2] = "产品编号";
            whs.Cells[1, 3] = "物料名称";
            whs.Cells[1, 4] = "物料规格";
            whs.Cells[1, 5] = "厂商";
            whs.Cells[1, 6] = "报检数量";
            whs.Cells[1, 7] = "厂商编码";
            whs.Cells[1, 8] = "物料分类名称";
            whs.Cells[1, 9] = "实收数量";
            whs.Cells[1, 10] = "不良数";
            whs.Cells[1, 11] = "QIS报检单号";

            Dictionary<string, string> BillIDsDic = new Dictionary<string, string>();
            for (int i=0;i< Bills.Count; i++)
            {
                string BillID= Convert.ToString(Bills[i][0]);
                string BillNo= Convert.ToString(Bills[i][1]);
                if (!BillIDsDic.ContainsKey(BillID))
                {
                    BillIDsDic.Add(BillID, BillNo);
                }
                whs.Cells[i+2, 1] = BillNo;
                whs.Cells[i+2, 2] = Bills[i][2];
                whs.Cells[i+2, 3] = Bills[i][3];
                whs.Cells[i+2, 4] = Bills[i][4];
                whs.Cells[i+2, 5] = Bills[i][6];
                whs.Cells[i+2, 6] = Bills[i][7];
                whs.Cells[i+2, 7] = Bills[i][5];
                whs.Cells[i+2, 8] = "物料分类名称";
                whs.Cells[i+2, 9] = 0;
                whs.Cells[i+2, 10] = 0;
                whs.Cells[i+2, 11] = "QIS报检单号";
            }
            string fileName = AppDomain.CurrentDomain.BaseDirectory + "DD_" + DateTime.Now.ToString("yyyyMMddHHmmssf") + ".XLS";
            whs.SaveAs(fileName, 51);
            //关闭对象
            Marshal.ReleaseComObject(_workbook);
            Marshal.ReleaseComObject(whs);
            excelApp.Quit();
            GC.Collect();

            log.Info("正在更新该订单的同步状态:");
            UpdateSyncStatus("PUR_ReceiveBill", BillIDsDic);

        }

        /// <summary>
        /// 更新订单的同步状态字段
        /// </summary>
        /// <param name="sFormId">需要更新的订单类型</param>
        /// <param name="dictionary">需要更新的订单FID和FBillNo</param>
        public void UpdateSyncStatus(string sFormId, Dictionary<string, string> dictionary)
        {
            //textBox_log.AppendText(Utils.getNowTime() + " 正在更新订单的同步状态...\r\n");
            string sModel = "";

            foreach (string FID in dictionary.Keys)
            {
                sModel += "{\"FID\":\"" + FID + "\",\"F_PAEZ_Exported\":\"1\"},";
            }
            sModel = sModel.Remove(sModel.LastIndexOf(","), 1); ; //移除掉最后一个","

            string sContent = "{\"ValidateFlag\":false,\"IsDeleteEntry\":false,\"Model\":[" + sModel + "]}";
            object[] saveInfo = new object[] { sFormId, sContent };
            string responseStatus = client.Execute<string>("Kingdee.BOS.WebApi.ServicesStub.DynamicFormService.BatchSave", saveInfo);
            JObject jsonResponseStatus = (JObject)JsonConvert.DeserializeObject(responseStatus);
            //所有订单都更新成功时
            if (Convert.ToBoolean(jsonResponseStatus["Result"]["ResponseStatus"]["IsSuccess"].ToString()))
            {
                //textBox_log.AppendText(Utils.getNowTime() + " 订单同步状态更新完成。\r\n");
                log.Info("订单同步状态更新完成。");
            }
            else//某些订单更新失败
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine(" 数据已同步但状态更新失败的单据，请手动检查同步情况：");
                List<string> errorsFIDIndex = new List<string>();
                JArray errorsJson = JArray.Parse(Convert.ToString(jsonResponseStatus["Result"]["ResponseStatus"]["Errors"]));
                for (int i = 0; i < errorsJson.Count; i++)
                {
                    int DIndex = Convert.ToInt32(errorsJson[i]["DIndex"].ToString());//sContent的位置，即dictionary中的索引
                    string Message = errorsJson[i]["Message"].ToString();//错误信息
                    string FieldName = errorsJson[i]["FieldName"].ToString();//出错的字段

                    sb.Append(dictionary.Values.ElementAt(DIndex));
                    if (!"".Equals(FieldName)) sb.Append(" 出错字段：").Append(FieldName);
                    sb.Append(" 错误信息：").AppendLine(Message);
                }
                //textBox_log.AppendText(Utils.getNowTime() + sb + "\r\n");
                log.Info(sb);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            ImportData();
            
        }
        private void ImportData()
        {
            MSExcel.Application excelApp = new MSExcel.Application
            {
                Visible = false//是打开可见
            };
            MSExcel.Workbooks _workbooks = excelApp.Workbooks;
            MSExcel._Workbook _workbook = _workbooks.Add("E:\\Joysing\\kingdee\\Plugins\\ZSKD.Indelb\\ZSKD.Indelb.ReciveBill\\IQC_G20200901112-写入ERP.xls");
            MSExcel._Worksheet whs = _workbook.Sheets[2];//获取第2张工作表 TODO：生产环境改回1

            whs.Activate();

            JArray ModelArray = new JArray();
            JObject ModelJson = new JObject();
            JArray FOrderEntrys = new JArray();
            List<string> ordenoList = new List<string>();

            int excelIndex = 2;
            int BillNoLineNumber = 0;//表头单据编号所在行数
            bool IsAllSuccess = true;//是否整个文件导入成功
            bool HasSuccess = false;//是否整个文件有导入成功的订单
            bool HasError = false;//是否整个文件有导入失败的订单

            while (true)
            {
                try
                {
                    MSExcel.Range rang = (MSExcel.Range)whs.Cells[excelIndex, 25];//ERP收料通知单单号
                    if (rang.Value != null)
                    {
                        string ERPBillNo = Convert.ToString(rang.Value);
                        string PrevFBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex - 1, 25]).Value);//上一行的ERP收料通知单单号
                        string NextFBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex + 1, 25]).Value);//下一行的ERP收料通知单单号
                        string QISBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 1]).Value);//QIS检验单号
                        string FDate = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 2]).Value);
                        string MaterialNumber = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 6]).Value);
                        string ComputerResult = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 13]).Value);//电脑判定
                        double RealQty = Convert.ToDouble(((MSExcel.Range)whs.Cells[excelIndex, 15]).Value);

                        //ERP收料通知单单号和上一行不同，则是另一张单据
                        if (!PrevFBillNo.Equals(ERPBillNo))
                        {
                            BillNoLineNumber = excelIndex;

                            //ordenoList.Add(ERPBillNo);
                            ////设置单据头信息
                            //ModelJson.Add("FBillTypeID", new JObject() { { "FNumber", "JYD001_SYS" } });//单据类型=来料检验单
                            //ModelJson.Add("FBusinessType", "1");//1 采购检验
                            //ModelJson.Add("FDate", FDate);
                            //ModelJson.Add("FInspectOrgId", new JObject() { { "FNumber", "100.1" } });//质检组织
                            //ModelJson.Add("FSourceOrgId", new JObject() { { "FNumber", "100.1" } });//来源组织
                            //ModelJson.Add("FEntity", FOrderEntrys);//分录

                            log.Info("正在读取：" + ERPBillNo);
                        }

                        string NeedPushEntryIds = "";
                        //excel的一行是相同物料合并数量的，在ERP查源单，查出来可能有多行物料
                        List<List<object>> Bills = PUR_ReceiveBill.GetAllBill(client, "FBillNo='" + ERPBillNo + "'" + " and FMaterialID.FNumber='" + MaterialNumber + "'");//todo F_PAEZ_Exported=1 未导出
                        for (int i = 0; i < Bills.Count; i++)
                        {
                            double FQty = 0;
                            string SrcBillID = Convert.ToString(Bills[i][0]);
                            string SrcBillNo = Convert.ToString(Bills[i][1]);
                            string SrcEntryID = Convert.ToString(Bills[i][8]);
                            double FActReceiveQty = Convert.ToDouble(Bills[i][7]); //交货数量
                            double FCheckJoinQty = Convert.ToDouble(Bills[i][9]);  //检验关联数量
                            double NoCheckQty = FActReceiveQty- FCheckJoinQty;  //剩余未检验数量
                            string SrcBillTypeID = Convert.ToString(Bills[i][10]);
                            string SrcSeq = Convert.ToString(Bills[i][11]);
                            if (NoCheckQty > RealQty)
                            {
                                FQty = RealQty;
                            }
                            else
                            {
                                FQty = NoCheckQty;
                            }
                            RealQty = RealQty - FQty;
                            if (FQty <= 0) continue;
                            NeedPushEntryIds = NeedPushEntryIds + SrcEntryID + ",";
                            //一行下推成一单
                            string NewBillId = PUR_ReceiveBill.PushToInspectBill(client, SrcEntryID);
                            if (!"".Equals(NewBillId))
                            {
                                //修改数量
                                List<List<object>> InspectBills = QM_InspectBill.GetAllBill(client, "FID=" + NewBillId);
                                if (InspectBills.Count > 0)
                                {
                                    JObject Entry = new JObject();
                                    ModelJson.Add("FID", Convert.ToString(InspectBills[0][0]));
                                    ModelJson.Add("FEntity", FOrderEntrys);
                                    FOrderEntrys.Add(Entry);
                                    Entry.Add("FEntryID", Convert.ToString(InspectBills[0][2]));
                                    Entry.Add("FInspectQty", FQty);
                                    Entry.Add("FMemo", "QIS导入，单号" + QISBillNo);
                                    if (!"合格".Equals(ComputerResult))
                                    {
                                        Entry.Add("FInspectResult", "2");//检验结果=不合格
                                    }
                                    Dictionary<string, object> ImportResult = QM_InspectBill.SaveBill(client, new StringBuilder(ModelJson.ToString()), new List<string>(ordenoList));
                                    ModelJson= new JObject();
                                    FOrderEntrys = new JArray();
                                    if (!Convert.ToBoolean(ImportResult["IsSuccess"]))
                                    {
                                        HasError = true;
                                        IsAllSuccess = false;
                                    }
                                    else
                                    {
                                        HasSuccess = true;
                                    }
                                }
                                else
                                {
                                    log.Info("下推的单据已被删除。");
                                }
                                
                            }


                            //设置分录明细
                            //JObject Entry = new JObject();
                            //JArray FEntity_LinkArray = new JArray();
                            //JObject FEntity_Link = new JObject();
                            //FEntity_LinkArray.Add(FEntity_Link);
                            //FEntity_Link.Add("FEntity_Link_FRuleId", "QM_PURReceive2Inspect");
                            //FEntity_Link.Add("FEntity_Link_FSTableName", "T_PUR_ReceiveEntry");//注意区分大小写
                            //FEntity_Link.Add("FEntity_Link_FSBillId", SrcBillID);//源单（采购订单）内码
                            //FEntity_Link.Add("FEntity_Link_FSId", SrcEntryID);//源单（采购订单）分录内码
                            //Entry.Add("FEntity_Link", FEntity_LinkArray);
                            //FOrderEntrys.Add(Entry);
                            //Entry.Add("FMaterialId", new JObject() { { "FNumber", "JYD001_SYS" } });//物料编码
                            //Entry.Add("FInspectQty", FQty);//检验数量
                            //Entry.Add("FSrcBillType0", SrcBillTypeID);//源单类型
                            //Entry.Add("FSrcBillNo0", SrcBillNo);//源单编号
                            //Entry.Add("FSrcInterId0", SrcBillID);//源单内码
                            //Entry.Add("FSrcEntryId0", SrcEntryID);//源单分录内码
                            //Entry.Add("FSrcEntrySeq0", SrcSeq);//源单行号

                        }
                        //移除掉最后一个","
                        if (NeedPushEntryIds.Length>0) NeedPushEntryIds = NeedPushEntryIds.Remove(NeedPushEntryIds.LastIndexOf(","), 1);

                        //判断 当前是一张单据的最后一条分录
                        if (((MSExcel.Range)whs.Cells[excelIndex + 1, 1]).Value == null || !ERPBillNo.Equals(NextFBillNo) )
                        {
                            //if (FOrderEntrys.Count > 0)
                            //{

                            //    Dictionary<string, object> ImportResult = QM_InspectBill.SaveBill(client, new StringBuilder(ModelJson.ToString()), new List<string>(ordenoList));
                            //    if (!Convert.ToBoolean(ImportResult["IsSuccess"]))
                            //    {
                            //        HasError = true;
                            //        IsAllSuccess = false;
                            //    }
                            //    else
                            //    {
                            //        HasSuccess = true;
                            //    }
                            //}

                            //ordenoList = new List<string>();
                            //ModelArray = new JArray();
                            //ModelJson = new JObject();
                            //FOrderEntrys = new JArray();
                        }
                        //TODO: excel已导出改为“是”
                    }
                    else
                    {
                        break;
                    }
                }
                catch (Exception ex)
                {
                    log.Error(ex.Message);
                }
                finally
                {
                    excelIndex++;
                }

            }
            

            //whs.SaveAs("E:\\Joysing\\kingdee\\Plugins\\ZSKD.Indelb\\ZSKD.Indelb.ReciveBill\\IQC_G20200901112-写入ERP.xls", 51);
            //关闭对象
            Marshal.ReleaseComObject(_workbook);
            Marshal.ReleaseComObject(whs);
            excelApp.Quit();
            GC.Collect();
        }
    }
}
