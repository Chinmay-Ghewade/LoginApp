<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page import="db.DBConnection" %>

<%
/* =========================
   SESSION DATE FIX
========================= */
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

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

/* =========================
   BRANCH CODE LOGIC (REFERENCE STYLE)
========================= */
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";

String branch_code = request.getParameter("branch_code");

if (branch_code == null || branch_code.trim().isEmpty()) {
    branch_code = sessionBranchCode;
}

/* SECURITY */
if (!"Y".equalsIgnoreCase(isSupportUser)) {
    branch_code = sessionBranchCode;
}

String branch_code_to = request.getParameter("branch_code_to");

if (branch_code_to == null || branch_code_to.trim().isEmpty()) {
    branch_code_to = sessionBranchCode;
}

if (!"Y".equalsIgnoreCase(isSupportUser)) {
    branch_code_to = sessionBranchCode;
}


/* =========================
   BACKEND LOGIC (JASPER VERSION)
========================= */
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");

    String branchCode = request.getParameter("branch_code");
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    String branchCodeTo = request.getParameter("branch_code_to");
    if (branchCodeTo == null || branchCodeTo.trim().isEmpty()) {
        branchCodeTo = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCodeTo = sessionBranchCode;
    }

    /* ✅ USE SAME NAMES AS HTML */
    String prCodeFr = request.getParameter("pr_code_fr");
    String prCodeTo = request.getParameter("pr_code_to");
    String asOnDate = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        /* VALIDATION */
        if (asOnDate == null || asOnDate.trim().isEmpty()) {
            throw new Exception("Enter As On Date");
        }

        if (prCodeFr == null || prCodeFr.trim().isEmpty()) {
            throw new Exception("Enter From Product Code");
        }

        if (prCodeTo == null || prCodeTo.trim().isEmpty()) {
            throw new Exception("Enter To Product Code");
        }

        conn = DBConnection.getConnection();

        /* DATE FORMAT (REFERENCE STYLE) */
        String oracleDateStr;

        if (asOnDate != null && !asOnDate.trim().isEmpty()) {

            java.util.Date utilDate =
                    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(utilDate).toUpperCase();

        } else {

            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(new java.util.Date()).toUpperCase();
        }

        /* LOAD JASPER */
        String jasperPath =
                application.getRealPath("/Reports/LoanExcessLimitAmountRG.jasper");

        net.sf.jasperreports.engine.JasperReport jasperReport =
                (net.sf.jasperreports.engine.JasperReport)
                        net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(jasperPath));

        /* PARAMETERS (MATCH REFERENCE STYLE) */
        Map<String, Object> parameters = new HashMap<>();

parameters.put("branch_code", branchCode);
/* BRANCH */
parameters.put("from_branch", branchCode);
parameters.put("to_branch", branchCodeTo);

/* EXACT MATCH WITH JAVA LOGIC */
parameters.put("from_product_code", prCodeFr);
parameters.put("to_product_code", prCodeTo);
parameters.put("as_on_date", oracleDateStr);
parameters.put("report_title", "ACCOUNTS WITH EXCESS AMOUNT LIMIT");

/* USER */
String userId = (String) session.getAttribute("userId");
parameters.put("user_id", userId);

parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));
        /* FILL */
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

        /* EXPORT */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"LoanExcessLimitReport.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            net.sf.jasperreports.engine.JasperExportManager
                    .exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        else if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"LoanExcessLimitReport.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

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

<title>ACCOUNTS WITH EXCESS AMOUNT LIMIT</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
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
ACCOUNTS WITH EXCESS AMOUNT LIMIT</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/LoanExcessLimitAmountRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- Branch Code Section -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Branch Code</div>
<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
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
<div class="parameter-label">To Branch Code</div>
<div class="input-box">
<input type="text"
name="branch_code_to"
id="branch_code_to"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

</div>

<!-- Product Code Section -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Product Code</div>
<div class="input-box">
<input type="text"
name="pr_code_fr"
id="product_code"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Product Code</div>
<div class="input-box">
<input type="text"
name="pr_code_to"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>
</div>

</div>

<!-- As On Date + Report Dropdown (Side By Side) -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="date"
name="as_on_date"
class="input-field"
value="<%=sessionDate%>" 
required>
</div>


</div>

<!-- Report Type -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
name="reporttype"
value="pdf"
checked>
PDF
</div>

<div class="format-option">
<input type="radio"
name="reporttype"
value="xls">
Excel
</div>

</div>

</div>

<!-- Generate Button -->

<button type="submit"
class="download-button">

Generate Report

</button>

</form>

</div>

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>

</html>