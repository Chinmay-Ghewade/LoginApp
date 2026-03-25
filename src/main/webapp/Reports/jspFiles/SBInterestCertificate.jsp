<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="64kb" autoFlush="true" %>

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

// fallback
if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
%>

<%
/* ==============================
   REMOVE DEFAULTS → USE REQUEST DIRECTLY
   ============================== */

String branchCode = request.getParameter("branch_code");
String accountCode = request.getParameter("account_code");
String fromDate = request.getParameter("from_date");
String toDate = request.getParameter("to_date");

// avoid null issues
if (branchCode == null) branchCode = "";
if (accountCode == null) accountCode = "";
if (fromDate == null) fromDate = "";
if (toDate == null) toDate = "";

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");

    Connection conn = null;

    try {

        // ✅ validation
        if (branchCode.trim().isEmpty() || accountCode.trim().isEmpty()) {
            throw new Exception("Branch Code and Account Code are required.");
        }

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();

        String jasperPath =
                application.getRealPath("/Reports/SBInterestCertificate.jasper");

        File jasperFile = new File(jasperPath);

        if (!jasperFile.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(jasperFile);

        /* ==========================
           PARAMETERS
           ========================== */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode.trim());
        parameters.put("account_code", accountCode.trim());
        parameters.put("from_date", fromDate);
        parameters.put("to_date", toDate);
        parameters.put("session_date", sessionDate);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* ==========================
           PDF EXPORT
           ========================== */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"SB_Interest_Certificate.pdf\""
            );

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream outStream = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* ==========================
           EXCEL EXPORT
           ========================== */
        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"SB_Interest_Certificate.xls\""
            );

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(
                    JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(
                    JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
            return;
        }

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html");
        out.println("<h2 style='color:red'>Error Generating Certificate</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");
        return;

    } finally {

        if (conn != null) {
            try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
<title>Saving Bank Interest Certificate</title>
<link rel="stylesheet"href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet"href="<%=request.getContextPath()%>/css/lookup.css">
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
    SAVING BANK INTEREST CERTIFICATE
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/SBInterestCertificate.jsp"
      target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>
<div class="input-box">
    <input type="text" name="branch_code"
           id="branch_code"
           class="input-field"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openBranchLookup()">…</button>
</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branch_name"
           class="input-field" readonly>
</div>

<div class="parameter-group">
<div class="parameter-label">Account Code</div>
<div class="input-box">
    <input type="text" name="account_code"
           id="account_code"
           class="input-field"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openAccountLookup()">…</button>
</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Account Name</div>
    <input type="text" id="account_name"
           class="input-field" readonly>
</div>

<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date" name="from_date"
       class="input-field"
       value="<%= sessionDate %>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date" name="to_date"
       class="input-field"
       required>
</div>

</div>

<div class="format-section">
<div class="parameter-label">Report Type</div>

<div class="format-options">
<div class="format-option">
<input type="radio" name="reporttype"
       value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype"
       value="xls"> Excel
</div>
</div>
</div>

<button type="submit" class="download-button">
Generate Certificate
</button>

</form>

</div>
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

// OPEN BRANCH LOOKUP
function openBranchLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// OPEN ACCOUNT LOOKUP
function openAccountLookup() {

    let branch = document.getElementById("branch_code").value;

    if (!branch || branch.trim() === "") {
        alert("Please select branch first");
        return;
    }

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=account&branchCode=" + encodeURIComponent(branch))
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// CLOSE MODAL
function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}

// SELECT BRANCH
function selectBranch(code, name) {
    document.getElementById("branch_code").value = code;
    document.getElementById("branch_name").value = name;
    closeLookup();
}

// SELECT ACCOUNT
function selectAccount(code, name) {
    document.getElementById("account_code").value = code;
    document.getElementById("account_name").value = name;
    closeLookup();
}

// FETCH NAME ON BLUR
document.getElementById("branch_code").addEventListener("blur", function() {

    let code = this.value;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + code)
        .then(res => res.text())
        .then(name => {
            document.getElementById("branch_name").value = name || "Not Found";
        });
});

document.getElementById("account_code").addEventListener("blur", function() {

    let code = this.value;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=account&action=getName&code=" + code)
        .then(res => res.text())
        .then(name => {
            document.getElementById("account_name").value = name || "Not Found";
        });
});

</script>
</body>
</html>