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

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";
%>

<%
String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String fromProduct = request.getParameter("from_product");
    String toProduct = request.getParameter("to_product");
    String asOnDate = request.getParameter("date");

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* DATE FORMAT */
    String oracleDate="";
    if(asOnDate!=null && !asOnDate.isEmpty()){
        java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

        oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(d).toUpperCase();
    }

    Connection conn=null;

    try{

        response.reset();
        conn = DBConnection.getConnection();

        String jasperPath =
        application.getRealPath("/Reports/OtherChargesReport.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("from_product", fromProduct);   // ✅ FIXED
        params.put("to_product", toProduct); 
        params.put("as_on_date",oracleDate);

        /* REPORT TITLE */
        params.put("report_title","OTHER CHARGES REPORT");

        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/") + File.separator);

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

        String reportType = request.getParameter("reporttype");

        /* ================= PDF ================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"OtherChargesReport.pdf\"");

            /* IMPORTANT: clear JSP buffer */
            out.clear();
            out = pageContext.pushBody();

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
                "attachment; filename=\"OtherChargesReport.xls\"");

            /* IMPORTANT: clear JSP buffer */
            out.clear();
            out = pageContext.pushBody();

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
        e.printStackTrace(new PrintWriter(out));
    }finally{
        if(conn!=null) conn.close();
    }

    return;
}
%>

<!DOCTYPE html>
<html>

<head>

<title>OTHER CHARGES REPORT</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=1">
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

<h1 class="report-title">
OTHER CHARGES REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/OtherChargesReport.jsp"
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
    <input type="text" id="branchName" class="input-field" readonly>
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

<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
name="date"
id="date"
class="input-field"
value="<%=sessionDate%>" 
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
checked>
PDF
</div>

<div class="format-option">
<input type="radio"
name="reporttype"
value="xls">
Excel
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