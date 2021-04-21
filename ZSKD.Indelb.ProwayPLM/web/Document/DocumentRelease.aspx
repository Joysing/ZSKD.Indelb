<%@ Register TagPrefix="cc2" Namespace="Proway.Framework.WebControls.InterfaceControls"
    Assembly="Proway.Framework.WebControls" %>

<%@ Page Language="c#" CodeBehind="DocumentRelease.aspx.cs" AutoEventWireup="True"
    Inherits="ProwayPLM.Document.DocumentRelease" %>

<%@ Register TagPrefix="cc1" Namespace="Proway.Framework.WebControls" Assembly="Proway.Framework.WebControls" %>
<%@ Register TagPrefix="componentart" Namespace="ComponentArt.Web.UI" Assembly="ComponentArt.Web.UI" %>
<%@ Register TagPrefix="powerform" Namespace="Proway.Framework.WebControls" Assembly="Proway.Framework.WebControls" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" >
<html>
<head>
    <title>DocumentRelease</title>
    <meta content="False" name="vs_snapToGrid">
    <meta content="True" name="vs_showGrid">
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="C#" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="../skins/menubar/hotmail.css" rel="stylesheet">

    <script language="JavaScript" src="../skins/menubar/hotmail.js"></script>
    
    <script type="text/javascript">
        function checkTextLength(obj, length) {
            if (obj == null) {
                window.alert('<%=L("脚本错误，参数不正确") %>');
                //用法：<asp:textbox   onkeypress="checkTextLength(this,30);"   onblur="checkTextLength(this,30);"   TextMode="MultiLine">   
            }
            else {
                if (obj.value.length > length - 1) {
                    if (event.keyCode == 0)
                        window.alert('<%=L("请确保文本框输入的内容最大长度为") %>' + length + '<%=L("个字符，超出部分将自动截断") %>');
                    obj.value = obj.value.substring(0, length - 1);
                }
            }
        }
    </script>
