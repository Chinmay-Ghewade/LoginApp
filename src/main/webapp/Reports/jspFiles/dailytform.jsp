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
    String branchCode = request.getParameter("branch_code");
    String asOnDateUI = request.getParameter("as_on_date");
    
    // If parameters are null (first load), set defaults
    if (branchCode == null) branchCode = "0002";
    if (asOnDateUI == null) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        asOnDateUI = sdf.format(new java.util.Date());
    }

    if ("download".equals(action)) {
        String reportType = request.getParameter("reporttype");
        String userId = "admin";
        
        Connection conn = null;
        CallableStatement cstmt = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            // Clear previous session data
            session.removeAttribute("OPENING_BALANCE");
            session.removeAttribute("CLOSING_BALANCE");
            session.removeAttribute("TOTAL_CR");
            session.removeAttribute("TOTAL_DR");
            session.removeAttribute("TOTAL_CASH");
            session.removeAttribute("TOTAL_DEBIT_ONLY");
            session.removeAttribute("TOTAL_TRDR");
            session.removeAttribute("TOTAL_TLTRCR");
            
            /* =========================
               RESPONSE SETUP
               ========================= */
            response.reset();
            response.setBufferSize(1024 * 1024);
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setDateHeader("Expires", 0);

            // Use DBConnection like daybookRG.jsp
            conn = DBConnection.getConnection();
            
            /* =========================
               DATE HANDLING (FIXED FOR ORACLE)
               ========================= */
            String oracleDate;
            String sqlFormattedDate = "";
            try {
                SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
                SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
                oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();
                sqlFormattedDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();
            } catch (Exception e) {
                // Default date if parsing fails
                oracleDate = "29-MAR-2025";
                sqlFormattedDate = "29-MAR-2025";
            }

            conn.setAutoCommit(false);

            // Call the stored procedure
            System.out.println("Calling stored procedure with params: branch=" + branchCode + ", date=" + oracleDate + ", user=" + userId);
            cstmt = conn.prepareCall("{ call sp_rep_supp_t_form( ?, ?, ? ) }");
            cstmt.setString(1, branchCode);
            cstmt.setString(2, oracleDate);
            cstmt.setString(3, userId);
            cstmt.execute();
            conn.commit();
            System.out.println("Stored procedure executed successfully");

            // Execute Cash Opening/Closing Balance SQL
            String bankCode = "0100";
            boolean isSessionDate = false;
            
            String cashBalanceSql = "";
            
            if (isSessionDate) {
                cashBalanceSql = " SELECT 'CSOB' AS TRANSACTIONINDICATOR_CODE, " +
                               "   'CASH OPEN BAL/CLOSE BAL' AS DESCRIPTION, " +
                               "   ABS(OPENINGBALANCE) AS AMOUNT " +
                               " FROM BALANCE.BRANCHGL BRANCHGL " +
                               " JOIN ACCOUNTLINK.DEFAULTBANKACCOUNTS DEFAULTBANKACCOUNTS ON(BANK_CODE = '" + bankCode + "') " +
                               " WHERE BRANCHGL.BRANCH_CODE = '" + branchCode + "' " +
                               " AND BRANCHGL.GLACCOUNT_CODE = DEFAULTBANKACCOUNTS.ACCOUNT_CODE_CASH_IN_HAND " +
                               " UNION ALL " +
                               " SELECT 'CSCB' AS TRANSACTIONINDICATOR_CODE, " +
                               "   'CASH OPEN BAL/CLOSE BAL' AS DESCRIPTION, " +
                               "   SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CSDR' " +
                               "                THEN AMOUNT " +
                               "                ELSE(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CSCR' " +
                               "                     THEN -AMOUNT " +
                               "                     ELSE 0 END) " +
                               "           END) AS AMOUNT " +
                               " FROM TRANSACTION.TRANSACTION_HT_VIEW " +
                               " WHERE TXN_DATE = TO_DATE('" + sqlFormattedDate + "', 'DD-MON-YYYY') " +
                               " AND BRANCH_CODE = '" + branchCode + "' " +
                               " AND TRANSACTIONSTATUS = 'A' " +
                               " AND TXN_NUMBER > 0";
            } else {
                cashBalanceSql = " SELECT 'CSOB' AS TRANSACTIONINDICATOR_CODE, " +
                               "   'CASH OPEN BAL/CLOSE BAL' AS DESCRIPTION, " +
                               "   ABS(OPENINGBALANCE) AS AMOUNT " +
                               " FROM BALANCE.BRANCHGLHISTORY BRANCHGLHISTORY " +
                               " JOIN ACCOUNTLINK.DEFAULTBANKACCOUNTS DEFAULTBANKACCOUNTS ON(BANK_CODE = '" + bankCode + "') " +
                               " WHERE BRANCHGLHISTORY.BRANCH_CODE = '" + branchCode + "' " +
                               " AND BRANCHGLHISTORY.TXN_DATE = TO_DATE('" + sqlFormattedDate + "', 'DD-MON-YYYY') " +
                               " AND BRANCHGLHISTORY.GLACCOUNT_CODE = DEFAULTBANKACCOUNTS.ACCOUNT_CODE_CASH_IN_HAND " +
                               " UNION ALL " +
                               " SELECT 'CSCB' AS TRANSACTIONINDICATOR_CODE, " +
                               "   'CASH OPEN BAL/CLOSE BAL' AS DESCRIPTION, " +
                               "   SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CSDR' " +
                               "                THEN AMOUNT " +
                               "                ELSE(CASE WHEN TRANSACTIONINDICator_code = 'CSCR' " +
                               "                     THEN -AMOUNT " +
                               "                     ELSE 0 END) " +
                               "           END) AS AMOUNT " +
                               " FROM TRANSACTION.TRANSACTION_HT_VIEW " +
                               " WHERE TXN_DATE = TO_DATE('" + sqlFormattedDate + "', 'DD-MON-YYYY') " +
                               " AND BRANCH_CODE = '" + branchCode + "' " +
                               " AND TRANSACTIONSTATUS = 'A' " +
                               " AND TXN_NUMBER > 0";
            }
            
            System.out.println("Cash Balance SQL: " + cashBalanceSql);
            
            double openingBalance = 0;
            double closingBalance = 0;
            
            try {
                Statement cashStmt = conn.createStatement();
                ResultSet cashRs = cashStmt.executeQuery(cashBalanceSql);
                
                while (cashRs.next()) {
                    String transCode = cashRs.getString("TRANSACTIONINDICATOR_CODE");
                    double amount = cashRs.getDouble("AMOUNT");
                    
                    System.out.println("Transaction Code: " + transCode + ", Amount: " + amount);
                    
                    if ("CSOB".equals(transCode)) {
                        openingBalance = amount;
                    } else if ("CSCB".equals(transCode)) {
                        closingBalance = amount;
                    }
                }
                
                if (cashRs != null) cashRs.close();
                if (cashStmt != null) cashStmt.close();
            } catch (Exception e) {
                System.out.println("Error executing cash balance query: " + e.getMessage());
            }
            
            System.out.println("Cash Opening Balance: " + openingBalance);
            System.out.println("Cash Closing Balance: " + closingBalance);
            
            // Store in session
            session.setAttribute("OPENING_BALANCE", openingBalance);
            session.setAttribute("CLOSING_BALANCE", closingBalance);

            // Execute SQL queries to get totals
            double totalCredit = 0;
            double totalDebit = 0;
            double totalCash = 0;
            double totalDebitOnly = 0;
            double totalTrdr = 0;
            double totalTltrcr = 0;
            
            // Query 1: Total Credit and Debit
            String totalSql1 = "SELECT SUM(CSCR_AMT + CLCR_AMT + TRCR_AMT) TOTAL_CR, " +
                             "SUM(CSDR_AMT + CLDR_AMT + TRDR_AMT) TOTAL_DR " +
                             "FROM TEMP.SUPP_T_FORM T, HEADOFFICE.GLACCOUNT G " +
                             "WHERE T.BRANCH_CODE = ? " +
                             "AND TXN_DATE = ? " +
                             "AND REP_USER_ID = ? " +
                             "AND REP_TYPE <> 'H' " +
                             "AND T.GLACCOUNT_CODE = G.GLACCOUNT_CODE";
            
            try {
                pstmt = conn.prepareStatement(totalSql1);
                pstmt.setString(1, branchCode);
                pstmt.setString(2, oracleDate);
                pstmt.setString(3, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    totalCredit = rs.getDouble("TOTAL_CR");
                    totalDebit = rs.getDouble("TOTAL_DR");
                    
                    System.out.println("Total Credit (All): " + totalCredit);
                    System.out.println("Total Debit (All): " + totalDebit);
                    
                    session.setAttribute("TOTAL_CR", totalCredit);
                    session.setAttribute("TOTAL_DR", totalDebit);
                }
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            } catch (Exception e) {
                System.out.println("Error in query 1: " + e.getMessage());
            }
            
            // Query 2: Cash and Debit totals
            String totalSql2 = "SELECT SUM(CSCR_AMT + CLCR_AMT) TOTAL_CASH, " +
                             "SUM(CSDR_AMT + CLDR_AMT) TOTAL_DEBIT " +
                             "FROM TEMP.SUPP_T_FORM T, HEADOFFICE.GLACCOUNT G " +
                             "WHERE T.BRANCH_CODE = ? " +
                             "AND TXN_DATE = ? " +
                             "AND REP_USER_ID = ? " +
                             "AND REP_TYPE <> 'H' " +
                             "AND T.GLACCOUNT_CODE = G.GLACCOUNT_CODE";
            
            try {
                pstmt = conn.prepareStatement(totalSql2);
                pstmt.setString(1, branchCode);
                pstmt.setString(2, oracleDate);
                pstmt.setString(3, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    totalCash = rs.getDouble("TOTAL_CASH");
                    totalDebitOnly = rs.getDouble("TOTAL_DEBIT");
                    
                    System.out.println("Total Cash (CSCR+CLCR): " + totalCash);
                    System.out.println("Total Debit (CSDR+CLDR): " + totalDebitOnly);
                    
                    session.setAttribute("TOTAL_CASH", totalCash);
                    session.setAttribute("TOTAL_DEBIT_ONLY", totalDebitOnly);
                }
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            } catch (Exception e) {
                System.out.println("Error in query 2: " + e.getMessage());
            }
            
            // Query 3: CLDR+TRDR totals
            String totalSql3 = "SELECT SUM(CLDR_AMT + TRDR_AMT) TOTALTRDR " +
                             "FROM TEMP.SUPP_T_FORM T, HEADOFFICE.GLACCOUNT G " +
                             "WHERE T.BRANCH_CODE = ? " +
                             "AND TXN_DATE = ? " +
                             "AND REP_USER_ID = ? " +
                             "AND REP_TYPE <> 'H' " +
                             "AND T.GLACCOUNT_CODE = G.GLACCOUNT_CODE";
            
            try {
                pstmt = conn.prepareStatement(totalSql3);
                pstmt.setString(1, branchCode);
                pstmt.setString(2, oracleDate);
                pstmt.setString(3, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    totalTrdr = rs.getDouble("TOTALTRDR");
                    
                    System.out.println("Total TRDR (CLDR+TRDR): " + totalTrdr);
                    
                    session.setAttribute("TOTAL_TRDR", totalTrdr);
                }
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            } catch (Exception e) {
                System.out.println("Error in query 3: " + e.getMessage());
            }
            
            // Query 4: CLCR+TRCR totals
            String totalSql4 = "SELECT SUM(CLCR_AMT + TRCR_AMT) TTLTRCR " +
                             "FROM TEMP.SUPP_T_FORM T, HEADOFFICE.GLACCOUNT G " +
                             "WHERE T.BRANCH_CODE = ? " +
                             "AND TXN_DATE = ? " +
                             "AND REP_USER_ID = ? " +
                             "AND REP_TYPE <> 'H' " +
                             "AND T.GLACCOUNT_CODE = G.GLACCOUNT_CODE";
            
            try {
                pstmt = conn.prepareStatement(totalSql4);
                pstmt.setString(1, branchCode);
                pstmt.setString(2, oracleDate);
                pstmt.setString(3, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    totalTltrcr = rs.getDouble("TTLTRCR");
                    
                    System.out.println("Total TLTRCR (CLCR+TRCR): " + totalTltrcr);
                    
                    session.setAttribute("TOTAL_TLTRCR", totalTltrcr);
                }
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            } catch (Exception e) {
                System.out.println("Error in query 4: " + e.getMessage());
            }

            System.out.println("WEB ROOT = " + application.getRealPath("/"));

            String reportsDir = application.getRealPath("/Reports");
            if (reportsDir == null) {
                throw new Exception("Reports directory not found on disk");
            }
            reportsDir += File.separator;
            
            String mainReportPath = reportsDir + "dailyTform.jrxml";
            String subReportPath = reportsDir + "subReportHeader.jrxml";
            
            // Check if report files exist
            File mainReportFile = new File(mainReportPath);
            File subReportFile = new File(subReportPath);
            
            if (!mainReportFile.exists()) {
                throw new Exception("Main report file not found: " + mainReportPath);
            }
            
            if (!subReportFile.exists()) {
                System.out.println("Subreport file not found: " + subReportPath + " - continuing without subreport");
            }

            /* =========================
               COMPILE MAIN REPORT
               ========================= */
            JasperReport jasperReport = JasperCompileManager.compileReport(mainReportPath);
            
            // Compile subreport if it exists
            JasperReport subJasperReport = null;
            if (subReportFile.exists()) {
                subJasperReport = JasperCompileManager.compileReport(subReportPath);
            }

            /* =========================
               PARAMETERS
               ========================= */
            Map<String, Object> params = new HashMap<>();
            params.put("branch_code", branchCode);
            params.put("user_id", userId);
            params.put("as_on_date", oracleDate);
            params.put("report_title", "Daily Supplementary Report_TForm");
            params.put("SUBREPORT_DIR", reportsDir);
            
            // Add bank code (required by some reports)
            params.put("bank_code", "0100");
            
            // Add image path if needed
            params.put("IMAGE_PATH", application.getRealPath("/images/UPSB MONO.png"));
            
            // Pass compiled subreport as parameter if it exists
            if (subJasperReport != null) {
                params.put("subReportHeader.jasper", subJasperReport);
            }
            
            // Pass all totals as parameters to the report
            params.put("TOTAL_CREDIT", totalCredit);
            params.put("TOTAL_DEBIT", totalDebit);
            params.put("TOTAL_CASH", totalCash);
            params.put("TOTAL_DEBIT_ONLY", totalDebitOnly);
            params.put("TOTAL_TRDR", totalTrdr);
            params.put("TOTAL_TLTRCR", totalTltrcr);
            params.put("OPENING_BALANCE", openingBalance);
            params.put("CLOSING_BALANCE", closingBalance);

            /* =========================
               FILL REPORT
               ========================= */
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, params, conn);
            
            // Debug: Check number of pages
            int pageCount = jasperPrint.getPages().size();
            System.out.println("Report filled successfully. Total pages: " + pageCount);
            
            if (pageCount == 0) {
                System.out.println("WARNING: Report has 0 pages. Check if there is data in TEMP.SUPP_T_FORM table.");
            }

            ServletOutputStream sos = response.getOutputStream();

            /* =========================
               EXPORT
               ========================= */
            if ("pdf".equalsIgnoreCase(reportType)) {

                response.reset();  // ✅ MUST reset here
                response.setContentType("application/pdf");

                response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"DailySupplementaryTForm.pdf\"; filename*=UTF-8''DailySupplementaryTForm.pdf"
                );

                response.setHeader("X-Content-Type-Options", "nosniff");

                JasperExportManager.exportReportToPdfStream(jasperPrint, sos);

                sos.flush();
                return; // ✅ VERY IMPORTANT
            

            } else if ("xls".equalsIgnoreCase(reportType)) {

                response.reset();
                response.setContentType("application/vnd.ms-excel");

                response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"DailySupplementaryTForm.xls\""
                );

                JRXlsExporter exporter = new JRXlsExporter();
                exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
                exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
                exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
                exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
                exporter.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, Boolean.FALSE);
                exporter.setParameter(JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
                exporter.setParameter(JRXlsExporterParameter.IS_IGNORE_GRAPHICS, Boolean.TRUE);

                exporter.exportReport();
                sos.flush();
                return;
            
            }

        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute(
                "errorMessage",
                "Error generating report: " + e.getMessage()
            );
            // Use relative path for redirect
            response.sendRedirect("dailytform.jsp?error=true");
            return;

        } finally {
            if (cstmt != null) { try { cstmt.close(); } catch (Exception ignored) {} }
            if (pstmt != null) { try { pstmt.close(); } catch (Exception ignored) {} }
            if (rs != null) { try { rs.close(); } catch (Exception ignored) {} }
            if (conn != null) { try { conn.close(); } catch (Exception ignored) {} }
        }
    }
