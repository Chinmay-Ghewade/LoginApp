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
String action = request.getParameter("action");

String branchCode  = request.getParameter("branch_code");
String asOnDateUI  = request.getParameter("as_on_date");
String productCode = request.getParameter("product_code");

if (branchCode == null) branchCode = "0002";

if (asOnDateUI == null || asOnDateUI.trim().isEmpty()) {
    asOnDateUI = new SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
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

        /* Optional parameters */
        String userId = (String) session.getAttribute("user_id");
        if (userId == null) userId = "admin";
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

    <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

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
                <input type="text" name="branch_code"
                       class="input-field"
                       value="<%=branchCode%>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" name="as_on_date"
                       class="input-field"
                       value="<%=asOnDateUI%>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">Product Code</div>
                <input type="text" name="product_code"
                       class="input-field"
                       placeholder="Enter product code"
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

</body>
</html>

<% } %>