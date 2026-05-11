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

Object obj =
    session.getAttribute("workingDate");

if(obj != null){

    if(obj instanceof java.sql.Date){

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    }else{

        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.equals("")){

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

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action =
    request.getParameter("action");

if("download".equals(action)){

    String reportType =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String asOnDate =
        request.getParameter("as_on_date");

    if(branchCode == null ||
       branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    /* ================= SECURITY ================= */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* ================= VALIDATION ================= */

    if(asOnDate == null ||
       asOnDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Please Select Date</h3>"
        );

        return;
    }

    /* ================= DATE FORMAT ================= */

    String oracleDate = "";

    try{

        java.util.Date d =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(asOnDate);

        oracleDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(d).toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();

        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= LOAD REPORT ================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/KYCCompleteNotComplete.jasper"
            );

        File file =
            new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : " +
                jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(file);

        /* ================= PARAMETERS ================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("as_on_date",oracleDate);
        parameters.put("branch_code",branchCode);
        parameters.put("report_title","KYC COMPLETED REPORT");
        String userId =
            (String)session.getAttribute("userId");

        if(userId == null) userId = "admin";

        parameters.put("user_id",userId);
        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* ================= FILL REPORT ================= */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn
            );

        if(jasperPrint.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");
            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= PDF EXPORT ================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"KYCCompletedReport.pdf\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint,
                outStream
            );

            outStream.flush();
            outStream.close();

            return;
        }

        /* ================= EXCEL EXPORT ================= */

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"KYCCompletedReport.xls\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream
            );

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>Error Generating Report</h3>"
        );

        e.printStackTrace(
            new PrintWriter(out)
        );

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

<title>
KYC Completed Report
</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>

var contextPath =
"<%=request.getContextPath()%>";

</script>

<script src=
"<%=request.getContextPath()%>/js/lookup.js">
</script>

<style>

.report-container{
    width:90%;
    margin:auto;
}

.report-title{
    text-align:center;
    color:#2D2B80;
    margin-top:20px;
}

.parameter-section{
    display:grid;
    grid-template-columns:1fr 1fr;
    gap:20px;
    margin-top:30px;
}

.parameter-group{
    display:flex;
    flex-direction:column;
}

.parameter-label{
    font-weight:bold;
    margin-bottom:8px;
}

.input-field{
    padding:10px;
    border:1px solid #ccc;
    border-radius:5px;
}

.input-box{
    display:flex;
    gap:10px;
}

.icon-btn{
    width:40px;
    border:none;
    background:#2D2B80;
    color:white;
    border-radius:5px;
    cursor:pointer;
}
.download-button{
    margin-top:30px;
    padding:12px 30px;
    background:#2D2B80;
    color:white;
    border:none;
    border-radius:5px;
    cursor:pointer;
}

.format-section{
    margin-top:20px;
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
}

.modal-content{
    width:80%;
    max-height:85%;
    overflow:auto;
    background:white;
    padding:20px;
    border-radius:8px;
}

.lookup-table{
    width:100%;
    border-collapse:collapse;
}

.lookup-table th,
.lookup-table td{
    border:1px solid #ccc;
    padding:8px;
}

.lookup-table tr:hover{
    background:#f2f2f2;
    cursor:pointer;
}

.error-box{
    color:red;
    margin-top:15px;
    font-weight:bold;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
KYC COMPLETED REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/KYCCompletedReport.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download">

<!-- ================= PARAMETERS ================= -->

<div class="parameter-section">

    <!-- Branch Code -->

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
                        ? "readonly" : "" %>
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

    <!-- Date -->

    <div class="parameter-group">

        <div class="parameter-label">
            As On Date
        </div>

        <input type="text"
               name="as_on_date"
               id="as_on_date"
               class="input-field"
               value="<%=displayDate%>"
               placeholder="DD/MM/YYYY"
               required>

    </div>

</div>

<!-- ================= REPORT TYPE ================= -->

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

<!-- ================= ERROR ================= -->

<div id="errorBox"
     class="error-box">
</div>

<!-- ================= BUTTON ================= -->

<button type="submit"
        class="download-button"
        onclick="return validateForm();">

    Generate Report

</button>

</form>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>
</body>

</html>