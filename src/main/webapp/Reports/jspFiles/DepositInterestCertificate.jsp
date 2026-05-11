<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="64kb" autoFlush="true" %>

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
   DOWNLOAD LOGIC
========================================================= */

String action =
    request.getParameter("action");

if("download".equals(action)){

    String reportType =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String accountCode =
        request.getParameter("account_code");

    String accountName =
        request.getParameter("account_name");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode = sessionBranchCode;
    }

    /* =====================================================
       SECURITY
    ===================================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(accountCode == null ||
       accountCode.trim().isEmpty()){

        out.println(
        "<h3 style='color:red'>" +
        "Please Insert Account Code" +
        "</h3>");

        return;
    }

    if(fromDate == null ||
       fromDate.trim().isEmpty()){

        out.println(
        "<h3 style='color:red'>" +
        "Please Insert From Date" +
        "</h3>");

        return;
    }

    if(toDate == null ||
       toDate.trim().isEmpty()){

        out.println(
        "<h3 style='color:red'>" +
        "Please Insert To Date" +
        "</h3>");

        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =====================================================
           DATE FORMAT
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
            "<h3 style='color:red'>" +
            "Invalid Date Format" +
            "</h3>");

            return;
        }

        /* =====================================================
           LOAD REPORT
        ===================================================== */

        String jasperPath =
            application.getRealPath(
            "/Reports/DepositInterestCertificate.jasper");

        File file =
            new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
            "Jasper file not found : " +
            jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport)
            JRLoader.loadObject(file);

        /* =====================================================
           PARAMETERS
        ===================================================== */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code",branchCode);
        parameters.put("account_code",accountCode);
        parameters.put("account_name",accountName);
        parameters.put("as_on_date",oracleFromDate);
        parameters.put("from_date",oracleFromDate);
        parameters.put("to_date",oracleToDate);
        parameters.put("report_title","DEPOSIT INTEREST CERTIFICATE");
        parameters.put("user_id",userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath(
                "/Reports/"));

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

            out.println(
            "<h2 style='color:red;" +
            "text-align:center;" +
            "margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }
        /* =====================================================
        EXPORT PDF
     ===================================================== */

     if("pdf".equalsIgnoreCase(reportType)){

         response.reset();

         response.setContentType(
             "application/pdf");

         response.setHeader(
             "Content-Disposition",
             "inline; filename=\"DepositInterestCertificate.pdf\"");

         response.setHeader(
             "Cache-Control",
             "no-store, no-cache, must-revalidate");

         response.setHeader(
             "Pragma",
             "no-cache");

         response.setDateHeader(
             "Expires",
             0);

         out.clear();
         out = pageContext.pushBody();

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

      response.reset();

      response.setContentType(
          "application/vnd.ms-excel");

      response.setHeader(
          "Content-Disposition",
          "attachment; filename=\"DepositInterestCertificate.xls\"");

      response.setHeader(
          "Cache-Control",
          "no-store, no-cache, must-revalidate");

      response.setHeader(
          "Pragma",
          "no-cache");

      response.setDateHeader(
          "Expires",
          0);

      out.clear();
      out = pageContext.pushBody();

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

        out.println(
        "<h3 style='color:red'>" +
        "Error Generating Report</h3>");

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

<title>Deposit Interest Certificate</title>

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

.input-box{
    display:flex;
    gap:10px;
}

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.icon-btn:hover{
    background:#1b1b60;
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

.error-msg{
    color:red;
    font-weight:bold;
    margin-top:20px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
DEPOSIT INTEREST CERTIFICATE
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositInterestCertificate.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm();">

<input type="hidden"
       name="action"
       value="download"/>

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
     ACCOUNT CODE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Account Code
</div>

<div class="input-box">

<input type="text"
       name="account_code"
       id="account_code"
       class="input-field"
       onblur="fetchAccountName()"
       required>

<button type="button"
        class="icon-btn"
        onclick="openLookup('account')">
...
</button>

</div>

</div>

<!-- =====================================================
     ACCOUNT NAME
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Account Name
</div>

<input type="text"
       name="account_name"
       id="account_name"
       class="input-field"
       readonly>

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
     ERROR DIV
===================================================== -->

<div id="errorDiv"
     class="error-msg"></div>

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

<div id="lookupModal"
     class="modal">

<div class="modal-content">

<button onclick="closeLookup()"
        style="float:right;">
✖
</button>

<div id="lookupTable"></div>

</div>

</div>

<script>

/* =====================================================
   DATE FORMAT
===================================================== */

function formatDate(field){

    let value =
        field.value.replace(/\D/g,'');

    if(value.length >= 2 &&
       value.length < 4){

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
   VALIDATION
===================================================== */

function validateForm(){

    let accountCode =
        document.getElementById(
            "account_code").value;

    let fromDate =
        document.getElementById(
            "from_date").value;

    let toDate =
        document.getElementById(
            "to_date").value;

    let errorDiv =
        document.getElementById(
            "errorDiv");

    errorDiv.innerHTML = "";

    if(accountCode.trim() === ""){

        errorDiv.innerHTML =
            "Please Insert Account Code";

        return false;
    }

    if(fromDate.trim() === ""){

        errorDiv.innerHTML =
            "Please Insert From Date";

        return false;
    }

    if(toDate.trim() === ""){

        errorDiv.innerHTML =
            "Please Insert To Date";

        return false;
    }

    return true;
}

</script>

</body>
</html>