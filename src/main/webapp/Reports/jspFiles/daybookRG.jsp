<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.math.BigDecimal" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
    String action = request.getParameter("action");

    if ("download".equals(action)) {

        String reporttype = request.getParameter("reporttype");
        String bankCode   = request.getParameter("bank_code");
        String branchCode = request.getParameter("branch_code");
        String asOnDate   = request.getParameter("as_on_date");

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

            /* =========================
               DATE HANDLING (FIXED FOR ORACLE)
               ========================= */
            java.sql.Date sqlAsOnDate;
            java.sql.Date sqlSessionDate;
            
            // Convert to Oracle DATE string format (DD-MMM-YYYY)
            String oracleDateStr;
            
            if (asOnDate != null && !asOnDate.trim().isEmpty()) {
                // Parse from yyyy-MM-dd format (HTML date input)
                java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);
                sqlAsOnDate = new java.sql.Date(utilDate.getTime());
                
                // Format for Oracle
                oracleDateStr = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                        .format(utilDate)
                        .toUpperCase();
            } else {
                // Default date
                java.util.Date utilDate = 
                        new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                                .parse("29-MAR-2025");
                sqlAsOnDate = new java.sql.Date(utilDate.getTime());
                oracleDateStr = "29-MAR-2025";
            }

            sqlSessionDate = sqlAsOnDate; // SAME DATE

            /* =========================
               DEFAULT VALUES
               ========================= */
            bankCode   = (bankCode != null && !bankCode.trim().isEmpty()) ? bankCode : "0100";
            branchCode = (branchCode != null && !branchCode.trim().isEmpty()) ? branchCode : "0002";

            /* =========================
               TALLY MESSAGE (STRING ONLY)
               ========================= */
            String tallyMessage =
                    checkTransferClearingTally(conn, oracleDateStr, bankCode, branchCode);

            request.setAttribute("tallyMessage", tallyMessage);

            /* =========================
               COMPILE MAIN REPORT
               ========================= */
            String jrxmlPath = application.getRealPath("/Reports/daybookRG.jrxml");
            JasperReport jasperReport =
                    JasperCompileManager.compileReport(jrxmlPath);

            /* =========================
               PARAMETERS (CRITICAL - UPDATED FOR ORACLE)
               ========================= */
            Map<String, Object> parameters = new HashMap<>();
            parameters.put("bank_code", bankCode);
            parameters.put("branch_code", branchCode);
            parameters.put("as_on_date", oracleDateStr);        // Use Oracle date string
            parameters.put("session_date", oracleDateStr);      // Use Oracle date string
            parameters.put("SUBREPORT_DIR", application.getRealPath("/Reports/"));
            parameters.put("TALLY_MESSAGE", tallyMessage);
            parameters.put("report_title", "DAY BOOK REPORT");
            parameters.put(
            	    "IMAGE_PATH",
            	    application.getRealPath("/images/UPSB MONO.png")
            	);


            /* =========================
               FILL REPORT
               ========================= */
            JasperPrint jasperPrint =
                    JasperFillManager.fillReport(jasperReport, parameters, conn);

            ServletOutputStream outStream = response.getOutputStream();

            /* =========================
               EXPORT
               ========================= */
            if ("pdf".equalsIgnoreCase(reporttype)) {

                response.reset(); // IMPORTANT
                response.setContentType("application/pdf");

                // ✅ THIS LINE IS THE REAL FIX
                response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"Daybook_Report.pdf\"; filename*=UTF-8''Daybook_Report.pdf"
                );

                // Optional but recommended
                response.setHeader("X-Content-Type-Options", "nosniff");

                JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);
                outStream.flush();
                return; // IMPORTANT
            

            } else if ("xls".equalsIgnoreCase(reporttype)) {

                response.setContentType("application/vnd.ms-excel");
                response.setHeader(
                        "Content-Disposition",
                        "attachment; filename=\"Daybook_Report.xls\""
                );

                JRXlsExporter exporter = new JRXlsExporter();
                exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
                exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
                exporter.setParameter(JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
                exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
                exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
                exporter.setParameter(JRXlsExporterParameter.IS_IGNORE_GRAPHICS, Boolean.TRUE);

                exporter.exportReport();
            }

            outStream.flush();
            outStream.close();
            return;

        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute(
                    "errorMessage",
                    "Error generating report: " + e.getMessage()
            );
            response.sendRedirect("daybookRG.jsp?error=true");

        } finally {
            if (conn != null) {
                try { conn.close(); } catch (Exception ignored) {}
            }
        }
    }
