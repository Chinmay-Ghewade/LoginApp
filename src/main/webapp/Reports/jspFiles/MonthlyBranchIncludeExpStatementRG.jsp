<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

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

if (branchCode == null) branchCode = "0002";
if (asOnDateUI == null) {
    asOnDateUI = "2025-03-29";
}

/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");
    Connection conn = null;
    ServletOutputStream sos = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        /* DATE FORMAT FOR ORACLE */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
        String oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();

        conn = DBConnection.getConnection();

        /* REPORT PATH */
        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String mainReportPath = reportsDir + "MonthlyBranchIncludeExpStatementRG.jasper";

        File reportFile = new File(mainReportPath);
        if (!reportFile.exists()) {
            throw new Exception("Report file not found: " + mainReportPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(reportFile);

        /* PARAMETERS */
        Map<String, Object> params = new HashMap<>();
params.put("branch_code", branchCode);
params.put("as_on_date", oracleDate);
params.put("report_title", "Monthly Branch Include Exp Statement");

/* SUBREPORT DIRECTORY */
params.put("SUBREPORT_DIR", reportsDir);

        /* FILL REPORT */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

        sos = response.getOutputStream();

        /* EXPORT */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"MonthlyBranchIncludeExpStatement.pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);

        } else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"MonthlyBranchIncludeExpStatement.xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, Boolean.FALSE);

            exporter.exportReport();
        }

        sos.flush();
        return;

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Monthly Branch Include Exp Statement: " + e.getMessage());
        response.sendRedirect("MonthlyBranchIncludeExpStatementRG.jsp?error=true");
        return;

    } finally {
        if (sos != null) try { sos.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<%
/* =====================================================
   UI SECTION
===================================================== */
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>Monthly Branch Include Exp Statement</title>
    <link rel="stylesheet"
          href="<%=request.getContextPath()%>/Reports/common-report.css">
</head>

<body>

<div class="report-container">

    <%
        String errorMessage = (String) session.getAttribute("errorMessage");
        if (errorMessage != null) {
    %>
        <div class="error-message">
            <%= errorMessage %>
        </div>
    <%
            session.removeAttribute("errorMessage");
        }
    %>

    <h1 class="report-title">MONTHLY BRANCH INCLUDE EXP STATEMENT</h1>

    <form method="post"
          action="<%=request.getRequestURI()%>"
          target="_blank"
          id="reportForm">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">
            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text"
                       name="branch_code"
                       class="input-field"
                       value="<%= branchCode %>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date"
                       name="as_on_date"
                       class="input-field"
                       value="<%= asOnDateUI %>" required>
            </div>
        </div>

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

</body>
</html>

<%
}
%>
