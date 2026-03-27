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
%>

<%
String action = request.getParameter("action");

String branchCode  = request.getParameter("branch_code");
String asOnDateUI  = request.getParameter("as_on_date");
String productCode = request.getParameter("product_code");

if (branchCode == null) branchCode = "";

if (asOnDateUI == null || asOnDateUI.trim().isEmpty()) {
    asOnDateUI = sessionDate;
}
/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("download".equals(action)) {

    Connection conn = null;

    try {

        /* Product Code Mandatory */
        if (productCode == null || productCode.trim().isEmpty()) {
            session.setAttribute("errorMessage",
                "Please enter Product Code.");
            response.sendRedirect("LedgerBalanceWithNames.jsp");
            return;
        }

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* Date Format */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String oracleDate =
                outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();

        /* Load Jasper */
        String jasperPath =
                application.getRealPath("/Reports/LedgerBalanceWithNames.jasper");

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("product_code", productCode.trim());


        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);


        params.put("report_title", "PRODUCT WISE LEDGER BALANCE");

        params.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        params.put("IMAGE_PATH",
                application.getRealPath("/images/UPSB MONO.png"));

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"LedgerBalanceWithNames.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"LedgerBalanceWithNames.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, Boolean.FALSE);

            exporter.exportReport();
            sos.flush();
            return;
        }

    } catch (Exception e) {

        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Ledger Balance Report: " + e.getMessage());
        response.sendRedirect("LedgerBalanceWithNames.jsp");
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
    <title>Ledger Balance With Names</title>

    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
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
        PRODUCT WISE LEDGER BALANCE
    </h1>

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
          action="LedgerBalanceWithNames.jsp"
          target="_blank">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <div class="input-box">
    <input type="text"
           name="branch_code"
           id="branch_code"
           class="input-field"
           value="<%=branchCode%>"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openBranchLookup()">…</button>
</div>
            </div>
            
            <div class="parameter-group">
    <div class="parameter-label">Branch Description</div>
    <input type="text"
           id="branchName"
           class="input-field"
           readonly>
</div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" name="as_on_date"
                       class="input-field"
                       value="<%=asOnDateUI%>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">Product Code</div>
                <div class="input-box">
    <input type="text"
           name="product_code"
           id="product_code"
           class="input-field"
           placeholder="Enter product code"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openProductLookup()">…</button>
</div>
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

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

// 🔹 Branch Popup
function openBranchLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// 🔹 Product Popup
function openProductLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=product")
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// 🔹 Close
function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}

// 🔹 Select Branch (WITH DESCRIPTION)
function selectBranch(code, name) {
    document.getElementById("branch_code").value = code;
    document.getElementById("branchName").value = name;
    closeLookup();
}

// 🔹 Select Product (ONLY CODE)
function selectProduct(code, name, type) {
    document.getElementById("product_code").value = code;
    closeLookup();
}

/* 🔹 AUTO FETCH BRANCH DESCRIPTION */
document.getElementById("branch_code").addEventListener("blur", function() {

    let code = this.value;

    if (!code) return;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + code)
        .then(res => res.text())
        .then(name => {
            document.getElementById("branchName").value = name || "Not Found";
        });
});

</script>

</body>
</html>

<% } %>