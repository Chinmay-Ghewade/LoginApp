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

String displayDate = "";

try {
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reportType  = request.getParameter("reporttype");
    String branchCode  = request.getParameter("branch_code");
    String fromDateStr = request.getParameter("from_date");
    String toDateStr   = request.getParameter("to_date");
    String reportSel   = request.getParameter("report_select");

    if(branchCode == null || branchCode.trim().isEmpty()){
        branchCode = (String) session.getAttribute("branchCode");
    }

   
    /* ===== VALIDATION ===== */

    if(fromDateStr == null || fromDateStr.trim().equals("")){
        out.println("<h3 style='color:red'>From Date Required</h3>");
        return;
    }

    if(toDateStr == null || toDateStr.trim().equals("")){
        out.println("<h3 style='color:red'>To Date Required</h3>");
        return;
    }

    java.util.Date fromDate = null;
    java.util.Date toDate   = null;

    try{
        fromDate = new SimpleDateFormat("dd/MM/yyyy").parse(fromDateStr);
        toDate   = new SimpleDateFormat("dd/MM/yyyy").parse(toDateStr);
    }catch(Exception e){
        out.println("<h3 style='color:red'>Invalid Date Format</h3>");
        return;
    }

    if(fromDate.after(toDate)){
        out.println("<h3 style='color:red'>From Date must be <= To Date</h3>");
        return;
    }

    /* ===== DATE FORMAT FOR ORACLE ===== */

    String fromDateOracle =
        new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
        .format(fromDate).toUpperCase();

    String toDateOracle =
        new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
        .format(toDate).toUpperCase();

    /* ===== CONDITION (FROM SERVLET LOGIC) ===== */

    String condition = "";

    if("D".equals(reportSel)){
        condition = " AND GL.CODETYPE LIKE 'DD%' ";
    } else if("L".equals(reportSel)){
        condition = " AND GL.CODETYPE LIKE 'LL%' ";
    } else if("P".equals(reportSel)){
        condition = " AND GL.ALIE IN ('I','E') ";
    } else {
        condition = "";
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* ===== LOAD JASPER ===== */

        String jasperPath =
        application.getRealPath("/Reports/ConsolidatedGLReportFrom_ToDate.jasper");

        JasperReport jasperReport =
        (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ===== PARAMETERS (CORRECT AS PER JRXML) ===== */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);

        /* VERY IMPORTANT FIX */
        params.put("as_on_date", fromDateOracle);   // FIRST DATE
        params.put("to_date", toDateOracle);        // SECOND DATE

        /* MATCH JRXML PARAM NAME */
        params.put("reportSelect", reportSel);

        params.put("report_title",
            "GL BALANCE REPORT FROM " + fromDateStr + " TO " + toDateStr);

        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);

        params.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION, conn);
        /* ===== FILL REPORT ===== */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, params, conn);

        /* ===== NO DATA ===== */

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ===== EXPORT ===== */

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"GLBalance_FromTo.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        else if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"GLBalance_FromTo.xls\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

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

    } catch(Exception e){

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new PrintWriter(out));

    } finally {

        if(conn != null){
            try { conn.close(); } catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>GL Balance Report </title>

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

.radio-container{
    display:flex;
    gap:25px;
    margin-top:8px;
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
GL BALANCE REPORT 
</h1>

<form method="post"
      action="ConsolidatedGLReportFrom_ToDate.jsp"
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
           <%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
           required>

    <% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
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

<!-- FROM DATE -->

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="text"
       name="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>
</div>

<!-- TO DATE -->

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="text"
       name="to_date"
       class="input-field"
       placeholder="DD/MM/YYYY"
       required>
</div>

<!-- REPORT TYPE SELECT -->

<div class="parameter-group">

<div class="parameter-label">Select Type</div>

<div class="radio-container">

<label>
<input type="radio" name="report_select" value="L" checked>
Loan
</label>

<label>
<input type="radio" name="report_select" value="D">
Deposit
</label>

<label>
<input type="radio" name="report_select" value="A">
All
</label>

<label>
<input type="radio" name="report_select" value="P">
P&L
</label>

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

<!-- POPUP -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>