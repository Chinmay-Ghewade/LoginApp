<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="db.DBConnection" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>


<%
String action = request.getParameter("action");
String branchCode = request.getParameter("branch_code");
String asOnDateUI = request.getParameter("as_on_date");

if (branchCode == null) branchCode = "0002";
if (asOnDateUI == null) {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    asOnDateUI = sdf.format(new java.util.Date());
}

/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");
    String userId = "admin";

    Connection conn = null;
    ServletOutputStream sos = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        /* DATE FORMAT */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
        String oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        String reportsDir = application.getRealPath("/Reports") + File.separator;

        String mainReportPath = reportsDir + "cashpaymentscrollRG.jasper";
        String subReportPath  = reportsDir + "subReportHeader.jasper";

        System.out.println("Main Report Path: " + mainReportPath);
        System.out.println("File Exists? " + new File(mainReportPath).exists());

        JasperReport mainReport =
                (JasperReport) JRLoader.loadObject(new File(mainReportPath));

        JasperReport subReport =
                (JasperReport) JRLoader.loadObject(new File(subReportPath));

        Map<String, Object> params = new HashMap<>();
        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("user_id", userId);
        params.put("report_title", "Cash Payment Scroll Report");
        params.put("SUBREPORT_DIR", reportsDir);
        params.put("subReportHeader.jasper", subReport);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(mainReport, params, conn);

        sos = response.getOutputStream();

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"CashPaymentScroll.pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);

        } else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"CashPaymentScroll.xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.exportReport();
        }

        sos.flush();
        return;

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Cash Payment Scroll: " + e.getMessage());
        response.sendRedirect("cashpaymentscrollRG.jsp?error=true");
        return;

    } finally {
        if (sos != null) try { sos.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<%
/* =====================================================
   UI SECTION (ONLY IF NOT DOWNLOAD)
===================================================== */
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>Cash Payment Scroll Report</title>
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

    <h1 class="report-title">CASH PAYMENT SCROLL REPORT</h1>

    <form method="post"
          action="<%=request.getRequestURI()%>"
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
