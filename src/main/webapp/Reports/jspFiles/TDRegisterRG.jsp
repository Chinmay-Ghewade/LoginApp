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
    String productCode = request.getParameter("product_code");
    String singleAll   = request.getParameter("single_all");
    String asOnDate    = request.getParameter("as_on_date");

    if(productCode == null) productCode="";
    productCode = productCode.trim();

    /* VALIDATION */

    if("S".equals(singleAll) && productCode.equals("")){
        out.println("<h3 style='color:red'>Please enter Product Code</h3>");
        return;
    }

    /* DATE FORMAT */

    String oracleDateStr="";

    if(asOnDate!=null && !asOnDate.trim().equals("")){

        java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDateStr =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d).toUpperCase();
    }

    /* FINAL PRODUCT CODE */

    String finalProductCode="";

    if("A".equals(singleAll)){
        finalProductCode = branchCode + "4%";
    }else{
        finalProductCode = branchCode + productCode + "%";
    }

    Connection conn=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* LOAD REPORT */

        String jasperPath =
        application.getRealPath("/Reports/TDRegisterRG.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* PARAMETERS */

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("branch_code",branchCode);
        parameters.put("as_on_date",oracleDateStr);
        parameters.put("report_title","TERM DEPOSIT REGISTER");
        parameters.put("finalProductCode",finalProductCode);

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(JRParameter.REPORT_CONNECTION,conn);

        /* FILL REPORT */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport,parameters,conn);

        /* EXPORT */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"TD_Register_Report.pdf\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
            jasperPrint,outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"TD_Register_Report.xls\"");

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

    }catch(Exception e){

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new PrintWriter(out));

    }finally{

        if(conn!=null){
            try{conn.close();}catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Term Deposit Register</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">

<style>

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
    cursor:not-allowed;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
TERM DEPOSIT REGISTER
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/TDRegisterRG.jsp"
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


<!-- As On Date -->

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())%>"
       required>

</div>

</div>


<div class="format-section">

<div class="parameter-label">Report Type</div>

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


<script>

function toggleProduct(){

    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
        document.querySelector('input[name="product_code"]');

    if(single){

        productField.disabled = false;
        productField.readOnly = false;

    }else{

        productField.value="";
        productField.disabled = true;
        productField.readOnly = true;

    }
}

window.onload=function(){
    toggleProduct();
}

</script>

</body>
</html>