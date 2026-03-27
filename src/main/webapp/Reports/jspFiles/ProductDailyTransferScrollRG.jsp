<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>

<%@ page import="db.DBConnection" %>

<% 
/* SESSION DATE */
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

/* SESSION BRANCH */
String branchCodeSession =
    (String) session.getAttribute("branchCode");

String branchDescSession =
    (String) session.getAttribute("branchDesc");

if(branchCodeSession == null) branchCodeSession = "";
if(branchDescSession == null) branchDescSession = "";
%>

<%
String action = request.getParameter("action");

String branchCode = request.getParameter("branch_code");
String txnDateUI = request.getParameter("txn_date");
String productCode = request.getParameter("product_code");
String singleAll = request.getParameter("single_all");

if (branchCode == null) branchCode = "";

if (txnDateUI == null || txnDateUI.trim().isEmpty()) {
    txnDateUI = "";   // ✅ Fixed date here
}


if ("download".equals(action)) {

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* =========================
           DATE FORMAT FOR ORACLE
        ========================= */
        SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
        String oracleDate = outFmt.format(inFmt.parse(txnDateUI)).toUpperCase();

        /* =========================
           CONDITION FOR SINGLE/ALL
        ========================= */
        		String condition = "";

        if ("S".equals(singleAll) && productCode != null && !productCode.trim().isEmpty()) {

            condition =
                " AND ( " +
                " (SUBSTR(T.DR_ACCOUNT_CODE,5,3) = ?) " +
                " OR " +
                " (SUBSTR(T.CR_ACCOUNT_CODE,5,3) = ?) " +
                " ) ";
        }

        /* =========================
           MAIN SQL
        ========================= */
        String sql =
            "SELECT T.*, " +

            " (CASE " +
            "    WHEN (T.DR_ACCOUNT_CODE IS NOT NULL AND SUBSTR(T.DR_ACCOUNT_CODE,5,3)='000') " +
            "         THEN T.DR_ACCOUNT_CODE " +
            "    WHEN (T.CR_ACCOUNT_CODE IS NOT NULL AND SUBSTR(T.CR_ACCOUNT_CODE,5,3)='000') " +
            "         THEN T.CR_ACCOUNT_CODE " +
            "    WHEN T.DR_ACCOUNT_CODE IS NOT NULL " +
            "         THEN SUBSTR(T.DR_ACCOUNT_CODE,5,3) " +
            "    ELSE SUBSTR(T.CR_ACCOUNT_CODE,5,3) " +
            "  END) AS PRODUCT_CODE, " +

            " (SELECT SUM(DR_AMOUNT) FROM TEMP.TRANSFERSCROLL_PRODUCT X " +
            "   WHERE X.BRANCH_CODE = T.BRANCH_CODE) AS DR_TOTAL, " +

            " (SELECT SUM(CR_AMOUNT) FROM TEMP.TRANSFERSCROLL_PRODUCT X " +
            "   WHERE X.BRANCH_CODE = T.BRANCH_CODE) AS CR_TOTAL, " +

            " (SELECT COUNT(*) FROM TEMP.TRANSFERSCROLL_PRODUCT X " +
            "   WHERE X.BRANCH_CODE = T.BRANCH_CODE AND X.DR_AMOUNT IS NOT NULL) AS DR_COUNT, " +

            " (SELECT COUNT(*) FROM TEMP.TRANSFERSCROLL_PRODUCT X " +
            "   WHERE X.BRANCH_CODE = T.BRANCH_CODE AND X.CR_AMOUNT IS NOT NULL) AS CR_COUNT " +

            "FROM TEMP.TRANSFERSCROLL_PRODUCT T " +
            "WHERE T.BRANCH_CODE = ? " +
            condition +

            " ORDER BY " +
            " (CASE " +
            "    WHEN (T.DR_ACCOUNT_CODE IS NOT NULL AND SUBSTR(T.DR_ACCOUNT_CODE,5,3)='000') " +
            "         THEN T.DR_ACCOUNT_CODE " +
            "    WHEN (T.CR_ACCOUNT_CODE IS NOT NULL AND SUBSTR(T.CR_ACCOUNT_CODE,5,3)='000') " +
            "         THEN T.CR_ACCOUNT_CODE " +
            "    WHEN T.DR_ACCOUNT_CODE IS NOT NULL " +
            "         THEN SUBSTR(T.DR_ACCOUNT_CODE,5,3) " +
            "    ELSE SUBSTR(T.CR_ACCOUNT_CODE,5,3) " +
            "  END), T.SR_NO";

        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, branchCode);

        if ("S".equals(singleAll) && productCode != null && !productCode.trim().isEmpty()) {
            pstmt.setString(2, productCode);
            pstmt.setString(3, productCode);
        }

        rs = pstmt.executeQuery();

        /* =========================
           LOAD JASPER REPORT
        ========================= */
        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String reportPath = reportsDir + "ProductDailyTransferScrollRG.jrxml";

        JasperReport jasperReport = JasperCompileManager.compileReport(reportPath);

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);        // ✅ must match JRXML
        params.put("report_title", "PRODUCT DAILY TRANSFER SCROLL"); 
        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);

        params.put("SUBREPORT_DIR", reportsDir);
        params.put("REPORT_CONNECTION", conn);

        JRResultSetDataSource jrDataSource =
                new JRResultSetDataSource(rs);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, jrDataSource);

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"ProductDailyTransferScroll.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"ProductDailyTransferScroll.xls\"");

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
                "Error generating Product Daily Transfer Scroll: " + e.getMessage());
        response.sendRedirect("ProductDailyTransferScrollRG.jsp");
        return;
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<% if (!"download".equals(action)) { %>

<!DOCTYPE html>
<html>
<head>
    <title>Product Daily Transfer Scroll</title>

    <!-- SAME CSS LIKE TFORM -->
    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
    cursor:not-allowed;
}

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

    <h1 class="report-title">PRODUCT DAILY TRANSFER SCROLL</h1>

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
          action="<%=request.getContextPath()%>/Reports/jspFiles/ProductDailyTransferScrollRG.jsp"
          target="_blank">

        <input type="hidden" name="action" value="download"/>

       <div class="parameter-section">

    <!-- BRANCH -->
    <div class="parameter-group">

        <div class="parameter-label">Branch Code</div>

        <div class="input-box">
            <input type="text"
                   name="branch_code"
                   id="branch_code"
                   class="input-field"
                   value="<%=branchCodeSession%>"
                   required>

            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('branch')">…</button>
        </div>

    </div>

    <div class="parameter-group">

        <div class="parameter-label">Branch Description</div>

        <input type="text"
               name="branchName"
               id="branchName"
               class="input-field"
               value="<%=branchDescSession%>"
               readonly>

    </div>

    <!-- DATE -->
    <div class="parameter-group">

        <div class="parameter-label">Transaction Date</div>

        <input type="date"
               name="txn_date"
               class="input-field"
               value="<%=sessionDate%>"
               required>

    </div>

    <!-- PRODUCT -->
    <div class="parameter-group">

        <div class="parameter-label">Product Code</div>

        <div class="input-box">
            <input type="text"
                   name="product_code"
                   id="product_code"
                   class="input-field">

            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('product')">…</button>
        </div>

        <div class="radio-container">

            <label>
                <input type="radio"
                       name="single_all"
                       value="S"
                       checked
                       onclick="toggleProduct()">
                Single
            </label>

            <label>
                <input type="radio"
                       name="single_all"
                       value="A"
                       onclick="toggleProduct()">
                All
            </label>

        </div>

    </div>

</div>

<!-- REPORT TYPE -->
<div class="format-section">

    <div class="parameter-label">Report Type</div>

    <label>
        <input type="radio" name="reporttype" value="pdf" checked>
        PDF
    </label>

    <label>
        <input type="radio" name="reporttype" value="xls">
        Excel
    </label>

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
function toggleProduct() {
    var single = document.querySelector('input[name="single_all"][value="S"]').checked;
    var productField = document.querySelector('input[name="product_code"]');

    if (single) {
        productField.disabled = false;
        productField.readOnly = false;
    } else {
        productField.value = "";
        productField.disabled = true;
        productField.readOnly = true;
    }
}

window.onload = function() {
    toggleProduct();
};
</script>

</body>
</html>

<% } %>

