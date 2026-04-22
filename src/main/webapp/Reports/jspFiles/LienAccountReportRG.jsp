<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION ================= */

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

String isSupportUser     = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String user_id           = (String) session.getAttribute("userId");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";
if(user_id==null) user_id="";

/* ================= ACTION ================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String fromProduct= request.getParameter("from_product");
    String toProduct  = request.getParameter("to_product");
    String typeSelect = request.getParameter("type_select");
    String reportType = request.getParameter("reporttype");

    /* 🔒 SECURITY */
    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* ================= CALL PROCEDURE ================= */

        CallableStatement stmt =
        conn.prepareCall("{ call Sp_Report_Lien_Info(?, ?, ?) }");

        stmt.setString(1, branchCode);

        String oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
        .toUpperCase();

        stmt.setString(2, oracleDate);
        stmt.setString(3, user_id);

        stmt.execute();
        conn.commit();

        /* ================= LOAD JASPER (DYNAMIC) ================= */

        String jasperFile = "";

        if("M".equalsIgnoreCase(typeSelect)){
            jasperFile = "LienAccountReportRG(line).jasper";
        }
        else{
            jasperFile = "LienAccountReportRG(NON line).jasper";
        }

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));
        
        /* ================= PARAMETERS ================= */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("from_product", fromProduct);
        params.put("to_product", toProduct);
        params.put("type_select", typeSelect);
        params.put("as_on_date", oracleDate);

        params.put("report_title","LIEN ACCOUNT REGISTER");

        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/") + File.separator);

        params.put("user_id", user_id);

        params.put(JRParameter.REPORT_CONNECTION, conn);

        /* ================= FILL ================= */

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
        
        /* CLEAR BUFFER (IMPORTANT) */
        out.clear();
        out = pageContext.pushBody();

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"LienAccountReport.pdf\"");

            ServletOutputStream os = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp,os);

            os.flush();
            os.close();
            return;
        }

        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"LienAccountReport.xls\"");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT,jp);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,os);

            exporter.exportReport();

            os.flush();
            os.close();
            return;
        }

    }catch(Exception e){

        e.printStackTrace(new PrintWriter(out));

        Throwable cause = e;
        while(cause.getCause()!=null){
            cause = cause.getCause();
        }

        session.setAttribute("errorMessage","Error = "+cause.getMessage());

        response.sendRedirect("LienAccountReportRG.jsp");
        return;
    }
    finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Lien Account Register</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.error-message {
    background:#ffe6e6;
    color:red;
    padding:10px;
    margin-bottom:10px;
    text-align:center;
    border-radius:5px;
    font-weight:bold;
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

/* Lookup Modal */
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

<h1 class="report-title">LIEN REGISTER</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/LienAccountReportRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= BRANCH + DATE (SIDE BY SIDE) ================= -->

<div class="parameter-section">

<!-- Branch Code -->
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

<% if("Y".equalsIgnoreCase(isSupportUser.trim())){ %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<!-- As On Date -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="from_date"
class="input-field"
value="<%=sessionDate%>"
required>
</div>

</div>

<!-- ================= PRODUCT RANGE ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">From Product Code</div>

<div class="input-box">

<input type="text"
name="from_product"
id="from_product_code"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>

</div>
</div>

<div class="parameter-group">

<div class="parameter-label">To Product Code</div>

<div class="input-box">

<input type="text"
name="to_product"
id="to_product_code"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>

</div>
</div>

</div>

<!-- ================= REPORT TYPE + LIEN TYPE ================= -->

<div class="parameter-section">

<!-- Report Type -->
<div class="parameter-group">

<div class="parameter-label">Report Type</div>

<div class="format-options">

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

<!-- Lien / Non-Lien -->
<div class="parameter-group">

<div class="parameter-label">Select</div>

<div class="format-options">

<label>
<input type="radio" name="type_select" value="M" checked>
Lien
</label>

<label>
<input type="radio" name="type_select" value="N">
Non Lien
</label>

</div>

</div>

</div>

<!-- ================= BUTTON ================= -->

<button type="submit" class="download-button">
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