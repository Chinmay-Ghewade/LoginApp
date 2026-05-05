<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.io.*,java.text.*" %>
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

// fallback
if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String displayDate = "";

try {
    java.util.Date d =
        new java.text.SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new java.text.SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");

    SimpleDateFormat inFmt = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat outFmt = new SimpleDateFormat("yyyy-MM-dd");

    if(fromDate != null && !fromDate.isEmpty()){
        fromDate = outFmt.format(inFmt.parse(fromDate));
    }

    if(toDate != null && !toDate.isEmpty()){
        toDate = outFmt.format(inFmt.parse(toDate));
    }
    
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    /* 🔒 SECURITY */
    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */
    if(fromDate == null || fromDate.trim().equals("")){
        session.setAttribute("errorMessage","Enter From Date!!!");
        response.sendRedirect("BTypeLoanInterest.jsp");
        return;
    }

    if(toDate == null || toDate.trim().equals("")){
        session.setAttribute("errorMessage","Enter To Date!!!");
        response.sendRedirect("BTypeLoanInterest.jsp");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        response.setHeader("Cache-Control","no-store, no-cache, must-revalidate");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader("Expires",0);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* 🔥 CALL STORED PROCEDURE */
        CallableStatement cs =
        conn.prepareCall("{ call Sp_BTYPE_MEMBER_REPORT(?,?,?) }");

        cs.setString(1, branchCode);
        cs.setString(2, fromDate);
        cs.setString(3, toDate);
        cs.execute();

        conn.commit();

        /* LOAD JASPER */
        String jasperPath =
        application.getRealPath("/Reports/BnkBtypememberInterestrep.jasper");

        File jasperFile = new File(jasperPath);

        if(!jasperFile.exists()){
            throw new RuntimeException("Jasper file not found : " + jasperPath);
        }

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(jasperFile);

        /* PARAMETERS */
        Map<String,Object> param = new HashMap<>();

        param.put("branch_code", branchCode);
        param.put("from_date", fromDate);
        param.put("to_date", toDate);
        param.put("user_id", userId);

        param.put(JRParameter.REPORT_CONNECTION, conn);

        /* FILL REPORT */
        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport, param, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* EXPORT PDF */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
            "inline; filename=\"BTypeLoanInterest.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        /* EXPORT XLS */
        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
            "attachment; filename=\"BTypeLoanInterest.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT, jp);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM, outStream);

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

        response.sendRedirect("BTypeLoanInterest.jsp");
        return;

    } finally {

        if(conn != null){
            try{ conn.close(); } catch(Exception ex){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>B-Type Loan Interest</title>

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
B-TYPE LOAN INTEREST REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/BTypeLoanInterest.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch -->
<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%= sessionBranchCode %>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button" class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- From Date -->
<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="text"
       name="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>
</div>

<!-- To Date -->
<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="text"
       name="to_date"
       class="input-field"
       placeholder="DD/MM/YYYY"
       required>
   </div>

</div>

<!-- Report Type -->
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

<!-- Lookup Modal -->
<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>