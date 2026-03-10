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

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String productCode= request.getParameter("product_code");
    String singleAll  = request.getParameter("single_all");

    if(productCode == null) productCode = "";
    productCode = productCode.trim();

    /* save original product code for report selection */
    String originalProductCode = productCode;
    		
    if("S".equals(singleAll) && productCode.equals("")){
        out.println("<h3 style='color:red'>Please enter Product Code</h3>");
        return;
    }

    /* SINGLE / ALL LOGIC */

    if("A".equals(singleAll)){
        productCode = "";   // ignore product code for ALL
    }

    /* DATE FORMAT FIX */

    if(fromDate != null && !fromDate.trim().equals("")){
        java.util.Date fd =
            new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);

        fromDate =
            new SimpleDateFormat("dd-MMM-yyyy", java.util.Locale.ENGLISH)
            .format(fd).toUpperCase();
    }

    if(toDate != null && !toDate.trim().equals("")){
        java.util.Date td =
            new SimpleDateFormat("yyyy-MM-dd").parse(toDate);

        toDate =
            new SimpleDateFormat("dd-MMM-yyyy", java.util.Locale.ENGLISH)
            .format(td).toUpperCase();
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =====================================
           REPORT SELECTION LOGIC
        ===================================== */

        String reportFile;

        // SINGLE PRODUCT
        if("S".equals(singleAll) && "601".equals(originalProductCode)){
            reportFile = "DepositMature2DateRG_Pigmy.jasper";
        }
        else{
            reportFile = "DepositMature2DateRG.jasper";
        }

        String jasperPath =
            application.getRealPath("/Reports/" + reportFile);

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* =====================================
        PARAMETERS
     ===================================== */

    		 Map<String,Object> parameters = new HashMap<>();

  // ADD THIS LINE
  String asOnDate = new SimpleDateFormat("dd/MM/yyyy").format(new java.util.Date());

  parameters.put("as_on_date", asOnDate);

  parameters.put("branch_code", branchCode);
  parameters.put("from_date", fromDate);
  parameters.put("to_date", toDate);
  parameters.put("product_code", productCode);
  parameters.put("single_all", singleAll);
        
        parameters.put("report_title",
            "DEPOSIT MATURE BUT NOT PAID");

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        String userId = (String) session.getAttribute("user_id");

        if(userId == null || userId.trim().equals("")){
            userId = "admin";
        }

        parameters.put("user_id", userId);

        parameters.put("IMAGE_PATH",
            application.getRealPath("/images/UPSB MONO.png"));

        /* =====================================
           FILL REPORT
        ===================================== */

        String sql = "";

        if("S".equals(singleAll) && "601".equals(originalProductCode)){

            /* PIGMY SQL */

            sql =
            "select ROWNUM AS SRNO, a.account_code , a.name , " +
            "to_char(A.DATEACCOUNTOPEN,'dd/mm/yyyy') ACCOUNTOPEN_D, " +
            "to_char(P.MATURITYDATE,'dd/mm/yyyy') MATURITY_D, " +
            "P.INSTALLMENTAMOUNT , P.UNITOFPERIOD ,P.PERIODOFDEPOSIT ,P.INTERESTRATE , " +
            "to_char(A.DATEACCOUNTCLOSE,'DD/MM/YYYY') AS C " +
            "from account.account a , account.accountpigmy p " +
            "where A.ACCOUNT_CODE=P.ACCOUNT_CODE " +
            "and substr(a.account_code,1,4)=? " +
            "and P.MATURITYDATE between ? and ? ";

        }else{

            /* NORMAL DEPOSIT SQL */

            sql =
            "SELECT ROWNUM AS SRNO, ACCOUNT_CODE, PRODUCT_CODE, MATURITYVALUE, DESCRIPTION, NAME, INTERESTRATE, " +
            "DEPOSITAMOUNT, UNITOFPERIOD, PERIODOFDEPOSIT, B, PROCESSFOR_MATURITY, A, C, LEDGERBALANCE, INTERESTPAID, INT, AMOUNT " +
            "FROM ( SELECT B.ACCOUNT_CODE, SUBSTR(B.ACCOUNT_CODE,5,3) AS PRODUCT_CODE, " +
            "B.MATURITYVALUE, K.DESCRIPTION, INITCAP(A.NAME) AS NAME, B.INTERESTRATE, " +
            "B.DEPOSITAMOUNT, B.UNITOFPERIOD, B.PERIODOFDEPOSIT, " +
            "TO_CHAR(B.MATURITYDATE,'DD/MM/YYYY') AS B, B.PROCESSFOR_MATURITY, " +
            "TO_CHAR(A.DATEACCOUNTOPEN,'DD/MM/YYYY') AS A, " +
            "TO_CHAR(A.DATEACCOUNTCLOSE,'DD/MM/YYYY') AS C, " +
            "C.LEDGERBALANCE, INTERESTPAID, '' AS INT, 0 AS AMOUNT " +
            "FROM ACCOUNT.ACCOUNTDEPOSIT B, ACCOUNT.ACCOUNT A, BALANCE.ACCOUNT C, HEADOFFICE.PRODUCT K " +
            "WHERE B.ACCOUNT_CODE = A.ACCOUNT_CODE " +
            "AND B.ACCOUNT_CODE = C.ACCOUNT_CODE " +
            "AND SUBSTR(B.ACCOUNT_CODE,5,3)= K.PRODUCT_CODE " +
            "AND SUBSTR(B.ACCOUNT_CODE,1,4) = ? " +
            "AND B.MATURITYDATE BETWEEN ? AND ? ";

            if("S".equals(singleAll) && !productCode.equals("")){
                sql += " AND SUBSTR(B.ACCOUNT_CODE,5,3) = ? ";
            }

            sql += " ORDER BY B.ACCOUNT_CODE ) ORDER BY SRNO";
        }
        		PreparedStatement ps = conn.prepareStatement(sql);

        		ps.setString(1, branchCode);
        		ps.setDate(2, java.sql.Date.valueOf(
        		        new SimpleDateFormat("yyyy-MM-dd").parse(request.getParameter("from_date")).toInstant().toString().substring(0,10)));
        		ps.setDate(3, java.sql.Date.valueOf(
        		        new SimpleDateFormat("yyyy-MM-dd").parse(request.getParameter("to_date")).toInstant().toString().substring(0,10)));

        		if(!("S".equals(singleAll) && "601".equals(originalProductCode))){
        		    if("S".equals(singleAll) && !productCode.equals("")){
        		        ps.setString(4, productCode);
        		    }
        		}

        		ResultSet rs = ps.executeQuery();

        		JRResultSetDataSource jrds = new JRResultSetDataSource(rs);

        		/* pass DB connection so subreports can run */
        		parameters.put(JRParameter.REPORT_CONNECTION, conn);

        		JasperPrint jasperPrint =
        		        JasperFillManager.fillReport(jasperReport, parameters, jrds);
        /* =====================================
           EXPORT PDF
        ===================================== */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"DepositMatureReport.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* =====================================
           EXPORT EXCEL
        ===================================== */

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"DepositMatureReport.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

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

        response.setContentType("text/html");

        out.println("<h2 style='color:red'>Error Generating Report</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");

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

<title>Deposit Mature But Not Paid</title>

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/Reports/common-report.css?v=10">

<style>
.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}
</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
DEPOSIT MATURE BUT NOT PAID
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositMature2DateRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch Code -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<input type="text"
       name="branch_code"
       class="input-field"
       value="0002"
       required>
</div>


<!-- Product Code -->
<div class="parameter-group">
<div class="parameter-label">Product Code</div>

<input type="text"
       name="product_code"
       class="input-field"
       placeholder="Enter Product Code">

<!-- Radio Buttons moved below -->
<div class="radio-container">

<label>
<input type="radio"
       name="single_all"
       value="S"
       onclick="toggleProduct()"
       checked>
Single
</label>

<label>
<input type="radio"
       name="single_all"
       value="A"
       onclick="toggleProduct()">
All
</label>

</div>

</div>


<!-- From Date -->
<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
       name="from_date"
       class="input-field"
       value="2008-08-25"
       required>
</div>


<!-- To Date -->
<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
       name="to_date"
       class="input-field"
       value="2009-09-25"
       required>
</div>

</div>


<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked>
PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls">
Excel
</div>

</div>

</div>


<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>


<script>

function toggleProduct() {

    var single =
      document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
      document.querySelector('input[name="product_code"]');

    if (single) {
        productField.disabled = false;
        productField.readOnly = false;
    } else {
        productField.value = "";
        productField.disabled = true;
        productField.readOnly = true;
    }
}

window.onload = function(){
    toggleProduct();
}

</script>

</body>
</html>