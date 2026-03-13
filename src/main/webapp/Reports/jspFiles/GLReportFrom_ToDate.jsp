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

if("download".equals(action) || "consolidated".equals(action)){

String reporttype   = request.getParameter("reporttype");
String branchCode   = request.getParameter("branch_code");
String fromDate     = request.getParameter("from_date");
String toDate       = request.getParameter("to_date");
String glCode       = request.getParameter("glaccount_code");
String accountSel   = request.getParameter("account_select");
String reportSel    = request.getParameter("report_select");

Connection conn = null;

try{

response.reset();
response.setBufferSize(1024*1024);

conn = DBConnection.getConnection();

/* DATE FORMAT */

String oracleFromDate="";
String oracleToDate="";

if(fromDate!=null && !fromDate.trim().equals("")){
    java.util.Date d =
    new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);

    oracleFromDate =
    new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
    .format(d).toUpperCase();
}

if(toDate!=null && !toDate.trim().equals("")){
    java.util.Date d =
    new SimpleDateFormat("yyyy-MM-dd").parse(toDate);

    oracleToDate =
    new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
    .format(d).toUpperCase();
}

/* LOAD REPORT */

String jasperPath="";

if("consolidated".equals(action)){
    jasperPath = application.getRealPath("/Reports/Consolidated.jasper");
}else{
    jasperPath = application.getRealPath("/Reports/GLReportFrom_ToDate.jasper");
}

JasperReport jasperReport =
(JasperReport)JRLoader.loadObject(new File(jasperPath));

/* PARAMETERS */

Map<String,Object> parameters = new HashMap<>();

parameters.put("branch_code",branchCode);
parameters.put("as_on_date",oracleFromDate);
parameters.put("glaccount_code",glCode);
parameters.put("account_select",accountSel);
parameters.put("report_select",reportSel);

parameters.put("report_title","GL BALANCE REPORT");

parameters.put("SUBREPORT_DIR",
application.getRealPath("/Reports/"));

String userId=(String)session.getAttribute("user_id");

if(userId==null || userId.trim().equals("")){
userId="admin";
}

parameters.put("user_id",userId);

parameters.put("IMAGE_PATH",
application.getRealPath("/images/UPSB MONO.png"));

JasperPrint jasperPrint = null;

/* ---------------- NORMAL REPORT ---------------- */

if("download".equals(action)){

String condition = "";
String condition1 = "";

if("S".equals(accountSel) && glCode!=null && !glCode.trim().equals("")){
    condition = " and glaccount_code='"+glCode+"' ";
}

if("B".equals(reportSel)){
    condition1=" and gl.alie in ('A','L')";
}
else if("P".equals(reportSel)){
    condition1=" and gl.alie in ('I','E')";
}

String sql =
" SELECT ROWNUM SERIALNUMBER,ACCOUNTCODE,ACCOUNTNAME,OPENBALANCE,TOTALDEBIT,TOTALCREDIT,CLOSINGBALANCE "+
" FROM (SELECT op.glaccount_code ACCOUNTCODE,gl.description ACCOUNTNAME,op.openingbalance OPENBALANCE, "+
" bet.total_debit TOTALDEBIT,bet.total_credit TOTALCREDIT, "+
" (op.openingbalance-bet.total_debit+bet.total_credit) CLOSINGBALANCE "+
" FROM "+
" (SELECT openingbalance,glaccount_code "+
" FROM balance.branchglhistory "+
" WHERE txn_date='"+oracleFromDate+"' "+
" and branch_code='"+branchCode+"' "+condition+") op ,"+
" (SELECT (sum(debitcash)+sum(debitclearing)+sum(debittransfer)) total_debit, "+
" (sum(creditcash)+sum(creditclearing)+sum(credittransfer)) total_credit, "+
" glaccount_code "+
" FROM balance.branchglhistory "+
" WHERE txn_date BETWEEN '"+oracleFromDate+"' and '"+oracleToDate+"' "+
" and branch_code='"+branchCode+"' "+condition+
" group by glaccount_code) bet,headoffice.glaccount gl "+
" where op.glaccount_code=bet.glaccount_code "+
" and op.glaccount_code=gl.glaccount_code "+
condition1+
" ORDER BY op.glaccount_code)";

Statement st = conn.createStatement(
ResultSet.TYPE_SCROLL_INSENSITIVE,
ResultSet.CONCUR_READ_ONLY);

ResultSet rs = st.executeQuery(sql);

JRResultSetDataSource jrRS = new JRResultSetDataSource(rs);

parameters.put(JRParameter.REPORT_CONNECTION, conn);

jasperPrint =
JasperFillManager.fillReport(jasperReport,parameters,jrRS);

}

/* ---------------- CONSOLIDATED REPORT ---------------- */

else{

String sqlConsolidated =
" SELECT accountcode account_code, accountname description, "+
" SUM(openbalance) op_balance, "+
" SUM(totaldebit) tot_debit, "+
" SUM(totalcredit) tot_credit, "+
" SUM(openbalance-totaldebit+totalcredit) closingbalance "+
" FROM ( "+
" SELECT op.glaccount_code accountcode, "+
" gl.description accountname, "+
" op.openingbalance openbalance, "+
" bet.total_debit totaldebit, "+
" bet.total_credit totalcredit "+
" FROM "+
" (SELECT openingbalance, glaccount_code "+
" FROM balance.branchglhistory "+
" WHERE txn_date='"+oracleFromDate+"' ) op, "+
" (SELECT SUM(debitcash+debitclearing+debittransfer) total_debit, "+
" SUM(creditcash+creditclearing+credittransfer) total_credit, "+
" glaccount_code "+
" FROM balance.branchglhistory "+
" WHERE txn_date BETWEEN '"+oracleFromDate+"' AND '"+oracleToDate+"' "+
" GROUP BY glaccount_code) bet, "+
" headoffice.glaccount gl "+
" WHERE op.glaccount_code=bet.glaccount_code "+
" AND op.glaccount_code=gl.glaccount_code "+
" ) "+
" GROUP BY accountcode,accountname "+
" ORDER BY accountcode";

Statement st2 = conn.createStatement();
ResultSet rs2 = st2.executeQuery(sqlConsolidated);

JRResultSetDataSource jrRS2 = new JRResultSetDataSource(rs2);

parameters.put(JRParameter.REPORT_CONNECTION, conn);

jasperPrint =
JasperFillManager.fillReport(jasperReport,parameters,jrRS2);

}

/* EXPORT PDF */

if("pdf".equalsIgnoreCase(reporttype)){

response.setContentType("application/pdf");

response.setHeader(
"Content-Disposition",
"inline; filename=GL_Balance_Report.pdf");

ServletOutputStream outStream =
response.getOutputStream();

JasperExportManager.exportReportToPdfStream(
jasperPrint,outStream);

outStream.flush();
outStream.close();

return;
}

/* EXPORT EXCEL */

else if("xls".equalsIgnoreCase(reporttype)){

response.setContentType("application/vnd.ms-excel");

response.setHeader(
"Content-Disposition",
"attachment; filename=GL_Balance_Report.xls");

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

}
catch(Exception e){

response.reset();
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

<title>GL Balance Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<style>

.radio-container{
display:flex;
gap:40px;
margin-top:6px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
GL BALANCE REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/GLReportFrom_ToDate.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download" id="actionType"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<input type="text"
name="branch_code"
class="input-field"
value="<%= session.getAttribute("branch_code")!=null ? session.getAttribute("branch_code") : "0002" %>"
required>

</div>

<div class="parameter-group">
<div class="parameter-label">GL Account Code</div>

<input type="text"
name="glaccount_code"
class="input-field"
value="00000000101143"
placeholder="Optional">

</div>

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
name="from_date"
class="input-field"
value="2025-03-29"
required>

</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
name="to_date"
class="input-field"
value="2025-03-29"
required>

</div>

</div>

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">
Account Select
</div>

<div class="radio-container">

<label>
<input type="radio"
name="account_select"
value="S"
checked> Single
</label>

<label>
<input type="radio"
name="account_select"
value="L"> All
</label>

</div>

</div>

<div class="parameter-group">

<div class="parameter-label">
Report Select
</div>

<div class="radio-container">

<label>
<input type="radio"
name="report_select"
value="A"
checked> All
</label>

<label>
<input type="radio"
name="report_select"
value="B"> BS
</label>

<label>
<input type="radio"
name="report_select"
value="P"> PL
</label>

<label>
<input type="radio"
name="report_select"
value="C"> Closing
</label>

</div>

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

<div style="display:flex;gap:15px;margin-top:20px;">

<button type="submit"
class="download-button"
onclick="document.getElementById('actionType').value='download'">
Generate Report
</button>

<button type="submit"
class="download-button"
onclick="document.getElementById('actionType').value='consolidated'">
Consolidated Report
</button>

</div>

</form>

</div>

</body>
</html>