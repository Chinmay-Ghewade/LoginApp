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

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String branchCode  = request.getParameter("branch_code");
    String accountCode = request.getParameter("account_code");
    String asOnDate    = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();

        /* =========================
           DATE FORMAT
           ========================= */

        String oracleDateStr;

        if (asOnDate != null && !asOnDate.trim().isEmpty()) {

            java.util.Date utilDate =
            new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDateStr =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(utilDate)
            .toUpperCase();
        }
        else {

            oracleDateStr =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new java.util.Date())
            .toUpperCase();
        }

        /* =========================
           LOAD REPORT
           ========================= */

        String jasperPath =
        application.getRealPath("/Reports/TDInterestProjectionRG.jasper");

        File jasperFile = new File(jasperPath);

        if (!jasperFile.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(jasperFile);

        /* =========================
           PARAMETERS
           ========================= */

        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("account_code", accountCode);
        parameters.put("as_on_date", oracleDateStr);
        parameters.put("report_title", "TD INTEREST PROJECTION REPORT");

        String userId = (String) session.getAttribute("user_id");

        if(userId == null || userId.trim().equals("")){
            userId = "admin";
        }

        parameters.put("user_id", userId);

        parameters.put("IMAGE_PATH",
        application.getRealPath("/images/UPSB MONO.png"));

        parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        /* =========================
           FILL REPORT
           ========================= */

        JasperPrint jasperPrint =
        JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* =========================
           EXPORT SECTION
           ========================= */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
            "Content-Disposition",
            "inline; filename=\"TD_Interest_Projection_Report.pdf\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
            "Content-Disposition",
            "attachment; filename=\"TD_Interest_Projection_Report.xls\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html");

        out.println("<h2 style='color:red'>Error Generating Report</h2>");
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

<title>TD Interest Projection Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

</head>

<body>

<div class="report-container">

<h1 class="report-title">
TD INTEREST PROJECTION REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/TDInterestProjectionRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<input type="text"
name="branch_code"
class="input-field"
value="0003"
required>
</div>

<div class="parameter-group">
<div class="parameter-label">Account Code</div>

<input type="text"
name="account_code"
class="input-field"
required>
</div>

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
class="input-field"
value="<%=new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())%>"
required>
</div>

</div>

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
name="reporttype"
value="pdf"
checked> PDF
</div>

<div class="format-option">
<input type="radio"
name="reporttype"
value="xls"> Excel
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