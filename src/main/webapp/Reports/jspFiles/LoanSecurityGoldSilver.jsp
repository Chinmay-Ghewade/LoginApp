<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.text.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
String sessionBranchCode = (String) session.getAttribute("branchCode");
if(sessionBranchCode == null) sessionBranchCode = "";

/* =========================
SESSION DATE LOGIC
========================= */
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {
 if (obj instanceof java.sql.Date) {
     sessionDate = new SimpleDateFormat("yyyy-MM-dd")
             .format((java.sql.Date) obj);
 } else {
     sessionDate = obj.toString();
 }
}

if (sessionDate == null || sessionDate.isEmpty()) {
 sessionDate = new SimpleDateFormat("yyyy-MM-dd")
         .format(new java.util.Date());
}

String action = request.getParameter("action");

if ("download".equals(action)) {

	/* =========================
	   PRODUCT LOGIC (REFERENCE STYLE)
	========================= */

	String productCode = request.getParameter("product_code");
	String singleAll   = request.getParameter("single_all");

	if(productCode == null) productCode = "";
	productCode = productCode.trim();

	/* VALIDATION */
	if("S".equals(singleAll) && productCode.equals("")){
	    throw new Exception("Enter Product Code");
	}

	/* FINAL PRODUCT CODE */
	String finalProductCode = "";

	if("A".equals(singleAll)){
	    finalProductCode = sessionBranchCode + "4%";
	}else{
	    finalProductCode = sessionBranchCode + productCode + "%";
	}
	String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");
    String reporttype = request.getParameter("reporttype");
    String format = request.getParameter("format");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        if(productCode == null || productCode.trim().equals("")){
            throw new Exception("Enter Product Code");
        }

        if(fromDate == null || fromDate.trim().equals("")){
            throw new Exception("Enter From Date");
        }

        if(toDate == null || toDate.trim().equals("")){
            throw new Exception("Enter To Date");
        }

        conn = DBConnection.getConnection();

        /* DATE FORMAT */
        String fromDateOracle =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
            .toUpperCase();

        String toDateOracle =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate))
            .toUpperCase();
        /* =========================
        REPORT TYPE LOGIC (FINAL)
     ========================= */

     String jasperName = "";

     if("D".equalsIgnoreCase(format)){
         jasperName = "/Reports/LoanSecurityGoldSilver.jasper";   // DETAILS
     }
     else if("S".equalsIgnoreCase(format)){
         jasperName = "/Reports/GoldLoanSubmisionReport.jasper"; // SUMMARY
     }
     else{
         jasperName = "/Reports/LoanSecurityGoldSilver.jasper"; // DEFAULT
     }
     
        String jasperPath = application.getRealPath(jasperName);

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new java.io.File(jasperPath));

        /* PARAMETERS */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", sessionBranchCode);
        parameters.put("product_code", finalProductCode);
        parameters.put("from_date", fromDateOracle);
        parameters.put("to_date", toDateOracle);

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put("report_title", "LOAN SECURITY GOLD SILVER");

        /* FILL */
        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, parameters, conn);

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        /* EXPORT */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                "inline; filename=\"LoanSecurityGoldSilver.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.close();
        }

        else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                "attachment; filename=\"LoanSecurityGoldSilver.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.close();
        }

        return;

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

        response.sendRedirect("LoanSecurityGoldSilver.jsp");
        return;
    
    } finally {
        if(conn!=null) conn.close();
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Loan Security Gold Silver</title>

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

<h1 class="report-title">LOAN SECURITY GOLD / SILVER</h1>

<form method="post"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- PRODUCT CODE -->
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
       name="single_all"
       value="S"
       onclick="toggleProduct()"
       checked> Single
</label>

<label>
<input type="radio"
       name="single_all"
       value="A"
       onclick="toggleProduct()"> All
</label>
</div>

</div>

<!-- PRODUCT NAME -->
<div class="parameter-group">
<div class="parameter-label">Product Name</div>

<input type="text"
       id="productName"
       class="input-field"
       placeholder="Product Name"
       readonly>
</div>

<!-- FROM DATE -->
<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date"
       name="fromDate"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

<!-- TO DATE -->
<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date"
       name="toDate"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

</div> <!-- ✅ parameter-section CLOSED -->

<!-- REPORT TYPE + MODE (SEPARATE SECTION) -->
<div style="display:flex; gap:120px; align-items:center; margin-top:30px;">

    <!-- REPORT TYPE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Type</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <label>
                <input type="radio" name="reporttype" value="pdf" checked> PDF
            </label>

            <label>
                <input type="radio" name="reporttype" value="xls"> Excel
            </label>

        </div>
    </div>

    <!-- REPORT MODE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Mode</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <label>
                <input type="radio" name="format" value="D" checked> Details
            </label>

            <label>
                <input type="radio" name="format" value="S"> Summary
            </label>

        </div>
    </div>

</div>

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
function toggleProduct(){

    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var field = document.getElementById("product_code");

    if(single){
        field.disabled = false;
        field.readOnly = false;
    }else{
        field.value = "";
        field.disabled = true;
        field.readOnly = true;
    }
}

window.onload = function(){
    toggleProduct();
};
</script>

</body>
</html>