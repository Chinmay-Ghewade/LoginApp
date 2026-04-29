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
/* ===== SESSION ===== */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.equals("")) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(sessionBranchCode == null) sessionBranchCode="";
if(isSupportUser == null) isSupportUser="N";
%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String branchCode  = request.getParameter("branch_code");
    String memberType  = request.getParameter("member_type");
    String asOnDate    = request.getParameter("as_on_date");
    String reporttype  = request.getParameter("reporttype");

    if(branchCode == null || branchCode.trim().equals("")){
        branchCode = (String)session.getAttribute("branchCode");
    }

    if(memberType == null) memberType="";

    /* ===== VALIDATION ===== */

    if(memberType.trim().equals("")){
        out.println("<h3 style='color:red'>Member Type Cannot be Empty</h3>");
        return;
    }

    /* ===== DATE FORMAT ===== */

    String oracleDate="";

    if(asOnDate!=null && !asOnDate.equals("")){
        java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
            new SimpleDateFormat("dd/MM/yyyy").format(d);
    }

    /* ===== SQL (FROM SERVLET getSql()) ===== */

    String sql =
    " SELECT TO_NUMBER(substr(account_code,8,14)) SHARES_NO, "+
    " NAME, "+
    " FN_GET_MEMBER_ADDRESS (substr(account_code,1,4),'A',substr(account_code,8,14)) ADDRESS, "+
    " TO_CHAR(DATEACCOUNTOPEN,'DD/MM/YYYY') OPEN_D, "+
    " TO_CHAR(DATEACCOUNTCLOSE,'DD/MM/YYYY') CLOSE_D "+
    " FROM account.account "+
    " WHERE SUBSTR(ACCOUNT_CODE,1,4) = '"+branchCode+"' "+
    " AND SUBSTR(ACCOUNT_CODE,5,3) = ( "+
    "   SELECT MEMBER_PRODUCT "+
    "   FROM SHARES.MEMBERTYPE_MASTER "+
    "   WHERE MEMBER_TYPECODE = '"+memberType+"' "+
    " ) "+
    " ORDER BY ACCOUNT_CODE ";

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* ===== LOAD JASPER ===== */

        String jasperPath =
        application.getRealPath("/Reports/J_Report.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* ===== PARAMETERS ===== */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("report_title","J REPORT");
        params.put("member_type", memberType);


        params.put("user_id", session.getAttribute("userId"));

        params.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION, conn);

        /* ===== FILL REPORT ===== */

        JasperPrint print =
        JasperFillManager.fillReport(jasperReport, params, conn);

        if (print.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ===== EXPORT ===== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"J_Report.pdf\"");

            ServletOutputStream outStream =
            response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(print, outStream);

            outStream.flush();
            outStream.close();

        }else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"J_Report.xls\"");

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
        response.sendRedirect("J_Report.jsp");
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

<title>J REPORT</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js?v=4"></script>

<style>

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
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
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    padding:20px;
    border-radius:8px;
    overflow:auto;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">J REPORT</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/J_Report.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- 🔹 Branch Code -->

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

<!-- 🔹 Branch Name (ADDED LIKE REFERENCE) -->

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- 🔹 Member Type -->

<div class="parameter-group">

<div class="parameter-label">Member Type</div>

<div class="input-box">

<input type="text"
       name="member_type"
       id="member_type"
       class="input-field"
       placeholder="Enter Member Type">

<button type="button"
        class="icon-btn"
        onclick="openLookup('memberType')">…</button>

</div>

</div>

<!-- 🔹 Description (IMPORTANT FROM SERVLET) -->

<div class="parameter-group">
<div class="parameter-label">Description</div>

<input type="text"
       name="memberTypeName"
       id="memberTypeName"
       class="input-field"
       readonly>
</div>

<!-- 🔹 As On Date -->

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

</div>

<!-- 🔹 FORMAT -->

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

<!-- 🔹 POPUP -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>