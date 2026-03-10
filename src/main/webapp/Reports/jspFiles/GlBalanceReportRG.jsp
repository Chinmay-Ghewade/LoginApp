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

String branchCode = request.getParameter("branch_code");
String asOnDateUI = request.getParameter("as_on_date");

/* Default Branch */
if (branchCode == null || branchCode.trim().isEmpty()) {
    branchCode = "0002";
}

/* Default Date = 03/29/2025 (Editable) */
if (asOnDateUI == null || asOnDateUI.trim().isEmpty()) {
    asOnDateUI = "2025-03-29";   // March 29, 2025
}

/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("download".equals(action)) {

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* Convert Date for Oracle (DD-MON-YYYY) */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String oracleDate =
                outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();

        /* Load Jasper File */
        String jasperPath =
                application.getRealPath("/Reports/GlBalanceReportRG.jasper");

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);

        /* Session User */
        String userId = (String) session.getAttribute("user_id");
        if (userId == null) userId = "admin";

        params.put("user_id", userId);
        params.put("report_title", "DAILY GL BALANCE REPORT");

        params.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        params.put("IMAGE_PATH",
                application.getRealPath("/images/logo.png"));

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        /* ================= PDF ================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"GlBalanceReportRG.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        /* ================= EXCEL ================= */
        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"GlBalanceReportRG.xls\"");

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
                "Error generating GL Balance Report: " + e.getMessage());
        response.sendRedirect("GlBalanceReportRG.jsp");
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
    <title>Daily GL Balance Report</title>

   <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

</head>

<body>

<div class="report-container">

    <h1 class="report-title">
        DAILY GL BALANCE REPORT
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
          action="GlBalanceReportRG.jsp"
          target="_blank">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text" 
                       name="branch_code"
                       class="input-field"
                       value="<%=branchCode%>" 
                       required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" 
                       name="as_on_date"
                       class="input-field"
                       value="<%=asOnDateUI%>" 
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