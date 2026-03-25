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

// fallback
if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
%>

<%
String branchCodeVal = request.getParameter("branch_code");
String productCodeVal = request.getParameter("product_code");
String asOnDateVal = request.getParameter("as_on_date");

if (branchCodeVal == null) branchCodeVal = "";
if (productCodeVal == null) productCodeVal = "";
if (asOnDateVal == null) asOnDateVal = "";
%>
<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype   = request.getParameter("reporttype");
    String branchCode   = request.getParameter("branch_code");
    String productCode  = request.getParameter("product_code");
    String asOnDate     = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        response.setHeader("Cache-Control","no-store, no-cache, must-revalidate");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader("Expires",0);

        conn = DBConnection.getConnection();

        /* DATE FORMAT */
        String oracleDateStr;

        if(asOnDate != null && !asOnDate.trim().equals("")){

            java.util.Date utilDate =
                new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDateStr =
                new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
                    .format(utilDate).toUpperCase();
        }
        else{

            oracleDateStr =
                new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
                    .format(new java.util.Date()).toUpperCase();
        }


        /* LOAD JASPER */
        String jasperPath =
            application.getRealPath("/Reports/AccountCategoryWiseReport.jasper");

        File jasperFile = new File(jasperPath);

        if(!jasperFile.exists()){
            throw new RuntimeException("Jasper file not found : "+jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(jasperFile);


        /* PARAMETERS */
        Map<String,Object> parameters = new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);
        parameters.put("product_code", productCode);
        parameters.put("as_on_date", oracleDateStr);

        parameters.put("report_title","ACCOUNT CATEGORY WISE REPORT");

        parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        parameters.put("user_id", userId);


        parameters.put("IMAGE_PATH",
                application.getRealPath("/images/UPSB MONO.png"));


        /* FILL REPORT */
        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport,parameters,conn);



        /* EXPORT PDF */
        if("pdf".equalsIgnoreCase(reporttype)){

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Account_Category_Wise_Report.pdf\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                    jasperPrint,outStream);

            outStream.flush();
            outStream.close();

            return;
        }


        /* EXPORT EXCEL */
        else if("xls".equalsIgnoreCase(reporttype)){

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Account_Category_Wise_Report.xls\""
            );

            ServletOutputStream outStream = response.getOutputStream();

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

<title>Account Category Wise Report</title>

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
ACCOUNT CATEGORY WISE REPORT
</h1>


<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/AccountCategoryWiseReport.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>



<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">Branch Code</div>

<div class="input-box">
    <input type="text"
           name="branch_code"
           id="branch_code"
           class="input-field"
           value="<%= branchCodeVal %>"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openBranchLookup()">…</button>
</div>

</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Description</div>
    <input type="text"
           id="branchName"
           class="input-field"
           readonly>
</div>


<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
    <input type="text"
           name="product_code"
           id="product_code"
           class="input-field"
           value="<%= productCodeVal %>"
           placeholder="Enter Product Code"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openProductLookup()">…</button>
</div>

</div>



<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
class="input-field"
value="<%= sessionDate %>"
required>

</div>

</div>



<div class="format-section">

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



<button type="submit" class="download-button">
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

// 🔹 Branch Popup
function openBranchLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// 🔹 Product Popup (ONLY CODE USE)
function openProductLookup() {
    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=product")
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        });
}

// 🔹 Close Modal
function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}

// 🔹 Select Branch (WITH DESCRIPTION)
function selectBranch(code, name) {
    document.getElementById("branch_code").value = code;

    let field = document.getElementById("branchName");
    if (field) {
        field.value = name;
    }

    closeLookup();
}

// 🔹 Select Product (ONLY CODE)
function selectProduct(code, name, type) {
    document.getElementById("product_code").value = code;
    closeLookup();
}

/* =========================
   🔹 BRANCH AUTO FETCH (IMPORTANT)
   ========================= */
document.getElementById("branch_code").addEventListener("blur", function() {

    let code = this.value;

    if (!code || code.trim() === "") return;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + encodeURIComponent(code))
        .then(res => res.text())
        .then(name => {

            let field = document.getElementById("branchName");

            if (field) {
                field.value = name || "Not Found";
            }
        });
});

</script>
</body>
</html>