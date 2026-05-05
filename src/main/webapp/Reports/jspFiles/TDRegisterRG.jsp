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

try {
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");

    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    /* 🔒 SECURITY */
    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }
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
    		    new SimpleDateFormat("dd/MM/yyyy").parse(asOnDate);

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
        
        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        parameters.put("user_id", userId);

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(JRParameter.REPORT_CONNECTION,conn);

        /* FILL REPORT */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport,parameters,conn);

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        
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

<title>Consolidated Balance Sheet</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.container{
    width:900px;
    margin:auto;
}

.section{
    background:#f5f5f5;
    padding:20px;
    border-radius:10px;
}

.label{
    font-weight:bold;
    margin-bottom:5px;
}

.input{
    width:100%;
    padding:8px;
}

.row{
    display:flex;
    gap:20px;
    margin-bottom:15px;
}

.btn{
    background:#2D2B80;
    color:white;
    padding:10px 20px;
    border:none;
    border-radius:6px;
    cursor:pointer;
}

.error-box{
    color:red;
    font-weight:bold;
    text-align:center;
    margin-top:10px;
}
</style>

<script>

function validateForm(){
    var date = document.getElementById("as_on_date").value;

    if(date == ""){
        alert("Please enter As On Date");
        return false;
    }
    return true;
}

/* SET REPORT TYPE */
function setReport(val){
    document.getElementById("report_select").value = val;
    document.getElementById("action").value = "download";
    document.forms[0].target = "_blank";
    document.forms[0].submit();

    /* reset */
    document.forms[0].target = "";
    document.getElementById("action").value = "";
}

</script>

</head>

<body>

<div class="container">

<h2 style="text-align:center;">
CONSOLIDATED BALANCE SHEET
</h2>

<form method="post"
      action="ConsolidatedBalancesheet.jsp"
      onsubmit="return validateForm();">

<!-- HIDDEN -->
<input type="hidden" name="action" id="action">
<input type="hidden" name="report_select" id="report_select" value="BS">

<div class="section">

<div class="row">

<div style="flex:1;">
<div class="label">Branch Code</div>

<input type="text"
       id="branch_code"
       name="branch_code"
       class="input"
       value="<%=sessionBranchCode%>"
       readonly>
</div>

<div style="flex:2;">
<div class="label">Branch Name</div>
<input type="text"
       id="branchName"
       class="input"
       readonly>
</div>

</div>

<div class="row">

<div style="flex:1;">
<div class="label">As On Date</div>

<input type="text"
       id="as_on_date"
       name="as_on_date"
       class="input"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY">
</div>

<div style="flex:1;">
<div class="label">Select</div>

<label>
<input type="radio" name="regularclosing" value="R" checked> Regular
</label>

<label>
<input type="radio" name="regularclosing" value="C"> Closing
</label>

</div>

</div>

</div>

<!-- REPORT TYPE -->

<div class="section" style="margin-top:10px;">

<div class="label">Report Format</div>

<label>
<input type="radio" name="reporttype" value="pdf" checked> PDF
</label>

<label>
<input type="radio" name="reporttype" value="xls"> Excel
</label>

</div>

<!-- ERROR -->

<div class="error-box">
<%= session.getAttribute("errorMessage") != null ? session.getAttribute("errorMessage") : "" %>
</div>

<br>

<div style="text-align:center; display:flex; gap:10px; justify-content:center;">

<button type="submit" name="action" value="validate" class="btn">
Validate
</button>

<button type="submit" name="action" value="generate" class="btn">
Generate Records
</button>

<button type="button"
        onclick="setReport('BS')"
        class="btn">
Balance Sheet
</button>

<button type="button"
        onclick="setReport('PL')"
        class="btn">
P & L
</button>

<button type="submit" name="action" value="cancel" class="btn">
Cancel
</button>

</div>

</form>

</div>

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>