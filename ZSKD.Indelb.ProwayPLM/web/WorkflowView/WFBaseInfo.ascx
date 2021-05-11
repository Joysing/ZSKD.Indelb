<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="WFBaseInfo.ascx.cs" Inherits="Kingdee.K3.PLM.WorkflowView.WFBaseInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Linq" %>

<script type="text/javascript">
    function TextAreapropertychange(obj) {
        obj.style.posHeight = obj.scrollHeight <= 20 ? 20 : obj.scrollHeight;
    }
</script>
<div style="width: 250px; height: 600px; overflow: inherit">
    <div class="title">基本信息</div>
    <ul id="ProcessInfo">
        <li style="margin: 5px 0 2px 0; height: 22px;"><span class="propname">流程主题：</span><input id="wfmaintitle" class="baseinput" /></li>
        <li id="wflevel"><span class="propname">紧急程度：</span>
            <input type="radio" name="wflevel" id="wflevelhigh" value="2" />
            <label for="wflevelhigh" class="propvalue12">高</label>
            <input type="radio" name="wflevel" id="wflevelmid" value="1" />
            <label for="wflevelmid" class="propvalue12">中</label>
            <input type="radio" name="wflevel" id="wflevellow" value="0" />
            <label for="wflevellow" class="propvalue12">低</label>
        </li>
        <li><span class="propname">创建人：</span><span id="wfCreator" class="propvalue12"></span></li>
        <li><span class="propname">创建时间：</span><span id="wfCreatetime" class="propvalue12"></span></li>
        <li id="liremark"><span class="propname">备注：</span>
            <input id="wfremark" class="baseinput" style="width: 190px;" />
            <%--<textarea id="wfremark" class="textareainput" style="width: 185px;" rows="1" onpropertychange="TextAreapropertychange

