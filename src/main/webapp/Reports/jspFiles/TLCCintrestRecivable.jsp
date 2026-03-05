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
String toDateUI = request.getParameter("to_date");
String productCode = request.getParameter("product_code");

String errorMessage = null;

if (branchCode == null) branchCode = "0002";
if (toDateUI == null || toDateUI.trim().isEmpty()) toDateUI = "2025-03-29";

if ("download".equals(action)) {

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* DATE FORMAT */

        SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String oracleDate = outFmt.format(inFmt.parse(toDateUI)).toUpperCase();

        /* PRODUCT CONDITION */

        String condition = "";

        if (productCode != null && !productCode.trim().isEmpty()) {
            condition = " AND SUBSTR(A.ACCOUNT_CODE,5,3) = ? ";
        }

        /* SQL */

        String sql =
            " SELECT A.ACCOUNT_CODE ACCOUNT_NO, " +
            " A.NAME AC_NAME, " +
            " P.DESCRIPTION, " +
            " FN_GET_BALANCE_ASON(?,A.ACCOUNT_CODE) BALANCE_AMT, " +
            " (FN_GET_RECPAY_REPORTS(?,A.ACCOUNT_CODE,'N') * (-1)) PAYBALE_AMT " +

            " FROM ACCOUNT.ACCOUNT A, ACCOUNT.ACCOUNTDEPOSIT D, HEADOFFICE.PRODUCT P " +

            " WHERE A.ACCOUNT_CODE = D.ACCOUNT_CODE " +
            " AND SUBSTR(A.ACCOUNT_CODE,5,3) = P.PRODUCT_CODE " +
            " AND SUBSTR(A.ACCOUNT_CODE,1,4) = ? " +

            " AND ((A.DATEACCOUNTOPEN IS NULL OR A.DATEACCOUNTOPEN <= ?)) " +
            " AND ((A.DATEACCOUNTCLOSE IS NULL OR A.DATEACCOUNTCLOSE > ?)) " +

            condition +

            " AND ( FN_GET_BALANCE_ASON(?,A.ACCOUNT_CODE) <> 0 " +
            " OR FN_GET_RECPAY_REPORTS(?,A.ACCOUNT_CODE,'N') <> 0 ) " +

            " ORDER BY P.PRODUCT_CODE, A.ACCOUNT_CODE";

        pstmt = conn.prepareStatement(sql);

        int idx = 1;

        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, branchCode);
        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);

        if (productCode != null && !productCode.trim().isEmpty()) {
            pstmt.setString(idx++, productCode);
        }

        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);

        rs = pstmt.executeQuery();

        /* LOAD REPORT */

        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String reportPath = reportsDir + "DepositPaybaleListRG.jrxml";

        JasperReport jasperReport = JasperCompileManager.compileReport(reportPath);

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("report_title", "PAYABLE DEPOSIT REPORT");

        String userId = (String) session.getAttribute("user_id");
        if (userId == null) userId = "admin";

        params.put("user_id", userId);

        params.put("SUBREPORT_DIR", reportsDir);
        params.put("REPORT_CONNECTION", conn);

        JRResultSetDataSource jrDataSource =
                new JRResultSetDataSource(rs);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, jrDataSource);

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"DepositPayableReport.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"DepositPayableReport.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);

            exporter.exportReport();
            sos.flush();
            return;
        }

    } catch (Exception e) {

        e.printStackTrace();
        errorMessage = "Error generating Deposit Payable Report : " + e.getMessage();

    } finally {

        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Deposit Payable Report</title>

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/Reports/common-report.css">

</head>

<body>

<div class="report-container">

<h1 class="report-title">PAYABLE DEPOSIT REPORT</h1>

<% if(errorMessage != null){ %>
<div class="error-message">
<%= errorMessage %>
</div>
<% } %>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositPaybaleListRG.jsp"
      target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>
<input type="text" name="branch_code"
       class="input-field"
       value="<%=branchCode%>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">Product Code</div>
<input type="text" name="product_code"
class="input-field"
value="<%=productCode!=null?productCode:""%>"
placeholder="Optional">
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date" name="to_date"
       class="input-field"
       value="<%=toDateUI%>" required>
</div>

</div>

<div class="format-section">
<div class="parameter-label">Report Type</div>
<input type="radio" name="reporttype" value="pdf" checked> PDF
<input type="radio" name="reporttype" value="xls"> Excel
</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

</body>
</html>