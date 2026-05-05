<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

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

String displayDate = "";

try {
    java.util.Date d =
        new java.text.SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new java.text.SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {


String reporttype  = request.getParameter("reporttype");


/* ================= BRANCH ================= */

String branchCode  = request.getParameter("branch_code");

if (branchCode == null || branchCode.trim().isEmpty()) {
    branchCode = sessionBranchCode;
}

if (!"Y".equalsIgnoreCase(isSupportUser)) {
    branchCode = sessionBranchCode;
}

/* ================= PRODUCT (UPDATED) ================= */

String prCodeFr = request.getParameter("pr_code_fr");
String prCodeTo = request.getParameter("pr_code_to");

/* ================= DATE ================= */

String fromDate = request.getParameter("from_date");
String toDate   = request.getParameter("to_date");

/* ================= VALIDATION ================= */

if(prCodeFr == null || prCodeFr.trim().isEmpty()){
    out.println("<h3 style='color:red'>Please Enter Product Code From</h3>");
    return;
}

if(prCodeTo == null || prCodeTo.trim().isEmpty()){
    out.println("<h3 style='color:red'>Please Enter Product Code To</h3>");
    return;
}

if(fromDate == null || fromDate.trim().isEmpty()){
    out.println("<h3 style='color:red'>Please Enter From Date</h3>");
    return;
}

if(toDate == null || toDate.trim().isEmpty()){
    out.println("<h3 style='color:red'>Please Enter To Date</h3>");
    return;
}

/* ================= DATE FORMAT ================= */

String oracleFromDate="";
String oracleToDate="";

try{

	java.util.Date d1 =
		    new SimpleDateFormat("dd/MM/yyyy").parse(fromDate);

		java.util.Date d2 =
		    new SimpleDateFormat("dd/MM/yyyy").parse(toDate);
		
    oracleFromDate =
        new java.text.SimpleDateFormat("dd-MMM-yyyy",java.util.Locale.ENGLISH)
        .format(d1).toUpperCase();

    oracleToDate =
        new java.text.SimpleDateFormat("dd-MMM-yyyy",java.util.Locale.ENGLISH)
        .format(d2).toUpperCase();

}catch(Exception e){
    out.println("<h3 style='color:red'>Invalid Date Format</h3>");
    return;
}

Connection conn = null;

try {

    response.reset();
    response.setBufferSize(1024*1024);

    conn = db.DBConnection.getConnection();

    /* ================= LOAD JASPER ================= */

    String jasperPath =
    application.getRealPath("/Reports/AccountLessThanMinBalanceRG.jasper");

    net.sf.jasperreports.engine.JasperReport jasperReport =
    (net.sf.jasperreports.engine.JasperReport)
    net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(jasperPath));

    /* ================= PARAMETERS ================= */

    java.util.Map<String,Object> parameters = new java.util.HashMap<>();

    /* 🔥 IMPORTANT: MATCH JRXML EXACTLY */
    parameters.put("branch_code", branchCode);
    parameters.put("as_on_date", oracleFromDate);
    parameters.put("to_date", oracleToDate);

    /* ✅ PRODUCT LOGIC FIXED */
    parameters.put("from_product", prCodeFr);
    parameters.put("to_product", prCodeTo);

    parameters.put("report_title",
        "ACCOUNT LESS THAN MINIMUM BALANCE");

    String userId = (String) session.getAttribute("userId");
    parameters.put("user_id", userId);

    parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

    parameters.put(net.sf.jasperreports.engine.JRParameter.REPORT_CONNECTION, conn);

    /* ================= FILL ================= */

    net.sf.jasperreports.engine.JasperPrint jasperPrint =
    net.sf.jasperreports.engine.JasperFillManager.fillReport(
        jasperReport, parameters, conn);

    if (jasperPrint.getPages().isEmpty()) {

        response.reset();
        response.setContentType("text/html");

        out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
        out.println("No Records Found!");
        out.println("</h2>");

        return;
    }

    /* ================= EXPORT ================= */

    if("pdf".equalsIgnoreCase(reporttype)){

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition",
        "inline; filename=\"AccountLessThanMinBalance.pdf\"");

        javax.servlet.ServletOutputStream outStream =
        response.getOutputStream();

        net.sf.jasperreports.engine.JasperExportManager
        .exportReportToPdfStream(jasperPrint,outStream);

        outStream.flush();
        outStream.close();
        return;
    }

    else if("xls".equalsIgnoreCase(reporttype)){

        response.setContentType("application/vnd.ms-excel");
        response.setHeader("Content-Disposition",
        "attachment; filename=\"AccountLessThanMinBalance.xls\"");

        javax.servlet.ServletOutputStream outStream =
        response.getOutputStream();

        net.sf.jasperreports.engine.export.JRXlsExporter exporter =
        new net.sf.jasperreports.engine.export.JRXlsExporter();

        exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.JASPER_PRINT,
            jasperPrint);

        exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.OUTPUT_STREAM,
            outStream);

        exporter.exportReport();

        outStream.flush();
        outStream.close();
        return;
    }

} catch(Exception e){

    out.println("<h3 style='color:red'>Error Generating Report</h3>");
    e.printStackTrace(new java.io.PrintWriter(out));

} finally {

    if(conn!=null){
        try{conn.close();}catch(Exception ex){}
    }
}


}
%>


<!DOCTYPE html>
<html>
<head>

<title>Account Less Than Minimum Balance</title>

<!-- CSS -->
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<!-- Lookup Script -->
<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.input-box { display:flex; gap:10px; }

.icon-btn {
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.modal {
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content {
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    padding:20px;
    border-radius:8px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
ACCOUNT LESS THAN MINIMUM BALANCE REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/AccountLessThanMinBalanceRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch Code -->

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

<!-- PRODUCT FROM -->

<div class="parameter-group">

<div class="parameter-label">Product Code From</div>

<div class="input-box">
    <input type="text"
       name="pr_code_fr"
       id="pr_code_fr"
       class="input-field"
       required>

    <button type="button"
            class="icon-btn"
            onclick="openLookup('product')">…</button>
</div>

</div>

<!-- PRODUCT TO -->

<div class="parameter-group">

<div class="parameter-label">Product Code To</div>

<div class="input-box">
   <input type="text"
       name="pr_code_to"
       id="pr_code_to"
       class="input-field"
       required>

    <button type="button"
            class="icon-btn"
            onclick="openLookup('product')">…</button>
</div>

</div>

<!-- DATE RANGE -->

<div class="parameter-group">

<div class="parameter-label">From Date</div>

<input type="text"
       name="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<div class="parameter-group">

<div class="parameter-label">To Date</div>

<input type="text"
       name="to_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

</div>

<!-- REPORT TYPE -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
       name="reporttype"
       value="pdf"
       checked> PDF
</div>

<div class="format-option">
<input type="radio"
       name="reporttype"
       value="xls"> Excel
</div>

</div>

</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- POPUP MODAL -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<!-- VALIDATION -->

<script>

document.querySelector("form").onsubmit = function(){

    let fromDate = document.querySelector("[name=from_date]").value;
    let toDate   = document.querySelector("[name=to_date]").value;

    if(fromDate > toDate){
        alert("From Date cannot be greater than To Date");
        return false;
    }

    return true;
};

</script>

</body>
</html>