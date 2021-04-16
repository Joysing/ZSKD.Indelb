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
using System.IO;
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
        public K3CloudApiClient client;//连接
        bool debug;//是否调试模式
        bool Executed;//是否执行完毕
        public static System.Timers.Timer aTimer;
        public Form1()
        {
            InitializeComponent();
            log4net.Config.XmlConfigurator.Configure();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            Login();
            debug = Convert.ToBoolean(ConfigurationManager.AppSettings["debug"].ToString().Trim());

            if (!debug)
            {
                aTimer = new System.Timers.Timer();
                aTimer.Elapsed += new System.Timers.ElapsedEventHandler(checkIsCompletedAll);
                aTimer.Interval = 5000;
                aTimer.AutoReset = true;
                aTimer.Enabled = true;
            }
            outPutReciveBill();
            ImportData();
            Executed = true;
        }
        private void checkIsCompletedAll(object source, System.Timers.ElapsedEventArgs e)
        {
            if (Executed)
            {
                log.Info("正在退出程序！");
                aTimer.Stop();
                Application.Exit();
            }
        }

        public bool Login()
        {
            log.Info("登录中...");
            try
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)SecurityProtocolTypeEnum.Ssl3 | (SecurityProtocolType)SecurityProtocolTypeEnum.Tls | (System.Net.SecurityProtocolType)SecurityProtocolTypeEnum.Tls11 | (SecurityProtocolType)SecurityProtocolTypeEnum.Tls12;

                string result;
                string sSERVER = ConfigurationManager.ConnectionStrings["SERVER"].ToString().Trim();
                string sDBID = ConfigurationManager.ConnectionStrings["DBID"].ToString().Trim();
                string sUserName = ConfigurationManager.ConnectionStrings["UID"].ToString().Trim();
                string sAppId = ConfigurationManager.ConnectionStrings["AppId"].ToString().Trim();
                string sAppSecret = ConfigurationManager.ConnectionStrings["AppSecret"].ToString().Trim();
                if (!sSERVER.Equals("") && !sDBID.Equals("") && !sUserName.Equals(""))
                {
                    client = new K3CloudApiClient(sSERVER);
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
                            return true;
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
            return false;
        }
        private void outPutReciveBill()
        {
            List<List<object>> Bills = PUR_ReceiveBill.GetAllBill(client, "FDocumentStatus = 'C' and FCheckInComing = 1 and F_PAEZ_Exported=0");//F_PAEZ_Exported=0 未导出
            if (Bills.Count==0)
            {
                log.Info("没有可以导出的收料通知单。");
                return;
            }

            MSExcel.Application excelApp = new MSExcel.Application
            {
                Visible = false//是打开可见
            };
            MSExcel.Workbooks _workbooks = excelApp.Workbooks;
            //MSExcel._Workbook _workbook = _workbooks.Add(AppDomain.CurrentDomain.BaseDirectory+"\\DD_20200901084512--ERP输出模板.XLS");
            MSExcel._Workbook _workbook = _workbooks.Add(System.Reflection.Missing.Value);
            MSExcel._Worksheet whs = _workbook.Sheets[1];//获取第1张工作表

            try
            {
                
                whs.Name = "Sheet1";
                //headline
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
                StringBuilder sbBillNos = new StringBuilder();
                for (int i = 0; i < Bills.Count; i++)
                {
                    string BillID = Convert.ToString(Bills[i][0]);
                    string BillNo = Convert.ToString(Bills[i][1]);
                    string FDetailEntity_FSeq = Convert.ToString(Bills[i][11]);
                    if (!BillIDsDic.ContainsKey(BillID))
                    {
                        BillIDsDic.Add(BillID, BillNo);
                        sbBillNos.Append("\"").Append(BillNo).Append("\",");
                    }
                    whs.Cells[i + 2, 1] = BillNo;
                    whs.Cells[i + 2, 2] = Bills[i][2];
                    whs.Cells[i + 2, 3] = Bills[i][3];
                    whs.Cells[i + 2, 4] = Bills[i][4];
                    whs.Cells[i + 2, 5] = Bills[i][6];
                    whs.Cells[i + 2, 6] = Bills[i][7];
                    whs.Cells[i + 2, 7] = Bills[i][5];
                    whs.Cells[i + 2, 8] = Bills[i][12];
                    whs.Cells[i + 2, 9] = 0;
                    whs.Cells[i + 2, 10] = 0;
                    whs.Cells[i + 2, 11] = "QIS_"+ BillNo+"_" +FDetailEntity_FSeq;
                }
                if (sbBillNos.Length > 0)
                {
                    sbBillNos.Remove(sbBillNos.Length - 1, 1); ; //移除掉最后一个","
                }

                string ERPOUTDirectory = Convert.ToString(ConfigurationManager.AppSettings["ERPOUT"].ToString().Trim());
                if (!Directory.Exists(ERPOUTDirectory))//如果不存在就创建文件夹  
                {
                    Directory.CreateDirectory(ERPOUTDirectory);
                }
                string fileName = ERPOUTDirectory + "K3Cloud_DD_" + DateTime.Now.ToString("yyyyMMddHHmmssf") + ".XLS";

                whs.SaveAs(fileName, 51);
                
                log.Info("正在更新该订单的同步状态。");
                PUR_ReceiveBill.ExportedToQIS(client,sbBillNos);
                //UpdateSyncStatus("PUR_ReceiveBill", BillIDsDic);
            }
            catch (Exception ex)
            {
                log.Error(ex);
            }
            finally {
                //关闭对象
                Marshal.ReleaseComObject(_workbook);
                Marshal.ReleaseComObject(whs);
                excelApp.Quit();
                GC.Collect();
            }
        }

        /// <summary>
        /// 更新订单的同步状态字段
        /// </summary>
        /// <param name="sFormId">需要更新的订单类型</param>
        /// <param name="dictionary">需要更新的订单FID和FBillNo</param>
        public void UpdateSyncStatus(string sFormId, Dictionary<string, string> dictionary)
        {
            if (dictionary.Count == 0)
            {
                return;
            }
            //textBox_log.AppendText(Utils.getNowTime() + " 正在更新订单的同步状态...\r\n");
            string sModel = "";

            foreach (string FID in dictionary.Keys)
            {
                sModel += "{\"FID\":\"" + FID + "\",\"F_PAEZ_Exported\":\"1\"},";
            }
            if(sModel.Length>0)
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
        private void button1_Click(object sender, EventArgs e)
        {
            outPutReciveBill();
        }
        private void button2_Click(object sender, EventArgs e)
        {
            ImportData();
            
        }
        private void ImportData()
        {
            string ERPInDirectory = Convert.ToString(ConfigurationManager.AppSettings["ERPIN"].ToString().Trim());
            if (!Directory.Exists(ERPInDirectory))
            {
                log.Info("ERPIN路径不存在。");
                return;
            }
            string ExcelPath = ERPInDirectory;
            List<FileInfo> ExcelFiles = getFiles(ExcelPath, ".xls");
            if (ExcelFiles.Count == 0)
            {
                log.Info("没有检测到Excel文件。");
                return;
            }
            foreach (FileInfo fileInfo in ExcelFiles)
            {
                try
                {
                    
                    string FilePath = fileInfo.FullName;
                    log.Info("正在处理：" + FilePath);
                    MSExcel.Application excelApp = new MSExcel.Application
                    {
                        Visible = false//是打开可见
                    };
                    MSExcel.Workbooks _workbooks = excelApp.Workbooks;
                    MSExcel._Workbook _workbook = _workbooks.Add(FilePath);
                    MSExcel._Worksheet whs = _workbook.Sheets[1];//获取第2张工作表 TODO：生产环境改回1

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
                            MSExcel.Range rang = (MSExcel.Range)whs.Cells[excelIndex, 32];//ERP收料通知单单号
                            if (rang.Value != null)
                            {
                                //if ("是".Equals(Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 42]).Value)))//已导出=是，则跳过
                                //{
                                //    continue;
                                //}

                                string ERPBillNo = Convert.ToString(rang.Value);
                                string PrevFBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex - 1, 32]).Value);//上一行的ERP收料通知单单号
                                string NextFBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex + 1, 32]).Value);//下一行的ERP收料通知单单号
                                string QISBillNo = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 1]).Value);//QIS检验单号
                                string FDate = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 2]).Value);
                                string MaterialNumber = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 7]).Value);
                                string ComputerResult = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 15]).Value);//电脑判定
                                double CheckQty = Convert.ToDouble(((MSExcel.Range)whs.Cells[excelIndex, 14]).Value);//批量数（报检数量）
                                double RealQty = Convert.ToDouble(((MSExcel.Range)whs.Cells[excelIndex, 22]).Value);//实收数量（合格数量）
                                string CheckResult = Convert.ToString(((MSExcel.Range)whs.Cells[excelIndex, 16]).Value);//检验结果
                                double unqualifiedQty = CheckQty - RealQty;//不合格数量

                                //ERP收料通知单单号和上一行不同，则是另一张单据
                                if (!PrevFBillNo.Equals(ERPBillNo))
                                {
                                    BillNoLineNumber = excelIndex;
                                    log.Info("正在读取：" + ERPBillNo);
                                }

                                string NeedPushEntryIds = "";
                                //excel的一行是相同物料合并数量的，在ERP查源单，查出来可能有多行物料
                                List<List<object>> Bills = PUR_ReceiveBill.GetAllBill(client, "FBillNo='" + ERPBillNo + "'" + " and FMaterialID.FNumber='" + MaterialNumber + "'");
                                for (int i = 0; i < Bills.Count; i++)
                                {
                                    double FQty = 0;
                                    string SrcBillID = Convert.ToString(Bills[i][0]);
                                    string SrcBillNo = Convert.ToString(Bills[i][1]);
                                    string SrcEntryID = Convert.ToString(Bills[i][8]);
                                    double FActReceiveQty = Convert.ToDouble(Bills[i][7]); //交货数量
                                    double FCheckJoinQty = Convert.ToDouble(Bills[i][9]);  //检验关联数量
                                    double NoCheckQty = FActReceiveQty - FCheckJoinQty;  //剩余未检验数量
                                    string SrcBillTypeID = Convert.ToString(Bills[i][10]);
                                    string SrcSeq = Convert.ToString(Bills[i][11]);
                                    if (NoCheckQty > CheckQty)
                                    {
                                        FQty = CheckQty;
                                    }
                                    else
                                    {
                                        FQty = NoCheckQty;
                                    }
                                    CheckQty = CheckQty - FQty;
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
                                            string NewBillNo = Convert.ToString(InspectBills[0][1]);

                                            JArray MultiLanguageTextArr = new JArray();
                                            JObject MultiLanguageTextJson = new JObject();
                                            MultiLanguageTextJson.Add("Key", 2052);
                                            MultiLanguageTextJson.Add("Value", "QIS导入，单号" + QISBillNo);

                                            JObject Entry = new JObject();
                                            ModelJson.Add("FID", Convert.ToString(InspectBills[0][0]));
                                            ModelJson.Add("FEntity", FOrderEntrys);
                                            ModelJson.Add("FDescription", "QIS导入，单号" + QISBillNo);

                                            FOrderEntrys.Add(Entry);
                                            Entry.Add("FEntryID", Convert.ToString(InspectBills[0][2]));
                                            Entry.Add("FInspectQty", FQty);
                                            Entry.Add("FMemo", "QIS导入，单号" + QISBillNo);
                                            if (!"合格".Equals(ComputerResult))
                                            {
                                                Entry.Add("FInspectResult", "2");//检验结果=不合格
                                                JArray FPolicyDetailEntrys = new JArray();//使用决策 子单据体
                                                JObject FPolicyDetailEntry1 = new JObject();
                                                JObject FPolicyDetailEntry2 = new JObject();
                                                switch (CheckResult)
                                                {
                                                    case "退货":
                                                        break;
                                                    case "让步接收":
                                                        Entry.Add("FPolicyDetail", FPolicyDetailEntrys);
                                                        FPolicyDetailEntrys.Add(FPolicyDetailEntry1);
                                                        FPolicyDetailEntry1.Add("FUsePolicy","A");
                                                        FPolicyDetailEntry1.Add("FPolicyQty", RealQty);

                                                        FPolicyDetailEntrys.Add(FPolicyDetailEntry2);
                                                        FPolicyDetailEntry2.Add("FUsePolicy", "B");
                                                        FPolicyDetailEntry2.Add("FPolicyQty", unqualifiedQty);

                                                        break;
                                                    case "挑选":
                                                        Entry.Add("FPolicyDetail", FPolicyDetailEntrys);
                                                        FPolicyDetailEntrys.Add(FPolicyDetailEntry1);
                                                        FPolicyDetailEntry1.Add("FUsePolicy", "A");
                                                        FPolicyDetailEntry1.Add("FPolicyQty", RealQty);

                                                        FPolicyDetailEntrys.Add(FPolicyDetailEntry2);
                                                        FPolicyDetailEntry2.Add("FUsePolicy", "E");
                                                        FPolicyDetailEntry2.Add("FPolicyQty", unqualifiedQty);
                                                        break;
                                                }
                                            }
                                            else if ("合格".Equals(ComputerResult)&&"内部原因".Equals(CheckResult)) {
                                                JArray FPolicyDetailEntrys = new JArray();//使用决策 子单据体
                                                JObject FPolicyDetailEntry1 = new JObject();
                                                Entry.Add("FPolicyDetail", FPolicyDetailEntrys);
                                                FPolicyDetailEntrys.Add(FPolicyDetailEntry1);
                                                FPolicyDetailEntry1.Add("FDetailID", Convert.ToString(InspectBills[0][3]));
                                                FPolicyDetailEntry1.Add("FMemo1", "内部原因");
                                            }
                                            


                                            Dictionary<string, object> ImportResult = QM_InspectBill.SaveBill(client, new StringBuilder(ModelJson.ToString()), new List<string>(ordenoList));
                                            //提交审核检验单
                                            CommonOperate commonOperate = new CommonOperate();
                                            commonOperate.SubmitBill(client, "QM_InspectBill", new StringBuilder("\"" + NewBillNo + "\""));
                                            commonOperate.AuditBill(client, "QM_InspectBill", new StringBuilder("\"" + NewBillNo + "\""));
                                            ModelJson = new JObject();
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


                                }
                                //移除掉最后一个","
                                if (NeedPushEntryIds.Length > 0) NeedPushEntryIds = NeedPushEntryIds.Remove(NeedPushEntryIds.LastIndexOf(","), 1);

                                //判断 当前是一张单据的最后一条分录
                                if (((MSExcel.Range)whs.Cells[excelIndex + 1, 1]).Value == null || !ERPBillNo.Equals(NextFBillNo))
                                {
                           
                                }
                            }
                            else
                            {
                                break;
                            }
                        }
                        catch (Exception ex)
                        {
                            log.Error(ex);
                        }
                        finally
                        {
                            excelIndex++;
                        }

                    }
                    string ERPBackup = Convert.ToString(ConfigurationManager.AppSettings["ERPBackup"].ToString().Trim());
                    string ResultDirectory = ERPBackup;//处理完后文件保存到这里
                    if (!Directory.Exists(ResultDirectory))//如果不存在就创建文件夹  
                    {
                        Directory.CreateDirectory(ResultDirectory);
                    }
                    whs.SaveAs(Path.Combine(ResultDirectory, fileInfo.Name), 51);
                    //关闭对象
                    Marshal.ReleaseComObject(_workbook);
                    Marshal.ReleaseComObject(whs);
                    excelApp.Quit();
                    GC.Collect();

                    fileInfo.Delete();
                }
                catch (Exception ex)
                {
                     log.Error(ex);
                }

            }
            
            Executed = true;
        }

        /// <summary>
        /// 读取目录下指定后缀的文件
        /// </summary>
        /// <param name="path">文件夹</param>
        /// <param name="extName">后缀名，如".txt"</param>
        /// <returns></returns>
        public static List<FileInfo> getFiles(string path, string extName)
        {
            List<FileInfo> lst = new List<FileInfo>();

            try
            {
                DirectoryInfo fdir = new DirectoryInfo(path);
                FileInfo[] file = fdir.GetFiles();
                //FileInfo[] file = Directory.GetFiles(path); //文件列表 
                if (file.Length != 0) //当前目录文件或文件夹不为空 
                {
                    foreach (FileInfo f in file) //显示当前目录所有文件 
                    {
                        if ((extName == null || extName == "") || (extName.ToLower().IndexOf(f.Extension.ToLower()) >= 0))
                        {
                            lst.Add(f);
                        }
                    }
                }
                return lst;
            }
            catch (Exception)
            {
                return lst;
            }
        }
    }
}
