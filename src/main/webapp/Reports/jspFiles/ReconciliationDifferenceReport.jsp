<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*, java.util.*, java.io.*, java.text.SimpleDateFormat" %>
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
String action = request.getParameter("action");

/* =========================
   🔹 DOWNLOAD REPORT (UNCHANGED)
   ========================= */
if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String asOnDate   = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        String oracleDateStr;

        if (asOnDate != null && !asOnDate.trim().isEmpty()) {
            java.util.Date utilDate =
                    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(utilDate)
                            .toUpperCase();
        } else {
            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(new java.util.Date())
                            .toUpperCase();
        }

        String reportDir = application.getRealPath("/Reports/");
        String jasperPath = reportDir + "ReconciliationDifferenceReport.jasper";

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        Map<String, Object> parameters = new HashMap<>();
        parameters.put("as_on_date", oracleDateStr);
        parameters.put("branch_code", branchCode);
        parameters.put("report_title", "RECONCILIATION DIFFERENCE REPORT");
        parameters.put("SUBREPORT_DIR", reportDir);

        String userId = (String) session.getAttribute("userId");

        parameters.put("user_id", userId);
        parameters.put("IMAGE_PATH", application.getRealPath("/images/UPSB MONO.png"));

        JasperPrint jp =
                JasperFillManager.fillReport(jasperReport, parameters, conn);
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();   // VERY IMPORTANT

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Reconciliation_Difference_Report.pdf\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();

            return;  // stop further JSP execution
        } else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Reconciliation_Difference_Report.xls\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }
        }catch (Exception e) {
        e.printStackTrace(new PrintWriter(out));
        return;
    } finally {
        if (conn != null) conn.close();
    }
}
%>

<!DOCTYPE html>
<html>
<head>
<title>Reconciliation Difference Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

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
    RECONCILIATION DIFFERENCE REPORT
</h1>

<form method="post" target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

    <!-- Branch -->
    <div class="parameter-group">
        <div class="parameter-label">Branch Code</div>

        <div class="input-box">
            <input type="text" id="branchCode" name="branch_code"
                   class="input-field">

            <button type="button" class="icon-btn"
                    onclick="openBranchLookup()">…</button>
        </div>
    </div>

    <div class="parameter-group">
        <div class="parameter-label">Description</div>
        <input type="text" id="branchName"
               class="input-field" readonly>
    </div>

    <!-- Date -->
    <div class="parameter-group">
        <div class="parameter-label">As On Date</div>
        <input type="date" name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>" required>
       
    </div>

</div>

<div class="format-section">
    <label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
    <label><input type="radio" name="reporttype" value="xls"> Excel</label>
</div>

<button type="submit" class="download-button">
    Generate Report
</button>

</form>

</div>

<!-- POPUP -->
<div id="branchModal" class="modal">
    <div class="modal-content">
        <button onclick="closeBranchLookup()" style="float:right;">✖</button>
        <div id="branchTable"></div>
    </div>
</div>

<script>

/* =========================
   🔹 CALL SERVLET (UPDATED)
   ========================= */
function openBranchLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")
        .then(res => res.text())
        .then(html => {
            document.getElementById("branchTable").innerHTML = html;
            document.getElementById("branchModal").style.display = "flex";
        });
}

function closeBranchLookup() {
    document.getElementById("branchModal").style.display = "none";
}

function selectBranch(code, name) {
    document.getElementById("branchCode").value = code;
    document.getElementById("branchName").value = name;
    closeBranchLookup();
}

/* =========================
   🔹 FETCH NAME FROM SERVLET
   ========================= */
document.getElementById("branchCode").addEventListener("blur", function() {

    let code = this.value;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + code)
        .then(res => res.text())
        .then(name => {
            document.getElementById("branchName").value = name || "Not Found";
        });
});

</script>

</body>
</html>
