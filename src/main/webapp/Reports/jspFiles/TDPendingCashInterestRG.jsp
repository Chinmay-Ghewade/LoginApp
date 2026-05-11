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

if(sessionDate == null || sessionDate.trim().equals("")){

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

/* =========================================================
   SESSION VALUES
========================================================= */

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

String userId =
    (String)session.getAttribute("userId");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";

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

    if(branchCode == null ||
       branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    /* ==========================================
       SECURITY
    ========================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* ==========================================
       VALIDATION
    ========================================== */

    if(branchCode == null ||
       branchCode.trim().equals("")){

        out.println("<h3 style='color:red'>");
        out.println("Branch Code Required");
        out.println("</h3>");
        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ==========================================
           LOAD REPORT
        ========================================== */

        String jasperPath =
            application.getRealPath(
                "/Reports/TDPendingCashInterestRG.jasper"
            );

        File file = new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : " + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(file);

        /* ==========================================
           PARAMETERS
        ========================================== */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);
        parameters.put("branch_codefilter%",branchCode + "%");
        parameters.put("as_on_date",displayDate);
        parameters.put("report_title","TD PENDING CASH INTEREST REPORT");
        parameters.put("session_date",displayDate);
        parameters.put("user_id",userId);
        
        parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));


        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* ==========================================
           FILL REPORT
        ========================================== */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn
            );

        /* ==========================================
           NO RECORDS
        ========================================== */

        if(jasperPrint.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;");
            out.println("text-align:center;");
            out.println("margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        /* ==========================================
           PDF EXPORT
        ========================================== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"TDPendingCashInterestReport.pdf\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager
                .exportReportToPdfStream(
                    jasperPrint,
                    outStream
                );

            outStream.flush();
            outStream.close();

            return;
        }

        /* ==========================================
           EXCEL EXPORT
        ========================================== */

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"TDPendingCashInterestReport.xls\""
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
            "<h3 style='color:red'>"
        );

        out.println(
            "Error Generating Report"
        );

        out.println("</h3>");

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
TD Pending Cash Interest Report
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
    margin-top:30px;
}

.report-title{
    text-align:center;
    color:#2D2B80;
    margin-bottom:30px;
}

.parameter-section{
    display:grid;
    grid-template-columns:
        repeat(2,1fr);

    gap:25px;
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
    height:38px;
    padding-left:10px;
    border:1px solid #ccc;
    border-radius:6px;
}

.input-box{
    display:flex;
    gap:10px;
}

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:42px;
    border-radius:6px;
    cursor:pointer;
}

.download-button{
    margin-top:30px;
    width:220px;
    height:45px;
    border:none;
    background:#2D2B80;
    color:white;
    font-size:16px;
    border-radius:8px;
    cursor:pointer;
}
.format-section{
    margin-top:25px;
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
    background:#fff;
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
    padding:6px 12px;
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

<h1 class="report-title">
TD PENDING CASH INTEREST REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/TDPendingCashInterestRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden"
       name="action"
       value="download">

<!-- ==========================================
     PARAMETERS
========================================== -->

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
       maxlength="4"
       class="input-field"
       value="<%=sessionBranchCode%>"
       <%= !"Y".equalsIgnoreCase(isSupportUser)
           ? "readonly"
           : ""
       %>
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

<!-- As On Date -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="text"
       name="as_on_date"
       class="input-field"
       value="<%= displayDate %>"
       placeholder="DD/MM/YYYY"  required>
</div>

</div>

<!-- ==========================================
     REPORT TYPE
========================================== -->

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

&nbsp;&nbsp;&nbsp;

<label>

<input type="radio"
       name="reporttype"
       value="xls">

Excel

</label>

</div>

<!-- ==========================================
     BUTTONS
========================================== -->

<button type="submit"
        class="download-button">

Generate Report

</button>

</form>

</div>

<!-- ==========================================
     LOOKUP MODAL
========================================== -->

<div id="lookupModal"
     class="modal">

<div class="modal-content">

<button class="close-btn"
onclick="closeLookup()">

X

</button>

<h3>
Lookup Details
</h3>

<div id="lookupTable">

</div>

</div>

</div>

<!-- ==========================================
     JAVASCRIPT
========================================== -->

<script>

/* ==========================================
   FORM VALIDATION
========================================== */

document.querySelector("form")
.addEventListener(
    "submit",
    function(e){

        var branchCode =
            document.getElementById(
                "branch_code"
            ).value.trim();

        if(branchCode === ""){

            alert(
                "Please Enter Branch Code"
            );

            e.preventDefault();

            return false;
        }
    }
);

/* ==========================================
   LOOKUP OPEN
========================================== */

function openLookup(type){

    document.getElementById(
        "lookupModal"
    ).style.display = "flex";

    var html = "";

    /* ======================================
       SAMPLE BRANCH LOOKUP TABLE
    ====================================== */

    if(type === "branch"){

        html += "<table border='1' ";
        html += "width='100%' ";
        html += "cellpadding='8'>";

        html += "<tr ";
        html += "style='background:#2D2B80;";
        html += "color:white;'>";

        html += "<th>Branch Code</th>";
        html += "<th>Branch Name</th>";

        html += "</tr>";

        html += "<tr ";
        html += "onclick=\"selectBranch('1001')\">";

        html += "<td>1001</td>";
        html += "<td>Main Branch</td>";

        html += "</tr>";

        html += "<tr ";
        html += "onclick=\"selectBranch('1002')\">";

        html += "<td>1002</td>";
        html += "<td>City Branch</td>";

        html += "</tr>";

        html += "</table>";
    }

    document.getElementById(
        "lookupTable"
    ).innerHTML = html;
}

/* ==========================================
   CLOSE LOOKUP
========================================== */

function closeLookup(){

    document.getElementById(
        "lookupModal"
    ).style.display = "none";
}

/* ==========================================
   SELECT BRANCH
========================================== */

function selectBranch(code){

    document.getElementById(
        "branch_code"
    ).value = code;

    closeLookup();
}

/* ==========================================
   WINDOW CLICK CLOSE
========================================== */

window.onclick = function(event){

    var modal =
        document.getElementById(
            "lookupModal"
        );

    if(event.target == modal){

        modal.style.display = "none";
    }
}

</script>

</body>
</html>