</head>
<body ms_positioning="GridLayout">
    <form id="Form1" method="post" runat="server">
    <cc1:Navigator ID="Navigator1" runat="server" Width="112px" Height="64px"></cc1:Navigator>
    <input id="hidPBOMVerId" type="hidden" runat="server" name="hidPBOMVerId">
    <input id="hidDBOMVerId" type="hidden" runat="server" name="hidDBOMVerId">
    <table id="tblMain">
        <tbody>
             <tr>
                <td width="800px">
                    <div class="Attribute_Frame" >
                        <table class="Attribute_Content" cellspacing="0" cellpadding="0" width="400" border="1">
                            <tr>
                                <td colspan="2">
                                    <!-- 表头 -->
                                    <table class="Attribute_Title" cellspacing="0" cellpadding="0" width="100%" border="0">
                                        <tr>
                                            <td class="Attribute_TitleHead">
                                            </td>
                                            <td>
                                                &nbsp;
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <!-- 内容 -->
                                    <table class="Inner_innerContent" cellspacing="1" >
                                        <tr>
                                            <td style="width: 88px; height: 9px">
                                                <asp:Label CssClass="w51" ID="Label2" runat="server">发布主题:</asp:Label>
                                            </td>
                                            <td style="height: 9px">
                                                <asp:TextBox ID="txtSubject" runat="server" Width="170px" CssClass="text"></asp:TextBox><asp:Label
                                                    CssClass="w51" ID="Label12" runat="server" Height="8px" ForeColor="Red">*</asp:Label>
                                            </td>
                                            <td style="width: 69px; height: 27px">
                                                <asp:Label CssClass="w51" ID="Label10" runat="server">状态:</asp:Label>
                                            </td>
                                            <td style="height: 27px">
                                                <asp:TextBox ID="txtState" runat="server" Width="190px" CssClass="text" ReadOnly="true"></asp:TextBox>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="width: 88px; height: 1px">
                                                <asp:Label CssClass="w51" ID="Label5" runat="server">创建人:</asp:Label>
                                            </td>
                                            <td style="height: 1px">
                                                <asp:TextBox ID="txtCreator" runat="server" Width="170px" CssClass="text" ReadOnly="True"></asp:TextBox>
                                            </td>
                                            <td style="width: 69px; height: 27px">
                                                <asp:Label CssClass="w51" ID="Label9" runat="server">发布分类:</asp:Label>
                                            </td>
                                            <td style="height: 27px">
                                                <asp:DropDownList ID="dropReleaseType" runat="server" Width="190px" Height="40px">
                                                </asp:DropDownList>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="width: 88px; height: 22px">
                                                <asp:Label CssClass="w51" ID="Label6" runat="server">创建日期:</asp:Label>
                                            </td>
                                            <td style="height: 22px">
                                                <powerform:CalendarEx ID="calCreateDate" runat="server" EnabledTime="True" Enabled="False"></powerform:CalendarEx>
                                            </td>
                                            <td colspan="2" class="tdheaderspan">
                                                <asp:CheckBox ID="chkInformOther" runat="server" Width="120px" Text="通知相关人员" Checked="True">
                                                </asp:CheckBox>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                            </td>
                                            <td>
                                                <asp:CheckBox ID="chkIsAutoRecycleOldVer" runat="server" Text="已发布版本自动回收" AutoPostBack="True"
                                                    Checked="True"></asp:CheckBox>
                                            </td>
                                            <td>
                                            </td>
                                            <td>
                                                <asp:CheckBox ID="chkInure" runat="server" Text="立即生效" AutoPostBack="True" OnCheckedChanged="chkInure_CheckedChanged">
                                                </asp:CheckBox>
                                            </td>
                                        </tr>
                                        <asp:Panel ID="PanEdit" runat="server">
                                            <tr>
                                                <td>
                                                    <asp:Label CssClass="w51" ID="labInure" runat="server">生效日期:</asp:Label>
                                                </td>
                                                <td>
                                                    <powerform:CalendarEx ID="calInsureDate" runat="server" EnabledTime="True"></powerform:CalendarEx>
                                                </td>
                                                <td>
                                                    <asp:Label CssClass="w51" ID="Label8" runat="server">失效日期:</asp:Label>
                                                </td>
                                                <td>
                                                    <powerform:CalendarEx ID="calLapseDate" runat="server" EnabledTime="True"></powerform:CalendarEx>
                                                </td>
                                            </tr>
                                        </asp:Panel>
                                        <tr>
                                            <td style="width: 88px; height: 20px">
                                                <asp:Label CssClass="w51" ID="Label3" runat="server">发布内容:</asp:Label>
                                            </td>
                                            <td style="height: 20px" colspan="3">
                                                <asp:TextBox ID="txtContext" runat="server" Width="100%" Height="52px" CssClass="text"
                                                    TextMode="MultiLine"></asp:TextBox>
                                                <asp:Label CssClass="w51" ID="Label11" runat="server" Height="8px" ForeColor="Red">*</asp:Label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="width: 88px; height: 32px">
                                                <asp:Label CssClass="w51" ID="Label4" runat="server">备注:</asp:Label>
                                            </td>
                                            <td style="height: 32px" colspan="3">
                                                <asp:TextBox ID="txtRemark" runat="server" Width="100%" Height="52px" CssClass="text"
                                                    TextMode="MultiLine"></asp:TextBox>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </table>
                    </div>
                </td>
            </tr>
            <tr>
                <cc2:PageBlock ID="PageBlock2" Title="发布对象" runat="server" Height="100px" Width="800px"
                    HtmlObject="tblPDM"></cc2:PageBlock>
                <td>
                </td>
            </tr>
            <tr>
                <td width="800px">
                    <table id="tblPDM" width="100%">
                        <tr>
                            <td>
                                <table>
                                    <tr>
                                        <td>
                                            <asp:Panel ID="PanExplains" Visible="False" runat="server">
                                                <asp:Label ID="Label7" runat="server">发布说明:</asp:Label>
                                                <asp:TextBox ID="txtExplains" runat="server" Width="193px" CssClass="text"></asp:TextBox>
                                                <asp:Button ID="btnUpdateExplains" runat="server" CssClass="SmallButtonCss" Text="保存说明"
                                                    OnClick="btnUpdateExplains_Click"></asp:Button>
                                            </asp:Panel>
                                            <asp:Panel ID="PanVer" Visible="False" runat="server">
                                                <asp:Label ID="Label1" runat="server">发布版本:</asp:Label>
                                                <asp:DropDownList ID="drpMajorVer" runat="server" Width="120px">
                                                </asp:DropDownList>
                                                <asp:Button ID="btnShowMajorVer" runat="server" CssClass="SmallButtonCss" Text="修改版本"
                                                    OnClick="btnShowMajorVer_Click" Visible="false"></asp:Button>
                                                <asp:Button ID="btnUpdateMajorVer" runat="server" CssClass="SmallButtonCss" Text="保存版本"
                                                    OnClick="btnUpdateMajorVer_Click"></asp:Button>
                                            </asp:Panel>
                                            <asp:Panel ID="PanVerExplain" Visible="False" runat="server">
                                                <asp:Label ID="Label13" runat="server">版本描述:</asp:Label>
                                                <asp:TextBox ID="txtVerExplain" runat="server" Width="193px" CssClass="text"></asp:TextBox>
                                                <asp:Button ID="btnUpdateVerExplain" runat="server" CssClass="SmallButtonCss" Text="保存描述" OnClick="btnUpdateVerExplain_Click">
                                                </asp:Button>
                                            </asp:Panel>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                        <tr>
                            <td width="800px">
                                <!--菜单-->
                                <cc1:MenuBar ID="MenuBarObject" runat="server" Width="100%"></cc1:MenuBar>
                            </td>
                        </tr>
                        <tr>
                            <td width="800px">
                                <cc1:DataGridEx ID="dgrdObject" runat="server" Width="100%" Height="26px" ReadOnly="False"
                                    ResourcePath="../skins/Paging/" AllowSorting="True" AutoGenerateColumns="False"
                                    RecordCount="0" Border="1" Advanced="False" PageIndex="1" ScriptPath="../Javascript/"
                                    ShowPageBox="True" ShowSelectBox="True" Resizable="False" SelectedItemColor="#BEC5DE"
                                    IsCanHiddenColumn="True" SelectTag="chkChoice">
                                    <Columns>
                                        <asp:TemplateColumn>
                                            <HeaderStyle HorizontalAlign="Center" Width="20px" VerticalAlign="Middle"></HeaderStyle>
                                            <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle"></ItemStyle>
                                            <ItemTemplate>
                                                <asp:CheckBox ID="chkChoice" runat="server"></asp:CheckBox>
                                            </ItemTemplate>
                                        </asp:TemplateColumn>
                                        <asp:TemplateColumn>
                                            <HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
                                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                            <ItemTemplate>
                                                <asp:ImageButton ID="imgSelect" runat="server" CommandName="imgSelect" ImageUrl='<%# Proway.Framework.Integration.DocumentHelper.GetObjectIcon(DataBinder.Eval(Container, "DataItem.ObjectOption").ToString(),DataBinder.Eval(Container, "DataItem.Icon").ToString()) %>'
                                                    onerror="this.src='../skins/DocIcon/ext.gif'"></asp:ImageButton>
                                            </ItemTemplate>
                                            <FooterStyle HorizontalAlign="Center"></FooterStyle>
                                        </asp:TemplateColumn>
                                        <asp:TemplateColumn>
                                            <HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
                                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                            <ItemTemplate>
                                                <asp:Image ID="imgeState" runat="server" ImageUrl='<%# Proway.Framework.Integration.DocumentHelper.GetObjectState(DataBinder.Eval(Container, "DataItem.ObjectOption").ToString(),DataBinder.Eval(Container, "DataItem.ObjectState").ToString(),DataBinder.Eval(Container, "DataItem.CheckOutState").ToString(),DataBinder.Eval(Container, "DataItem.ObjectId").ToString()) %>'>
                                                </asp:Image>
                                            </ItemTemplate>
                                            <FooterStyle HorizontalAlign="Center"></FooterStyle>
                                        </asp:TemplateColumn>
                                    </Columns>
                                </cc1:DataGridEx>
                            </td>
                        </tr>
                          <tr>
                            <td width="800px">
                                <cc2:PageBlock ID="Pageblock5" Title="关联附件" runat="server" Width="100%"></cc2:PageBlock>
                                <cc1:MenuBar ID="MenuBarAttObject" runat="server" Width="100%"></cc1:MenuBar>
                                <cc1:datagridex id="dgrdWFAttachment" runat="server" readonly="False" width="100%"
                                    cssclass="DataGrid" resourcepath="../skins/Paging/" allowsorting="True" autogeneratecolumns="False"
                                    iscanhiddencolumn="True" showpagebox="True" pageindex="1" advanced="False" border="1"
                                    recordcount="0" scriptpath="../Javascript/" selecttag="chkAtt" showselectbox="True"
                                    resizable="False" selecteditemcolor="#BEC5DE" allowcustompaging="True" allowpaging="True"
                                    onitemdatabound="dgrdWFAttachment_ItemDataBound">
							<Columns>
								<asp:TemplateColumn>
									<HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
									<ItemStyle HorizontalAlign="Center"></ItemStyle>
									<ItemTemplate>
										<asp:CheckBox id="chkAtt" runat="server"></asp:CheckBox>
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:TemplateColumn>
									<HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
									<ItemStyle HorizontalAlign="Center"></ItemStyle>
									<ItemTemplate>
										<asp:ImageButton id="ibtnAtt" runat="server" CommandName="ibtnAtt" ImageUrl='<%#  Eval("ObjectIconPath").ToString() %>' onerror="this.src='../skins/DocIcon/ext.gif'">
										</asp:ImageButton>
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:TemplateColumn>
									<HeaderStyle HorizontalAlign="Center" Width="25px"></HeaderStyle>
									<ItemStyle HorizontalAlign="Center"></ItemStyle>
									<ItemTemplate>
										<asp:Image id="Image1" runat="server" ImageUrl='<%#  Eval("ObjectStatePath").ToString() %>'>
										</asp:Image>
									</ItemTemplate>
									<FooterStyle HorizontalAlign="Center"></FooterStyle>
								</asp:TemplateColumn>
							</Columns>
							<PagerStyle Visible="False"></PagerStyle>
						</cc1:datagridex>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td>
                    <cc2:PageBlock ID="Pageblock1" Title="权限分配" runat="server" Height="100px" Width="800px"
                        HtmlObject="tblPower"></cc2:PageBlock>
                </td>
            </tr>
            <tr>
                <td>
                    <table id="tblPower" width="100%">
                        <tr>
                            <td width="800px">
                                <!--菜单-->
                                <cc1:MenuBar ID="MenuBarUser" runat="server" Width="100%"></cc1:MenuBar>
                            </td>
                        </tr>
                        <tr>
                            <td valign="top" width="800px">
                                <cc1:DataGridEx ID="dgrdUser" runat="server" Width="100%" Height="26px" ReadOnly="False"
                                    ResourcePath="../skins/Paging/" AllowSorting="True" AutoGenerateColumns="False"
                                    RecordCount="0" Border="1" Advanced="False" PageIndex="1" ScriptPath="../Javascript/"
                                    ShowPageBox="True" ShowSelectBox="True" Resizable="False" SelectedItemColor="#BEC5DE"
                                    IsCanHiddenColumn="True" SelectTag="ChoiceId">
                                    <Columns>
                                        <asp:TemplateColumn>
                                            <HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
                                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                            <ItemTemplate>
                                                <asp:CheckBox ID="ChoiceId" runat="server"></asp:CheckBox>
                                            </ItemTemplate>
                                        </asp:TemplateColumn>
                                        <asp:TemplateColumn>
                                            <HeaderStyle HorizontalAlign="Center" Width="20px"></HeaderStyle>
                                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                            <ItemTemplate>
                                                <asp:ImageButton ID="ibtnPower" runat="server" CommandName="IamgePower" ImageUrl="../skins/DataGrid/select.gif">
                                                </asp:ImageButton>
                                            </ItemTemplate>
                                        </asp:TemplateColumn>
                                    </Columns>
                                </cc1:DataGridEx>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr runat="server" id="tr_SignOpinion" visible="false">
                <td>
                    <table width="800px">
                     <tr>
                        <td style="width: 88px; height: 52px">签收意见：</td>
                        <td><asp:textbox CssClass="text" id="txtSignOpinion" runat="server" Width="100%" 
                            Height="52px" TextMode="MultiLine" onkeypress="return checkTextLength(this,300);" onblur="checkTextLength(this,300);"></asp:textbox></td>
                     </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td>
                    <table width="800px">
                        <tr>
                            <td align="right">
                                <span style="display: none">
                                    <asp:Button ID="btnRefresh" runat="server" Text="PDM刷新" OnCommand="btnRefresh_Command">
                                    </asp:Button>
                                    <asp:Button ID="btnRefreshUser" runat="server" Text="用户刷新" OnClick="btnRefreshUser_Click">
                                    </asp:Button>
                                    <asp:Button ID="btnSplitReleaseBack" runat="server" Text="拆分发布" OnCommand="btnSplitReleaseBack_Click">
                                    </asp:Button>
                                    </span>
                                <asp:Button ID="btnOperate" runat="server" CssClass="ButtonCss" Text="修改发布" OnClick="btnOperate_Click">
                                </asp:Button>
                                <asp:Button ID="btnSave" runat="server" CssClass="BlueButtonCss" Text="确定" OnClick="btnSave_Click">
                                </asp:Button>
                                <asp:Button ID="btnApply" runat="server" CssClass="ButtonCss" Text="应用" OnClick="btnApply_Click">
                                </asp:Button>                              
                                <asp:Button ID="btnSign" runat="server" CssClass="BlueButtonCss" Text="签收" Visible="False"
                                    OnClick="btnSign_Click"></asp:Button>
                                <asp:Button ID="btnReject" runat="server" CssClass="ButtonCss" Text="拒收" Visible="False"
                                    OnClick="btnReject_Click"></asp:Button>                                
                                <asp:Button ID="btnTransmit" runat="server" CssClass="ButtonCss" Text="转发布" Visible="False"
                                    OnClick="btnTransmit_Click"></asp:Button>
                                <asp:Button ID="btnReturn" runat="server" CssClass="ButtonCss" Text="关闭" OnClick="btnReturn_Click">
                                </asp:Button>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </tbody>
    </table>
        <div id ="WaitDiv" style='position: absolute;width:300px;height:30px;color:#00f;text-align:center;display:none;border:1px solid #999;background-color: #fff' ><img style="margin:1px 1px 10px 1px auto" src='../skins/images/wait.gif' /><div style="height: 28px; line-height: 28px;"></div></div>
        <div id="msgBox" style="display:none;width:100%;height:40px;background-color:#e0f1d9;color:#468847;font-size:14px;position:fixed;bottom:0px;left:0px;padding:8px 5px;line-height:40px; text-align:center;"></div>
         <a name="#repub"></a>  
    <script language="javascript" type="text/javascript">
        PageInitial();
        function showMessage(msg) {
            if (!msg) return;
            var msgb=$("#msgBox");
            msgb.html(msg).show().focus();
            setTimeout(function () { msgb.fadeOut(400);}, 2000);
        }
        showMessage('<%=(!Page.IsPostBack && (Request.QueryString["msg"]??"")=="1")?L("签收成功"):"" %>');

        function waitTip(text) {
            var w = document.getElementById("WaitDiv");
            if (!w) return;
            w.style.display = "block";
            var l = (getBodyClientWidth() - w.offsetWidth) / 2 + document.body.scrollLeft;
            var t = (getBodyClientHeight() - w.offsetHeight) / 2 + document.body.scrollTop;
            if (l < 0) l = 0; if (t < 0) t = 0;
            w.style.left = l + "px";
            w.style.top = t + "px";
            w.lastChild.innerHTML = text;
        }

    </script>

    </form>
</body>
</html>
