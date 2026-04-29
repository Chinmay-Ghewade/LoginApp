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

if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String asOnDate   = request.getParameter("as_on_date");
    String format     = request.getParameter("format");      // A / N
    String reporttype = request.getParameter("reporttype");  // pdf / xls

    /* ===== SESSION FALLBACK ===== */

    if(branchCode == null || branchCode.trim().equals("")){
        branchCode = (String)session.getAttribute("branchCode");
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = (String)session.getAttribute("branchCode");
    }

    /* ===== VALIDATION ===== */

    if(asOnDate == null || asOnDate.trim().equals("")){
        session.setAttribute("errorMessage","Please Insert As On Date!");
        response.sendRedirect("NewSharesReport.jsp");
        return;
    }

     /* ===== ORDER CONDITION ===== */

    String orderBy = "A";

    if("N".equals(format)){
        orderBy = "N";
    }
    
    /* ===== SQL (FROM SERVLET getSql1) ===== */

   
    Connection conn=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* ===== LOAD JASPER ===== */

        String jasperPath =
        application.getRealPath("/Reports/NewSharesReport.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* ===== PARAMETERS ===== */

        Map<String,Object> params = new HashMap<>();

        params.put("report_title", "NEW SHARES REPORT");
        params.put("branch_code", branchCode);
        java.util.Date d =
        	    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        	String oracleDate =
        	    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
        	    .format(d).toUpperCase();

        	params.put("as_on_date", oracleDate);   // ✅ FIX
        params.put("user_id", session.getAttribute("userId"));

        params.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));
        params.put("orderByField", orderBy);

        params.put(JRParameter.REPORT_CONNECTION, conn);

        /* ===== FILL REPORT ===== */

        JasperPrint print =
        JasperFillManager.fillReport(jasperReport, params, conn);

        if(print.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center'>No Records Found</h2>");
            return;
        }

        /* ===== EXPORT ===== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"NewSharesReport.pdf\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(print, outStream);

            outStream.flush();
            outStream.close();

        }else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"NewSharesReport.xls\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT, print);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
        }

        return;

    }catch(Exception e){

        e.printStackTrace();

        Throwable cause = e;
        while(cause.getCause()!=null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg!=null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute("errorMessage", msg);
        response.sendRedirect("NewSharesReport.jsp");
        return;

    }finally{

        if(conn!=null){
            try{conn.close();}catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>New Shares Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-box{ display:flex; gap:10px; }

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.input-field:disabled{
    background:#e0e0e0;
}

.modal{
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#fff;
    width:80%;
    max-height:85%;
    padding:20px;
    border-radius:8px;
    overflow:auto;
}

.error-box{
    color:red;
    text-align:center;
    margin-bottom:10px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">NEW SHARES REPORT</h1>



<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/NewSharesReport.jsp"
      target="_blank"
      autocomplete="off">

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
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
       required>

   <% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
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
       value="<%=sessionDate%>"
       class="input-field"
       required>
</div>

<!-- REPORT TYPE -->

<div class="parameter-group">
<div class="parameter-label">Report Type</div>

<div class="radio-container">

<label>
<input type="radio" name="format" value="A" checked> Account Wise
</label>

<label>
<input type="radio" name="format" value="N"> Name Wise
</label>

</div>
</div>

</div>

<!-- FORMAT -->

<div class="format-section">

<div class="parameter-label">Format</div>

<div class="format-options">

<label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
<label><input type="radio" name="reporttype" value="xls"> Excel</label>

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
<button onclick="closeLookup()">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>