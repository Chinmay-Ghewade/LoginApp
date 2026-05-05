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
/* ================= SESSION DATA ================= */

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

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

/* FORMAT DISPLAY DATE */

String displayDate = "";

try {
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

/* USER + BRANCH */

String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser     = (String) session.getAttribute("isSupportUser");
String userId            = (String) session.getAttribute("userId");

if(sessionBranchCode == null) sessionBranchCode = "";
if(isSupportUser == null) isSupportUser = "N";

/* ERROR MESSAGE */

String errorMessage = request.getParameter("errorMessage");
if(errorMessage == null) errorMessage = "";

%>
<%
String action = request.getParameter("action");

if ("generate".equals(action)) {

    String reportType = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String dateInput  = request.getParameter("date");

    if(branchCode == null || branchCode.trim().isEmpty()){
        branchCode = (String) session.getAttribute("branchCode");
    }

    
    /* ===== DATE CONVERSION ===== */

    String oracleDate = "";

    try {
        java.util.Date d =
            new SimpleDateFormat("dd/MM/yyyy").parse(dateInput);

        oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(d).toUpperCase();

    } catch(Exception e) {
        out.println("<h3 style='color:red'>Invalid Date Format</h3>");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* ===== LOAD JASPER ===== */

        String jasperPath =
        application.getRealPath("/Reports/ConsolidatedGLBalance.jasper");

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ===== PARAMETERS ===== */

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDate);
        parameters.put("report_title", "CONSOLIDATED GL BALANCE REPORT");

        parameters.put("user_id", userId);

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(JRParameter.REPORT_CONNECTION, conn);

        /* ===== FILL REPORT ===== */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* ===== NO DATA CHECK ===== */

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ===== EXPORT ===== */

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"ConsolidatedGLBalance.pdf\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint, outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"ConsolidatedGLBalance.xls\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    } catch(Exception e) {

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new PrintWriter(out));

    } finally {

        if(conn != null){
            try { conn.close(); } catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Consolidated GL Balance</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.input-box {
    display:flex;
    gap:10px;
}

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
CONSOLIDATED GL BALANCE REPORT
</h1>

<form method="post"
      action="ConsolidatedGLBalance.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="generate"/>

<div class="parameter-section">

<!-- BANK / BRANCH -->

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
    <input type="text"
           name="branch_code"
           id="branch_code"
           class="input-field"
           value="<%= sessionBranchCode %>"
           <%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
           required>

    <% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
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

<!-- DATE -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="text"
       name="date"
       class="input-field"
       value="<%= displayDate %>"
       placeholder="DD/MM/YYYY"
       required>
</div>

</div>

<!-- REPORT TYPE -->

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

<!-- ERROR -->

<% if(!errorMessage.equals("")) { %>
<h3 style="color:red;text-align:center;">
<%= errorMessage %>
</h3>
<% } %>

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>