(this)"></textarea>--%>
        </li>
    </ul>



    <div class="title" id="historytitle">历史意见</div>
    <div class="historymore"><span id="historymoretitle">查看更多</span></div>
    <ul id="historyoption">
        <% if (!Page.IsCallback && !Page.IsPostBack && HistoryOptionData.Rows.Count > 0)
           {
               DataRow[] drs = HistoryOptionData.Select("AssessDate <>''", "AssessDate");
               for (int i = 0; i <= drs.Length - 1; i++)
               {
                   DataRow dr = drs[i];
                   string nodename = dr["NodeName"].ToString();
                   string noderemark = dr[checkSuggest].ToString();
                   string execname = !string.IsNullOrEmpty(dr[subpersion].ToString()) ? dr[subpersion].ToString() : dr["UserName"].ToString();
                   string liclass = "NormalHistory";
                   if (i == drs.Length - 1)           //上一个签了的节点
                   {
                       liclass = "LastHistory";
                   }      
        %>
        <li class="<%= liclass%>">
            <div></div>
            <div class="historyfirstrow"><span class="wfnodename" title="<%=nodename%>"><%=nodename%></span><span class="wfnodeperson" title="<%=execname%>"><%=execname%></span><span class="wfnoderesult"><%=dr[checkResult].ToString()%></span></div>
            <div class="wfnoderemark showallhistory_remark" title="<%=noderemark%>"><%=noderemark%></div>
            <div class="wfnodetime"><%=dr["AssessDate"].ToString()%></div>
        </li>
        <%} //end for
               var noAssess = HistoryOptionData.Select("AssessDate =''");
               DataRow currentNode = null;
               if (noAssess != null && noAssess.Length > 0) currentNode = noAssess[0]; //当前未签节点
               if (currentNode != null)
               {
                   string currentnodename = currentNode["NodeName"].ToString();
                   string currentexecname = !string.IsNullOrEmpty(currentNode[subpersion].ToString()) ? currentNode[subpersion].ToString() : currentNode["UserName"].ToString();   
        %>
        <li class="CurrentNode">
            <div></div>
            <div class="historyfirstrow"><span class="wfnodename" title="<%=currentnodename%>"><%=currentnodename%></span><span class="wfnodeperson" title="<%=currentexecname%>"><%=currentexecname%></span><span class="wfnoderesult"><%=currentNode[checkResult].ToString()%></span></div>
        </li>
        <%}
           } %>
    </ul>

    <input type="button" id="btngodo" class="BlueButtonCss" style="margin: 15px 0 0 65px; display: none;" value="去处理">
	
	<!--二开修改 2021-04-21 BEGIN-->
	<div id="ProcessPublishers" style="margin-bottom: 10px;">
        <div class="title" style="margin-bottom: 10px;">流程发布人员</div>
        <div id="ProcessPublisher" style="margin-top: 6px; height: 28px;">
            <span id="ProcessPublisherlbl" class="propvalue12" style="position: relative;">人员</span>
            <input id="ProcessPublisherInput" class="input_selectvalue" readonly="true" style="width: 120px; margin-bottom: 8px; outline: none; padding: 2px;" />
            <input editnextexecutorflag="<%=EditNextExecutorflag%>" type="button" id="btnProcessPublisherSet" class="btn normalbtn" data-toggle="tooltip" style="height: 26px; width: 45px; margin: 0 0 8px 6px; padding: 0 0 0 2px;" value="设置">
        </div>
    </div>
	<!--二开修改 2021-04-21 END-->
	
    <div id="ProcessDeal" style="width: 234px; height: 254px;">
        <div class="title" style="margin-bottom: 10px;">处理</div>
        <div id="DealMethod">
            <div id="dealmethodradiodiv" class="propvalue12" style="float: left; margin-right: 10px;">处理方式</div>
            <label id="dealagreelbl">
                <input name="selectmethod" id="dealagree" dvalue="1" type="radio" lblshow="下一节点处理人" />同意通过</label>
            <label id="dealhelplbl">
                <input name="selectmethod" id="dealhelp" dvalue="2" type="radio" lblshow="协办人" />协办</label>
            <label id="dealturnlbl">
                <input name="selectmethod" id="dealturn" dvalue="3" type="radio" lblshow="转办人" />转办</label>
            <label id="dealbacklbl">
                <input name="selectmethod" id="dealback" dvalue="4" type="radio" lblshow="退回节点" style="margin-left: 58px;" />退回</label>
            <label id="dealdirectbacklbl">
                <input name="selectmethod" id="dealdirectback" dvalue="5" type="radio" lblshow="退回节点" style="margin: 0 0px 0 24px;" />直接退回</label>
            <label id="dealdenylbl">
                <input name="selectmethod" id="dealdeny" dvalue="6" type="radio" lblshow="退回节点" style="margin-left: 58px;" />否决</label>
            <label id="dealnoareeelbl">
                <input name="selectmethod" id="dealnoareee" dvalue="7" type="radio" lblshow="下一节点处理人" style="margin: 0 0px 0 24px;" />不同意通过</label>
        </div>
        <div id="NextDealPerson" style="margin-top: 6px; height: 28px;">
            <div id="divCase" style="margin-bottom: 4px; display: none;">
                <span id="nextNodelbl" class="propvalue12" style="position: relative; margin-right: 35px">下一节点</span>
                <div id="selectCaseNodediv" class="btn-group" style="border: none;">
                    <input id="inputCaseNode" class="input_selectvalue" readonly="true" style="width: 100px; margin: 0; outline: none; padding: 1px;">
                    <button class="btn dropdown-toggle" data-target="#div_casenodelist" data-toggle="dropdown" style="width: 20px; margin: 0 0 0 -1px; height: 24px; padding-left: 6px; outline: none; border: #cccccc 1px solid; border-left: none;"><span class="caret"></span></button>
                    <div id="div_casenodelist" style="position: absolute; overflow-y: auto; overflow-x: hidden; width: 123px;">
                        <ul id="casenodedroplist" class="dropdown-menu AttachLinkdropdown" style="min-width: 121px; margin-top: -1px; top: 0; max-height: 190px; cursor: pointer;">
                            <% if (!Page.IsCallback && !Page.IsPostBack)
                               {
                                   foreach (System.Collections.Generic.KeyValuePair<string, string> nextnode in CaseNodes)
                                   { %>
                            <li data-nodeid="<%=nextnode.Key%>" title="<%=nextnode.Value%>">
                                <div></div>
                                <a><%=nextnode.Value%></a></li>
                            <%}
                               }%>
                        </ul>
                    </div>
                </div>
            </div>
            <span id="nextPersonlbl" class="propvalue12" style="position: relative;">下一节点处理人</span>
            <input id="nextPerson" class="input_selectvalue" readonly="true" style="width: 71px; margin-bottom: 8px; outline: none; padding: 2px;" />

            <div id="selectReturnNodediv" class="btn-group" style="border: none; display: none;">
                <input id="inputReturnNode" class="input_selectvalue" readonly="true" style="width: 100px; margin: 0; outline: none; padding: 1px;">
                <button class="btn dropdown-toggle" data-target="#div_nodelist" data-toggle="dropdown" style="width: 20px; margin: 0 0 0 -1px; height: 24px; padding-left: 6px; outline: none; border: #cccccc 1px solid; border-left: none;"><span class="caret"></span></button>
                <div id="div_nodelist" style="position: absolute; overflow-y: auto; overflow-x: hidden; width: 123px;">
                    <ul id="returnnodedroplist" class="dropdown-menu AttachLinkdropdown" style="min-width: 121px; margin-top: -1px; top: 0; max-height: 190px; cursor: pointer;">
                        <% if (!Page.IsCallback && !Page.IsPostBack)
                           {
                               foreach (System.Collections.Generic.KeyValuePair<string, string> backnode in BackOrRefusNodes)
                               { %>
                        <li data-nodeid="<%=backnode.Key%>" title="<%=backnode.Value%>">
                            <div>
                                <%
                                   if (BackOrRefusNodes.Count > 1)
                                   {
                                %><input class="parallelcheck" type="checkbox" style="vertical-align: top" /><%}%><a style="padding-left: 8px"><%=backnode.Value%></a>
                            </div>
                        </li>

                        <%}
                           }%>
                    </ul>
                </div>
            </div>
            <input editnextexecutorflag="<%=EditNextExecutorflag%>" type="button" id="btnNextDealSet" class="btn normalbtn" data-toggle="tooltip" style="height: 26px; width: 45px; margin: 0 0 8px 6px; padding: 0 0 0 2px;" value="设置">
        </div>
        <div style="margin-top: 2px;">
            <div class="propvalue12" style="float: left; margin: 8px 5px 0 0;">处理意见</div>
            <textarea id="dealoptionword" class="textareainput" style="margin-left: -1px; width: 165px; color: #666666;" rows="1" onpropertychange="TextAreapropertychange(this)">请在这里输入您的处理意见</textarea>
        </div>

        <ul id="nodeapplication" style="list-style: none; margin: 0; display: none;">
            <% 
                if (!Page.IsCallback && !Page.IsPostBack)
                {
                    var i = 0;
                    foreach (DataRow dr in ApplicationData.Rows)
                    {
                        var RelationAppId = dr["RelationAppId"].ToString();
                        var AppName = dr["AppName"].ToString() + (dr["AppUrl"].ToString() == "Document/DocumentRelease.aspx?" ? (++i).ToString() : "");
                        var AppUrl = dr["AppUrl"].ToString();
            %>
            <li>
                <a style="cursor: pointer;" appurl="<%= AppUrl%>" appid="<%=RelationAppId%>"><%= AppName%>></a>
                <img id="Image3" parametervalue="<%=AppUrl %>" src="../skins/Paging/GoToPage.gif" onclick="ShowProcessReleaseDetail(ParameterValue)" />
            </li>
            <%}
                }%>
        </ul>


        <input type="button" id="btntempsave" class="ButtonCss" style="margin: 5px 0 0 10px; float: left; width: 98px !important;" value="暂存">
        <input type="button" id="btnapply" class="BlueButtonCss" style="margin: 5px 0 0 10px; width: 98px !important;" value="提交">
        <br />
        <input type="button" id="btnStartChildProcess" class="ButtonCss" style="margin: 5px 0 0 10px; float: left; width: 206px !important;display:none" value="启动子流程">
    </div>
    <div id="divtips" style="margin-top: 12px; width: 196px; display: none; position: relative;">
        <div id="Div2" style="background: url(../static/img/tooltips/sanjiao.png)  no-repeat 0 0; width: 18px; height: 12px; position: relative; top: 4px; left: 162px"></div>
        <div id="Div3" style="background: url(../static/img/tooltips/left.png) no-repeat 0 0; width: 8px; height: 35px; padding-right: 4px; float: left;"></div>
        <div id="Div4" style="background: url(../static/img/tooltips/right.png)  no-repeat 0 0; width: 9px; height: 35px; float: right"></div>
        <div id="divtop" style="background: url(../static/img/tooltips/top.png) repeat-x 0 2px; background-color: #f3f8ff; height: 7px; margin-left: 7px; margin-right: 8px; padding-top: 8px"></div>
        <div id="Div6" style="background: url(../static/img/tooltips/bottom.png) repeat-x 0 0; background-color: #f3f8ff; height: 7px; margin: 0 7px 0 7px; border-top: 11px solid #f3f8ff"></div>
    </div>
    <div>
        <span style="height: 200px; width: 234px"></span>
    </div>
