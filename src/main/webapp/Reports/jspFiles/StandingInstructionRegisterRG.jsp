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
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    asOnDateUI = sdf.format(new java.util.Date());
}

/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("preview".equals(action) || "download".equals(action)) {
	String userId = "admin";


    String reporttype = request.getParameter("reporttype");
    Connection conn = null;
    ServletOutputStream outStream = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        /* ===== ORACLE DATE FORMAT ===== */
        String oracleDate;
try {
    SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
    oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();
} catch (Exception e) {
    oracleDate = "01-JAN-2025";  // fallback date
}

        conn = DBConnection.getConnection();

        /* ===== REPORT PATH (NO HARDCODED PATH) ===== */
        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String mainReportPath = reportsDir + "StandingInstructionRegisterRG.jasper";
        String subReportPath  = reportsDir + "subReportHeader.jasper";

        File mainFile = new File(mainReportPath);
        if (!mainFile.exists()) {
            throw new Exception("Main report not found: " + mainReportPath);
        }

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(mainFile);

        /* ===== PARAMETERS ===== */
        Map<String, Object> parameters = new HashMap<>();
        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDate);
        parameters.put("report_title", "Standing Instruction Register Report");
        parameters.put("SUBREPORT_DIR", reportsDir);
        parameters.put("IMAGE_PATH", application.getRealPath("/images/UPSB MONO.png"));


        /* ===== FILL REPORT ===== */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, parameters, conn);

        outStream = response.getOutputStream();

        /* ===== EXPORT TYPE ===== */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");

            // 🔥 Always inline for preview
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"StandingInstructionRegister_" 
                + branchCode + ".pdf\""
            );

            response.setHeader("X-Content-Type-Options", "nosniff");

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            return;
        
         } else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=StandingInstructionRegister_" 
                + branchCode + ".xls"
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, Boolean.FALSE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_COLUMNS, Boolean.TRUE);
            exporter.exportReport();
        }

        outStream.flush();
        return;

    } catch (Exception e) {
        e.printStackTrace();
        request.setAttribute("errorMessage",
                "Error generating report: " + e.getMessage());
    } finally {
        if (outStream != null) try { outStream.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>
<%
if (!"preview".equals(action) && !"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>Standing Instruction Register Report</title>

    <link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

</head>

<body>

<div class="report-container">

    <h1 class="report-title">STANDING INSTRUCTION REGISTER REPORT</h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/StandingInstructionRegisterRG.jsp"
          target="_blank"
          id="reportForm">

        <input type="hidden" name="action" value="preview"/>

        <div class="parameter-section">

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <input type="text"
                       name="branch_code"
                       class="input-field"
                       required
                       value="<%= branchCode %>">
            </div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date"
                       name="as_on_date"
                       class="input-field"
                       required
                       value="<%= asOnDateUI %>">
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
                class="download-button"
                id="previewBtn">
            Generate Report
        </button>

    </form>

</div>

<script>
document.addEventListener('DOMContentLoaded', function() {

    const form = document.getElementById('reportForm');
    const previewBtn = document.getElementById('previewBtn');
    const originalText = previewBtn.innerHTML;

    const dateField = document.querySelector('input[name="as_on_date"]');
    if (!dateField.value) {
        const today = new Date();
        const dd = String(today.getDate()).padStart(2, '0');
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const yyyy = today.getFullYear();
        dateField.value = `${yyyy}-${mm}-${dd}`;
    }

    form.addEventListener('submit', function(e) {

        const branchCode = document.querySelector('input[name="branch_code"]').value.trim();
        const asOnDate = document.querySelector('input[name="as_on_date"]').value.trim();

        if (!branchCode || !asOnDate) {
            alert('Please fill all required fields!');
            e.preventDefault();
            return false;
        }

        previewBtn.disabled = true;
        previewBtn.innerHTML = 'Generating Report...';
        previewBtn.style.opacity = '0.7';

        return true;
    });

    window.addEventListener('pageshow', function(event) {
        if (event.persisted) {
            previewBtn.disabled = false;
            previewBtn.innerHTML = originalText;
            previewBtn.style.opacity = '1';
        }
    });

});
</script>

</body>
</html>

<%
}
%>
