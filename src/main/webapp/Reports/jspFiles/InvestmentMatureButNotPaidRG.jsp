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
%>

<%

String action = request.getParameter("action");

if ("download".equals(action)) {


String reportType  = request.getParameter("reporttype");
String reportMode  = request.getParameter("report_mode");

String branchCode  = request.getParameter("branch_code");
String productCode = request.getParameter("product_code");
String asOnDate    = request.getParameter("as_on_date");
String singleAll = request.getParameter("single_all");

if(productCode == null) productCode = "";
productCode = productCode.trim();

// ✅ VALIDATION
if("S".equals(singleAll) && productCode.equals("")){
    out.println("<h3 style='color:red'>Please enter Product Code</h3>");
    return;
}


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

    /* ✅ USER ID (FIXED) */
    String userId = (String) session.getAttribute("userId");
    param.put("user_id", userId);
    
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

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">
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

<h1 class="report-title">
INVESTMENT MATURE BUT NOT PAID
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/InvestmentMatureButNotPaidRG.jsp"
target="_blank"
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
                   required>

            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('branch')">…</button>
        </div>

    </div>

    <div class="parameter-group">

        <div class="parameter-label">Branch Description</div>

        <input type="text"
               id="branchName"
               class="input-field"
               readonly>

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
                       name="single_all"
                       value="S"
                       checked
                       onclick="toggleProduct()">
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

    <!-- ================= DATE ================= -->
    <div class="parameter-group">

        <div class="parameter-label">As On Date</div>

        <input type="date"
               name="as_on_date"
               class="input-field"
               value="<%=sessionDate%>"
               required>

    </div>

</div>

<!-- ================= REPORT OPTIONS ================= -->
<div style="display:flex; gap:120px; align-items:center; margin-top:30px;">

    <!-- REPORT TYPE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Type</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <label>
                <input type="radio" name="reporttype" value="pdf" checked>
                PDF
            </label>

            <label>
                <input type="radio" name="reporttype" value="xls">
                Excel
            </label>

        </div>

    </div>

    <!-- REPORT MODE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Mode</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <label>
                <input type="radio" name="report_mode" value="DETAIL" checked>
                Details
            </label>

            <label>
                <input type="radio" name="report_mode" value="SUMMARY">
                Summary
            </label>

        </div>

    </div>

</div>

<button type="submit"
class="download-button">

Generate Report

</button>

</form>

</div>

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>
function toggleProduct() {

    var selected =
        document.querySelector('input[name="single_all"]:checked').value;

    var productField = document.getElementById("product_code");

    if (selected === "S") {
        // ✅ SINGLE → ENABLE FIELD
        productField.disabled = false;
        productField.readOnly = false;

    } else {
        // ✅ ALL → DISABLE FIELD
        productField.value = "";
        productField.disabled = true;
        productField.readOnly = true;
    }
}

// AUTO RUN ON PAGE LOAD
window.addEventListener("DOMContentLoaded", function () {
    toggleProduct();
});
</script>

</body>

</html>
