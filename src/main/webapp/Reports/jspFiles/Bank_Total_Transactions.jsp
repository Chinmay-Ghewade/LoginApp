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

if(sessionDate == null ||
   sessionDate.trim().equals("")){

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

/* =========================================================
   DISPLAY DATE
========================================================= */

String displayDate = "";

try{

    java.util.Date dt =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(dt);

}catch(Exception e){

    displayDate = "";
}

/* =========================================================
   SESSION VARIABLES
========================================================= */

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

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    /* =====================================================
       NULL HANDLING
    ===================================================== */

    if(fromDate == null)
        fromDate = "";

    if(toDate == null)
        toDate = "";

    fromDate = fromDate.trim();
    toDate   = toDate.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(fromDate.equals("")){

        out.println(
            "<h3 style='color:red'>" +
            "Please Enter From Date" +
            "</h3>"
        );

        return;
    }

    if(toDate.equals("")){

        out.println(
            "<h3 style='color:red'>" +
            "Please Enter To Date" +
            "</h3>"
        );

        return;
    }

    /* =====================================================
       DATE FORMAT
    ===================================================== */

    String oracleFromDate = "";
    String oracleToDate   = "";

    try{

        java.util.Date dt1 =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(fromDate);

        java.util.Date dt2 =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(toDate);

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(dt1).toUpperCase();

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(dt2).toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>" +
            "Invalid Date Format" +
            "</h3>"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();

        response.setBufferSize(
            1024 * 1024
        );

        conn = DBConnection.getConnection();

        /* =================================================
           LOAD REPORT
        ================================================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/Bank_Total_Transactions.jasper"
            );

        File reportFile =
            new File(jasperPath);

        if(!reportFile.exists()){

            throw new RuntimeException(
                "Jasper File Not Found : "
                + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)
            JRLoader.loadObject(reportFile);

        /* =================================================
           PARAMETERS
        ================================================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("from_date",oracleFromDate);
        parameters.put("to_date",oracleToDate);
        parameters.put("report_title","BRANCHWISE TOTAL TRANSACTIONS");
        parameters.put("user_id",userId);
        parameters.put("branch_code",sessionBranchCode);  
        parameters.put("as_on_date",oracleToDate);
        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* =================================================
           FILL REPORT
        ================================================= */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn
            );

        /* =================================================
           NO RECORDS
        ================================================= */

        if(jasperPrint.getPages().isEmpty()){

            response.reset();

            response.setContentType(
                "text/html"
            );

            out.println(
            "<h2 style='color:red;" +
            "text-align:center;" +
            "margin-top:50px;'>"
            );

            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* =================================================
           PDF
        ================================================= */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Bank_Total_Transactions.pdf\""
            );

            ServletOutputStream outputStream =
                response.getOutputStream();

            JasperExportManager
            .exportReportToPdfStream(
                jasperPrint,
                outputStream
            );

            outputStream.flush();
            outputStream.close();

            return;
        }

        /* =================================================
           XLS
        ================================================= */

        else if(
            "xls".equalsIgnoreCase(reporttype)
        ){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Bank_Total_Transactions.xls\""
            );

            ServletOutputStream outputStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outputStream
            );

            exporter.exportReport();

            outputStream.flush();
            outputStream.close();

            return;
        }

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>" +
            "Error Generating Report" +
            "</h3>"
        );

        e.printStackTrace(
            new PrintWriter(out)
        );

    }finally{

        if(conn != null){

            try{
                conn.close();
            }catch(Exception ex){
            }
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Bank Total Transactions</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script src=
"<%=request.getContextPath()%>/js/lookup.js?v=5">
</script>

<style>

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

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
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    overflow:auto;
    padding:20px;
    border-radius:8px;
}

.error-box{
    color:red;
    font-weight:bold;
    text-align:center;
    margin-top:20px;
}

.date-row{
    display:flex;
    gap:20px;
    margin-top:20px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
BRANCHWISE TOTAL TRANSACTIONS
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/Bank_Total_Transactions.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download"/>

<!-- ================= DATE SECTION ================= -->

<div class="date-row">

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
required>

</div>

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
required>

</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<div class="radio-container">

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

</div>

<!-- ================= BUTTONS ================= -->

<div style="text-align:center;margin-top:25px;">

<button type="submit"
class="download-button"
onclick="return validateForm();">

Generate Report

</button>

</div>

<!-- ================= ERROR BOX ================= -->

<div id="errorBox"
class="error-box">
</div>

</form>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

/* =====================================================
   VALIDATION
===================================================== */

function validateForm(){

    var fromDate =
        document.getElementById(
            "from_date"
        ).value.trim();

    var toDate =
        document.getElementById(
            "to_date"
        ).value.trim();

    var errorBox =
        document.getElementById(
            "errorBox"
        );

    errorBox.innerHTML = "";

    if(fromDate === ""){

        errorBox.innerHTML =
            "Please Enter From Date";

        return false;
    }

    if(toDate === ""){

        errorBox.innerHTML =
            "Please Enter To Date";

        return false;
    }

    if(!isValidDate(fromDate)){

        errorBox.innerHTML =
            "Invalid From Date Format";

        return false;
    }

    if(!isValidDate(toDate)){

        errorBox.innerHTML =
            "Invalid To Date Format";

        return false;
    }

    var from =
        convertDate(fromDate);

    var to =
        convertDate(toDate);

    if(from > to){

        errorBox.innerHTML =
            "From Date Must Be Less Than Or Equal To To Date";

        return false;
    }

    return true;
}

/* =====================================================
   DATE VALIDATION
===================================================== */

function isValidDate(dateString){

    var regex =
        /^(\d{2})\/(\d{2})\/(\d{4})$/;

    return regex.test(dateString);
}

/* =====================================================
   DATE CONVERSION
===================================================== */

function convertDate(dateStr){

    var parts = dateStr.split("/");

    return new Date(
        parts[2],
        parts[1]-1,
        parts[0]
    );
}

/* =====================================================
   DATE BLUR CHECK
===================================================== */

document.getElementById(
    "from_date"
).addEventListener(
"blur",
function(){

    if(!isValidDate(this.value)){

        alert(
            "Invalid From Date Format"
        );

        this.focus();
    }
});

document.getElementById(
    "to_date"
).addEventListener(
"blur",
function(){

    if(!isValidDate(this.value)){

        alert(
            "Invalid To Date Format"
        );

        this.focus();
    }
});

</script>

</body>
</html>