</div>
<script language="vbscript">
    function go()
    go=msgbox("是否为退回审核对象另起流程进行审核?",3+32)
    end function
</script>

<script type="text/javascript">
    function isSelectedItems() {
        var tbl = $("#dgrdWFObject");
        var chks = tbl.find(".DataGridRow").find(":checkbox:checked");
        return chks.length > 0;
    }

    function isSelectedAllItems() {
        var tbl = $("#dgrdWFObject");
        var chks = tbl.find(".DataGridRow").find(":checkbox").length;
        var selChks = tbl.find(".DataGridRow").find(":checkbox:checked").length;
        return selChks == 0 || chks == selChks;
    }

    function confirmReturnObjects() {
        var treeNode = getTreeSelectedDocument();
        if (isSelectedItems()) {
            txt = '是否确定退回勾选对象?';
        }
        else if (treeNode) {
            txt = "是否确定退回以下勾选对象?\n" + treeNode;
        }
        else {
            txt = '是否退回全部对象？';
        }
        return confirm(txt);
    }

    function confirmdirctReturnObjects() {
        var treeNode = getTreeSelectedDocument();
        if (isSelectedItems()) {
            txt = '是否确定直接退回勾选对象?';
        }
        else if (treeNode) {
            txt = "是否确定直接退回以下勾选对象?\n" + treeNode;
        }
        else {
            txt = '是否直接退回全部对象？';
        }
        return confirm(txt);
    }

    function confirmToAnotherObjects() {
        var treeNode = getTreeSelectedDocument();
        if (isSelectedItems()) {
            txt = '是否确定转办勾选对象?';
        }
        else if (treeNode) {
            txt = "是否确定转办以下勾选对象?\n" + getTreeSelectedDocument();
        }
        else {
            txt = '是否转办全部对象？';
        }
        return confirm(txt);
    }

    $(function () {
        var processId = '<%=GetProcessId()%>';
        var NodeId = '<%=NodeId%>';
        var UserId = '<%=UserId%>';

        //设置下一步人员
        function initbtnNextDealSetClick() {
            $("#btnNextDealSet").on("click", function () {
                if ($("#dealagree").prop("checked") == true) { // 同意               
                    var baseid = '<%=BaseId%>';
                    var curnodeid = '<%=NodeId%>';
                    var creator = '<%=GetFlowCreator()%>';
                    var nextnodeid = '<%=GetNextNodeID()%>';
                    var mcNodeId = nextnodeid;
                    if ($("#casenodedroplist > li").length > 0) {
                        mcNodeId = $("#inputCaseNode").attr("nodevalue");
                    }
                    var mode = '<%=EditNextExecutorflag%>';
                    var index = Math.random();
                    if (!nextnodeid) return;
                    var url = "../Workflow/WorkFlowNodeUserDetail.aspx?CurNodeId=" + curnodeid + "&NodeId=" + mcNodeId + "&Mode=" + mode + "&ProcessId=" + processId + "&Creator=" + creator + "&Option=Checkup&BaseId=" + baseid + "&mcNodeId=" + mcNodeId + "&r=" + index;
                    ModalDialog.showModalDialog(url, null, 'dialogWidth:500px;dialogHeight:485px;help:no;resizable:no;status:no', {
                        callback: function (resdate) {
                            if (resdate != undefined) { $("#nextPerson").val(resdate); getUserState(); }
                        }
                    });
                }
                if ($("#dealhelp").prop("checked") == true) { //协办
                    var url = "../Common/SelectUserFrame.aspx?";
                    ModalDialog.showModalDialog(url, null, 'dialogWidth:780px;dialogHeight:500px;help:no;resizable:no;status:no', {
                        callback:

    function (resdate) { if (resdate) { AfterSelectUser(resdate, $("#dealhelp"), false) } }
                    });
                }
                if ($("#dealturn").prop("checked") == true) { //转办
                    var url = "../Common/SelectUserFrame.aspx?&ChoiceCount=one";
                    ModalDialog.showModalDialog(url, null, 'dialogWidth:780px;dialogHeight:500px;help:no;resizable:no;status:no', {
                        callback:

    function (resdate) { if (resdate) { AfterSelectUser(resdate, $("#dealturn"), true) } }
                    });
                }
            });
        }

        //监听人员变化
        $PageChangeSubscribe.on('<%=BaseId%>_chanageuser', function (resdate) {
            if (resdate != undefined) { $("#nextPerson").val(resdate); getUserState(); }
        }, window);

        function getUserState() {
            var mcNodeId = "";
            if ($("#casenodedroplist > li").length > 0) {
                mcNodeId = $("#inputCaseNode").attr("nodevalue");
            }
            var topPX = "-138px";
            if (mcNodeId != "")
                topPX = "-120px";
            $.ajax({
                type: "Post",
                async: false,
                url: "WorkflowNodeUserDetail.aspx?NodeId=" + NodeId + "&ProcessId=" + processId + "&UserId=" + processId + "&act=checkuser" + "&mcNodeId=" + mcNodeId,
                success: function (data) {
                    if (data == 'false') {
                        $("#divtips").css({ display: 'block', top: topPX, left: '28px' });
                        var btndisplay = $("#btnapply").prop("disabled");
                        if (!btndisplay) {
                            $("#btnapply").prop("disabled", true);
                            $("#btnapply").attr("NouUser", "true");
                        }
                        $("#divtop").html("有部分节点未分配处理人,请分配");
                    }
                    else {
                        var nouser = $("#btnapply").attr("NouUser");
                        if (nouser == 'true') {
                            $("#btnapply").prop("disabled", false);
                        }
                        else {
                            $("#btnapply").attr("NouUser", "");
                        }
                        $("#divtips").css({ display: 'none' });
                    }
                },
            })
        }


        //加载流程信息
        var wfmaintitle = $("#wfmaintitle");
        var subject = $("#txtSubject").val();
        wfmaintitle.val(subject);//主题
        wfmaintitle.attr("title", subject);
        var wfremark = $("#wfremark");
        var Remark = $("#txtRemark").val();
        wfremark.val(Remark);//备注
        wfremark.attr("title", Remark);
        $("#wfCreator").html($("#txtCreator").val());        //创建人
        $("#wfCreatetime").html($("#txtCreateDate").val());  //创建时间

        if (wfremark.html() != "")
            wfremark.trigger("onpropertychange");

        var selectvalue = $("#dropExtent").find("option:selected").attr("value2");
        $("#wflevel > input[value=" + selectvalue + "]").prop("checked", true);
        $("#wflevel").attr("oldindex", selectvalue);

        var readonly = $("#txtSubject").attr("readonly"),  //主题和备注修改控制
            disabled = readonly == 'readonly';
        $("#wfmaintitle").prop("readOnly", readonly).prop('disabled', disabled);
        $("#wfremark").prop("readOnly", readonly).prop('disabled', disabled);
        $("#wflevel").prop("disabled", readonly).prop('disabled', disabled);

        //历史意见显示
        historyShow();

        //处理方式控制
        DealMethodControl();

        getUserState();

        $('#DealMethod label:enabled:eq(0)').find('input').prop("checked", true).trigger("change"); //将第一个可勾选的处理方式选中

        //显示暂存的处理方式和人+节点
        ShowDealMethod();

        //设置按钮
        initbtnNextDealSetClick();

        //应用程序
        var appnum = "<%=ApplicationData.Rows.Count%>";
        if (appnum > 0) {
            $("#nodeapplication").show();
            $("#nodeapplication > li > a").on("click", function () {
                $this = $(this);
                var url = $this.attr("appurl") + "id=" + $this.attr("appid");
                OpenPage(url, "应用程序:" + $this.html());
            });
        }

        //设置下拉列表的高度
        var nodelist = $('#div_nodelist'), pos1 = $('#DealMethod'),
            winh = $(window).height();
        nodelist.height(winh - pos1.offset().top - pos1.height() - 26);

        var casenodelist = $('#div_casenodelist');
        casenodelist.height(winh - pos1.offset().top - pos1.height() - 26);
        //
        function getNodeChildRight() {
            $.ajax({
                type: "Post",
                async: false,
                url: "../Workflow/ProcessDetailChild.aspx?NodeId=" + NodeId + "&Action=GetCount&IsActual=true",
                success: function (count) {
                    if (count != '0') {
                        $("#btnStartChildProcess").css({ display: 'block' });
                        if (count == '1') {
                            $("#btnStartChildProcess").on("click", function () {
                                $.overlay({ title: '正在处理中，请稍候......' }).prop();
                                __AjaxCallback_Obj.CustomCallServer({
                                    method: 'btnStartChild_Click',
                                    args: { _event_target: 'btnStartChild' },
                                    Context: {
                                        success: function (res) {
                                            $.overlay().close();
                                            alert(__AjaxCallback_Obj.Param('btnStartChild_Result'));
                                        }, error: function (res) {}
                                    }
                                });
                            });
                        }
                        else {
                            $("#btnStartChildProcess").on("click", function () {
                                var url = "../Workflow/ProcessDetailChild.aspx?NodeId=" + NodeId + "&processId=" + processId + "&IsActual=true";
                                ModalDialog.showModalDialog(url, null, 'dialogWidth:500px;dialogHeight:485px;help:no;resizable:no;status:no', {
                                    title: '选择子流程启动',
                                    callback: function () { }
                                });
                            });
                        }
                    }
                    else {
                        $("#btnStartChildProcess").css({ display: 'none' });
                    }
                },
            })
        }
        getNodeChildRight();
    })

    //历史意见显示
    function historyShow() {
        var historymoretitle = $("#historymoretitle");
        $("#btngodo").on("click", function () {
            historymoretitle.click();
        })

        var historynum = $("#historyoption > li").length;
        if (historynum > 1) //有历史记录
        {
            if (historynum > 2) {
                //历史信息记录
                $(".historymore").show();
                var historyoption = $("#historyoption");
                historymoretitle.on('click', function () {
                    $("#historyoption > li.NormalHistory").toggle(); //显/隐历史节点
                    $("#historyoption > li.CurrentNode").toggle();   //显/隐当前节点
                    $this = $(this);
                    if ($this.html() == "查看更多") {
                        $this.html("收起");
                        $("#divtips").css("display", "none");
                    } else {
                        $this.html("查看更多");
                        var nouser = $("#btnapply").attr("NouUser");
                        if (nouser == 'true') {
                            $("#divtips").css("display", "");
                        }
                    }
                    $("#btngodo").toggle();
                    $("#historyoption > li > div.wfnoderemark").toggleClass("showallhistory_remark");
                    $("#historyoption > li > div.wfnodetime").toggleClass("showallhistory_nodetime");
                    $("#historyoption > li.LastHistory").toggleClass("HistoryLeftBorder");
                    $("#ProcessDeal").toggle();
                    historyoption.scrollTop(2000);
                })
            } else { //有一条历史记录 + 一条当前记录
                $(".historymore").hide();
                $("#historyoption > li.CurrentNode").hide(); //隐藏当前节点
                var historyoptionone = $("#historyoption > li");
                historyoptionone.css("margin-top", "5px");
            }
        } else { //没有历史记录
            $("#historytitle").hide();
        }
    }

    //处理方式控制
    function DealMethodControl() {
        $("#dealagree").attr("showname", "<%=NextNodeExecutor%>"); //初始下一步处理人
        $("#dealnoareee").attr("showname", "<%=NextNodeExecutor%>");

        //处理意见
        dealOptionWord();
        var btnSave = ($("#btnSave[disabled!=disabled]").length > 0);
        var btnPass = ($("#btnPass[disabled!=disabled]").length > 0);
        var btnDPass = ($("#btnDPass[disabled!=disabled]").length > 0);
        var canagree = btnSave || btnPass || btnDPass;  //确定 + 同意通过 + 直接通过
        if (canagree) {
            var dealagree = $("#dealagree");
            dealagree.attr("btnSave", btnSave);
            dealagree.attr("btnPass", btnPass);
            dealagree.attr("btnDPass", btnDPass);
            //dealagree.prop("checked", true);
        } else {
            $("#dealagreelbl").prop("disabled", !canagree);
        }
        //debugger
        //Case节点---------
        if (btnSave || btnPass) {
            var agree = $("#dealagree");
            if ($("#casenodedroplist > li").length > 0) {
                ShowCaseNode(agree);
            }

        }
        //-------------

        var canCooperate = ($("#btnCooperate[disabled!=disabled]").length > 0);  //协办
        $("#dealhelplbl").prop("disabled", !canCooperate);

        var changeHandler = ($("#btnChangeHandler[disabled!=disabled]").length > 0);//转办
        $("#dealturnlbl").prop("disabled", !changeHandler);

        var returnback = ($("#btnReturn[disabled!=disabled]").length > 0);  //退回
        $("#dealbacklbl").prop("disabled", !returnback);

        var dealdirectback = ($("#btnDreturn[disabled!=disabled]").length > 0);  //直接退回
        $("#dealdirectbacklbl").prop("disabled", !dealdirectback);

        var btnRefus = ($("#btnRefus[disabled!=disabled]").length > 0);//否决
        $("#dealdenylbl").prop("disabled", !btnRefus);

        var btnDissent = ($("#btnDissent[disabled!=disabled]").length > 0);  //不同意通过
        $("#dealnoareeelbl").prop("disabled", !btnDissent);
        if (!canagree && !canCooperate && !changeHandler && !returnback && !dealdirectback && !btnRefus && !btnDissent) {
            $("#btnNextDealSet").prop("disabled", true);
            $("#btntempsave").addClass("disabled").prop("disabled", true);
            $("#btnapply").addClass("disabled").prop("disabled", true);
            $("#dealoptionword").attr("readOnly", true).prop("disabled", true);
        }
        //if ($("#btnSaveOpinion").length > 0)  //暂存
        //if ($("#btnFreeze").length > 0)  //冻结
        //if ($("#btnthaw").length > 0)  //解冻

        //处理方式动作
        var nextPersonlbl = $("#nextPersonlbl");
        $(document).on("click", "#dealagree", function () {//同意
            var nouser = $("#btnapply").prop("NouUser");
            if (nouser == 'true') {
                $("#divtips").css("display", "");
            }
            var isDReturnNode = '<%=IsDReturnNode%>';
            if (isDReturnNode == 'f') {
                $("#divCase").show();
                $("#NextDealPerson").height("56px");
            } else {
                $("#divCase").hide();
                $("#NextDealPerson").height("28px");
            }
            $("#btnNextDealSet[EditNextExecutorflag=view]").prop("disabled", true);
        }).on("click", "#dealdeny", function () { //否定
            $("#divtips").css("display", "none");
            ShowReturnNode(this);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        }).on("click", "#dealhelp", function () { //协办
            $("#divCase").hide();
            $("#NextDealPerson").height("28px");
            $("#divtips").css("display", "none");
            $("#btnNextDealSet").prop("disabled", false);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        }).on("click", "#dealturn", function () { //转办
            $("#divCase").hide();
            $("#NextDealPerson").height("28px");
            $("#divtips").css("display", "none");
            $("#btnNextDealSet").prop("disabled", false);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        }).on("click", "#dealback", function () { //退回
            $("#divtips").css("display", "none");
            ShowReturnNode(this);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        }).on("click", "#dealdirectback", function () { //直接退回
            $("#divtips").css("display", "none");
            ShowReturnNode(this);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        }).on("click", "#dealnoareee", function () { //不同意通过
            $("#divCase").hide();
            $("#NextDealPerson").height("28px");
            $("#divtips").css("display", "none");
            $("#btnNextDealSet").prop("disabled", true);
            $("#btnapply").removeClass("disabled").prop("disabled", false);
        });

        $(document).on('click', '#returnnodedroplist > li', SelectReturnNode)
        .on('click', '.parallelcheck', function (e) { e.stopPropagation() })

        //下拉选择退回节点
        function SelectReturnNode() {
            var $this = $(this);
            var nodeid = $this.attr("data-nodeid");
            var nodename = $this.attr("title");
            var inputReturnNode = $("#inputReturnNode");
            inputReturnNode.attr("nodevalue", nodeid);
            inputReturnNode.attr("title", nodename);
            inputReturnNode.val(nodename);
            var checkedradio = $("#DealMethod input:checked");
            checkedradio.attr("showname", nodename);
            checkedradio.attr("wfobjid", nodeid);
            $("input.parallelcheck").attr("checked", false);
        }

        $("input.parallelcheck").click(function () {
            var nodeid = "";
            var nodename = "";
            var fromnodeid = "";
            $("input.parallelcheck:checked").each(function () {
                var $this = $(this);
                if ($this.parent().parent().attr("data-nodeid") != "" && $this.parent().parent().attr("title") != "") {
                    nodeid += $this.parent().parent().attr("data-nodeid") + ";";
                    nodename += $this.parent().parent().attr("title") + ";";
                }
            });
            if (nodeid != "")
                nodeid = nodeid.substring(0, nodeid.length - 1);
            if (nodename != "")
                nodename = nodename.substring(0, nodename.length - 1);
            var inputReturnNode = $("#inputReturnNode");
            inputReturnNode.attr("nodevalue", nodeid);
            inputReturnNode.attr("title", nodename);
            inputReturnNode.val(nodename);
            var checkedradio = $("#DealMethod input:checked");
            checkedradio.attr("showname", nodename);
            checkedradio.attr("wfobjid", nodeid);
        });

        $("#casenodedroplist > li").click(function () {
            var $this = $(this);
            var nodeid = $this.attr("data-nodeid");
            var nodename = $this.find(">a").html();
            var inputCaseNode = $("#inputCaseNode");
            inputCaseNode.attr("nodevalue", nodeid);
            inputCaseNode.attr("title", nodename);
            inputCaseNode.val(nodename);
            //var checkedradio = $("#DealMethod input:checked");
            //checkedradio.attr("showname", nodename);
            //checkedradio.attr("wfobjid", nodeid);
            $("#rbMC").find("input:radio").removeAttr("CHECKED");
            $("#rbMC").find("input:radio").each(function () {
                var value = $(this).val(); if (value == nodeid) {
                    $(this).attr("CHECKED", "checked")

                }
            });
            getCaseUserState();
        });

        $("#btntempsave").click(function () {
            tempsave();
        });

        //提交按钮事件
        btnapplyaction();
    }

    function getCaseUserState() {
        var NodeId = '<%=NodeId%>';
        var processId = '<%=GetProcessId()%>';
        var userId = '<%=UserId%>';
        var topPX = "-138px";
        var mcNodeId = "";
        if ($("#casenodedroplist > li").length > 0) {
            mcNodeId = $("#inputCaseNode").attr("nodevalue");
            topPX = "-120px";
        }
        $.ajax({
            type: "Post",
            async: false,
            url: "WorkflowNodeUserDetail.aspx?NodeId=" + NodeId + "&ProcessId=" + processId + "&UserId=" + userId + "&act=getuser" + "&mcNodeId=" + mcNodeId,
            success: function (data) {
                var nextPerson = $("#nextPerson");
                var value = data;
                nextPerson.prop("title", value);
                nextPerson.val(value);
                if (data == '') {
                    $("#divtips").css({ display: 'block', top: topPX, left: '28px' });
                    var btndisplay = $("#btnapply").prop("disabled");
                    if (!btndisplay) {
                        $("#btnapply").prop("disabled", true);
                        $("#btnapply").attr("NouUser", "true");
                    }
                    $("#divtop").html("有部分节点未分配处理人,请分配");
                }
                else {
                    var nouser = $("#btnapply").attr("NouUser");
                    if (nouser == 'true') {
                        $("#btnapply").prop("disabled", false);
                    }
                    else {
                        $("#btnapply").attr("NouUser", "");
                    }
                    $("#divtips").css({ display: 'none' });
                }
            },
        })
    }

    //处理意见
    function dealOptionWord() {
        var dealoptionword = $("#dealoptionword");
        var txtWFOpinion = $("#txtWFOpinion");
        if (txtWFOpinion.val() != "") {
            dealoptionword.val(txtWFOpinion.val());
            dealoptionword.prop("title", txtWFOpinion.val());
        }
        dealoptionword.on("focus", function () {
            var o = $(this)
            if (o.html() == "请在这里输入您的处理意见") {
                o.html("");
                o.css("color", "black");
            }
        });
        dealoptionword.on("blur", function () {
            o = $(this)
            if (o.html() == "") {
                o.html("请在这里输入您的处理意见");
            }
            o.css("color", "#666666");
        });

        if (dealoptionword.html != "")
            dealoptionword.trigger("onpropertychange");
    }

    //显示下一执行人
    function ShowNextPerson() {
        var nextPerson = $("#nextPerson");
        nextPerson.show();
        var checkedradio = $("#DealMethod input:checked");
        var value = checkedradio.prop("showname") || "";
        var title = checkedradio.prop("lblshow") || '';
        nextPerson.prop("title", value);
        nextPerson.val(value);


        $("#selectReturnNodediv").hide();
        var btnNextDealSet = $("#btnNextDealSet");
        btnNextDealSet.show();
        var nextPersonlbl = $("#nextPersonlbl");
        nextPersonlbl.html(title);
        nextPersonlbl.css("top", "-2px");
    }

    $('#DealMethod').on('change', 'input[type="radio"]', function () {
        ShowNextPerson();
    })

    //显示可退回节点
    function ShowReturnNode(r) {
        var checkedradio = $(r);
        var nodename = checkedradio.attr("showname") || "";
        var nodeid = checkedradio.attr("wfobjid") || "";
        var inputReturnNode = $('#inputReturnNode');
        inputReturnNode.attr("title", nodename);
        inputReturnNode.val(nodename);
        checkedradio.attr("showname", nodename);
        checkedradio.attr("wfobjid", nodeid);

        if (!nodename && $("#returnnodedroplist > li").length == 1) {
            var firstli = $("#returnnodedroplist > li:eq(0)");
            nodeid = firstli.attr("data-nodeid");
            nodename = firstli.attr("title");
            inputReturnNode.attr("title", nodename);
            inputReturnNode.val(nodename);
            checkedradio.attr("showname", nodename);
            checkedradio.attr("wfobjid", nodeid);
        }

        //隐藏下一节点人
        $("#divCase").hide();
        $("#NextDealPerson").height("28px");
        $("#nextPerson").hide();
        $("#selectReturnNodediv").show();
        $("#btnNextDealSet").hide();
        var nextPersonlbl = $("#nextPersonlbl");
        var lbltitle = checkedradio.attr("lblshow");
        nextPersonlbl.html(lbltitle);
        nextPersonlbl.css("top", "2px");
        if (checkedradio.attr("id") != "dealback") {
            $(".parallelcheck").hide();
        }
        else {
            $(".parallelcheck").show();
        }
    }

    //显示可退回节点
    function ShowCaseNode(r) {
        var checkedradio = $(r);
        var nodeid = $("#casenodedroplist > li:eq(0)").attr("data-nodeid");
        var nodename = $("#casenodedroplist > li:eq(0)").find(">a").html();
        //var nodename = checkedradio.attr("showname") || "";
        //var nodeid = checkedradio.attr("wfobjid") || "";

        var inputReturnNode = $('#inputCaseNode');
        inputReturnNode.attr("title", '');
        inputReturnNode.val('');
        inputReturnNode.attr("nodevalue", '');

        //checkedradio.attr("showname", nodename);
        //checkedradio.attr("wfobjid", nodeid);

        //if (!nodename && $("#casenodedroplist > li").length == 1) {
        //    var firstli = $("#casenodedroplist > li:eq(0)");
        //    nodeid = firstli.attr("data-nodeid");
        //    nodename = firstli.find(">a").html();
        //    inputReturnNode.attr("title", nodename);
        //    inputReturnNode.val(nodename);
        //    checkedradio.attr("showname", nodename);
        //    checkedradio.attr("wfobjid", nodeid);
        //}

        //隐藏下一节点人
        $("#nextPerson").show();
        $("#divCase").show();
        $("#btnNextDealSet").show();
        var nextPersonlbl = $("#nextPersonlbl");
        var lbltitle = checkedradio.attr("lblshow");
        nextPersonlbl.html(lbltitle);
        nextPersonlbl.css("top", "2px");
        $("#NextDealPerson").height("56px");
    }


    function ajaxdoaction(method, btn, nodekeyid) {
        if ($("#btn_save[disabled!=disabled]").length > 0) {
            $("#btn_save").click(); //表单保存
        }
        copyvalue();
        $.overlay({ title: '正在处理中，请稍候......' }).prop();
        __AjaxCallback_Obj.CustomCallServer({
            method: method,
            args: { _event_target: btn, _event_argument: nodekeyid },
            Context: {
                success: function (res) {
                    $.overlay().close();
                }, error: function (res) {
                    //todo
                }
            }
        });
    }

    //保存表单和赋值
    function tableandvaluecopy() {
        var change = copyvalue();
        return change;
    }


    function SaveClientForm() {
        debugger;
        var frame1 = frames["ifrClientForm"];
        if (frame1 != null) {
            var frame = frame1.document.frames["ButtonMenuFrame"];
            //		            var frame = frame1.document.frames("ifrClientForm");
            if (frame != null) {
                if (frame.document.getElementById("btnSave") != null && frame.document.getElementById("btnSave").className != "Hide") {
                    frame.document.getElementById("btnSave").click();
                }
            }
        }
    }
    //同意
    function btnapplyaction() {
        $("#btnapply").click(function () {
            //SaveClientForm();
            //return;
            createJsonData();
            var dealagree = $("#dealagree");
            if (dealagree.prop("checked") == true) { //提交 - 同意
                var check = "<%=CheckDocSign()%>";
                if (check == "True") {
                    if (!confirm("归档对象不会签名，是否通过流程？"))
                        return;
                }
                tableandvaluecopy();
                var btn = "";
                if (dealagree.attr("btnPass") == 'true') {
                    btn = "btnPass_Click";
                } else if (dealagree.attr("btnSave") == 'true') {
                    btn = "btnSave_Click";
                } else if (dealagree.attr("btnDPass") == 'true') {
                    btn = "btnDPass_Click";
                }
                if (btn == "") { alert("Error no button"); return }
                ajaxdoaction(btn, "btnPass");
            }
            if ($("#dealnoareee").prop("checked") == true) { //提交 - 不同意通过
                tableandvaluecopy();
                ajaxdoaction("btnDissent_Click", "btnDissent");
            }
            if ($("#dealhelp").prop("checked") == true) { //提交 - 协办
                tableandvaluecopy();
                var userid = $("#dealhelp").prop("wfobjid");
                ajaxdoaction("btnCooperate_Click", "btnCooperate", userid);
            }
            if ($("#dealturn").prop("checked") == true) { //提交 - 转办
                if (!confirmToAnotherObjects()) return;
                tableandvaluecopy();
                var userid = $("#dealturn").prop("wfobjid");
                ajaxdoaction("btnChangeHandler_Click", "btnChangeHandler", userid);
            }
            if ($("#dealback").prop("checked") == true) { //提交 - 退回
                if (!confirmReturnObjects()) return;
                $("#dealback").attr("data-bhname", "dealdirectback");
                tableandvaluecopy();
                var nodeid = $("#dealback").prop("wfobjid")
                if (nodeid) {
                    var hasBinds = "<%= GetProcessBinds()%>";
                    var IsReturnNewWorkflow = "<%= IsReturnNewWorkflow()%>";
                    if (!isSelectedAllItems() && hasBinds != "True" && IsReturnNewWorkflow == "True") {
                        var a = go();
                        if (a == 6)     //是
                        {
                            ajaxdoaction("btnDreturnNew_Click", "btnReturnNew", nodeid);
                            return;
                        }
                        else if (a == 7)  //否
                        {
                            ajaxdoaction("btnDreturn_Click", "btnDreturn", nodeid);
                            return;
                        }
                        else     //取消
                            return;
                        //if (confirm("是否为退回审核对象另起流程进行审核?")) {
                        //    ajaxdoaction("btnReturnNew_Click", "btnReturnNew", nodeid);
                        //    return;
                        //}
                        
                    }
                    ajaxdoaction("btnReturn_Click", "btnReturn", nodeid);
                } else {
                    ShowMessage('未选择退回节点');
                }
            }

            if ($("#dealdirectback").prop("checked") == true) { //提交 - 直接退回
                if (!confirmdirctReturnObjects()) return;
                $("#dealdirectback").attr("data-bhname", "dealdirectback");
                tableandvaluecopy();
                var nodeid = $("#dealdirectback").prop("wfobjid");
                if (nodeid) {
                    var hasBinds = "<%= GetProcessBinds()%>";
                    var IsReturnNewWorkflow = "<%= IsReturnNewWorkflow()%>";
                    if (!isSelectedAllItems() && hasBinds != "True" && IsReturnNewWorkflow == "True") {
                        var a = go();
                        if (a == 6)     //是
                        {
                            ajaxdoaction("btnDreturnNew_Click", "btnReturnNew", nodeid);
                            return;
                        }
                        else if (a == 7)  //否
                        {
                            ajaxdoaction("btnDreturn_Click", "btnDreturn", nodeid);
                            return;
                        }
                        else     //取消
                            return;
                        //if (confirm("是否为直接退回审核对象另起流程进行审核?")) {
                        //    ajaxdoaction("btnDreturnNew_Click", "btnReturnNew", nodeid);
                        //    return;
                        //}
                    }
                    ajaxdoaction("btnDreturn_Click", "btnDreturn", nodeid);
                } else {
                    ShowMessage('未选择退回节点');
                }
            }
            if ($("#dealdeny").prop("checked") == true) { //提交 - 否决   
                tableandvaluecopy();
                var nodeid = $("#dealdeny").prop("wfobjid");
                if (nodeid) {
                    ajaxdoaction("btnRefus_Click", "btnRefus", nodeid);
                } else {
                    ShowMessage('未选择退回节点');
                }
            }
        });
    }

    //将界面的值赋值到原有老控件上
    function copyvalue() {
        var wfmaintitle = $("#wfmaintitle");
        var subject = $("#txtSubject");
        var wfremark = $("#wfremark");
        var readonly = subject.attr("readonly");
        var txtBaseName = $("#txtBaseName");
        var haschangge = false;
        if (readonly != "readonly") {
            if (wfmaintitle.val() != wfmaintitle.attr("title")) {
                subject.val(wfmaintitle.val());
                haschangge = true;
            }
            if (wfremark.val() != wfremark.attr("title")) {
                $("#txtRemark").val(wfremark.val());
                haschangge = true;
            }
            if (txtBaseName.val() != txtBaseName.attr("title")) {
                haschangge = true;
            }
            var levelindex = $("#wflevel > input:checked").attr("value");
            if ($("#wflevel").attr("oldindex") != levelindex) {
                $("#dropExtent > option[value2=" + levelindex + "]").attr("selected", "selected");
                haschangge = true;
            }
        }
        var dealoptionval = $("#dealoptionword").val();
        if (dealoptionval != "请在这里输入您的处理意见" || dealoptionval == "") {
            $("#txtWFOpinion").val(dealoptionval);
            haschangge = true;
        } else {
            $("#txtWFOpinion").val("");
        }
        return haschangge;
    }

    function AfterSelectUser(user, checkobj, choiseone) {
        var nameandid = "";
        var username = "";
        var userid = "";
        if (choiseone) {
            if (user.indexOf(";") > 0) {
                nameandid = user.split(";");
            } else {
                nameandid = user.split(",");
            }
            username = nameandid[0];
            userid = nameandid[1];
        } else {
            nameandid = user.split(";");
            username = nameandid[0].split(",");
            userid = nameandid[1].split(",");
        }
        checkobj.attr("showname", username); //数据存到处理方式选择框里
        checkobj.attr("wfobjid", userid);
        ShowNextPerson();
    }

    //显示暂存信息
    function ShowDealMethod() {
        var val = $("#txtTempSave").val();
        if (val != "") {
            var dealinfo = $.parseJSON(val);
            var dealinput = $("#DealMethod input[dvalue=" + dealinfo.dealmethod + "] ");
            if (dealinput.length && dealinput.prop("disabled") == false) {
                if (dealinfo.dealmethod != "dealagree") {
                    $("#divtips").css("display", "none");
                }
                //dealinput.prop("checked", true);
                if (dealinfo.dealmethod == 2 || dealinfo.dealmethod == 3) { //转办协办
                    dealinput.prop("wfobjid", dealinfo.wfobjid);
                    dealinput.prop("showname", dealinfo.showname);
                    ShowNextPerson();
                    $("#btnNextDealSet").prop("disabled", false);
                }
                else if (dealinfo.dealmethod == 4 || dealinfo.dealmethod == 5 || dealinfo.dealmethod == 6) {//需要退回
                    dealinput.prop("wfobjid", dealinfo.wfobjid);
                    dealinput.prop("showname", dealinfo.showname);
                    ShowReturnNode();
                } else { //暂存了处理方式:同意
                    $("#btnNextDealSet[EditNextExecutorflag=view]").prop("disabled", true); //下一步处理人不能选择
                }
            } else {  //对应的处理方式radio不可编辑
                if (dealinfo.dealmethod == 1) {
                    $("#btnNextDealSet[EditNextExecutorflag=view]").prop("disabled", true); //下一步处理人不能选择
                }
            }
        } else { //初始进入界面,默认为同意
            $("#btnNextDealSet[EditNextExecutorflag=view]").prop("disabled", true); //下一步处理人不能选择
        }
    }

    //获取信息to暂存
    function getDealMethodCheckedValue(rtn) {
        $("#DealMethod input").each(function () {
            var o = $(this);
            if (o.prop("checked")) {
                rtn.dealmethod = o.prop("dvalue");
                if (rtn.dealmethod == 2 || rtn.dealmethod == 3) { //转办协办
                    rtn.wfobjid = o.prop("wfobjid");
                    rtn.showname = $('#nextPerson').val();
                }
                else if (rtn.dealmethod == 4 || rtn.dealmethod == 5 || rtn.dealmethod == 6) {//需要退回
                    rtn.wfobjid = o.prop("wfobjid");
                    rtn.showname = $('#inputReturnNode').val();
                }
                return rtn;
            }
        })
    }

    //暂存
    function tempsave() {
        var DealMethodCheckedValue = {};
        getDealMethodCheckedValue(DealMethodCheckedValue);
        var dealmethodvalue = JSON.stringify(DealMethodCheckedValue);
        var haschangge = tableandvaluecopy();
        var txtTempSave = $("#txtTempSave");
        haschangge = txtTempSave.val() != dealmethodvalue || haschangge;
        $("#btntempsave").attr("data-bhname", "btnSaveOpinion");
        if (haschangge) {
            txtTempSave.val(dealmethodvalue);
            $.overlay({ title: '正在处理中，请稍候......' }).prop();
            __AjaxCallback_Obj.CustomCallServer({
                method: 'btnApply_Click',
                args: { _event_target: 'btnApply' },
                Context: {
                    success: function (res) {
                        $.overlay().close();
                        if (res && res != "") {
                            alert(res);
                        }
                    }, error: function (res) {

                    }
                }
            });
        }
    }


    function ShowProcessReleaseDetail(appurl) {
        if (appurl == "Document/DocumentRelease.aspx?") {
            var Url = "Workflow/ProcessReleaseDetail.aspx?BaseId=" + '<%= this.BaseId %>';
            if (window.top.location.href.indexOf('Default.aspx') > 0)
            { addpage(Url, '发布列表'); }
            else
            { window.open('../' + Url); }
        }
    }
</script>
