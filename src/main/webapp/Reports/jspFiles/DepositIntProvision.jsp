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
/* ================= SESSION DATA ================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

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

String displayDate = "";

try {

    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {

    displayDate = "";
}

String isSupportUser =
        (String) session.getAttribute("isSupportUser");

String sessionBranchCode =
        (String) session.getAttribute("branchCode");

if(isSupportUser == null) isSupportUser = "N";
if(sessionBranchCode == null) sessionBranchCode = "";
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String branchCode  = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String singleAll   = request.getParameter("single_all");
    String asOnDate    = request.getParameter("as_on_date");

    if(branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    if(productCode == null)
        productCode = "";

    productCode = productCode.trim();

    /* VALIDATION */

    if("S".equals(singleAll) && productCode.equals("")) {

        out.println("<h3 style='color:red'>Please Enter Product Code</h3>");
        return;
    }

    if(asOnDate == null || asOnDate.trim().equals("")) {

        out.println("<h3 style='color:red'>Please Select As On Date</h3>");
        return;
    }

    /* DATE FORMAT */

    String oracleDateStr = "";

    try {

    	java.util.Date d =
    		    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

    		oracleDateStr =
    		    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
    		            .format(d).toUpperCase();
    		
    } catch(Exception e) {

        out.println("<h3 style='color:red'>Invalid Date Format</h3>");
        return;
    }

    /* FINAL PRODUCT CODE */

    String finalProductCode = "";

    if("A".equals(singleAll)) {

        finalProductCode = branchCode + "4%";

    } else {

        finalProductCode = branchCode + productCode + "%";
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* LOAD REPORT */

        String jasperPath =
            application.getRealPath(
                "/Reports/DepositIntProvision.jasper");

        File file = new File(jasperPath);

        if(!file.exists()) {

            throw new RuntimeException(
                "Jasper file not found : " + jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(file);

        /* PARAMETERS */

        Map<String,Object> parameters = new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDateStr);
        parameters.put("product_code", finalProductCode);
        
        parameters.put(
            "report_title",
            "DEPOSIT INTEREST PROVISION REPORT");

        String userId =
            (String) session.getAttribute("userId");

        if(userId == null)
            userId = "admin";

        parameters.put("user_id", userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn);

        /* FILL REPORT */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn);

        if(jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println(
                "<h2 style='color:red;text-align:center;margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        /* EXPORT PDF */

        if("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Deposit_Int_Provision.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                    jasperPrint,
                    outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* EXPORT EXCEL */

        else if("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType(
                "application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Deposit_Int_Provision.xls\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

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

    } catch(Exception e) {

        out.println(
            "<h3 style='color:red'>Error Generating Report</h3>");

        e.printStackTrace(new PrintWriter(out));

    } finally {

        if(conn != null) {

            try {
                conn.close();
            } catch(Exception ex) {}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Deposit Interest Provision Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.radio-container {
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled {
    background-color:#e0e0e0;
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

<h1 class="report-title">
DEPOSIT INTEREST PROVISION REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositIntProvision.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- BRANCH -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
       name="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       <%= !"Y".equalsIgnoreCase(isSupportUser)
           ? "readonly"
           : "" %>
       required>

<% if("Y".equalsIgnoreCase(isSupportUser)){ %>

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">

...
</button>

<% } %>

</div>

</div>

<!-- PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
Product Code
</div>

<div class="input-box">

<input type="text"
       name="product_code"
       class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">

...
</button>

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

<!-- DATE -->

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

</div>

<!-- REPORT FORMAT -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<label>
<input type="radio"
       name="reporttype"
       value="pdf"
       checked>

PDF
</label>

<label>
<input type="radio"
       name="reporttype"
       value="xls">

Excel
</label>

</div>

<!-- BUTTON -->

<button type="submit"
        class="download-button">

Generate Report

</button>

</form>

<!-- LOOKUP POPUP -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<!-- ERROR MESSAGE -->

<div class="error-box">

<%
String err =
    request.getParameter("error");

if(err != null){
    out.print(err);
}
%>

</div>

</div>
<script>
function toggleProduct(){
    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var field =
        document.querySelector('input[name="product_code"]');

    if(single){
        field.disabled = false;
    } else {
        field.value = "";
        field.disabled = true;
    }
}

window.onload = toggleProduct;
</script>

</body>
</html>