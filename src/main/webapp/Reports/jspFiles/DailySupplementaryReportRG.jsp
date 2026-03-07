<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Locale" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String asOnDate   = request.getParameter("as_on_date");

    Connection conn = null;
    Connection summaryConn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {

        /* =========================
           RESPONSE PREPARATION
           ========================= */
        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();
        summaryConn = DBConnection.getConnection();

        /* =========================
           DATE FORMAT
           ========================= */
        String oracleDate;

        if (asOnDate != null && !asOnDate.trim().isEmpty()) {

            java.util.Date utilDate =
                    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDate =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(utilDate)
                            .toUpperCase();

        } else {

            oracleDate =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(new java.util.Date())
                            .toUpperCase();
        }

        /* =========================
           LOAD COMPILED REPORT
           ========================= */

        String jasperPath =
        application.getRealPath("/Reports/DailySupplementaryReportRG.jasper");

        File jasperFile = new File(jasperPath);

        if (!jasperFile.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(jasperFile);

        /* =========================
           SUMMARY QUERY
           ========================= */

        String summarySql =
        "SELECT NVL(SUM(CREDIT_TOTAL),0) CASH_RECEIPT, " +
        "NVL(SUM(DEBIT_TOTAL),0) CASH_PAYMENT " +
        "FROM ( " +
        "SELECT (CREDIT_CASH+CREDIT_TRANSFER+CREDIT_CLEARING) CREDIT_TOTAL, " +
        "(DEBIT_CASH+DEBIT_TRANSFER+DEBIT_CLEARING) DEBIT_TOTAL " +
        "FROM ( " +
        "SELECT " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='CSCR' THEN DT.AMOUNT ELSE 0 END CREDIT_CASH, " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='TRCR' THEN DT.AMOUNT ELSE 0 END CREDIT_TRANSFER, " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='CLCR' THEN DT.AMOUNT ELSE 0 END CREDIT_CLEARING, " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='CSDR' THEN DT.AMOUNT ELSE 0 END DEBIT_CASH, " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='TRDR' THEN DT.AMOUNT ELSE 0 END DEBIT_TRANSFER, " +
        "CASE WHEN DT.TRANSACTIONINDICATOR_CODE='CLDR' THEN DT.AMOUNT ELSE 0 END DEBIT_CLEARING " +
        "FROM TRANSACTION.TRANSACTION_HT_VIEW DT " +
        "WHERE DT.BRANCH_CODE=? " +
        "AND DT.TXN_DATE=TO_DATE(?,'DD-MON-YYYY') " +
        "AND DT.TRANIDENTIFICATION_ID NOT IN (31,32) " +
        "AND DT.TRANSACTIONSTATUS='A'))";

        pstmt = summaryConn.prepareStatement(summarySql);
        pstmt.setString(1, branchCode);
        pstmt.setString(2, oracleDate);

        rs = pstmt.executeQuery();

        double cashReceipt = 0;
        double cashPayment = 0;

        if(rs.next()){
            cashReceipt = rs.getDouble("CASH_RECEIPT");
            cashPayment = rs.getDouble("CASH_PAYMENT");
        }

        rs.close();
        pstmt.close();
        summaryConn.close();

        /* =========================
           PARAMETERS
           ========================= */

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDate);
        parameters.put("report_title", "Daily Supplementary Report");

        parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        parameters.put("CASH_RECEIPT", cashReceipt);
        parameters.put("CASH_PAYMENT", cashPayment);
        parameters.put("NET_POSITION", cashReceipt - cashPayment);

        String userId = (String)session.getAttribute("user_id");

        if(userId == null || userId.trim().equals("")){
            userId = "admin";
        }

        parameters.put("user_id", userId);

        parameters.put("IMAGE_PATH",
        application.getRealPath("/images/UPSB MONO.png"));

        /* =========================
           FILL REPORT
           ========================= */

        JasperPrint jasperPrint =
        JasperFillManager.fillReport(jasperReport, parameters, conn);

        String timestamp =
        new SimpleDateFormat("yyyyMMdd_HHmmss").format(new java.util.Date());

        ServletOutputStream outputStream =
        response.getOutputStream();

        /* =========================
           EXPORT PDF
           ========================= */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
            "Content-Disposition",
            "inline; filename=\"DailySupplementaryReport_"
            + branchCode + "_" + timestamp + ".pdf\"");

            JasperExportManager.exportReportToPdfStream(
            jasperPrint, outputStream);
        }

        /* =========================
           EXPORT EXCEL
           ========================= */

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
            "Content-Disposition",
            "attachment; filename=DailySupplementaryReport_"
            + branchCode + "_" + timestamp + ".xls");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setExporterInput(
            new SimpleExporterInput(jasperPrint));

            exporter.setExporterOutput(
            new SimpleOutputStreamExporterOutput(outputStream));

            SimpleXlsReportConfiguration configuration =
            new SimpleXlsReportConfiguration();

            configuration.setOnePagePerSheet(false);
            configuration.setDetectCellType(true);
            configuration.setRemoveEmptySpaceBetweenRows(false);
            configuration.setRemoveEmptySpaceBetweenColumns(false);
            configuration.setWhitePageBackground(true);

            configuration.setSheetNames(
            new String[]{"Daily Supplementary Report"});

            exporter.setConfiguration(configuration);
            exporter.exportReport();
        }

        outputStream.flush();
        outputStream.close();
        return;

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html;charset=UTF-8");

        out.println("<h2 style='color:red'>Error Generating Report</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");

        return;

    } finally {

        try {
            if(rs!=null) rs.close();
            if(pstmt!=null) pstmt.close();
            if(summaryConn!=null) summaryConn.close();
            if(conn!=null) conn.close();
        } catch(Exception ex){}
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Daily Supplementary Report</title>

    <link rel="stylesheet"
          href="<%=request.getContextPath()%>/Reports/common-report.css?v=10">
</head>

<body>

<div class="report-container">
    <h1 class="report-title">
        Daily Supplementary Report
    </h1>

    <form id="reportForm"
      method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DailySupplementaryReportRG.jsp"
      target="_blank"
      autocomplete="off">


        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">
            <div class="parameter-group">
                <div class="parameter-label required">Branch Code</div>
                <input type="text" 
                       name="branch_code" 
                       id="branch_code"
                       class="input-field" 
                       value="0002" 
                       required
                       placeholder="Enter branch code (e.g., 0002)">
            </div>

            <div class="parameter-group">
                <div class="parameter-label required">As On Date</div>
                <input type="date" 
       name="as_on_date" 
       id="as_on_date"
       class="input-field"
       value="2025-12-01"
       required>
            </div>
        </div>

        <div class="format-section">
            <div class="parameter-label required">Report Type</div>

            <div class="format-options">
                <div class="format-option">
                    <input type="radio" name="reporttype" value="pdf" checked id="pdfRadio">
                    <label for="pdfRadio">PDF</label>
                </div>

                <div class="format-option">
                    <input type="radio" name="reporttype" value="xls" id="excelRadio">
                    <label for="excelRadio">Excel</label>
                </div>
            </div>
        </div>

        <button type="submit" class="download-button" id="submitBtn">
            Generate Report
        </button>

    </form>
</div>



<script>
    
    // Form validation and submission handling
    document.getElementById('reportForm').addEventListener('submit', function(e) {
        var branchCode = document.getElementById('branch_code').value;
        var asOnDate = document.getElementById('as_on_date').value;
        
        if (!branchCode || !asOnDate) {
            alert('Please fill all required fields');
            e.preventDefault();
            return false;
        }
        
        // Show loading overlay
        document.getElementById('loadingOverlay').style.display = 'flex';
        
        // Disable submit button
        var submitBtn = document.getElementById('submitBtn');
        submitBtn.disabled = true;
        submitBtn.innerHTML = 'Generating...';
        
        return true;
    });
    
    // Hide loading when page is shown (back button)
    window.addEventListener('pageshow', function(event) {
        document.getElementById('loadingOverlay').style.display = 'none';
        var submitBtn = document.getElementById('submitBtn');
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Generate Report';
    });
</script>

</body>
</html>