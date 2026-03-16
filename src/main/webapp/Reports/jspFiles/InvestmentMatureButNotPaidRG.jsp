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

if ("download".equals(action)) {


String reportType  = request.getParameter("reporttype");
String reportMode  = request.getParameter("report_mode");

String branchCode  = request.getParameter("branch_code");
String productCode = request.getParameter("product_code");
String asOnDate    = request.getParameter("as_on_date");

Connection conn = null;

try {

    conn = DBConnection.getConnection();

    SimpleDateFormat input  = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat oracle = new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH);

    String oracleDate = oracle.format(input.parse(asOnDate)).toUpperCase();

    String jasperFile;

    if("SUMMARY".equalsIgnoreCase(reportMode)){
        jasperFile="InvestmentMatureButNotPaidRG(summary).jasper";
    }else{
        jasperFile="InvestmentMatureButNotPaidRG.jasper";
    }

    String jasperPath = application.getRealPath("/Reports/"+jasperFile);

    File file = new File(jasperPath);

    if(!file.exists()){
        throw new RuntimeException("Jasper file not found : "+jasperPath);
    }

    JasperReport report = (JasperReport)JRLoader.loadObject(file);

    Map<String,Object> param = new HashMap<String,Object>();

    param.put("branch_code",branchCode);
    param.put("product_code",productCode);
    param.put("as_on_date",oracleDate);

    String userId = (String)session.getAttribute("user_id");
    if(userId==null || userId.trim().equals(""))
        userId="admin";

    param.put("user_id",userId);
    param.put("SUBREPORT_DIR",application.getRealPath("/Reports/"));

    JasperPrint print = JasperFillManager.fillReport(report,param,conn);

    if("pdf".equalsIgnoreCase(reportType)){

        response.reset();
        response.setContentType("application/pdf");

        response.setHeader(
        "Content-Disposition",
        "inline; filename=\"InvestmentMatureButNotPaidRG.pdf\"");

        ServletOutputStream outStream = response.getOutputStream();

        JasperExportManager.exportReportToPdfStream(print,outStream);

        outStream.flush();
        outStream.close();
        return;
    }

    if("xls".equalsIgnoreCase(reportType)){

        response.reset();
        response.setContentType("application/vnd.ms-excel");

        response.setHeader(
        "Content-Disposition",
        "attachment; filename=\"InvestmentMatureButNotPaidRG.xls\"");

        ServletOutputStream outStream = response.getOutputStream();

        JRXlsExporter exporter = new JRXlsExporter();

        exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT,print);
        exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM,outStream);
        exporter.setParameter(JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET,false);
        exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS,true);

        exporter.exportReport();

        outStream.flush();
        outStream.close();
        return;
    }

}
catch(Exception e){

    response.setContentType("text/html");

    out.println("<h2 style='color:red'>Error Generating Report</h2>");
    out.println("<pre>");
    e.printStackTrace(new PrintWriter(out));
    out.println("</pre>");

    return;
}
finally{
    if(conn!=null){
        try{conn.close();}catch(Exception ignored){}
    }
}


}
%>

<!DOCTYPE html>

<html>

<head>

<title>Investment Mature But Not Paid</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

</head>

<body>

<div class="report-container">

<h1 class="report-title">
INVESTMENT MATURE BUT NOT PAID
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/InvestmentMatureButNotPaidRG.jsp"
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

<div class="parameter-label">Product Code</div>

<input type="text"
name="product_code"
class="input-field">

</div>

</div>

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
class="input-field"
required>

</div>

<div class="parameter-group">

<div class="parameter-label">Report Mode</div>

<div class="format-options">

<div class="format-option">

<input type="radio"
name="report_mode"
value="DETAILS"
checked>

Details

</div>

<div class="format-option">

<input type="radio"
name="report_mode"
value="SUMMARY">

Summary

</div>

</div>

</div>

</div>

<div class="format-section">

<div class="parameter-label">
Report Format
</div>

<div class="format-options">

<div class="format-option">

<input type="radio"
name="reporttype"
value="pdf"
checked>

PDF

</div>

<div class="format-option">

<input type="radio"
name="reporttype"
value="xls">

Excel

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
