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
String asOnDateUI = request.getParameter("as_on_date");

if (branchCode == null) branchCode = "0002";
if (asOnDateUI == null) {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    asOnDateUI = sdf.format(new java.util.Date());
}

if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");
    String userId = "admin";

    Connection conn = null;

    try {

        /* =========================
           RESPONSE SETUP
           ========================= */
        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* =========================
           DATE FORMAT FOR ORACLE
           ========================= */
        String oracleDate;
        try {
            SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
            oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();
        } catch (Exception e) {
            oracleDate = asOnDateUI;
        }

        /* =========================
           REPORT PATHS
           ========================= */
        String reportsDir = application.getRealPath("/Reports") + File.separator;

        String mainReportPath = reportsDir + "cashreciptscrollrg.jrxml";
        String subReportPath  = reportsDir + "subReportHeader.jrxml";

        JasperReport jasperReport = JasperCompileManager.compileReport(mainReportPath);
        JasperReport subJasperReport = JasperCompileManager.compileReport(subReportPath);

        /* =========================
           PARAMETERS
           ========================= */
        Map<String, Object> params = new HashMap<>();
        params.put("branch_code", branchCode);
        params.put("user_id", userId);
        params.put("as_on_date", oracleDate);
        params.put("report_title", "Cash Receipt Scroll Report");
        params.put("SUBREPORT_DIR", reportsDir);
        params.put("subReportHeader.jasper", subJasperReport);

        /* =========================
           FILL REPORT
           ========================= */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

        ServletOutputStream sos = response.getOutputStream();

        /* =========================
           EXPORT
           ========================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"CashReceiptScroll.pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;

        } else if ("xls".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"CashReceiptScroll.xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.exportReport();

            sos.flush();
            return;
        }

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Cash Receipt Scroll: " + e.getMessage());
        response.sendRedirect("cashreciptscrollRG.jsp?error=true");
        return;
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Cash Receipt Scroll Report</title>
    <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">
</head>

<body>

<div class="report-container">

    <h1 class="report-title">CASH RECEIPT SCROLL REPORT</h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/cashreciptscrollRG.jsp"
          target="_blank"
          id="reportForm">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">
            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text" name="branch_code"
                       class="input-field"
                       value="<%= branchCode %>" required>
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" name="as_on_date"
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

        <button type="submit"
                class="download-button"
                id="downloadBtn">
            Generate Report
        </button>

    </form>
</div>

</body>
</html>
