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
String action = request.getParameter("action");

String branchCode = request.getParameter("branch_code");
String txnDateUI = request.getParameter("txn_date");
String productCode = request.getParameter("product_code");
String singleAll = request.getParameter("single_all");

if (branchCode == null) branchCode = "0002";

if (txnDateUI == null || txnDateUI.trim().isEmpty()) {
    txnDateUI = "2025-03-29";   // ✅ Fixed date here
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
        String userId = (String) session.getAttribute("user_id");
        if (userId == null || userId.trim().isEmpty()) {
            userId = "admin";
        }
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
    <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

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

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text" name="branch_code"
                       class="input-field"
                       value="<%=branchCode%>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">Transaction Date</div>
                <input type="date" name="txn_date"
                       class="input-field"
                       value="<%=txnDateUI%>" required>
            </div>

           <div class="parameter-group">

    <table style="width:400px;">
        <tr>
            <td style="width:120px;">Select</td>
            <td style="text-align:center;">Single</td>
            <td style="text-align:center;">All</td>
        </tr>

        <tr>
            <td></td>
            <td style="text-align:center;">
                <input type="radio" name="single_all" value="S"
                       onclick="toggleProduct()"
                       <%= "S".equals(singleAll) || singleAll == null ? "checked" : "" %>>
            </td>

            <td style="text-align:center;">
                <input type="radio" name="single_all" value="A"
                       onclick="toggleProduct()"
                       <%= "A".equals(singleAll) ? "checked" : "" %>>
            </td>
        </tr>
    </table>

</div>


            <div class="parameter-group">
                <div class="parameter-label">Product Code</div>
                <input type="text" name="product_code"
                       class="input-field"
                       placeholder="Enter product code">
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

