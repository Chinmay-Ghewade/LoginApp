<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="64kb" autoFlush="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* ==============================
   DEFAULT VALUES (Editable)
   ============================== */
String defaultBranch = request.getParameter("branch_code") != null
        ? request.getParameter("branch_code") : "0002";

String defaultAccount = request.getParameter("account_code") != null
        ? request.getParameter("account_code") : "00024020016659";

String defaultFromDate = request.getParameter("from_date") != null
        ? request.getParameter("from_date") : "2015-04-18";

String defaultToDate = request.getParameter("to_date") != null
        ? request.getParameter("to_date") : "2016-06-17";


String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");

    String branchCode  = defaultBranch.trim();
    String accountCode = defaultAccount.trim();
    String fromDate    = defaultFromDate;
    String toDate      = defaultToDate;

    Connection conn = null;

    try {

        if (branchCode.isEmpty() || accountCode.isEmpty()) {
            throw new Exception("Branch Code and Account Code are required.");
        }

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();

        String jasperPath =
                application.getRealPath("/Reports/SBInterestCertificate.jasper");

        File jasperFile = new File(jasperPath);

        if (!jasperFile.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(jasperFile);

        /* ==========================
           PARAMETERS
           ========================== */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("account_code", accountCode);
        parameters.put("from_date", fromDate);
        parameters.put("to_date", toDate);

        // SESSION DATE
        String sessionDate = (String) session.getAttribute("SESSION_DATE");

        if (sessionDate == null || sessionDate.trim().isEmpty()) {
            sessionDate = new SimpleDateFormat("dd-MM-yyyy")
                                .format(new java.util.Date());
        }

        parameters.put("session_date", sessionDate);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* ==========================
           PDF EXPORT
           ========================== */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"SB_Interest_Certificate.pdf\""
            );

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream outStream = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);
            outStream.flush();
            outStream.close();
            return;
        }

        /* ==========================
           EXCEL EXPORT
           ========================== */
        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"SB_Interest_Certificate.xls\""
            );

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(
                    JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(
                    JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
            return;
        }

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html");
        out.println("<h2 style='color:red'>Error Generating Certificate</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");
        return;

    } finally {

        if (conn != null) {
            try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
<title>Saving Bank Interest Certificate</title>
<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

</head>

<body>

<div class="report-container">

<h1 class="report-title">
    SAVING BANK INTEREST CERTIFICATE
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/SBInterestCertificate.jsp"
      target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>
<input type="text" name="branch_code"
       class="input-field"
       value="<%= defaultBranch %>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">Account Code</div>
<input type="text" name="account_code"
       class="input-field"
       value="<%= defaultAccount %>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date" name="from_date"
       class="input-field"
       value="<%= defaultFromDate %>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date" name="to_date"
       class="input-field"
       value="<%= defaultToDate %>" required>
</div>

</div>

<div class="format-section">
<div class="parameter-label">Report Type</div>

<div class="format-options">
<div class="format-option">
<input type="radio" name="reporttype"
       value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype"
       value="xls"> Excel
</div>
</div>
</div>

<button type="submit" class="download-button">
Generate Certificate
</button>

</form>

</div>
</body>
</html>