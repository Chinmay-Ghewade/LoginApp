<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%!
/* =========================
   NUMBER TO WORDS FUNCTION
   ========================= */

private static final String[] units = {
"", "One", "Two", "Three", "Four", "Five", "Six",
"Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve",
"Thirteen", "Fourteen", "Fifteen", "Sixteen",
"Seventeen", "Eighteen", "Nineteen"
};

private static final String[] tens = {
"", "", "Twenty", "Thirty", "Forty", "Fifty",
"Sixty", "Seventy", "Eighty", "Ninety"
};

public String convertToWords(int number) {

    if (number < 20)
        return units[number];

    if (number < 100)
        return tens[number / 10] +
               ((number % 10 != 0) ? " " + units[number % 10] : "");

    if (number < 1000)
        return units[number / 100] + " Hundred " +
               ((number % 100 != 0) ? convertToWords(number % 100) : "");

    if (number < 100000)
        return convertToWords(number / 1000) + " Thousand " +
               ((number % 1000 != 0) ? convertToWords(number % 1000) : "");

    if (number < 10000000)
        return convertToWords(number / 100000) + " Lakh " +
               ((number % 100000 != 0) ? convertToWords(number % 100000) : "");

    return convertToWords(number / 10000000) + " Crore " +
           ((number % 10000000 != 0) ? convertToWords(number % 10000000) : "");
}
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String accountCode = request.getParameter("account_code");
    String asOnDate = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

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

        } else {

            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(new java.util.Date())
                            .toUpperCase();
        }

        /* =========================
           FETCH BRANCH NAME
           ========================= */

        String branchName = "";

        PreparedStatement psBranch =
                conn.prepareStatement(
                        "SELECT NAME FROM HEADOFFICE.BRANCH WHERE BRANCH_CODE=?");

        psBranch.setString(1, branchCode);

        ResultSet rsBranch = psBranch.executeQuery();

        if (rsBranch.next()) {
            branchName = rsBranch.getString("NAME");
        }

        rsBranch.close();
        psBranch.close();

        /* =========================
           FETCH CUSTOMER ADDRESS
           ========================= */

        String address1 = "";
        String address2 = "";
        String address3 = "";

        PreparedStatement psAddr =
                conn.prepareStatement(
                        "SELECT c.address1,c.address2,c.address3 " +
                        "FROM account.account a, customer.customer c " +
                        "WHERE a.customer_id=c.customer_id " +
                        "AND a.account_code=?");

        psAddr.setString(1, accountCode);

        ResultSet rsAddr = psAddr.executeQuery();

        if (rsAddr.next()) {

            address1 = rsAddr.getString("address1");
            address2 = rsAddr.getString("address2");
            address3 = rsAddr.getString("address3");
        }

        rsAddr.close();
        psAddr.close();

        /* =========================
           FETCH BALANCE
           ========================= */

        double balance = 0;

        PreparedStatement psBal =
                conn.prepareStatement(
                        "SELECT NVL(LEDGERBALANCE,0) BAL " +
                        "FROM BALANCE.ACCOUNT " +
                        "WHERE ACCOUNT_CODE=?");

        psBal.setString(1, accountCode);

        ResultSet rsBal = psBal.executeQuery();

        if (rsBal.next()) {
            balance = rsBal.getDouble("BAL");
        }

        rsBal.close();
        psBal.close();

        /* =========================
           BALANCE IN WORDS
           ========================= */

        		   int rupees = (int) balance;
           int paise = (int) Math.round((balance - rupees) * 100);

           String rupeeWord = (rupees == 0) ? "Zero" : convertToWords(rupees);

           String balanceWords;

           if (paise > 0) {

               String paiseWord = convertToWords(paise);

               balanceWords = rupeeWord + " and " + paiseWord + " Paise Only";

           } else {

               balanceWords = rupeeWord + " Only";
           }
        /* =========================
           LOAD REPORT
           ========================= */

        String jasperPath =
                application.getRealPath("/Reports/BalanceCertificateLetterFR.jasper");

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* =========================
           PARAMETERS
           ========================= */

        Map<String, Object> parameters = new HashMap<>();

        parameters.put("account_code", accountCode);
        parameters.put("as_on_date", oracleDateStr);
        parameters.put("branch_code", branchCode);
        parameters.put("branch_name", branchName);

        parameters.put("account_balance", balance);
        parameters.put("Rs_in_word", balanceWords);

        parameters.put("customer_address1", address1);
        parameters.put("customer_address2", address2);
        parameters.put("customer_address3", address3);

        String userId = (String) session.getAttribute("user_id");

        if(userId == null || userId.trim().equals("")){
            userId = "admin";
        }

        parameters.put("user_id", userId);
        
        parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        parameters.put("IMAGE_PATH",
                application.getRealPath("/images/UPSB MONO.png"));

        parameters.put("report_title",
                "BALANCE CERTIFICATE LETTER");

        /* =========================
           FILL REPORT
           ========================= */

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(
                        jasperReport,
                        parameters,
                        conn);

        /* =========================
           EXPORT
           ========================= */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"BalanceCertificateLetter.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                    jasperPrint,
                    outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"BalanceCertificateLetter.xls\"");

            ServletOutputStream outStream =
                    response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                    JRXlsExporterParameter.JASPER_PRINT,
                    jasperPrint);

            exporter.setParameter(
                    JRXlsExporterParameter.OUTPUT_STREAM,
                    outStream);

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
            try { conn.close(); }
            catch (Exception ignored) {}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Balance Certificate Letter</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">
</head>

<body>

<div class="report-container">

<h1 class="report-title">
BALANCE CERTIFICATE LETTER
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/BalanceCertificateLetterFR.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<input type="text"
name="branch_code"
class="input-field"
value="0002"
required>

</div>

<div class="parameter-group">

<div class="parameter-label">
Account Code
</div>

<input type="text"
name="account_code"
class="input-field"
value="00022010003387"
required>

</div>

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="date"
name="as_on_date"
class="input-field"
value="2025-03-29"
required>

</div>

</div>

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<label>
<input type="radio" name="reporttype" value="pdf" checked>
PDF
</label>

<label>
<input type="radio" name="reporttype" value="xls">
Excel
</label>

</div>

<button type="submit"
class="download-button">

Generate Certificate

</button>

</form>

</div>

</body>
</html>