%>

<%
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>Daily Supplementary Report_TForm</title>
<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

</head>

<body>
    

    <div class="report-container">
        <% 
            // Check for success/error messages in session
            String successMessage = (String) session.getAttribute("successMessage");
            String errorMessage = (String) session.getAttribute("errorMessage");
            
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
        %>
        
        <h1 class="report-title">DAILY SUPPLEMENTARY REPORT - TFORM</h1>
        
        <!-- Get all session attributes for display -->
        <%
            Double totalCr = (Double) session.getAttribute("TOTAL_CR");
            Double totalDr = (Double) session.getAttribute("TOTAL_DR");
            Double totalCash = (Double) session.getAttribute("TOTAL_CASH");
            Double totalDebitOnly = (Double) session.getAttribute("TOTAL_DEBIT_ONLY");
            Double totalTrdr = (Double) session.getAttribute("TOTAL_TRDR");
            Double totalTltrcr = (Double) session.getAttribute("TOTAL_TLTRCR");
            Double openingBalance = (Double) session.getAttribute("OPENING_BALANCE");
            Double closingBalance = (Double) session.getAttribute("CLOSING_BALANCE");
        %>
        
        <!-- IMPORTANT: Use the current page URL for form action -->
       <form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/dailytform.jsp"
      target="_blank"
      id="reportForm">


            
            <input type="hidden" name="action" value="download"/>
            
            <div class="parameter-section">
                <div class="parameter-group">
                    <div class="parameter-label">Branch Code</div>
                    <input type="text" name="branch_code" class="input-field" required
                           placeholder="Enter branch code"
                           value="<%= branchCode %>">
                </div>
                
                <div class="parameter-group">
                    <div class="parameter-label">As On Date</div>
                    <input type="date" name="as_on_date" class="input-field" required
                           value="<%= asOnDateUI %>">
                </div>
            </div>
            
            <div class="format-section">
                <div class="parameter-label">Report Type</div>
                <div class="format-options">
                    <div class="format-option">
                        <input type="radio" name="reporttype" id="pdf" value="pdf" checked>
                        <label for="pdf">PDF</label>
                    </div>
                    <div class="format-option">
                        <input type="radio" name="reporttype" id="excel" value="xls">
                        <label for="excel">Excel</label>
                    </div>
                </div>
            </div>
            
            <button type="submit" class="download-button" id="downloadBtn">
                Generate Report
            </button>
        </form>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.getElementById('reportForm');
            const loading = document.getElementById('loading');
            const downloadBtn = document.getElementById('downloadBtn');
            
            // Store original button text
            const originalBtnText = downloadBtn.innerHTML;
            
            // Set default date to today (only if not already set by server)
            const asOnDateField = document.querySelector('input[name="as_on_date"]');
            if (!asOnDateField.value) {
                const today = new Date();
                const dd = String(today.getDate()).padStart(2, '0');
                const mm = String(today.getMonth() + 1).padStart(2, '0');
                const yyyy = today.getFullYear();
                asOnDateField.value = `${yyyy}-${mm}-${dd}`;
            }
            
            // Handle form submission
            form.addEventListener('submit', function(e) {
                const branchCode = document.querySelector('input[name="branch_code"]').value.trim();
                const asOnDate = document.querySelector('input[name="as_on_date"]').value.trim();
                
                // Basic validation
                if (!branchCode || !asOnDate) {
                    alert('Please fill all required fields!');
                    e.preventDefault();
                    return false;
                }
                
                // Validate date format
                const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
                if (!dateRegex.test(asOnDate)) {
                    alert('Please enter a valid date in YYYY-MM-DD format');
                    e.preventDefault();
                    return false;
                }
                
                // Show loading overlay
                loading.style.display = 'flex';
                
                // Disable button and change text
                downloadBtn.disabled = true;
                downloadBtn.innerHTML = 'Generating Report...';
                downloadBtn.style.opacity = '0.7';
                
                // The form will submit normally with target="_blank"
                return true;
            });
            
            // Reset button state when returning to the page
            window.addEventListener('pageshow', function(event) {
                // Check if the page is being loaded from cache
                if (event.persisted) {
                    loading.style.display = 'none';
                    downloadBtn.disabled = false;
                    downloadBtn.innerHTML = originalBtnText;
                    downloadBtn.style.opacity = '1';
                }
            });
            
            // Prevent form resubmission on page refresh
            if (window.history.replaceState) {
                window.history.replaceState(null, null, window.location.href);
            }
        });
    </script>
</body>
</html>
<%
}
%>