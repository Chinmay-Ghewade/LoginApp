<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>
<%@ page import="java.io.File" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
String action = request.getParameter("action");
String reportAction = request.getParameter("report_action"); // printing / list

String branchCode = (String) session.getAttribute("branch_code");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(branchCode == null) branchCode="";
if(sessionBranchCode == null) sessionBranchCode="";
if(isSupportUser == null) isSupportUser="N";

/* ================= GENERATE ================= */

if("generate".equals(action)){

    String asOnDate = request.getParameter("as_on_date");
    String fromBr   = request.getParameter("from_br");
    String toBr     = request.getParameter("to_br");

    String[] deposit = request.getParameterValues("Deposit_accounts");
    String[] saving  = request.getParameterValues("Saving_accounts");
    String[] pigmy   = request.getParameterValues("Pigmy_accounts");

    String reportType = request.getParameter("reporttype");

    /* ================= BRANCH SECURITY ================= */

    if(branchCode == null || branchCode.equals("")){
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* ================= VALIDATION (SAME AS SERVLET) ================= */

    if(asOnDate == null || asOnDate.equals("")){
        session.setAttribute("errorMessage","Enter As On Date !!!");
        response.sendRedirect("RateWiseClassificationOfDepositRG.jsp");
        return;
    }

    if(branchCode.equals("0000")){
        if(fromBr == null || fromBr.equals("")){
            session.setAttribute("errorMessage","Enter From Branch Code !!!");
            response.sendRedirect("RateWiseClassificationOfDepositRG.jsp");
            return;
        }
        if(toBr == null || toBr.equals("")){
            session.setAttribute("errorMessage","Enter To Branch Code !!!");
            response.sendRedirect("RateWiseClassificationOfDepositRG.jsp");
            return;
        }
    }

    if(deposit == null && saving == null && pigmy == null){
        session.setAttribute("errorMessage",
        "Please select one From Saving, Deposit, Pigmy!");
        response.sendRedirect("RateWiseClassificationOfDepositRG.jsp");
        return;
    }

    /* ================= DATE FORMAT ================= */

    String oracleDate="";

    if(asOnDate != null && !asOnDate.equals("")){
        java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(d).toUpperCase();
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();
        Statement stmt = conn.createStatement();

        /* ===== DELETE OLD DATA ===== */
        stmt.executeUpdate("DELETE FROM BANKDATA.RATEWISEDEPOSITCLASS");

        /* ===== BUILD ACCOUNT TYPE CONDITION ===== */
        String condiType = "(";

        boolean first = true;

        if(deposit != null){
            condiType += "'4'";
            first = false;
        }

        if(saving != null){
            if(!first) condiType += ",";
            condiType += "'2'";
            first = false;
        }

        if(pigmy != null){
            if(!first) condiType += ",";
            condiType += "'6'";
        }

        condiType += ")";

        /* ===== DATE FORMAT ===== */
        String fromDate = oracleDate;

        /* ===== INSERT DATA ===== */
        String sql = 
"INSERT INTO BANKDATA.RATEWISEDEPOSITCLASS " +
"(BRANCH_CODE, ACCOUNT_CODE, BALANCE, PERIOD, INTEREST_RATE, INNER, GLACCOUNT_CODE, OUTER) " +
"SELECT " +
"SUBSTR(A.ACCOUNT_CODE,1,4), " +
"A.ACCOUNT_CODE, " +
"SYSTEM.FN_GET_BALANCE_ASON('" + fromDate + "',A.ACCOUNT_CODE), " +
"0, " +
"SYSTEM.Fn_Get_Deposit_Ir(A.ACCOUNT_CODE,'" + fromDate + "'), " +
"'A', '00000000000', '0' " +
"FROM ACCOUNT.ACCOUNT A " +
"WHERE SUBSTR(A.ACCOUNT_CODE,5,1) IN " + condiType + " " +
"AND SUBSTR(A.ACCOUNT_CODE,1,4) BETWEEN '" +
(fromBr != null && !fromBr.isEmpty() ? fromBr : branchCode) +
"' AND '" +
(toBr != null && !toBr.isEmpty() ? toBr : branchCode) +
"' " +
"AND SYSTEM.FN_GET_BALANCE_ASON('" + fromDate + "',A.ACCOUNT_CODE) <> 0 " +
"AND SYSTEM.Fn_Get_Deposit_Ir(A.ACCOUNT_CODE,'" + fromDate + "') > 0";
        stmt.executeUpdate(sql);

        stmt.close();

        /* ================= SELECT JASPER ================= */

        String jasperFile="";

        if("printing".equalsIgnoreCase(reportAction)){
            jasperFile="RateWiseClassificationOfDepositRG(Printing).jasper";
        }else{
            jasperFile="RateWiseClassificationOfDepositRG(List).jasper";
        }

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);

        JasperReport jr =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */
        		
        String accType = "";

        if(deposit != null) accType += "'4',";
        if(saving  != null) accType += "'2',";
        if(pigmy   != null) accType += "'6',";

        if(accType.endsWith(",")){
            accType = accType.substring(0, accType.length()-1);
        }		

        Map<String,Object> params = new HashMap<>();

        params.put("as_on_date",oracleDate);
        params.put("branch_code", fromBr != null && !fromBr.isEmpty() ? fromBr : branchCode);
        params.put("to_branch", toBr != null && !toBr.isEmpty() ? toBr : branchCode);
        params.put("acc_type", accType);
        
        params.put("SUBREPORT_DIR",
        		application.getRealPath("/Reports/") + "/");
        
        params.put("report_title","RATE WISE CLASSIFICATION OF DEPOSIT");

        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);

        params.put(JRParameter.REPORT_CONNECTION,conn);

        /* ================= FILL ================= */

        JasperPrint jp =
        JasperFillManager.fillReport(jr,params,conn);

        if(jp.getPages().isEmpty()){
            session.setAttribute("errorMessage","No Records Found!");
            response.sendRedirect("RateWiseClassificationOfDepositRG.jsp");
            return;
        }

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"RateWiseDeposit.pdf\"");

            ServletOutputStream os = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp,os);

            os.flush();
            os.close();
            return;
        }
        else{

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"RateWiseDeposit.xls\"");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT,jp);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,os);

            exporter.exportReport();

            os.flush();
            os.close();
            return;
        }

    }catch(Exception e){

        e.printStackTrace();

        Throwable cause = e;

        while(cause.getCause()!=null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg!=null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute("errorMessage","Error Message = "+msg);

        response.sendRedirect(
        request.getContextPath()+"/Reports/jspFiles/RateWiseClassificationOfDepositRG.jsp");

        return;

    }finally{

        if(conn!=null){
            try{conn.close();}catch(Exception ignored){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Rate Wise Classification Of Deposit</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.input-box { display:flex; gap:10px; }

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.checkbox-group{
    display:flex;
    gap:30px;
    margin-top:10px;
}

.modal{
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#fff;
    width:80%;
    padding:20px;
    border-radius:10px;
}

</style>

</head>

<body>

<div class="report-container">

<!-- ================= ERROR ================= -->

<%
String errorMessage = (String)session.getAttribute("errorMessage");
if(errorMessage != null){
%>
<div class="error-message">
    <%= errorMessage %>
</div>
<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">
RATE WISE CLASSIFICATION OF DEPOSIT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/RateWiseClassificationOfDepositRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="generate"/>
<input type="hidden" name="report_action" id="report_action"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- ================= HO BRANCH RANGE ================= -->

<% if("0000".equals((String)session.getAttribute("branch_code"))) { %>

<div class="parameter-group">
<div class="parameter-label">From Branch</div>

<div class="input-box">
<input type="text" name="from_br" class="input-field">
<button type="button" class="icon-btn" onclick="openLookup('branch')">…</button>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Branch</div>

<div class="input-box">
<input type="text" name="to_br" class="input-field">
<button type="button" class="icon-btn" onclick="openLookup('branch')">…</button>
</div>
</div>

<% } %>

<!-- ================= AS ON DATE ================= -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

<!-- ================= ACCOUNT TYPE ================= -->

<div class="parameter-group">
<div class="parameter-label">Account Type</div>

<div class="checkbox-group">

<label>
<input type="checkbox" name="Deposit_accounts" value="Y"
<%= "CHECKED".equals(session.getAttribute("Is_deposit")) ? "checked" : "" %>>
Deposit
</label>

<label>
<input type="checkbox" name="Saving_accounts" value="Y"
<%= "CHECKED".equals(session.getAttribute("Is_saving")) ? "checked" : "" %>>
Saving
</label>

<label>
<input type="checkbox" name="Pigmy_accounts" value="Y"
<%= "CHECKED".equals(session.getAttribute("Is_pigmy")) ? "checked" : "" %>>
Pigmy
</label>

</div>
</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div style="display:flex; gap:120px; margin-top:30px;">

<div class="parameter-group">

<div class="parameter-label">Report Type</div>

<div style="display:flex; gap:30px;">

<label>
<input type="radio" name="reporttype" value="pdf" checked> PDF
</label>

<label>
<input type="radio" name="reporttype" value="xls"> Excel
</label>

</div>

</div>

</div>

<!-- ================= BUTTONS ================= -->

<div style="margin-top:30px; display:flex; gap:20px;">

<button type="submit"
        class="download-button"
        onclick="setReportAction('printing')">
Rate Wise Printing
</button>

<button type="submit"
        class="download-button"
        onclick="setReportAction('list')">
Rate Wise List
</button>

</div>

</form>

</div>

<!-- ================= LOOKUP POPUP ================= -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

<!-- ================= SCRIPT ================= -->

<script>

function setReportAction(val){
    document.getElementById("report_action").value = val;
}

document.querySelector("form").onsubmit = function(){

    let date = document.querySelector("[name='as_on_date']").value;

    let deposit = document.querySelector("[name='Deposit_accounts']").checked;
    let saving  = document.querySelector("[name='Saving_accounts']").checked;
    let pigmy   = document.querySelector("[name='Pigmy_accounts']").checked;

    if(date === ""){
        alert("Enter As On Date");
        return false;
    }

    if(!deposit && !saving && !pigmy){
        alert("Select at least one account type");
        return false;
    }

    return true;
};

</script>

</body>
</html>