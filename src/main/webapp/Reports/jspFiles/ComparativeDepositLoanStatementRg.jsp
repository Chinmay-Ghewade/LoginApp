<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.InputStream" %>

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
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String reporttype = request.getParameter("reporttype");
    String accType = request.getParameter("account_type");

    if(branchCode == null) branchCode="";
    if(fromDate == null) fromDate="";
    if(toDate == null) toDate="";

    /* ✅ CORRECT DATE FORMAT (MATCHES JASPER) */
    String oracleFromDate="", oracleToDate="";

    try {
        java.util.Date d1 = new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);
        oracleFromDate = new SimpleDateFormat("dd/MM/yyyy").format(d1);

        java.util.Date d2 = new SimpleDateFormat("yyyy-MM-dd").parse(toDate);
        oracleToDate = new SimpleDateFormat("dd/MM/yyyy").format(d2);

    } catch(Exception e){
        out.println("<h3 style='color:red'>Invalid Date</h3>");
        return;
    }

    Connection conn = null;

    try{
        conn = DBConnection.getConnection();

        /* ✅ LOAD JASPER (BEST METHOD) */
        String reportFile = "";

        if("L".equalsIgnoreCase(accType)){
            // Deposit
            reportFile = "/Reports/ComparativeDepositLoanStatementRg.jasper";
        }else{
            // Loan
            reportFile = "/Reports/ComparativeDepositLoanStatementRg(loan account).jasper";
        }

        InputStream reportStream = application.getResourceAsStream(reportFile);

        if(reportStream == null){
            out.println("<h3 style='color:red'>Jasper file not found: " + reportFile + "</h3>");
            return;
        }
        
        if(reportStream == null){
            out.println("<h3 style='color:red'>Jasper file not found</h3>");
            return;
        }

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(reportStream);

        /* ✅ PARAMETERS (MATCH JRXML) */
        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("from_date", oracleFromDate);
        params.put("to_date", oracleToDate);
        params.put("report_title", "Comparative Deposit Loan Statement");
        params.put("as_on_date", oracleToDate);
        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);


        params.put("SUBREPORT_DIR",
        	    application.getRealPath("/Reports/") + File.separator);
        
        /* ✅ JASPER EXECUTION */
        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport, params, conn);

        /* ✅ PDF */
        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition","inline; filename=Report.pdf");

            ServletOutputStream outStream = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jp,outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* ✅ EXCEL */
        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType("application/vnd.ms-excel");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.close();
            return;
        }

    }catch(Exception e){
        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new java.io.PrintWriter(out));
    }finally{
        try{
            if(conn != null) conn.close();
        }catch(Exception ex){}
    }
}
%>

<!DOCTYPE html>
<html>

<head>

<title>Comparative Deposit Loan Statement</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.input-box { display:flex; gap:10px; }

.icon-btn {
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.radio-container {
    display:flex;
    gap:30px;
    margin-top:10px;
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
COMPARATIVE DEPOSIT LOAN STATEMENT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/ComparativeDepositLoanStatementRg.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= BRANCH ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">

<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if("Y".equalsIgnoreCase(isSupportUser.trim())){ %>
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


</div>

<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
name="from_date"
class="input-field"
value="<%=sessionDate%>"  
required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
name="to_date"
class="input-field"
required>
</div>

</div>

<!-- ================= ACCOUNT + REPORT TYPE ================= -->

<div class="parameter-section" style="display:flex; gap:50px;">

<!-- Account Type -->
<div class="parameter-group">

<div class="parameter-label">Account Type</div>

<div class="radio-container">

<label>
<input type="radio" name="account_type" value="L" checked>
Deposit
</label>

<label>
<input type="radio" name="account_type" value="C">
Loan
</label>

</div>

</div>

<!-- Report Type -->
<div class="parameter-group">

<div class="parameter-label">Report Type</div>

<div class="format-options" style="display:flex; gap:20px;">

<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls"> Excel
</div>

</div>

</div>

</div>
<!-- ================= BUTTON ================= -->

<button type="submit"
class="download-button">
Generate Report
</button>

</form>

</div>

<!-- ================= LOOKUP POPUP ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>