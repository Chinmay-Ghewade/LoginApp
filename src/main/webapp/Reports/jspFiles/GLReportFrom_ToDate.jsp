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
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String displayDate = "";

try{

    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(d);

}catch(Exception e){

    displayDate = "";
}


String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>


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
    new SimpleDateFormat("dd/MM/yyyy").parse(fromDate);

    oracleFromDate =
    new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
    .format(d).toUpperCase();
}

if(toDate!=null && !toDate.trim().equals("")){
    java.util.Date d =
    new SimpleDateFormat("dd/MM/yyyy").parse(toDate);

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

/* ✅ USER ID (FIXED) */
String userId = (String) session.getAttribute("userId");
parameters.put("user_id", userId);

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

if (jasperPrint.getPages().isEmpty()) {

    response.reset();
    response.setContentType("text/html");

    out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
    out.println("No Records Found!");
    out.println("</h2>");

    return;
}

}

/* ---------------- CONSOLIDATED REPORT ---------------- */

else{
	
	String condition2 = "";

	if("B".equals(reportSel)){

	    condition2 =
	    " and gl.alie in ('A','L') ";

	}
	else if("P".equals(reportSel)){

	    condition2 =
	    " and gl.alie in ('I','E') ";

	}
	else if("C".equals(reportSel)){

	    condition2 =
	    " and gl.alie in ('A','L','I','E') ";
	}
	
	String condition3 = "";

	if("S".equals(accountSel)
	    && glCode != null
	    && !glCode.trim().equals("")){

	    condition3 =
	        " and op.glaccount_code='"
	        + glCode + "' ";
	}

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
		condition2+
		condition3+
" ) "+
" GROUP BY accountcode,accountname "+
" ORDER BY accountcode";

Statement st2 = conn.createStatement();
ResultSet rs2 = st2.executeQuery(sqlConsolidated);

JRResultSetDataSource jrRS2 = new JRResultSetDataSource(rs2);

parameters.put(JRParameter.REPORT_CONNECTION, conn);

jasperPrint =
JasperFillManager.fillReport(jasperReport,parameters,jrRS2);

//🔥 CHECK IF NO DATA
if (jasperPrint.getPages().isEmpty()) {

    response.reset();
    response.setContentType("text/html");

    out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
    out.println("No Records Found!");
    out.println("</h2>");

    return;
}

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

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>


<style>

.radio-container{
display:flex;
gap:40px;
margin-top:6px;
}

.input-box { display:flex; gap:10px; }

.icon-btn {
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.modal {
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content {
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    padding:20px;
    border-radius:8px;
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
                <div class="input-box">

        <input type="text"
               id="branch_code"
               name="branch_code"
               class="input-field"
               value="<%= sessionBranchCode %>"
               <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %> >

        <% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('branch')">…</button>
        <% } %>

    </div>
            </div>
            
            <div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

<div class="parameter-group">
    <div class="parameter-label">GL Account Code</div>

    <div class="input-box">

        <input type="text"
               id="product_code"
               name="glaccount_code"
               class="input-field"
               placeholder="Select GL Account">

        <!-- 🔥 LOOKUP BUTTON -->
        <button type="button"
                class="icon-btn"
                onclick="openLookup('glByAccountType')">…</button>

    </div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Account Name</div>
    <input type="text" id="productName" class="input-field" readonly>
</div>

<!-- 🔥 IMPORTANT -->
<input type="hidden" id="account_type" name="account_type">

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="text"
name="from_date"
class="input-field"
value="<%= displayDate %>"
placeholder="DD/MM/YYYY" required>

</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="text"
name="to_date"
class="input-field"
placeholder="DD/MM/YYYY"
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

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>