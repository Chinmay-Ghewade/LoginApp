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

if (obj != null) {

    if (obj instanceof java.sql.Date) {

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    } else {

        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.trim().equals("")){

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

/* =========================================================
   DISPLAY DATE
========================================================= */

String displayDate = "";

try {

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

    String branchCode =
        request.getParameter("branch_code");

    String agentCode =
        request.getParameter("agent_code");

    String asOnDate =
        request.getParameter("as_on_date");

    /* =====================================================
       SECURITY
    ===================================================== */

    if(branchCode == null ||
       branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* =====================================================
       NULL HANDLING
    ===================================================== */

    if(agentCode == null)
        agentCode = "";

    if(asOnDate == null)
        asOnDate = "";

    agentCode = agentCode.trim();
    asOnDate  = asOnDate.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(agentCode.equals("")){

        out.println(
            "<h3 style='color:red'>" +
            "Please Enter Agent Code" +
            "</h3>"
        );

        return;
    }

    if(asOnDate.equals("")){

        out.println(
            "<h3 style='color:red'>" +
            "Please Select As On Date" +
            "</h3>"
        );

        return;
    }

    /* =====================================================
       DATE CONVERSION
    ===================================================== */

    String oracleDate = "";

    try{

        java.util.Date dt =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(asOnDate);

        oracleDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(dt).toUpperCase();

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
                "/Reports/PigmyBalanceList.jasper"
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

        parameters.put("branch_code",branchCode);
        parameters.put("agentCode",agentCode);
        parameters.put("as_on_date",oracleDate);
        parameters.put("report_title","AGENTWISE PIGMY BALANCE LIST");
        parameters.put("user_id",userId);
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

            response.setContentType("text/html");

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
                "inline; filename=\"PigmyBalanceList.pdf\""
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
                "attachment; filename=\"PigmyBalanceList.xls\""
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

<title>Pigmy Balance List</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script src=
"<%=request.getContextPath()%>/js/lookup.js?v=6">
</script>

<style>

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    cursor:not-allowed;
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

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
AGENTWISE PIGMY BALANCE LIST
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/PigmyBalanceList.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->

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
…
</button>

<% } %>

</div>

</div>

<!-- ================= AGENT ================= -->

<div class="parameter-group">

<div class="parameter-label">
Agent Code
</div>

<div class="input-box">

<input type="text"
name="agent_code"
id="agent_code"
class="input-field"
placeholder="Enter Agent Code"
required>

<input type="text"
id="agentName"
class="input-field"
readonly>

<button type="button"
class="icon-btn"
onclick="openLookup(
'agent',
'branchCode=' +
document.getElementById(
'branch_code'
).value
)">
…
</button>

</div>

</div>

</div>

<!-- ================= DATE SECTION ================= -->

<div class="parameter-section"
style="margin-top:20px;">

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<div class="input-box">

<input type="text"
name="as_on_date"
id="as_on_date"
class="input-field"
value="<%=displayDate%>"
placeholder="DD/MM/YYYY"
required>

</div>

</div>

<!-- EMPTY GRID -->

<div class="parameter-group">
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

<div style=
"text-align:center;
margin-top:25px;">

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

    var agentCode =
        document.getElementById(
            "agent_code"
        ).value.trim();

    var asOnDate =
        document.getElementById(
            "as_on_date"
        ).value.trim();

    var errorBox =
        document.getElementById(
            "errorBox"
        );

    errorBox.innerHTML = "";

    if(agentCode === ""){

        errorBox.innerHTML =
            "Please Enter Agent Code";

        return false;
    }

    if(asOnDate === ""){

        errorBox.innerHTML =
            "Please Select As On Date";

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

document.getElementById(
    "as_on_date"
).addEventListener(
"blur",
function(){

    if(!isValidDate(this.value)){

        alert(
            "Invalid Date Format"
        );

        this.focus();
    }
});

</script>

</body>
</html>