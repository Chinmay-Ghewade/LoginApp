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

if (sessionDate == null || sessionDate.trim().equals("")) {

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

/* DISPLAY DATE */

String displayDate = "";

try {

    java.util.Date dt =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(dt);

} catch(Exception e) {

    displayDate = "";
}

/* SESSION VARIABLES */

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

if("download".equals(action)) {

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String productCode =
        request.getParameter("product_code");

    String fromAgentCode =
        request.getParameter("from_agent_code");

    String toAgentCode =
        request.getParameter("to_agent_code");

    String startingDate =
        request.getParameter("starting_date");

    String endingDate =
        request.getParameter("ending_date");

    /* =====================================================
       SECURITY
    ===================================================== */

    if(branchCode == null || branchCode.trim().equals("")) {
        branchCode = sessionBranchCode;
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* =====================================================
       NULL HANDLING
    ===================================================== */

    if(productCode == null)      productCode = "";
    if(fromAgentCode == null)    fromAgentCode = "";
    if(toAgentCode == null)      toAgentCode = "";
    if(startingDate == null)     startingDate = "";
    if(endingDate == null)       endingDate = "";

    productCode   = productCode.trim();
    fromAgentCode = fromAgentCode.trim();
    toAgentCode   = toAgentCode.trim();
    startingDate  = startingDate.trim();
    endingDate    = endingDate.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(productCode.equals("")) {

        out.println("<h3 style='color:red'>Please Enter Product Code</h3>");
        return;
    }

    if(fromAgentCode.equals("")) {

        out.println("<h3 style='color:red'>Please Enter From Agent Code</h3>");
        return;
    }

    if(toAgentCode.equals("")) {

        out.println("<h3 style='color:red'>Please Enter To Agent Code</h3>");
        return;
    }

    if(startingDate.equals("")) {

        out.println("<h3 style='color:red'>Please Select Starting Date</h3>");
        return;
    }

    if(endingDate.equals("")) {

        out.println("<h3 style='color:red'>Please Select Ending Date</h3>");
        return;
    }

    /* =====================================================
       DATE FORMAT CONVERSION
    ===================================================== */

    String oracleStartDate = "";
    String oracleEndDate   = "";

    try {

        java.util.Date sdt =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(startingDate);

        oracleStartDate =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(sdt)
            .toUpperCase();

        java.util.Date edt =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(endingDate);

        oracleEndDate =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(edt)
            .toUpperCase();

    } catch(Exception e) {

        out.println("<h3 style='color:red'>Invalid Date Format</h3>");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =================================================
           LOAD JASPER REPORT
        ================================================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/PigmyAgentWiseBalanceBook.jasper"
            );

        File reportFile = new File(jasperPath);

        if(!reportFile.exists()) {

            throw new RuntimeException(
                "Jasper File Not Found : " + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(reportFile);

        /* =================================================
           PARAMETERS
        ================================================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);
        parameters.put("product_code", productCode);
        parameters.put("from_agent_code", fromAgentCode);
        parameters.put("to_agent_code", toAgentCode);
        parameters.put("starting_date", oracleStartDate);
        parameters.put("ending_date", oracleEndDate);
        parameters.put("branch_code%",branchCode + "6%");
        parameters.put("report_title","PIGMY AGENT WISE BALANCE BOOK");
        parameters.put("user_id", userId);
        parameters.put("as_on_date",endingDate);

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
           NO RECORDS CHECK
        ================================================= */

        if(jasperPrint.getPages().isEmpty()) {

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
           EXPORT PDF
        ================================================= */

        if("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"PigmyAgentWiseBalanceBook.pdf\""
            );

            ServletOutputStream outputStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint,
                outputStream
            );

            outputStream.flush();
            outputStream.close();

            return;
        }

        /* =================================================
           EXPORT XLS
        ================================================= */

        else if("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"PigmyAgentWiseBalanceBook.xls\""
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

    } catch(Exception e) {

        out.println(
            "<h3 style='color:red'>" +
            "Error Generating Report" +
            "</h3>"
        );

        e.printStackTrace(new PrintWriter(out));

    } finally {

        if(conn != null) {

            try {
                conn.close();
            } catch(Exception ex) {
            }
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Pigmy Agent Wise Balance Book</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js?v=5"></script>

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
PIGMY AGENT WISE BALANCE BOOK
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/PigmyAgentWiseBalanceBook.jsp"
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

<!-- ================= PRODUCT ================= -->

<div class="parameter-group">

<div class="parameter-label">
Product Code
</div>

<div class="input-box">

<input type="text"
name="product_code"
id="product_code"
class="input-field"
value="110"
readonly>

<input type="text"
id="productName"
class="input-field"
value="PIGMY AGENT"
readonly>

</div>

</div>

<!-- ================= FROM AGENT ================= -->

<div class="parameter-group">

<div class="parameter-label">
From Agent Code
</div>

<div class="input-box">

<input type="text"
name="from_agent_code"
id="from_agent_code"
class="input-field"
placeholder="Enter From Agent Code"
required>

<button type="button"
class="icon-btn"
onclick="openLookup(
'agent',
'branchCode=' +
document.getElementById('branch_code').value
)">
…
</button>

</div>
</div>

<!-- ================= TO AGENT ================= -->

<div class="parameter-group">

<div class="parameter-label">
To Agent Code
</div>

<div class="input-box">

<input type="text"
name="to_agent_code"
id="to_agent_code"
class="input-field"
placeholder="Enter To Agent Code"
required>

<button type="button"
class="icon-btn"
onclick="openLookup(
'agent',
'branchCode=' +
document.getElementById('branch_code').value
)">
…
</button>

</div>
</div>

</div>

<!-- ================= DATE SECTION ================= -->

<div class="parameter-section"
style="margin-top:20px;">

<!-- STARTING DATE -->

<div class="parameter-group">

<div class="parameter-label">
Starting Date
</div>

<div class="input-box">

<input type="text"
name="starting_date"
id="starting_date"
class="input-field"
value="<%=displayDate%>"
placeholder="DD/MM/YYYY"
required>

</div>

</div>

<!-- ENDING DATE -->

<div class="parameter-group">

<div class="parameter-label">
Ending Date
</div>

<div class="input-box">

<input type="text"
name="ending_date"
id="ending_date"
class="input-field"
value="<%=displayDate%>"
placeholder="DD/MM/YYYY"
required>

</div>

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

<div style="text-align:center; margin-top:25px;">

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

<!-- ================= SCRIPT ================= -->

<script>

function validateForm(){

    var productCode =
        document.getElementById(
            "product_code"
        ).value.trim();

    var fromAgent =
        document.getElementById(
            "from_agent_code"
        ).value.trim();

    var toAgent =
        document.getElementById(
            "to_agent_code"
        ).value.trim();

    var startingDate =
        document.getElementById(
            "starting_date"
        ).value.trim();

    var endingDate =
        document.getElementById(
            "ending_date"
        ).value.trim();

    var errorBox =
        document.getElementById(
            "errorBox"
        );

    errorBox.innerHTML = "";

    if(productCode === ""){

        errorBox.innerHTML =
            "Please Enter Product Code";

        return false;
    }

    if(fromAgent === ""){

        errorBox.innerHTML =
            "Please Enter From Agent Code";

        return false;
    }

    if(toAgent === ""){

        errorBox.innerHTML =
            "Please Enter To Agent Code";

        return false;
    }

    if(startingDate === ""){

        errorBox.innerHTML =
            "Please Select Starting Date";

        return false;
    }

    if(endingDate === ""){

        errorBox.innerHTML =
            "Please Select Ending Date";

        return false;
    }

    return true;
}

/* ================= DATE VALIDATION ================= */

function isValidDate(dateString){

    var regex =
        /^(\d{2})\/(\d{2})\/(\d{4})$/;

    return regex.test(dateString);
}

document.getElementById(
    "starting_date"
).addEventListener("blur",function(){

    if(!isValidDate(this.value)){

        alert(
            "Invalid Starting Date Format"
        );

        this.focus();
    }
});

document.getElementById(
    "ending_date"
).addEventListener("blur",function(){

    if(!isValidDate(this.value)){

        alert(
            "Invalid Ending Date Format"
        );

        this.focus();
    }
});

</script>

</body>
</html>