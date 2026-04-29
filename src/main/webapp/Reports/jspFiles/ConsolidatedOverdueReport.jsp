<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat,java.io.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION ================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.equals("")) {
    sessionDate = new SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if(isSupportUser == null) isSupportUser="N";
if(sessionBranchCode == null) sessionBranchCode="";
%>

<%
/* ================= ACTION ================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode   = request.getParameter("branch_code");
    String productCode  = request.getParameter("product_code");
    String singleAll    = request.getParameter("single_all");
    String asOnDate     = request.getParameter("as_on_date");
    String fromMonth    = request.getParameter("from_month");
    String toMonth      = request.getParameter("to_month");
    String overdueType  = request.getParameter("overdue_type");
    String loanAgainst  = request.getParameter("loan_against");
    String reporttype   = request.getParameter("reporttype");
    String colType      = request.getParameter("col_type");   // ✅ FIXED (missing)

    /* ===== DEFAULT VALUES ===== */

    if(overdueType == null) overdueType = "O";
    if(colType == null) colType = "A";

    if(branchCode==null || branchCode.trim().equals(""))
        branchCode = sessionBranchCode;

    if(!"Y".equalsIgnoreCase(isSupportUser))
        branchCode = sessionBranchCode;

    if(productCode==null) productCode="";
    if(fromMonth==null || fromMonth.equals("")) fromMonth="0";
    if(toMonth==null || toMonth.equals("")) toMonth="99";

    /* ===== VALIDATION ===== */

    if("S".equals(singleAll) && productCode.trim().equals("")){
        out.println("<h3 style='color:red'>Enter Product Code</h3>");
        return;
    }

    /* ===== DATE FORMAT ===== */

    String oracleDate="";

    if(asOnDate!=null && !asOnDate.equals("")){
        java.util.Date d =
            new java.text.SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
            new java.text.SimpleDateFormat("dd-MMM-yyyy",java.util.Locale.ENGLISH)
            .format(d).toUpperCase();
    }

    /* ===== SQL CONDITIONS ===== */

    String condition="";
    if("S".equals(singleAll)){
        condition = " AND P.PRODUCT_CODE='"+productCode+"' ";
    }

    String sqlDate="";
    if("I".equals(overdueType)){
        sqlDate=" AND TL.ACCOUNTREVIEWDATE >= '"+oracleDate+"' ";
    }else if("D".equals(overdueType)){
        sqlDate=" AND TL.ACCOUNTREVIEWDATE < '"+oracleDate+"' ";
    }

    String ruleCondition="";
    if("N".equals(loanAgainst)){
        ruleCondition=" AND P.LOANRULE_ID NOT IN (5,3) ";
    }

    /* ===== SQL (⚠️ DO NOT MODIFY STRUCTURE) ===== */

    String sql =
    " SELECT T.ACCOUNT_CODE, AA.NAME, "+
    " T.LEDGER_BALANCE, T.OVERDUE_BALANCE, "+
    " FN_GET_OVD_MONTH_NPA(AA.ACCOUNT_CODE,'"+oracleDate+"') OVERDUE_MONTHS "+
    " FROM ( "+
    " SELECT ACCOUNT_CODE, SUM(LEDGER_BALANCE) LEDGER_BALANCE, "+
    " SUM(OVERDUE_BALANCE) OVERDUE_BALANCE "+
    " FROM ( "+
    " SELECT A.ACCOUNT_CODE, "+
    " FN_GET_BALANCE_ASON('"+oracleDate+"',A.ACCOUNT_CODE) LEDGER_BALANCE, "+
    " OVERDUEONINSTALLMENTRULE(A.ACCOUNT_CODE,'"+oracleDate+"','N',0) OVERDUE_BALANCE "+
    " FROM ACCOUNT.ACCOUNT A, HEADOFFICE.PRODUCTPARAMETERLOAN P "+
    " WHERE P.PRODUCT_CODE = SUBSTR(A.ACCOUNT_CODE,5,3) "+
    condition + ruleCondition +
    " AND P.IS_CAL_OVD='Y' "+
    " ) GROUP BY ACCOUNT_CODE ) T, ACCOUNT.ACCOUNT AA, ACCOUNT.ACCOUNTLOAN TL "+
    " WHERE AA.ACCOUNT_CODE=T.ACCOUNT_CODE "+
    " AND TL.ACCOUNT_CODE=T.ACCOUNT_CODE "+
    " AND T.OVERDUE_BALANCE>0 "+
    sqlDate +
    " AND FN_GET_OVD_MONTH_NPA(AA.ACCOUNT_CODE,'"+oracleDate+"') BETWEEN "+fromMonth+" AND "+toMonth;

    /* ===== DB ===== */

    Connection conn=null;

    try{

        conn = DBConnection.getConnection();

        /* ===== JASPER FILE SELECTION ===== */

        String jasperFile = "";

        if("I".equals(overdueType)){   // Installment Due

            if("G".equals(colType)){
                jasperFile = "ConsolidatedOverdueReport(installment due gurantor).jasper";
            }else{
                jasperFile = "ConsolidatedOverdueReport (installment due).jasper";
            }

        }else{   // Installment Add / All

            jasperFile = "ConsolidatedOverdueReport(installment add).jasper";
        }

        /* ===== PATH ===== */

        String jasperPath =
            application.getRealPath("/Reports/" + jasperFile);

        /* ===== LOAD REPORT ===== */

        net.sf.jasperreports.engine.JasperReport jasperReport =
        (net.sf.jasperreports.engine.JasperReport)
        net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(jasperPath));

        java.util.Map<String,Object> params = new java.util.HashMap<>();

        params.put("SQL_QUERY", sql);
        params.put("REPORT_TITLE", "CONSOLIDATED OVERDUE REPORT");
        params.put(net.sf.jasperreports.engine.JRParameter.REPORT_CONNECTION, conn);

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("from_month", fromMonth);
        params.put("to_month", toMonth);
        params.put("product_code", productCode);
        params.put("user_id", session.getAttribute("userId"));
        params.put("SUBREPORT_DIR", application.getRealPath("/Reports/") + "/");

        net.sf.jasperreports.engine.JasperPrint print =
        net.sf.jasperreports.engine.JasperFillManager.fillReport(jasperReport, params, conn);

        if(print.getPages().isEmpty()){
            out.println("<h2 style='color:red;text-align:center'>No Records Found</h2>");
            return;
        }

        response.reset();

    /* ===== EXPORT ===== */

    if("xls".equalsIgnoreCase(reporttype)){

        response.setContentType("application/vnd.ms-excel");
        response.setHeader("Content-Disposition","attachment; filename=OverdueReport.xls");

        net.sf.jasperreports.engine.export.JRXlsExporter exporter =
        new net.sf.jasperreports.engine.export.JRXlsExporter();

        exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.JASPER_PRINT, print);

        exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.OUTPUT_STREAM,
            response.getOutputStream());

        exporter.exportReport();

    }else{

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition","inline; filename=OverdueReport.pdf");

        net.sf.jasperreports.engine.JasperExportManager
        .exportReportToPdfStream(print, response.getOutputStream());
    }

    return;

    }catch(Exception e){

        e.printStackTrace();

        Throwable cause = e;

        while(cause.getCause() != null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg != null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute(
            "errorMessage",
            "Error Message = " + msg
        );

        response.sendRedirect("ConsolidatedOverdueReport.jsp");
        return;
    }finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Consolidated Overdue Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

/* 🔹 Layout */
.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-box { display:flex; gap:10px; }

/* 🔹 Button */
.icon-btn {
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

/* 🔹 Disabled field */
.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
}

/* 🔹 MODAL (FIXED CENTER POPUP) */
.modal {
    display:none;
    position:fixed;
    top:0;
    left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.6);
    z-index:9999;

    display:flex;
    justify-content:center;
    align-items:center;
}

