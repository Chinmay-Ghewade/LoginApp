<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page import="java.io.File,java.io.PrintWriter" %>

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
%>

<%
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";
%>

<%
String action = request.getParameter("action");

if("validate".equals(action)){

    String accountCode = request.getParameter("account_code");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");

    if(accountCode==null || accountCode.trim().equals("")){
        out.println("<script>alert('Enter Account Code');history.back();</script>");
        return;
    }

    if(fromDate==null || fromDate.trim().equals("")){
        out.println("<script>alert('Enter From Date');history.back();</script>");
        return;
    }

    if(toDate==null || toDate.trim().equals("")){
        out.println("<script>alert('Enter To Date');history.back();</script>");
        return;
    }

    Connection conn=null;

    try{
        conn = DBConnection.getConnection();

        CallableStatement stmt =
        conn.prepareCall("{ call sp_report_daily_products( ?, ?, ?) }");

        stmt.setString(1, accountCode);
        stmt.setString(2, fromDate);
        stmt.setString(3, toDate);

        stmt.execute();
        stmt.close();

        conn.commit();

        out.println("<script>alert('Validated Successfully');</script>");
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

        response.sendRedirect("ProductDisplay.jsp");
        return;
    
    }finally{
        if(conn!=null) conn.close();
    }

    return;
}
%>

<%
if("download".equals(action)){

    String accountCode = request.getParameter("account_code");
    String reportType = request.getParameter("reporttype");

    Connection conn=null;

    try{

        response.reset();
        conn = DBConnection.getConnection();

        String jasperPath =
        application.getRealPath("/Reports/ProductDisplay.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("account_code",accountCode);
        params.put("report_title","PRODUCT DISPLAY");
        params.put("user_id",userId);

        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport,params,conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= PDF ================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"ProductDisplay_Report.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        /* ================= EXCEL ================= */
        else if ("xls".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"ProductDisplay_Report.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

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

        response.sendRedirect("ProductDisplay.jsp");
        return;

    }finally{
        if(conn!=null) conn.close();
    }

    return;
}
%>

<!DOCTYPE html>
<html>
<head>

<title>PRODUCT DISPLAY</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

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
PRODUCT DISPLAY
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/ProductDisplay.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= BRANCH ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">Branch Code</div>

<div class="input-box">

<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
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
    <input type="text" id="branchName"
           class="input-field" readonly>
</div>

</div>

<!-- ================= ACCOUNT ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">Account Code</div>

<div class="input-box">

<input type="text"
name="account_code"
id="account_code"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('account')">…</button>

</div>

</div>

<div class="parameter-group">
<div class="parameter-label">Account Name</div>
<input type="text"
id="account_name"
class="input-field"
readonly>
</div>

</div>

<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
name="from_date"
class="input-field"
value="<%=sessionDate%>"
required>

</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
name="to_date"
class="input-field"
required>

</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
name="reporttype"
value="pdf"
checked> PDF
</div>

<div class="format-option">
<input type="radio"
name="reporttype"
value="xls"> Excel
</div>

</div>

</div>

<!-- ================= BUTTON ================= -->

<button type="submit"
class="download-button">
Generate Report
</button>

</form>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>