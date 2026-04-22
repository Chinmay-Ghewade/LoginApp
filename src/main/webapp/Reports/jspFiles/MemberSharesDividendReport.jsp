<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.io.*,java.text.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION DATE ================= */

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

/* ================= SESSION USER ================= */

String isSupportUser     = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String user_id           = (String) session.getAttribute("user_id");

if(isSupportUser == null) isSupportUser = "N";
if(sessionBranchCode == null) sessionBranchCode = "";
if(user_id == null) user_id = "";

/* ================= DEFAULT VALUES ================= */

String fromyear = "";
String toyear   = "";
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");

    String fromBranch = request.getParameter("frombr_no_0");
    String toBranch   = request.getParameter("tobr_no_0");

    /* 🔒 SECURITY */
    if(!"Y".equalsIgnoreCase(isSupportUser)){
        fromBranch = sessionBranchCode;
        toBranch   = sessionBranchCode;
    }

    String fromDate = request.getParameter("fromyear_0");
    String toDate   = request.getParameter("toyear_0");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* ================= DATE FORMAT ================= */

        String oracleFromDate = "";
        String oracleToDate   = "";

        if(fromDate != null && !fromDate.isEmpty()){
            java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);

            oracleFromDate =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d).toUpperCase();
        }

        if(toDate != null && !toDate.isEmpty()){
            java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd").parse(toDate);

            oracleToDate =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d).toUpperCase();
        }

        /* ================= LOAD REPORT ================= */

        String jasperPath =
        application.getRealPath("/Reports/BnkBtypememberInterestrep.jasper");

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("from_branch", fromBranch);
        parameters.put("to_branch", toBranch);

        parameters.put("from_date", oracleFromDate);
        parameters.put("to_date", oracleToDate);

        parameters.put("user_id", user_id);
        parameters.put("report_title", "MEMBER INTEREST REPORT");

        parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        parameters.put(JRParameter.REPORT_CONNECTION, conn);

        /* ================= FILL ================= */

        JasperPrint jasperPrint =
        JasperFillManager.fillReport(jasperReport, parameters, conn);

        if (jasperPrint.getPages().isEmpty()) {

            response.setContentType("text/html");
            out.println("<h2 style='color:red;text-align:center;'>No Records Found</h2>");
            return;
        }

        /* ================= EXPORT ================= */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=MemberInterestReport.pdf");

            ServletOutputStream os = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint, os);

            os.close();
            return;
        }
        else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=MemberInterestReport.xls");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT, jasperPrint);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM, os);

            exporter.exportReport();

            os.close();
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

        response.sendRedirect("MemberSharesDividendReport.jsp");
        return;
  
    } finally {
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Member Shares Dividend Report</title>

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
MEMBER SHARES DIVIDEND REPORT
</h1>

<form method="post" target="_blank">

<input type="hidden" name="action" value="download">

<!-- BRANCH -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Branch Code</div>
<input type="text"
name="frombr_no_0"
value="<%=sessionBranchCode%>"
class="input-field"
<%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Branch Code</div>
<input type="text"
name="tobr_no_0"
value="<%=sessionBranchCode%>"
class="input-field"
<%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
required>
</div>

</div>

<!-- DATE -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Financial Year</div>
<input type="date" name="fromyear_0"
class="input-field"
value="<%=sessionDate%>"
 required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Financial Year</div>
<input type="date" name="toyear_0"
value="<%=toyear%>" class="input-field" required>
</div>

</div>

<!-- REPORT TYPE -->

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

</body>
</html>