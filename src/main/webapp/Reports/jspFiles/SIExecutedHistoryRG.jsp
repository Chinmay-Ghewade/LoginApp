<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="db.DBConnection" %>

<%
/* ==========================================
   GET PARAMETERS + DEFAULT VALUES
========================================== */

String action = request.getParameter("action");

String branchCode = request.getParameter("branch_code");
String asOnDate = request.getParameter("as_on_date");

/* Default values for first load */
if (branchCode == null || branchCode.trim().isEmpty()) {
    branchCode = "0007";
}

if (asOnDate == null || asOnDate.trim().isEmpty()) {
    asOnDate = "2014-09-18";   // yyyy-MM-dd (HTML format)
}

/* ==========================================
   DOWNLOAD SECTION
========================================== */

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");

    Connection conn = null;
    ServletOutputStream outStream = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();

        /* DATE FORMAT FOR REPORT */
        SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outputFormat = new SimpleDateFormat("ddMMMyyyy");
        java.util.Date date = inputFormat.parse(asOnDate);
        String formattedDate = outputFormat.format(date).toUpperCase();

        /* REPORT PATH */
        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String jasperPath = reportsDir + "SIExecutedHistoryRG.jasper";

        File jasperFile = new File(jasperPath);
        if (!jasperFile.exists()) {
            throw new Exception("Report not found: " + jasperPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(jasperFile);

        /* PARAMETERS */
        Map<String, Object> parameters = new HashMap<>();
        parameters.put("branch_code", branchCode);
        parameters.put("report_title", "SI Executed History Report");
        parameters.put("as_on_date", formattedDate);
        parameters.put("SUBREPORT_DIR", reportsDir);

        /* FILL REPORT */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, parameters, conn);

        outStream = response.getOutputStream();

        /* EXPORT */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"SIExecutedHistory_" 
                + branchCode + "_" + formattedDate + ".pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

        } else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"SIExecutedHistory_" 
                + branchCode + "_" + formattedDate + ".xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.exportReport();
        }

        outStream.flush();
        return;

    } catch (Exception e) {
        session.setAttribute("errorMessage",
                "Error generating SI Executed History Report: " + e.getMessage());
        response.sendRedirect("SIExecutedHistoryRG.jsp?error=true");
        return;

    } finally {
        if (outStream != null) try { outStream.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<%
/* ==========================================
   UI SECTION
========================================== */
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>SI Executed History Report</title>

    <!-- Common Report CSS -->
    <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

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

    <h1 class="report-title">SI EXECUTED HISTORY REPORT</h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/SIExecutedHistoryRG.jsp"
          target="_blank"
          id="reportForm">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text"
                       name="branch_code"
                       class="input-field"
                       value="<%= branchCode %>"
                       required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date"
                       name="as_on_date"
                       class="input-field"
                       value="<%= asOnDate %>"
                       required>
            </div>

        </div>

        <div class="format-section">
            <div class="parameter-label">Report Type</div>

            <div class="format-options">
                <div class="format-option">
                    <input type="radio" name="reporttype" value="pdf" checked>
                    <label>PDF</label>
                </div>

                <div class="format-option">
                    <input type="radio" name="reporttype" value="xls">
                    <label>Excel</label>
                </div>
            </div>
        </div>

        <button type="submit"
                class="download-button">
            Generate Report
        </button>

    </form>

</div>

</body>
</html>

<%
}
%>
