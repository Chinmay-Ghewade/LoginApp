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
String displayDate = "";

try {
    java.util.Date d =
        new java.text.SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new java.text.SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
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

if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String fromProduct = request.getParameter("from_product");
    String toProduct = request.getParameter("to_product");
    String fromAmount = request.getParameter("from_amount");
    String toAmount = request.getParameter("to_amount");

    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");

    /* ✅ DATE FIX */
    SimpleDateFormat in = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

    String oracleFromDate = "";
    String oracleToDate = "";

    if(fromDate != null && !fromDate.isEmpty()){
        java.util.Date d1 = in.parse(fromDate);
        oracleFromDate = outFmt.format(d1).toUpperCase();
    }

    if(toDate != null && !toDate.isEmpty()){
        java.util.Date d2 = in.parse(toDate);
        oracleToDate = outFmt.format(d2).toUpperCase();
    }
    
    String reportType = request.getParameter("reporttype");

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    Connection conn=null;

    try{

        response.reset();
        conn = DBConnection.getConnection();

        String jasperPath =
        application.getRealPath("/Reports/AmountWiseLoanReport.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("from_product",fromProduct);
        params.put("to_product",toProduct);
        params.put("from_amount",fromAmount);
        params.put("to_amount",toAmount);
        params.put("from_date",oracleFromDate);
        params.put("to_date",oracleToDate);
        params.put("user_id",userId);

        /* ✅ REPORT TITLE */
        params.put("report_title","AMOUNT WISE LOAN REPORT");

        /* ✅ AS ON DATE (FROM DATE LIKE REFERENCE) */
        String asOnDate = "";

        if(fromDate != null && !fromDate.isEmpty()){
            
            java.util.Date utilDate =
                new SimpleDateFormat("dd/MM/yyyy").parse(fromDate);

            asOnDate =
                new SimpleDateFormat("dd-MM-yyyy").format(utilDate);
        }

        params.put("as_on_date", asOnDate);

        /* ✅ SUBREPORT FIX */
        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/") + File.separator);
        
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
                "inline; filename=\"AmountWiseLoanReport.pdf\"");

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
                "attachment; filename=\"AmountWiseLoanReport.xls\"");

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
        e.printStackTrace(new java.io.PrintWriter(out));
    }finally{
        if(conn!=null) conn.close();
    }

    return;
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Amount Wise Loan Report</title>

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
AMOUNT WISE LOAN REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/AmountWiseLoanReport.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= BRANCH SECTION ================= -->

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

<!-- ================= PRODUCT SECTION ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">From Product Code</div>

<div class="input-box">
<input type="text"
name="from_product"
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
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>

</div>

</div>

<!-- ================= AMOUNT SECTION ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Amount</div>
<input type="number"
name="from_amount"
class="input-field"
required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Amount</div>
<input type="number"
name="to_amount"
class="input-field"
required>
</div>

</div>

<!-- ================= DATE SECTION ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="text"
       name="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="text"
       name="to_date"
       class="input-field"
       placeholder="DD/MM/YYYY"
       required>
</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

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