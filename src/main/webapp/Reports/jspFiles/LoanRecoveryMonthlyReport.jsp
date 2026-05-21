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

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

String sessionBankCode =
    (String)session.getAttribute("bankCode");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(sessionBankCode == null)
    sessionBankCode = "";
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    String fromProductCode =
        request.getParameter("pr_code_fr");

    String toProductCode =
        request.getParameter("pr_code_to");

    if(branchCode == null ||
       branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    /* ================= SECURITY ================= */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* ================= VALIDATION ================= */

    if(fromDate == null ||
       fromDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Enter From Date</h3>");

        return;
    }

    if(toDate == null ||
       toDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Enter To Date</h3>");

        return;
    }

    if(fromProductCode == null ||
       fromProductCode.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Enter From Product Code</h3>");

        return;
    }

    if(toProductCode == null ||
       toProductCode.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Enter To Product Code</h3>");

        return;
    }

    String oracleFromDate = "";
    String oracleToDate = "";

    try{

        java.util.Date fd =
            new SimpleDateFormat("yyyy-MM-dd")
                .parse(fromDate);

        java.util.Date td =
            new SimpleDateFormat("yyyy-MM-dd")
                .parse(toDate);

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH)
                .format(fd)
                .toUpperCase();

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH)
                .format(td)
                .toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>");

        return;
    }

    Connection conn = null;
    CallableStatement call = null;

    try{

        response.reset();

        response.setBufferSize(
            1024 * 1024);

        conn =
            DBConnection.getConnection();

        /* ================= PROCEDURE CALL ================= */

        call =
            conn.prepareCall(
                "call SP_REP_MONTHLYRECOVERY(?,?,?,?,?)");

        call.setString(1, branchCode);

        call.setString(2, oracleFromDate);

        call.setString(3, oracleToDate);

        call.setString(4, fromProductCode);

        call.setString(5, toProductCode);

        call.execute();

        call.close();

        /* ================= REPORT ================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/RptMonthlyLoanRecovery.jasper");

        File file =
            new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : "
                + jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport)
                JRLoader.loadObject(file);

        /* ================= PARAMETERS ================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put(
            "branch_code",
            branchCode);

        parameters.put(
            "from_date",
            oracleFromDate);

        parameters.put(
            "to_date",
            oracleToDate);

        parameters.put(
            "as_on_date",
            oracleToDate);

        parameters.put(
            "from_product",
            fromProductCode);

        parameters.put(
            "to_product",
            toProductCode);

        parameters.put(
            "report_title",
            "LOAN RECOVERY MONTHLY REPORT");

        String userId =
            (String)session.getAttribute(
                "userId");

        if(userId == null)
            userId = "admin";

        parameters.put(
            "user_id",
            userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath(
                "/Reports/"));

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn);

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn);

        if(jasperPrint.getPages().isEmpty()){

            response.reset();

            response.setContentType(
                "text/html");

            out.println(
                "<h2 style='color:red;"
                + "text-align:center;"
                + "margin-top:50px;'>");

            out.println(
                "No Records Found!");

            out.println("</h2>");

            return;
        }

        /* ================= PDF ================= */

        if("pdf".equalsIgnoreCase(
            reporttype)){

            response.setContentType(
                "application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; "
                + "filename=\"LoanRecoveryMonthlyReport.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager
                .exportReportToPdfStream(
                    jasperPrint,
                    outStream);

            outStream.flush();

            outStream.close();

            return;
        }

        /* ================= EXCEL ================= */

        else if("xls".equalsIgnoreCase(
            reporttype)){

            response.setContentType(
                "application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; "
                + "filename=\"LoanRecoveryMonthlyReport.xls\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter
                    .JASPER_PRINT,
                jasperPrint);

            exporter.setParameter(
                JRXlsExporterParameter
                    .OUTPUT_STREAM,
                outStream);

            exporter.exportReport();

            outStream.flush();

            outStream.close();

            return;
        }

    }
    catch(Exception e){

        e.printStackTrace();

        Throwable cause = e;

        while(cause.getCause() != null){

            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg != null && msg.contains("ORA-")){

            msg = msg.substring(
                    msg.indexOf("ORA-"));
        }

        session.setAttribute(
            "errorMessage",
            "Error Message = " + msg
        );

        response.sendRedirect(
            "LoanRecoveryMonthlyReport.jsp");

        return;
    }
    finally{

        if(call != null){

            try{
                call.close();
            }catch(Exception ignored){}
        }

        if(conn != null){

            try{
                conn.close();
            }catch(Exception ignored){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Loan Recovery Monthly Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.report-container{
    width:95%;
    margin:auto;
    margin-top:20px;
}

.report-title{
    text-align:center;
    color:#2D2B80;
    margin-bottom:25px;
}

.parameter-section{
    display:flex;
    flex-wrap:wrap;
    gap:25px;
    margin-bottom:20px;
}

.parameter-group{
    display:flex;
    flex-direction:column;
    min-width:280px;
}

.parameter-label{
    font-weight:bold;
    margin-bottom:8px;
}

.input-box{
    display:flex;
    gap:10px;
}

.input-field{
    padding:10px;
    border:1px solid #c7c7c7;
    border-radius:8px;
    width:100%;
}

.input-field:disabled{
    background:#e0e0e0;
    cursor:not-allowed;
}

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
    font-size:18px;
}

.format-section{
    margin-top:20px;
    margin-bottom:20px;
}

.download-button{
    background:#2D2B80;
    color:white;
    border:none;
    padding:12px 30px;
    border-radius:8px;
    cursor:pointer;
    font-size:15px;
}

.download-button:hover{
    opacity:0.9;
}

.modal{
    display:none;
    position:fixed;
    top:0;
    left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
    z-index:9999;
}

.modal-content{
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    overflow:auto;
    padding:20px;
    border-radius:8px;
}

.close-btn{
    float:right;
    background:red;
    color:white;
    border:none;
    border-radius:5px;
    padding:5px 10px;
    cursor:pointer;
}

.lookup-table{
    width:100%;
    border-collapse:collapse;
}

.lookup-table th,
.lookup-table td{
    border:1px solid #c7c7c7;
    padding:8px;
}

.lookup-table tr:hover{
    background:#e8e8ff;
    cursor:pointer;
}

.error-box{
    color:red;
    font-weight:bold;
    margin-top:15px;
}

</style>

</head>

<body>

<div class="report-container">

<%
String errorMessage =
    (String)session.getAttribute(
        "errorMessage");

if(errorMessage != null){
%>

<div class="error-message">
    <%= errorMessage %>
</div>

<%
session.removeAttribute(
    "errorMessage");
}
%>

<h1 class="report-title">
LOAN RECOVERY MONTHLY REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/LoanRecoveryMonthlyReport.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden"
       name="action"
       value="download"/>

<div class="parameter-section">

<!-- BRANCH CODE -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
       name="branch_code"
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

<!-- FROM PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
From Product Code
</div>

<div class="input-box">

<input type="text"
name="pr_code_fr"
id="product_code"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>

</div>

<!-- TO PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
To Product Code
</div>

<div class="input-box">

<input type="text"
name="pr_code_to"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>

</div>

</div>

<!-- FROM DATE -->

<div class="parameter-group">

<div class="parameter-label">
From Date
</div>

<input type="date"
       name="from_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

<!-- TO DATE -->

<div class="parameter-group">

<div class="parameter-label">
To Date
</div>

<input type="date"
       name="to_date"
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

<!-- LOOKUP MODAL -->

<div id="lookupModal"
     class="modal">

<div class="modal-content">

<button class="close-btn"
        onclick="closeLookup()">

X

</button>

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

</body>
</html>