%>

<%!
    /* =========================================================
       CHECK TRANSFER / CLEARING TALLY
       ========================================================= */
    private String checkTransferClearingTally(Connection conn,
                                              String oracleDate,  // Already in DD-MMM-YYYY format
                                              String bankCode,
                                              String branchCode)
            throws SQLException {

        StringBuilder query = new StringBuilder();
        query.append("SELECT SUM(RECEIPT_TRANSFER) AS TRANSFER_RECEIPT, ")
             .append("SUM(PAYMENT_TRANSFER) AS TRANSFER_PAYMENT, ")
             .append("SUM(RECEIPT_CLEARING) AS CLEARING_RECEIPT, ")
             .append("SUM(PAYMENT_CLEARING) AS CLEARING_PAYMENT ")
             .append("FROM ( ")
             .append(" SELECT ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'TRCR' THEN AMOUNT ELSE 0 END) RECEIPT_TRANSFER, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'TRDR' THEN AMOUNT ELSE 0 END) PAYMENT_TRANSFER, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CLCR' THEN AMOUNT ELSE 0 END) RECEIPT_CLEARING, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CLDR' THEN AMOUNT ELSE 0 END) PAYMENT_CLEARING ")
             .append(" FROM TRANSACTION.TRANSACTION_HT_VIEW ")
             .append(" WHERE TXN_DATE = TO_DATE('").append(oracleDate).append("','DD-MON-YYYY') ")
             .append(" AND BRANCH_CODE = '").append(branchCode).append("' ")
             .append(" AND TRANSACTIONSTATUS = 'A' ")
             .append(" AND TXN_NUMBER > 0 ")
             .append(")");

        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query.toString());

        String tallyMessage = " Day Book Tallied.";

        if (rs.next()) {
            double trR = rs.getDouble("TRANSFER_RECEIPT");
            double trP = rs.getDouble("TRANSFER_PAYMENT");
            double clR = rs.getDouble("CLEARING_RECEIPT");
            double clP = rs.getDouble("CLEARING_PAYMENT");

            if (trR != trP && clR != clP) {
                tallyMessage = "** Transfer And Clearing Not Tallied.";
            } else if (trR != trP) {
                tallyMessage = "** Transfer Not Tallied.";
            } else if (clR != clP) {
                tallyMessage = "** Clearing Not Tallied.";
            }
        }

        rs.close();
        stmt.close();

        return tallyMessage;
    }


    /* =========================================================
       DATE FORMAT HELPERS
       ========================================================= */
    private String convertToDDMMYYYY(String oracleDate) {
        try {
            SimpleDateFormat in = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
            SimpleDateFormat out = new SimpleDateFormat("dd/MM/yyyy");
            return out.format(in.parse(oracleDate));
        } catch (Exception e) {
            return "29/03/2025";
        }
    }
%>

<%
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>DayBookRG Report</title>
<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

  <style>
html, body {
    margin: 0;
    padding: 0;
    overflow-x: hidden;
}
</style>
    
</head>

<body>
    <div class="loading-overlay" id="loading">
        <div class="spinner"></div>
        <div class="loading-text">Generating Report...</div>
    </div>

    <div class="report-container">
        <% 
            // Check for success/error messages in session
            String successMessage = (String) session.getAttribute("successMessage");
            String errorMessage = (String) session.getAttribute("errorMessage");
            String tallyMessage = (String) request.getAttribute("tallyMessage");
            
            if (successMessage != null) {
        %>
            <div class="success-message" id="successMessage">
                <%= successMessage %>
            </div>
        <%
                // Remove message from session after displaying
                session.removeAttribute("successMessage");
            }
            
            if (errorMessage != null) {
        %>
            <div class="error-message" id="errorMessage">
                <%= errorMessage %>
            </div>
        <%
                // Remove message from session after displaying
                session.removeAttribute("errorMessage");
            }
            
            if (tallyMessage != null) {
        %>
            <div class="info-message" id="tallyMessage">
                <%= tallyMessage %>
            </div>
        <%
                // Remove message from session after displaying
                session.removeAttribute("tallyMessage");
            }
        %>
        
        <h1 class="report-title">DAYBOOK REPORT</h1>
        
        <!-- REMOVE ONSUBMIT - Let form submit directly -->
