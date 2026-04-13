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
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>
<%
String installmentCode = request.getParameter("installment_code");
if (installmentCode == null) installmentCode = "";

String installmentName = request.getParameter("installmentName");
if (installmentName == null) installmentName = "";

String productCode = request.getParameter("product_code");
if(productCode == null) productCode = "";
productCode = productCode.trim();
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String branchCode  = request.getParameter("branch_code");
    String asOnDate    = request.getParameter("as_on_date");

    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    /* 🔒 SECURITY */
    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */

    if(installmentCode == null || installmentCode.trim().equals("")){
        out.println("<h3 style='color:red'>Please enter Installment Code</h3>");
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

    Connection conn=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* 🔥 LOAD YOUR REPORT */
        String jasperPath =
        application.getRealPath("/Reports/PreEmicheck.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* 🔹 PARAMETERS */

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("branch_code",branchCode);
        parameters.put("as_on_date",oracleDateStr);
        parameters.put("installment_id", installmentCode);
        parameters.put("report_title","EMI REPORT");

        
        String userId = (String) session.getAttribute("userId");
        parameters.put("user_id", userId);
        
        parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));


        parameters.put(JRParameter.REPORT_CONNECTION,conn);

        
        String finalProductCode = "";

        String singleAll = request.getParameter("single_all");

        if(singleAll == null) singleAll = "S"; // default safe

        if("A".equalsIgnoreCase(singleAll)){
            
            finalProductCode = branchCode + "%";

        }else{

            if(productCode == null || productCode.trim().equals("")){
                out.println("<h3 style='color:red'>Please enter Product Code</h3>");
                return;
            }

            finalProductCode = branchCode + productCode.trim() + "%";
        }

        parameters.put("fromproductcode", finalProductCode);

        JasperPrint jasperPrint =
        	    JasperFillManager.fillReport(jasperReport, parameters, conn);
        /* NO DATA */

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;'>No Records Found</h2>");
            return;
        }

        /* EXPORT */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"PreEmi_Report.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint,outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"PreEmi_Report.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT,jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM,outStream);

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

<title>Pre EMI Check Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

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

<h1 class="report-title">PRE EMI CHECK REPORT</h1>

<form method="post" action="" target="_blank" autocomplete="off">

<!-- 🔥 IMPORTANT -->
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
       value="<%=sessionBranchCode%>"
       <%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %> required>

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
<button type="button" class="icon-btn"
        onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- 🔹 INSTALLMENT -->

<div class="parameter-group">
<div class="parameter-label">Installment Code</div>

<div class="input-box">
<input type="text"
       name="installment_code"
       id="installment_code"
       class="input-field"
       value="<%=installmentCode%>"
       required>

<button type="button"
        class="icon-btn"
        onclick="openLookup('installment')">…</button>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Description</div>
<input type="text"
       id="installmentName"
       name="installmentName"
       class="input-field"
       value="<%=installmentName%>"
       readonly>
</div>

<!-- 🔹 PRODUCT CODE -->

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


<!-- 🔹 DATE -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>" required>
</div>

</div>

<!-- 🔹 REPORT TYPE -->

<div class="format-section" style="margin-top:20px;">

<label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
<label><input type="radio" name="reporttype" value="xls"> Excel</label>

</div>

<!-- 🔘 BUTTON -->

<div style="margin-top:20px;">
<button type="submit" class="download-button">
Generate Report
</button>
</div>

</form>
</div>

<!-- 🔹 LOOKUP POPUP -->

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