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

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

/* DEBUG (remove later) */
// out.println("Action = " + action);

if ("download".equalsIgnoreCase(action)) {

    String reporttype = request.getParameter("reporttype");
    String reportName = request.getParameter("report_name");
    String branchCode = request.getParameter("branch_code");
    String asOnDate   = request.getParameter("as_on_date");

    String userId = (String) session.getAttribute("userId");

    /* SESSION FALLBACK */
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control","no-store, no-cache, must-revalidate");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader("Expires",0);

        conn = DBConnection.getConnection();

        /* ================= JASPER ================= */

        String jasperFile = "";

        if("balance".equals(reportName)){
            jasperFile = "LoanClassificationReport(Balance Wise).jasper";
        }
        else if("intrate".equals(reportName)){
            jasperFile = "LoanClassificationReport (int. rate).jasper";
        }
        else if("limit".equals(reportName)){
            jasperFile = "LoanClassificationReport(limitWise).jasper";
        }
        else if("intlist".equals(reportName)){
            jasperFile = "LoanClassificationReport(LoanIntList).jasper";
        }
        else if("overdue".equals(reportName)){
            jasperFile = "LoanClassificationReport (LoanOverdue).jasper";
        }
        else if("period".equals(reportName)){
            jasperFile = "LoanClassificationReport(Period Wise).jasper";
        }
        else if("sanction".equals(reportName)){
            jasperFile = "LoanClassificationReport(Sanction Amt Wise).jasper";
        }
        else {
            // fallback
            jasperFile = "LoanClassificationReport(Balance Wise).jasper";
        }

        /* FILE PATH */
        String jasperPath = application.getRealPath("/Reports/" + jasperFile);

        File file = new File(jasperPath);

        if (!file.exists()) {
            out.println("<h3 style='color:red'>Jasper File Not Found: " + jasperFile + "</h3>");
            return;
        }

        JasperReport jr = (JasperReport) JRLoader.loadObject(file);

        /* PARAMETERS */
        Map<String,Object> param = new HashMap<>();

        param.put("branch_code", branchCode);
        param.put("as_on_date", asOnDate);
        param.put("report_title","LOAN CLASSIFICATION REPORT");
        param.put("user_id", userId);
        
        param.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        param.put(JRParameter.REPORT_CONNECTION, conn);

        /* FILL REPORT */
        JasperPrint jp = JasperFillManager.fillReport(jr, param, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* EXPORT */

        if ("pdf".equalsIgnoreCase(reporttype)) {

    response.reset();
    response.setContentType("application/pdf");

    response.setHeader(
        "Content-Disposition",
        "inline; filename=\"LoanClassificationReport.pdf\""
    );

    ServletOutputStream outStream = response.getOutputStream();

    JasperExportManager.exportReportToPdfStream(jp, outStream);

    outStream.flush();
    outStream.close();

    return;
}
else if ("xls".equalsIgnoreCase(reporttype)) {

    response.reset();
    response.setContentType("application/vnd.ms-excel");

    response.setHeader(
        "Content-Disposition",
        "attachment; filename=\"LoanClassificationReport.xls\""
    );

    ServletOutputStream outStream = response.getOutputStream();

    JRXlsExporter exporter = new JRXlsExporter();

    exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
    exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

    exporter.exportReport();

    outStream.flush();
    outStream.close();

    return;
}

    } catch(Exception e){

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

        response.sendRedirect("LoanClassificationReport.jsp");
        return;
    }  finally {

        if(conn!=null){
            try{conn.close();}catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Loan Classification Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

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

.report-options {
    display:flex;
    flex-wrap:wrap;
    gap:15px;
    margin-top:5px;
}

</style>

</head>

<body>

<div class="report-container">

<%
String errorMessage = (String)session.getAttribute("errorMessage");

if(errorMessage != null){
%>
<div class="error-message"><%=errorMessage%></div>
<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">
LOAN CLASSIFICATION REPORT
</h1>

<!-- ✅ FIXED FORM ACTION -->
<form method="post"
action="LoanClassificationReport.jsp"
target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch Code -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%= sessionBranchCode %>"
<%= !"Y".equalsIgnoreCase(isSupportUser != null ? isSupportUser.trim() : "") ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser != null ? isSupportUser.trim() : "")) { %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- DATE -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
class="input-field"
value="<%=sessionDate%>"  
required>
</div>

</div>

<!-- REPORT SELECTION -->
<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Report</div>

<div class="report-options">

<label><input type="radio" name="report_name" value="balance" checked> Balance Wise</label>

<label><input type="radio" name="report_name" value="intrate"> Interest Rate</label>

<label><input type="radio" name="report_name" value="limit"> Limit Wise</label>

<label><input type="radio" name="report_name" value="intlist"> Loan Int List</label>

<label><input type="radio" name="report_name" value="overdue"> Loan Overdue</label>

<label><input type="radio" name="report_name" value="period"> Period Wise</label>

<label><input type="radio" name="report_name" value="sanction"> Sanction Amt Wise</label>

</div>

</div>

</div>

<!-- FORMAT -->
<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls"> Excel
</div>

</div>

</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- LOOKUP MODAL -->
<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>