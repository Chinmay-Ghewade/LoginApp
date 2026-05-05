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
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String branchCode = request.getParameter("branch_code");
    String userId     = request.getParameter("user_id");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String reporttype = request.getParameter("reporttype");

    /* ================= CLEAN INPUT ================= */

    if (branchCode != null) branchCode = branchCode.trim();
    if (userId != null) userId = userId.trim();

    /* ================= BRANCH ================= */

    if (branchCode == null || branchCode.isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* ================= CHECKBOX ================= */

    String[] checks = request.getParameterValues("CHECK");

    if (checks == null || checks.length == 0) {
        out.println("<h3 style='color:red'>Select at least one Indicator</h3>");
        return;
    }

    StringBuilder sb = new StringBuilder();

    for (int i = 0; i < checks.length; i++) {
        if (sb.length() > 0) sb.append(",");
        sb.append(checks[i]);
    }

    String checkStr = sb.toString();
    
    /* ================= VALIDATION ================= */

    if (userId == null || userId.isEmpty()) {
        out.println("<h3 style='color:red'>Enter User ID</h3>");
        return;
    }

    if (fromDate == null || fromDate.trim().isEmpty() ||
        toDate == null || toDate.trim().isEmpty()) {

        out.println("<h3 style='color:red'>Enter Date Range</h3>");
        return;
    }

    /* ================= DATE ================= */

    String oracleFrom = "";
    String oracleTo   = "";

    try {

        java.util.Date d1 =
            new java.text.SimpleDateFormat("yyyy-MM-dd").parse(fromDate);

        java.util.Date d2 =
            new java.text.SimpleDateFormat("yyyy-MM-dd").parse(toDate);

        oracleFrom =
            new java.text.SimpleDateFormat("dd-MMM-yyyy", java.util.Locale.ENGLISH)
            .format(d1).toUpperCase();

        oracleTo =
            new java.text.SimpleDateFormat("dd-MMM-yyyy", java.util.Locale.ENGLISH)
            .format(d2).toUpperCase();

    } catch (Exception e) {
        out.println("<h3 style='color:red'>Invalid Date Format</h3>");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= USER VALIDATION ================= */

       PreparedStatement ps = conn.prepareStatement(
    "SELECT DISTINCT USER_ID FROM TRANSACTION.DAILYTXN WHERE USER_ID=? AND BRANCH_CODE=?"
);

ps.setString(1, userId);
ps.setString(2, branchCode);

ResultSet rsUser = ps.executeQuery();

if (!rsUser.next()) {
    out.println("<h3 style='color:red'>Invalid User ID</h3>");
    return;
}

        rsUser.close();
        ps.close();

        /* ================= LOAD JASPER ================= */

        String jasperPath =
            application.getRealPath("/Reports/TransactionDetailsRG.jasper");

        net.sf.jasperreports.engine.JasperReport jasperReport =
            (net.sf.jasperreports.engine.JasperReport)
            net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(jasperPath));

        /* ================= PARAMETERS ================= */

        java.util.Map<String, Object> parameters = new java.util.HashMap<>();

        parameters.put("branch_code", branchCode);

    
        String asOnDate =
        	    new java.text.SimpleDateFormat("dd-MMM-yyyy", java.util.Locale.ENGLISH)
        	    .format(new java.util.Date())
        	    .toUpperCase();

        	parameters.put("as_on_date", asOnDate);
        	parameters.put("from_date", oracleFrom);
     parameters.put("to_date", oracleTo);
     parameters.put("user_id", userId);

     // 🔥 IMPORTANT FIX (NAME MATCH)
     parameters.put("indicatorStr", checkStr);   // CHANGE THIS
        parameters.put("report_title", "TRANSACTION DETAILS REPORT");

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

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
                "inline; filename=\"TransactionDetails_Report.pdf\"");

            javax.servlet.ServletOutputStream outStream =
                response.getOutputStream();

            net.sf.jasperreports.engine.JasperExportManager
                .exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();

        } else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
                "attachment; filename=\"TransactionDetails_Report.xls\"");

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
        }

    } catch (Exception e) {

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new java.io.PrintWriter(out));

    } finally {

        if (conn != null) {
            try { conn.close(); } catch (Exception ex) {}
        }
    }
}
%>

<!DOCTYPE html>

<html>
<head>

<title>Transaction Details Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css?v=5">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js?v=5"></script>

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

.checkbox-container{
    display:flex;
    flex-wrap:wrap;
    gap:15px;
    margin-top:10px;
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
TRANSACTION DETAILS REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/TransactionDetailsRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch -->

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%=sessionBranchCode%>"
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %> <button type="button"
     class="icon-btn"
     onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- User -->

<div class="parameter-group">
    <div class="parameter-label">User ID</div>

    <div class="input-box">
        <input type="text"
               name="user_id"
               id="user_id"
               class="input-field"
               required>

        <button type="button"
            class="icon-btn"
            onclick="
                let branch = document.getElementById('branch_code').value;
                if(!branch){
                    alert('Please select branch first');
                    return;
                }
                openLookup('user','branchCode='+branch);
            ">
            …
        </button>
    </div>
</div>

<!-- ✅ ADD THIS (IMPORTANT) -->
<div class="parameter-group">
    <div class="parameter-label">User Name</div>
    <input type="text" id="userName" class="input-field" readonly>
</div>
<!-- Date -->

<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date"
       name="from_date"
       class="input-field"
       required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date"
       name="to_date"
       class="input-field"
       required>
</div>

<!-- Indicators -->

<div class="parameter-group">
<div class="parameter-label">Transaction Indicators</div>

<div class="checkbox-container">

<label><input type="checkbox" name="CHECK" value="CSCR" checked> CSCR</label> <label><input type="checkbox" name="CHECK" value="TRCR"> TRCR</label> <label><input type="checkbox" name="CHECK" value="CLCR"> CLCR</label> <label><input type="checkbox" name="CHECK" value="CSDR"> CSDR</label> <label><input type="checkbox" name="CHECK" value="TRDR"> TRDR</label> <label><input type="checkbox" name="CHECK" value="CLDR"> CLDR</label>

</div>

</div>

</div>

<!-- Report Type -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">
<label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
<label><input type="radio" name="reporttype" value="xls"> Excel</label>
</div>

</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- Modal -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

document.querySelector("form").onsubmit=function(){

    let fromDate=document.querySelector("[name=from_date]").value;
    let toDate=document.querySelector("[name=to_date]").value;
    let user=document.querySelector("[name=user_id]").value;

    if(user===""){
        alert("Enter User ID");
        return false;
    }

    if(fromDate>toDate){
        alert("From Date cannot be greater than To Date");
        return false;
    }

    let checks=document.querySelectorAll("input[name='CHECK']:checked");

    if(checks.length===0){
        alert("Select at least one Transaction Indicator");
        return false;
    }

    return true;
};

</script>

</body>
</html>
