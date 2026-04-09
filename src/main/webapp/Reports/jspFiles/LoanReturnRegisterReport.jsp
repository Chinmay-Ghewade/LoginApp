<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.text.*, java.util.*" %>
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

%>

<%
String user_id = (String) session.getAttribute("user_id");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(user_id == null) user_id="";
if(sessionBranchCode == null) sessionBranchCode="";
if(isSupportUser == null) isSupportUser="N";
%>

<%
String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode   = request.getParameter("branch_code");
    String product_code = request.getParameter("product_code");
    String fromDate     = request.getParameter("from_date");
    String toDate       = request.getParameter("to_date");
    String format       = request.getParameter("format");

    // ✅ ADD THIS (report type)
    String reporttype   = request.getParameter("reporttype");
    if(reporttype == null) reporttype = "pdf";

    // 🔒 SECURITY
    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    Connection conn = null;

    try{

        response.reset();
        conn = DBConnection.getConnection();

        // DATE FORMAT
        if(fromDate != null && !fromDate.equals("")){
            java.util.Date d = new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);
            fromDate = new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
                        .format(d).toUpperCase();
        }

        if(toDate != null && !toDate.equals("")){
            java.util.Date d = new SimpleDateFormat("yyyy-MM-dd").parse(toDate);
            toDate = new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
                        .format(d).toUpperCase();
        }

        // REPORT SELECT
        String reportFile = "LoanReturnRegisterReport.jasper";

        if("S".equals(format)){
            reportFile = "LoanReturnRegisterReportSubmission.jasper";
        }

        String path = application.getRealPath("/Reports/" + reportFile);

        JasperReport jr =
            (JasperReport) JRLoader.loadObject(new java.io.File(path));

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("from_date", fromDate);
        params.put("to_date", toDate);
        params.put("product_code", product_code);
        params.put("user_id", user_id);

        params.put("SUBREPORT_DIR", application.getRealPath("/Reports/"));
        params.put(JRParameter.REPORT_CONNECTION, conn);

        JasperPrint jp = JasperFillManager.fillReport(jr, params, conn);

        if(jp.getPages().isEmpty()){
            out.println("<h3 style='color:red'>No Records Found</h3>");
            return;
        }

        ServletOutputStream outStream = response.getOutputStream();

        /* =====================================
           PDF EXPORT
        ===================================== */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=LoanReturnReport.pdf"); // change to attachment if needed

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* =====================================
           EXCEL EXPORT
        ===================================== */
        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=LoanReturnReport.xls");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jp);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
            return;
        }
    }catch(Exception e){

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

        response.sendRedirect("LoanReturnRegisterReport.jsp");
        return;
  
    }finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Loan Return Register Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
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
    background:#fff;
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

<h1 class="report-title">Loan Return Register Report</h1>

<form method="post"
      action="LoanReturnRegisterReport.jsp"
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
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
<button type="button" class="icon-btn"
onclick="openLookup('branch','branch_code')">…</button>
<% } %>
</div>
</div>

<!-- Product -->
<div class="parameter-group">
<div class="parameter-label">Product Code</div>

<div class="input-box">
<input type="text" name="product_code" id="product_code" class="input-field">

<button type="button" class="icon-btn"
onclick="openLookup('product','product_code')">…</button>
</div>
</div>

<!-- Dates -->
<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date" name="from_date" class="input-field"        
value="<%=sessionDate%>" required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date" name="to_date" class="input-field" required>
</div>

<!-- 🔥 REPORT TYPE + FORMAT SIDE BY SIDE -->
<div style="display:flex; gap:120px; align-items:center; margin-top:30px;">

    <!-- REPORT TYPE FIRST -->
    <div class="parameter-group">

        <div class="parameter-label">Report Type</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <div class="format-option">
                <input type="radio" name="reporttype" value="pdf" checked>
                PDF
            </div>

            <div class="format-option">
                <input type="radio" name="reporttype" value="xls">
                Excel
            </div>

        </div>
    </div>

    <!-- FORMAT NEXT -->
    <div class="parameter-group">

        <div class="parameter-label">Format</div>

        <div class="format-options" style="display:flex; gap:20px;">

            <div class="format-option">
                <input type="radio" name="format" value="R" checked>
                Return
            </div>

            <div class="format-option">
                <input type="radio" name="format" value="S">
                Submission
            </div>

        </div>
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