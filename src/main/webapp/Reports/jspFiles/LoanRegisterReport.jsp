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
String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if (sessionBranchCode == null) sessionBranchCode = "";
if (isSupportUser == null) isSupportUser = "N";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reportType  = request.getParameter("reporttype");

    String branchCode = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String radioValue = request.getParameter("all_products");
    
    if(productCode == null) productCode = "";
    productCode = productCode.trim();

    /* VALIDATION */
    if("S".equalsIgnoreCase(radioValue) && productCode.equals("")){
        out.println("<h3 style='color:red'>Please enter Product Code</h3>");
        return;
    }

    /* IMPORTANT FIX (LIKE REFERENCE JSP) */
    boolean isAll = "A".equalsIgnoreCase(radioValue);

    if(!isAll){
        if(productCode.equals("")){
            out.println("<h3 style='color:red'>Please enter Product Code</h3>");
            return;
        }
    }
    String openClose  = request.getParameter("open_close");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    
    /* ================= SESSION SECURITY ================= */
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    Connection conn = null;

    try {

        /* ================= RESPONSE RESET ================= */
        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= DATE FORMAT ================= */
        String oracleFrom = "";
        String oracleTo   = "";

        if (fromDate != null && !fromDate.trim().isEmpty()) {

            java.util.Date d1 =
                new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);

            oracleFrom =
                new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(d1).toUpperCase();
        }

        if (toDate != null && !toDate.trim().isEmpty()) {

            java.util.Date d2 =
                new SimpleDateFormat("yyyy-MM-dd").parse(toDate);

            oracleTo =
                new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(d2).toUpperCase();
        }

        /* ================= SELECT JASPER ================= */
        String jasperFileName = "";

        if ("O".equalsIgnoreCase(openClose)) {
            jasperFileName = "LoanRegisterReport.jasper";   // OPEN
        } 
        else if ("C".equalsIgnoreCase(openClose)) {
            jasperFileName = "LoanRegisterReport(close).jasper"; // CLOSE
        } 
        else {
            jasperFileName = "LoanRegisterReport.jasper"; // DEFAULT
        }

        String jasperPath =
            application.getRealPath("/Reports/" + jasperFileName);

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        if(isAll){
            parameters.put("product_code", "");   // ✅ EMPTY STRING
        }else{
            parameters.put("product_code", productCode);
        }
        parameters.put("radio_value", radioValue);
        parameters.put("as_on_date", oracleFrom);
        parameters.put("to_date", oracleTo);

        parameters.put("report_title", "LOAN REGISTER REPORT");

        /* USER ID */
        String userId = (String) session.getAttribute("userId");
        parameters.put("user_id", userId);

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(JRParameter.REPORT_CONNECTION, conn);

        /* ================= FILL REPORT ================= */
        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* ================= NO DATA ================= */
        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= EXPORT ================= */

        /* PDF */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Loan_Register_Report.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* EXCEL */
        else if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Loan_Register_Report.xls\"");

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

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new PrintWriter(out));

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

<title>Loan Register Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

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

.error{
    color:red;
    text-align:center;
    margin-top:10px;
    font-weight:bold;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">LOAN REGISTER REPORT</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/LoanRegisterReport.jsp"
      target="_blank"
      onsubmit="return validateForm()"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->
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

<!-- ================= PRODUCT ================= -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
<input type="text"
       name="product_code"
       id="product_code"
       class="input-field"
       placeholder="Enter Product Code">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">…</button>
</div>

<div class="radio-container">

<label>
<input type="radio"
       name="all_products"
       value="S"
       checked
       onclick="toggleProduct()"> Single
</label>

<label>
<input type="radio"
       name="all_products"
       value="A"
       onclick="toggleProduct()"> All
</label>

</div>

</div>


<!-- ================= DATE RANGE ================= -->
<div class="parameter-group">

<div class="parameter-label">From Date</div>

<input type="date"
       name="from_date"
       id="from_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

<div class="parameter-group">

<div class="parameter-label">To Date</div>

<input type="date"
       name="to_date"
       id="to_date"
       class="input-field"
       required>

</div>

</div>

<!-- ================= REPORT + ACCOUNT TYPE (SIDE BY SIDE) ================= -->
<div class="parameter-section" style="display:flex; gap:40px;">

    <!-- REPORT TYPE -->
    <div class="parameter-group">

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

    <!-- ACCOUNT TYPE -->
    <div class="parameter-group">

        <div class="parameter-label">Account Type</div>

        <div class="radio-container">

            <label>
                <input type="radio"
                       name="open_close"
                       value="O"
                       checked> Open
            </label>

            <label>
                <input type="radio"
                       name="open_close"
                       value="C"> Close
            </label>

        </div>

    </div>

</div>
<!-- ERROR -->
<div id="errorBox" class="error"></div>

<!-- BUTTON -->
<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- LOOKUP MODAL -->
<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

<script>

/* PRODUCT ENABLE/DISABLE */
function toggleProduct(){

    var single =
        document.querySelector('input[name="all_products"]:checked').value === "S";

    var productField =
        document.getElementById("product_code");

    if(single){
        productField.disabled = false;
        productField.readOnly = false;
    }else{
        productField.value = "";
        productField.disabled = true;
        productField.readOnly = true;
    }
}

/* VALIDATION */
function validateForm(){

    var errorBox = document.getElementById("errorBox");
    errorBox.innerHTML = "";

    var type =
        document.querySelector('input[name="all_products"]:checked').value;

    var product =
        document.getElementById("product_code").value.trim();

    var from =
        document.getElementById("from_date").value;

    var to =
        document.getElementById("to_date").value;

    if(type === "S" && product === ""){
        errorBox.innerHTML = "Enter Product Code!!!";
        return false;
    }

    if(from === ""){
        errorBox.innerHTML = "Enter From Date!!!";
        return false;
    }

    if(to === ""){
        errorBox.innerHTML = "Enter To Date!!!";
        return false;
    }

    if(new Date(from) > new Date(to)){
        errorBox.innerHTML = "From date must be <= To Date!!!";
        return false;
    }

    return true;
}

/* INIT */
window.onload = function(){
    toggleProduct();
}

</script>

</body>
</html>