<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION DATE ================= */
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

/* ================= SESSION ================= */
String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser     = (String) session.getAttribute("isSupportUser");

if (sessionBranchCode == null) sessionBranchCode = "";
if (isSupportUser == null) isSupportUser = "N";

/* ================= REQUEST ================= */
String action     = request.getParameter("action");
String branchCode = request.getParameter("branch_code");
String dueDate    = request.getParameter("due_date");
String asOnDate   = request.getParameter("as_on_date");

/* DEFAULT BRANCH */
if (branchCode == null || branchCode.trim().isEmpty()) {
    branchCode = sessionBranchCode;
}

/* SECURITY */
if (!"Y".equalsIgnoreCase(isSupportUser)) {
    branchCode = sessionBranchCode;
}

/* DEFAULT DATES */
if (asOnDate == null || asOnDate.trim().isEmpty()) {
    asOnDate = sessionDate;
}

if (dueDate == null || dueDate.trim().isEmpty()) {
    dueDate = sessionDate;
}

/* ================= DOWNLOAD ================= */
if ("download".equals(action)) {

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* DATE CONVERSION (VERY IMPORTANT) */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String asOnDateOracle = outFmt.format(inFmt.parse(asOnDate)).toUpperCase();
        String dueDateOracle  = outFmt.format(inFmt.parse(dueDate)).toUpperCase();

        /* DEBUG (REMOVE LATER) */
        System.out.println("==== DEBUG VALUES ====");
        System.out.println("branch_code : " + branchCode);
        System.out.println("as_on_date  : " + asOnDateOracle);
        System.out.println("due_date    : " + dueDateOracle);

        /* LOAD JASPER */
        String jasperPath = application.getRealPath("/Reports/DueRenewalReport.jasper");

        File reportFile = new File(jasperPath);
        if (!reportFile.exists()) {
            throw new Exception("Jasper file not found at: " + jasperPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(reportFile);

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", asOnDateOracle);   // ✅ CORRECT
        params.put("due_date", dueDateOracle);

        params.put("report_title", "DUE RENEWAL ACCOUNT REPORT");

        params.put("SUBREPORT_DIR", application.getRealPath("/Reports/"));
        params.put("IMAGE_PATH", application.getRealPath("/images/logo.png"));

        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);

        /* FILL REPORT */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

        /* NO DATA CHECK */
        if (jasperPrint == null || jasperPrint.getPages().size() == 0) {
            response.setContentType("text/html");
            out.println("<h3 style='color:red;text-align:center;margin-top:50px;'>No Records Found</h3>");
            return;
        }

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        /* ================= PDF ================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"DueRenewalReport.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        /* ================= EXCEL ================= */
        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"DueRenewalReport.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, Boolean.FALSE);

            exporter.exportReport();
            sos.flush();
            return;
        }

    } catch (Exception e) {

        e.printStackTrace();

        response.setContentType("text/html");
        out.println("<h3 style='color:red;text-align:center;'>Error: " + e.getMessage() + "</h3>");
        return;

    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<% if (!"download".equals(action)) { %>

<!DOCTYPE html>
<html>
<head>
<title>Due Renewal Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";

function validateForm() {
    var dueDate = document.forms[0]["due_date"].value;
    if (!dueDate) {
        alert("Please select Due Date");
        return false;
    }
    return true;
}
</script>

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
    width:100%;
    height:100%;
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

<h1 class="report-title">Due Renewal Account Report</h1>

<%
String errorMessage = (String) session.getAttribute("errorMessage");
if (errorMessage != null) {
%>
<div class="error-message"><%= errorMessage %></div>
<%
session.removeAttribute("errorMessage");
}
%>

<form method="post"
      action="DueRenewalReport.jsp"
      target="_blank"
      onsubmit="return validateForm();">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
       name="branch_code"
       id="branch_code"
       value="<%=branchCode%>"
       class="input-field"
       <%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
<button type="button" class="icon-btn"
        onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- As On Date -->
<div class="parameter-group">
                <div class="parameter-label">From Date</div>
                <input type="date" 
                       name="as_on_date"
                       class="input-field"
                       value="<%=sessionDate%>"
                       required>
            </div>

<!-- Due Date -->
<div class="parameter-group">
<div class="parameter-label">Due Date</div>
<input type="date"
       name="due_date"
       class="input-field"
       required>
</div>

</div>

<div class="format-section">
<div class="parameter-label">Report Type</div>
<input type="radio" name="reporttype" value="pdf" checked> PDF
<input type="radio" name="reporttype" value="xls"> Excel
</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- LOOKUP POPUP -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>

<% } %>