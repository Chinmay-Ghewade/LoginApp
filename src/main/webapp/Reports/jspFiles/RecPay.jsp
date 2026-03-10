<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true"%>
<%@ page buffer="none" %>

<%@ page import="java.sql.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.text.DecimalFormat"%>

<%@ page import="net.sf.jasperreports.engine.*"%>
<%@ page import="net.sf.jasperreports.engine.export.*"%>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader"%>
<%@ page import="net.sf.jasperreports.export.*"%>

<%@ page import="db.DBConnection"%>

<%!
/* =====================================================
   NUMBER TO WORDS
===================================================== */

public String convertToWords(long n){

    String[] units = {"","One","Two","Three","Four","Five","Six","Seven",
    "Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen",
    "Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"};

    String[] tens = {"","","Twenty","Thirty","Forty","Fifty",
    "Sixty","Seventy","Eighty","Ninety"};

    if(n < 20)
        return units[(int)n];

    if(n < 100)
        return tens[(int)n/10] + " " + units[(int)n%10];

    if(n < 1000)
        return units[(int)n/100] + " Hundred " + convertToWords(n%100);

    if(n < 100000)
        return convertToWords(n/1000) + " Thousand " + convertToWords(n%1000);

    if(n < 10000000)
        return convertToWords(n/100000) + " Lakh " + convertToWords(n%100000);

    return convertToWords(n/10000000) + " Crore " + convertToWords(n%10000000);
}

public String numberToWords(double amount){

    if(amount == 0)
        return "Zero Rupees Only";

    long rupees = (long)Math.abs(amount);

    return convertToWords(rupees) + " Rupees Only";
}
%>

<%

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String asOnDate = request.getParameter("as_on_date");

    /* Default Date = 29-Mar-2025 */
    if(asOnDate == null || asOnDate.trim().equals("")){
        asOnDate = "2025-03-29";
    }
    Connection conn = null;

    try{

        response.reset();

        response.setHeader("Cache-Control","no-store, no-cache");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader("Expires",0);

        conn = DBConnection.getConnection();

        /* ======================
           DATE FORMAT
        ====================== */

        String oracleDate;

        if(asOnDate!=null && !asOnDate.trim().equals("")){

            java.util.Date utilDate =
            new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(utilDate).toUpperCase();

        }else{

            oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(new java.util.Date()).toUpperCase();
        }


        /* ======================
           TOTAL CREDIT / DEBIT
        ====================== */

        double totalCredit = 0;
        double totalDebit  = 0;

        PreparedStatement psTotals = conn.prepareStatement(

        "SELECT " +
        "SUM(CASE WHEN TRANSACTIONINDICATOR_CODE='TRCR' THEN AMOUNT ELSE 0 END) TOTALCREDIT," +
        "SUM(CASE WHEN TRANSACTIONINDICATOR_CODE='TRDR' THEN AMOUNT ELSE 0 END) TOTALDEBIT " +
        "FROM TRANSACTION.TRANSACTION_HT_VIEW " +
        "WHERE BRANCH_CODE=? AND TXN_DATE=? " +
        "AND TRANSACTIONINDICATOR_CODE IN ('TRCR','TRDR')"

        );

        psTotals.setString(1,branchCode);
        psTotals.setString(2,oracleDate);

        ResultSet rsTotals = psTotals.executeQuery();

        if(rsTotals.next()){

            totalCredit = rsTotals.getDouble("TOTALCREDIT");
            totalDebit  = rsTotals.getDouble("TOTALDEBIT");
        }

        rsTotals.close();
        psTotals.close();


        /* ======================
           OPENING BALANCE
        ====================== */

        double openingBalance = 0;

        PreparedStatement psOpen = conn.prepareStatement(

        "SELECT OPENINGBALANCE FROM BALANCE.BRANCHGLHISTORY " +
        "WHERE BRANCH_CODE=? AND TXN_DATE=?"

        );

        psOpen.setString(1,branchCode);
        psOpen.setString(2,oracleDate);

        ResultSet rsOpen = psOpen.executeQuery();

        if(rsOpen.next()){

            openingBalance = Math.abs(rsOpen.getDouble("OPENINGBALANCE"));
        }

        rsOpen.close();
        psOpen.close();


        /* ======================
           CLOSING BALANCE
        ====================== */

        double closingBalance =
        openingBalance + totalCredit - totalDebit;


        /* ======================
           BALANCE IN WORDS
        ====================== */

        String closingBalanceWords =
        numberToWords(closingBalance);
        DecimalFormat df = new DecimalFormat("#,##,##0");
        String formattedBalance = df.format(closingBalance);


        /* ======================
           LOAD JASPER
        ====================== */

        String jasperPath =
        application.getRealPath("/Reports/RecPay.jasper");

        File jasperFile = new File(jasperPath);

        if(!jasperFile.exists()){

            throw new RuntimeException(
            "Jasper file not found : " + jasperPath);
        }

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(jasperFile);


        /* ======================
           PARAMETERS
        ====================== */

        Map<String,Object> parameters =
        new HashMap<String,Object>();

        parameters.put("branch_code",branchCode);
        parameters.put("as_on_date",oracleDate);

        parameters.put("TOTALCREDIT",totalCredit);
        parameters.put("TOTALDEBIT",totalDebit);

        parameters.put("OPENINGBALANCE",openingBalance);
        parameters.put("CLOSINGBALANCE",closingBalance);

        parameters.put("CLOSING_BALANCE_WORDS",closingBalanceWords);
        parameters.put("STR_BALANCE", formattedBalance);

        parameters.put("report_title",
        "CASH RECEIPT AND PAYMENT");

        parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        parameters.put("user_id", "admin");

        parameters.put("IMAGE_PATH",
        application.getRealPath("/images/UPSB MONO.png"));


        /* ======================
           FILL REPORT
        ====================== */

        JasperPrint jasperPrint =
        JasperFillManager.fillReport(
        jasperReport,
        parameters,
        conn);


        /* ======================
           EXPORT PDF
        ====================== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"CashReceiptPayment.pdf\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint,outStream
            );

            outStream.flush();
            outStream.close();

            return;   // VERY IMPORTANT
        }

        /* ======================
           EXPORT EXCEL
        ====================== */

        else if("xls".equalsIgnoreCase(reporttype)){

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"CashReceiptPayment.xls\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream
            );

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }
    catch(Exception e){

        out.println("<h2 style='color:red'>Error Generating Report</h2>");
        out.println("<pre>");

        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);

        out.println(sw.toString());
        out.println("</pre>");
    }
    finally{

        if(conn!=null){

            try{conn.close();}
            catch(Exception ex){}
        }
    }
}
%>

<% if (!"download".equals(action)) { %>

<!DOCTYPE html>
<html>
<head>

<title>CASH RECEIPT AND PAYMENT</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

</head>

<body>

<div class="report-container">

<h1 class="report-title">
CASH RECEIPT AND PAYMENT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/RecPay.jsp"
target="_blank">

<input type="hidden"
name="action"
value="download">

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<input type="text"
name="branch_code"
class="input-field"
value="0001"
required>
</div>

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
class="input-field"
value="<%= (request.getParameter("as_on_date")==null ? "2025-03-29" : request.getParameter("as_on_date")) %>"
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

<button type="submit"
class="download-button">
Generate Report
</button>

</form>

</div>

</body>
</html>
<% } %>