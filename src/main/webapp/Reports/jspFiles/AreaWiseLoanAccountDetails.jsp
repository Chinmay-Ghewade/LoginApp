<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>

<%
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";

String action = request.getParameter("action");
%>

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
%>

<%
if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");

    /* 🔒 DEFAULT + SECURITY */
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    String productCode = request.getParameter("product_code");
    String areaCode    = request.getParameter("area_code");
    String asOnDate    = request.getParameter("as_on_date");

    String p_amt   = request.getParameter("principle_amount_0");
    String p_due   = request.getParameter("principle_due_0");
    String i_due   = request.getParameter("interest_due_0");
    String inst_due= request.getParameter("installment_due_0");
    String net_due = request.getParameter("netloan_due_0");

    if(productCode == null) productCode = "";
    if(areaCode == null) areaCode = "";

    /* 📅 DATE FORMAT */
    String oracleDate = "";

    if (asOnDate != null && !asOnDate.trim().isEmpty()) {
        java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(d).toUpperCase();
    }

    Connection conn = null;

    try {

        /* ⚡ IMPORTANT */
        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* 📄 LOAD REPORT */
        String jasperPath =
        application.getRealPath("/Reports/AreaWiseLoanAccountDetails.jasper");

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* 📌 PARAMETERS */
        Map<String, Object> param = new HashMap<>();

        param.put("branch_code", branchCode);
        param.put("area_code", areaCode);
        param.put("as_on_date", oracleDate);
        param.put("user_id", userId);

        param.put("principle_amount", p_amt);
        param.put("principle_due", p_due);
        param.put("interest_due", i_due);
        param.put("installment_due", inst_due);
        param.put("netloan_due", net_due);

        param.put(JRParameter.REPORT_CONNECTION, conn);

        /* 🧾 FILL REPORT */
        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport, param, conn);

        /* ❌ NO DATA */
       if (jp.getPages().isEmpty()) {

    response.reset();
    response.setContentType("text/html");

    out.println("<html><body>");
    out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
    out.println("No Records Found!");
    out.println("</h2>");
    out.println("</body></html>");

    return; // 🔥 VERY IMPORTANT (stops form rendering)
}

        /* 📤 EXPORT */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"AreaWiseLoanReport.pdf\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"AreaWiseLoanReport.xls\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT, jp);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }catch(Exception e){

        e.printStackTrace();

        Throwable cause = e;

        while(cause.getCause() != null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg != null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute(
            "errorMessage",
            "Error Message = " + msg
        );

        response.sendRedirect("AreaWiseLoanAccountDetails.jsp");
        return;
   
    } finally {

        if (conn != null) {
            try { conn.close(); } catch (Exception ex) {}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Area Wise Loan Account Details</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js?V=1"></script>

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

<%
String errorMessage = (String)session.getAttribute("errorMessage");

if(errorMessage != null){
%>

<div class="error-message">
    <%= errorMessage %>
</div>

<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">
AREA WISE LOAN ACCOUNT DETAILS
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/AreaWiseLoanAccountDetails.jsp"
target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- 🔹 BRANCH -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
    <input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
       required>

   <% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<!-- 🔹 BRANCH NAME -->
<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- 🔥 AREA CODE -->
<div class="parameter-group">

<div class="parameter-label">Area Code</div>

<div class="input-box">

<input type="text"
       name="area_code"
       id="area_code"
       class="input-field"
       required>

<button type="button"
onclick="openLookup('area')"
class="icon-btn">…</button>

</div>
</div>

<!-- 🔥 AREA NAME -->
<div class="parameter-group">
<div class="parameter-label">Area Name</div>
<input type="text" id="areaName" class="input-field" readonly>
</div>

<!-- 🔹 PRODUCT -->
<div class="parameter-group">
<div class="parameter-label">Product Code</div>

<div class="input-box">
<input type="text"
       name="product_code"
       id="product_code"
       class="input-field">

<button type="button"
onclick="openLookup('product')"
class="icon-btn">…</button>
</div>
</div>

<!-- DATE -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="date" name="as_on_date" class="input-field"  value="<%=sessionDate%>"  required>
</div>

<!-- AMOUNT -->
<!-- 🔥 PRINCIPLE AMOUNT -->
<div class="parameter-group">
<div class="parameter-label">Principle Amount</div>
<input type="number" name="principle_amount_0" id="principle_amount_0"
       class="input-field"
       onblur="isNumericValueCheck()">
</div>

<!-- 🔥 PRINCIPLE DUE -->
<div class="parameter-group">
<div class="parameter-label">Principle Due</div>
<input type="number" name="principle_due_0" id="principle_due_0"
       class="input-field"
       onblur="isNumericPrincipleDue()">
</div>

<!-- 🔥 INTEREST DUE -->
<div class="parameter-group">
<div class="parameter-label">Interest Due</div>
<input type="number" name="interest_due_0" id="interest_due_0"
       class="input-field"
       onblur="isNumericInterestDue()">
</div>

<!-- 🔥 INSTALLMENT DUE -->
<div class="parameter-group">
<div class="parameter-label">Installment Due</div>
<input type="number" name="installment_due_0" id="installment_due_0"
       class="input-field"
       onblur="isNumericInstallmentDue()">
</div>

<!-- 🔥 NET LOAN DUE -->
<div class="parameter-group">
<div class="parameter-label">Net Loan Due</div>
<input type="number" name="netloan_due_0" id="netloan_due_0"
       class="input-field"
       onblur="isNumericNetloanDue()">
</div>

</div>

<!-- REPORT TYPE -->
<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls"> Excel
</div>

</div>

</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- 🔥 LOOKUP MODAL -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>
function isNumericValueCheck(){
    let val = document.getElementById("principle_amount_0");
    if(isNaN(val.value)){ val.value=0; alert("Numeric only"); }
}

function isNumericPrincipleDue(){
    let val = document.getElementById("principle_due_0");
    if(isNaN(val.value)){ val.value=0; alert("Numeric only"); }
}

function isNumericInterestDue(){
    let val = document.getElementById("interest_due_0");
    if(isNaN(val.value)){ val.value=0; alert("Numeric only"); }
}

function isNumericInstallmentDue(){
    let val = document.getElementById("installment_due_0");
    if(isNaN(val.value)){ val.value=0; alert("Numeric only"); }
}

function isNumericNetloanDue(){
    let val = document.getElementById("netloan_due_0");
    if(isNaN(val.value)){ val.value=0; alert("Numeric only"); }
}
</script>

</body>
</html>