<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/daybookRG.jsp"
      autocomplete="off"
      id="reportForm"
      target="_blank">

            <input type="hidden" name="action" value="download"/>
            
            <div class="parameter-section">
                <div class="parameter-group">
                    <div class="parameter-label">Bank Code</div>
                    <input type="text" name="bank_code" class="input-field" required
                           placeholder="Enter bank code"
                           value="<%= request.getParameter("bank_code") != null ? request.getParameter("bank_code") : "0100" %>">
                </div>
                
                <div class="parameter-group">
                    <div class="parameter-label">Branch Code</div>
                  <input type="text" name="branch_code" class="input-field" required
       value="<%= request.getParameter("branch_code") != null 
                ? request.getParameter("branch_code") 
                : "0002" %>">

               </div>
                
                <div class="parameter-group">
                    <div class="parameter-label">As On Date</div>
                    <input type="date" name="as_on_date" class="input-field" required
                           value="<%= request.getParameter("as_on_date") != null ? request.getParameter("as_on_date") : "2025-03-29" %>">
                </div>
            </div>
            
            <div class="format-section">
                <div class="parameter-label">Report Type</div>
                <div class="format-options">
                    <div class="format-option">
                        <input type="radio" name="reporttype" id="pdf" value="pdf" checked>
                        <label for="pdf">PDF </label>
                    </div>
                    <div class="format-option">
                        <input type="radio" name="reporttype" id="excel" value="xls">
                        <label for="excel">Excel</label>
                    </div>
                </div>
            </div>
            
            <button type="button" class="download-button" id="downloadBtn" onclick="submitForm()">
                Generate Report
            </button>
        </form>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.getElementById('reportForm');
            const loading = document.getElementById('loading');
            const downloadBtn = document.getElementById('downloadBtn');
            const successMessage = document.getElementById('successMessage');
            const errorMessage = document.getElementById('errorMessage');
            const tallyMessage = document.getElementById('tallyMessage');
            
            // Store original button text
            const originalBtnText = downloadBtn.innerHTML;
            
            // Function to show success message after download
            function checkDownloadSuccess() {
                // Remove existing success/error messages after 5 seconds
                setTimeout(function() {
                    if (successMessage) {
                        successMessage.style.display = 'none';
                    }
                    if (errorMessage) {
                        errorMessage.style.display = 'none';
                    }
                    if (tallyMessage) {
                        tallyMessage.style.display = 'none';
                    }
                }, 5000);
            }
            
            // Check for messages on page load
            checkDownloadSuccess();
            
            // Submit form and handle download
            window.submitForm = function() {
                const bankCode = document.getElementsByName('bank_code')[0].value.trim();
                const branchCode = document.getElementsByName('branch_code')[0].value.trim();
                const asOnDate = document.getElementsByName('as_on_date')[0].value.trim();
                
                // Basic validation
                if (!bankCode || !branchCode || !asOnDate) {
                    alert('Please fill all required fields!');
                    return false;
                }
                
                // Show loading overlay
                loading.style.display = 'flex';
                
                // Disable button and change text
                downloadBtn.disabled = true;
                downloadBtn.innerHTML = 'Generating Report...';
                downloadBtn.style.opacity = '0.7';
                
                // Submit form - will open in new tab/window
                form.submit();
                
                // Hide loading after 3 seconds (in case download takes time)
                setTimeout(function() {
                    loading.style.display = 'none';
                    downloadBtn.disabled = false;
                    downloadBtn.innerHTML = originalBtnText;
                    downloadBtn.style.opacity = '1';
                }, 3000);
                
                return true;
            };
            
            // Reset button state when page is shown again
            window.addEventListener('pageshow', function(event) {
                loading.style.display = 'none';
                downloadBtn.disabled = false;
                downloadBtn.innerHTML = originalBtnText;
                downloadBtn.style.opacity = '1';
            });
            
            // Prevent form resubmission on page refresh
            if (window.history.replaceState) {
                window.history.replaceState(null, null, window.location.href);
            }
            
            // Listen for beforeunload to show loading when leaving page
            window.addEventListener('beforeunload', function() {
                loading.style.display = 'flex';
            });
        });
    </script>
    
</body>
</html>
<%
}
%>   