/* 🔹 Modal Box */
.modal-content {
    background:#fff;
    width:80%;
    max-height:85%;
    overflow:auto;
    padding:20px;
    border-radius:10px;
    box-shadow:0 0 20px rgba(0,0,0,0.4);
    position:relative;
}

/* 🔹 Close button */
.modal-content button{
    position:absolute;
    right:10px;
    top:10px;
    background:red;
    color:white;
    border:none;
    padding:5px 10px;
    cursor:pointer;
}

</style>

</head>

<body>

<div class="report-container">

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
CONSOLIDATED OVERDUE REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/ConsolidatedOverdueReport.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- 🔹 Branch Code -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">

<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       <%= !"Y".equalsIgnoreCase(isSupportUser == null ? "" : isSupportUser.trim()) ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser == null ? "" : isSupportUser.trim())) { %>
<button type="button" class="icon-btn" onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<!-- 🔹 Product -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
<input type="text" name="product_code" id="product_code" class="input-field">

<button type="button" class="icon-btn"
        onclick="openLookup('product')">…</button>
</div>

<div class="radio-container">
<label><input type="radio" name="single_all" value="S" checked onclick="toggleProduct()"> Single</label>
<label><input type="radio" name="single_all" value="A" onclick="toggleProduct()"> All</label>
</div>

</div>

<!-- 🔹 Due Months -->
<div class="parameter-group">
<div class="parameter-label">Due Months</div>

<div class="input-box">
<input type="text" name="from_month" class="input-field" placeholder="From">
<input type="text" name="to_month" class="input-field" placeholder="To">
</div>
</div>

<!-- 🔹 Date -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

<!-- 🔹 Overdue Type -->
<div class="parameter-group">
<div class="parameter-label">Overdue Type</div>

<div class="radio-container">
<label><input type="radio" name="overdue_type" value="O" checked>All</label>
<label><input type="radio" name="overdue_type" value="I">Installment</label>
<label><input type="radio" name="overdue_type" value="D">Due Date</label>
</div>
</div>

<!-- 🔹 Loan Against -->
<div class="parameter-group">
<div class="parameter-label">Loan Against Deposit</div>

<div class="radio-container">
<label><input type="radio" name="loan_against" value="Y" checked>Yes</label>
<label><input type="radio" name="loan_against" value="N">No</label>
</div>
</div>

<!-- 🔥 NEW (IMPORTANT FOR YOUR JASPER LOGIC) -->
<div class="parameter-group">
<div class="parameter-label">Report Columns</div>

<div class="radio-container">
<label><input type="radio" name="col_type" value="A" checked>Address</label>
<label><input type="radio" name="col_type" value="G">Guarantor</label>
<label><input type="radio" name="col_type" value="N">Phone</label>
</div>
</div>

</div>

<!-- 🔹 Format -->
<div class="format-section">
<div class="parameter-label">Report Type</div>

<div class="format-options">
<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls"> Excel
</div>
</div>
</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- 🔥 POPUP -->
<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()">✖</button>
<div id="lookupTable"></div>
</div>
</div>

<script>

/* 🔹 Product toggle */
function toggleProduct(){
    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField = document.getElementById("product_code");

    if(single){
        productField.disabled = false;
    }else{
        productField.value="";
        productField.disabled = true;
    }
}

/* 🔹 Ensure popup hidden initially */
document.getElementById("lookupModal").style.display="none";

window.onload = function(){
    toggleProduct();
};

</script>

</body>
</html>