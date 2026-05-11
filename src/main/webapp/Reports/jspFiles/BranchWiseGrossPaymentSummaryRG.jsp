<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
/* =========================================================
   SESSION DATA
========================================================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if(obj != null){
    if(obj instanceof java.sql.Date){
        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);
    }else{
        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.isEmpty()){
    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

String displayDate = "";

try{
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(d);

}catch(Exception e){
    displayDate = "";
}

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String userId =
    (String)session.getAttribute("userId");

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(isSupportUser == null)
    isSupportUser = "N";

if(userId == null)
    userId = "admin";
%>

<%
/* =========================================================
   DOWNLOAD / REPORT GENERATION
========================================================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reportType =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    if(branchCode == null || branchCode.trim().isEmpty()){
        branchCode = sessionBranchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */

    if(fromDate == null || fromDate.trim().isEmpty()){
        out.println("<h3 style='color:red'>Please Enter From Date</h3>");
        return;
    }

    if(toDate == null || toDate.trim().isEmpty()){
        out.println("<h3 style='color:red'>Please Enter To Date</h3>");
        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =====================================================
           DATE CONVERSION
        ===================================================== */

        String oracleFromDate = "";
        String oracleToDate = "";

        try{

            java.util.Date fd =
                new SimpleDateFormat("dd/MM/yyyy")
                .parse(fromDate);

            java.util.Date td =
                new SimpleDateFormat("dd/MM/yyyy")
                .parse(toDate);

            oracleFromDate =
                new SimpleDateFormat("MM-yyyy")
                .format(fd);

            oracleToDate =
                new SimpleDateFormat("MM-yyyy")
                .format(td);

        }catch(Exception e){

            out.println("<h3 style='color:red'>Invalid Date Format</h3>");
            return;
        }

        /* =====================================================
           MONTH NAME LOGIC
        ===================================================== */
        		String br  = "";
        		String br1 = "";
        		String br2 = "";

        		int month =
        		    Integer.parseInt(
        		        oracleFromDate.substring(0,2));

        		Calendar cal = Calendar.getInstance();

        		/* MONTH 1 */

        		cal.set(Calendar.MONTH, month - 1);

        		br =
        		    new SimpleDateFormat("MMMM")
        		    .format(cal.getTime())
        		    .toUpperCase();

        		/* MONTH 2 */

        		cal.set(Calendar.MONTH, month % 12);

        		br1 =
        		    new SimpleDateFormat("MMMM")
        		    .format(cal.getTime())
        		    .toUpperCase();

        		/* MONTH 3 */

        		cal.set(Calendar.MONTH, (month + 1) % 12);

        		br2 =
        		    new SimpleDateFormat("MMMM")
        		    .format(cal.getTime())
        		    .toUpperCase();

     /* =====================================================
        JASPER REPORT
     ===================================================== */

     String jasperPath =
         application.getRealPath(
         "/Reports/brWiseSalarySummaryReport.jasper");

     File file = new File(jasperPath);

     if(!file.exists()){
         throw new RuntimeException(
             "Jasper file not found : " + jasperPath);
     }

     JasperReport jasperReport =
         (JasperReport)JRLoader.loadObject(file);
     
        /* =====================================================
           PARAMETERS
        ===================================================== */
        		
        		Map<String,Object> parameters =
        		    new HashMap<String,Object>();

        		parameters.put("branch_code", branchCode);

        		parameters.put("ac_close_date",
        		    oracleFromDate);

        		parameters.put("review_date",
        		    oracleToDate);

        		parameters.put("account_name", br);

        		parameters.put("agent_name", br1);

        		parameters.put("user_id", br2);

        		parameters.put("report_title",
        		    "BRANCH WISE GROSS PAYMENT SUMMARY REPORT");

        		parameters.put("as_on_date",
        		    displayDate);

        		parameters.put("address", "");

        		parameters.put("SUBREPORT_DIR",
        		    application.getRealPath("/Reports/"));

        		parameters.put(
        		    JRParameter.REPORT_CONNECTION,
        		    conn);

        /* =====================================================
           FILL REPORT
        ===================================================== */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn);

        if(jasperPrint.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
       /* =====================================================
           EXPORT PDF
        ===================================================== */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"BranchWiseGrossPaymentSummary.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint,
                outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        /* =====================================================
           EXPORT EXCEL
        ===================================================== */

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"BranchWiseGrossPaymentSummary.xls\"");

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

    }catch(Exception e){

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new PrintWriter(out));

    }finally{

        if(conn != null){
            try{
                conn.close();
            }catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Branch Wise Gross Payment Summary Report</title>

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
BRANCH WISE GROSS PAYMENT SUMMARY REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/BranchWiseGrossPaymentSummaryRG.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm();">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- =====================================================
     BRANCH CODE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%=sessionBranchCode%>"
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

<!-- =====================================================
     FROM DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
From Date
</div>

<input type="text"
       name="from_date"
       id="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       maxlength="10"
       onkeyup="formatDate(this)"
       required>

</div>

<!-- =====================================================
     TO DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
To Date
</div>

<input type="text"
       name="to_date"
       id="to_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       maxlength="10"
       onkeyup="formatDate(this)"
       required>

</div>

</div>

<!-- =====================================================
     REPORT TYPE
===================================================== -->

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

<label style="margin-left:20px;">
<input type="radio"
       name="reporttype"
       value="xls">
Excel
</label>

</div>

<!-- =====================================================
     ERROR MESSAGE
===================================================== -->

<div id="errorDiv" class="error-msg"></div>

<!-- =====================================================
     BUTTON
===================================================== -->

<button type="submit"
        class="download-button">
Generate Report
</button>

</form>

</div>

<!-- =====================================================
     LOOKUP MODAL
===================================================== -->

<div id="lookupModal" class="modal">

<div class="modal-content">

<button class="close-btn"
        onclick="closeLookup()">
X
</button>

<div id="lookupTable"></div>

</div>

</div>

<!-- =====================================================
     JAVASCRIPT
===================================================== -->

<script>

/* =====================================================
   DATE FORMAT
===================================================== */

function formatDate(field){

    let value = field.value.replace(/\D/g,'');

    if(value.length >= 2 && value.length < 4){
        value =
            value.substring(0,2) + '/' +
            value.substring(2);
    }

    else if(value.length >= 4){
        value =
            value.substring(0,2) + '/' +
            value.substring(2,4) + '/' +
            value.substring(4,8);
    }

    field.value = value;
}

/* =====================================================
   DATE VALIDATION
===================================================== */

function isValidDate(dateString){

    const regex =
        /^(\d{2})\/(\d{2})\/(\d{4})$/;

    if(!regex.test(dateString))
        return false;

    const parts =
        dateString.split("/");

    const day =
        parseInt(parts[0],10);

    const month =
        parseInt(parts[1],10);

    const year =
        parseInt(parts[2],10);

    const date =
        new Date(year, month - 1, day);

    return date.getFullYear() === year &&
           date.getMonth() === month - 1 &&
           date.getDate() === day;
}

/* =====================================================
   FORM VALIDATION
===================================================== */

function validateForm(){

    let fromDate =
        document.getElementById("from_date").value;

    let toDate =
        document.getElementById("to_date").value;

    let errorDiv =
        document.getElementById("errorDiv");

    errorDiv.innerHTML = "";

    if(fromDate.trim() === ""){
        errorDiv.innerHTML =
            "Please Enter From Date";
        return false;
    }

    if(toDate.trim() === ""){
        errorDiv.innerHTML =
            "Please Enter To Date";
        return false;
    }

    if(!isValidDate(fromDate)){
        errorDiv.innerHTML =
            "Invalid From Date";
        return false;
    }

    if(!isValidDate(toDate)){
        errorDiv.innerHTML =
            "Invalid To Date";
        return false;
    }

    return true;
}

/* =====================================================
   LOOKUP OPEN
===================================================== */

function openLookup(type){

    document.getElementById("lookupModal")
        .style.display = "flex";

    if(type === 'branch'){

        document.getElementById("lookupTable").innerHTML =
        "<iframe src='" +
        contextPath +
        "/lookup/branchLookup.jsp' " +
        "style='width:100%;height:500px;border:none;'></iframe>";
    }
}

/* =====================================================
   LOOKUP CLOSE
===================================================== */

function closeLookup(){

    document.getElementById("lookupModal")
        .style.display = "none";
}

</script>

</body>
</html>