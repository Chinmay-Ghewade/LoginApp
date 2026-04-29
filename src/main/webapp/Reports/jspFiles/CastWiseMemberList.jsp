<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION ================= */

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

String branchCode = (String) session.getAttribute("branchCode");
String userId     = (String) session.getAttribute("userId");

if(branchCode==null) branchCode="";
if(userId==null) userId="";

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";

/* 🔒 FORCE SESSION BRANCH (IMPORTANT FIX) */
if(!"Y".equalsIgnoreCase(isSupportUser)){
    branchCode = sessionBranchCode;
}

/* ================= ACTION ================= */

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String productCode = request.getParameter("product_code");
    String singleAll   = request.getParameter("single_all");
    String type        = request.getParameter("depositdetail_0");
    String asOnDate    = request.getParameter("as_on_date");

    if(productCode == null) productCode = "";
    productCode = productCode.trim();

    /* VALIDATION */

    if("S".equals(singleAll) && productCode.equals("")){
        out.println("<h3 style='color:red'>Please enter Product Code</h3>");
        return;
    }

    /* DATE FORMAT */

    String oracleDate = "";

    if(asOnDate != null && !asOnDate.isEmpty()){
        java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(d).toUpperCase();
    }

    /* FINAL PRODUCT CODE */

    String finalProductCode = "";

    if("A".equals(singleAll)){
        finalProductCode = branchCode + "4%";
    }else{
        finalProductCode = branchCode + productCode + "%";
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* CALL PROCEDURE */

        CallableStatement stmt =
        conn.prepareCall("{ call Sp_Report_Castwisemember(?,?,?) }");

        stmt.setString(1, branchCode);
        if("A".equals(singleAll)){
            stmt.setString(2, "4");   // IMPORTANT FIX
        }else{
            stmt.setString(2, productCode);
        }
        stmt.setString(3, oracleDate);

        stmt.execute();
        stmt.close();

        /* SELECT REPORT */

        String jasperFile =
        "D".equals(type) ?
        "bnkrptCastWiseMemberListDetails.jasper" :
        "bnkrptCastWiseMemberListSummary.jasper";

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);

        JasperReport report =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* PARAMETERS */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("finalProductCode", finalProductCode);
        params.put("report_title","CAST WISE MEMBER LIST");
        params.put("user_id", userId);

        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION, conn);

        /* FILL */

        JasperPrint jp =
        JasperFillManager.fillReport(report, params, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        out.clear();
        out = pageContext.pushBody();

        /* EXPORT */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=CastWiseMemberList.pdf");

            JasperExportManager.exportReportToPdfStream(jp,
            response.getOutputStream());
        }
        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=CastWiseMemberList.xls");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT, jp);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,
            response.getOutputStream());

            exporter.exportReport();
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

        response.sendRedirect("CastWiseMemberList.jsp");
        return;
    }
    finally{

        if(conn != null){
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Cast Wise Member List</title>

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

<h1 class="report-title">
CASTE WISE SHARE MEMBER LIST
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/CastWiseMemberList.jsp"
target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Product -->

<!-- Product Code -->

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

<!-- Date -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
value="<%=sessionDate%>"
class="input-field"
required>
</div>

</div>

<!-- ================= REPORT TYPE + SELECT ================= -->

<div style="display:flex; gap:120px; align-items:center; margin-top:20px;">

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

    <!-- DETAILS / SUMMARY -->
    <div class="parameter-group">

        <div class="parameter-label">Select</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <label>
                <input type="radio" name="depositdetail_0" value="D" checked>
                Details
            </label>

            <label>
                <input type="radio" name="depositdetail_0" value="S">
                Summary
            </label>

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