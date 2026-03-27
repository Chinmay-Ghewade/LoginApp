<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

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

        sessionDate =
            new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date) obj);

    } else {

        sessionDate = obj.toString();
    }
}

/* ❌ NO DEFAULT TODAY DATE */
if (sessionDate == null) {
    sessionDate = "";
}
%>

<%

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reportType  = request.getParameter("reporttype");
    String letterType  = request.getParameter("letter_type");

    String branchCode  = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String fromDate    = request.getParameter("from_date");
    String toDate      = request.getParameter("to_date");

    Connection conn = null;

    try {

        conn = DBConnection.getConnection();

        /* DATE FORMAT */

        SimpleDateFormat inputFormat  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat oracleFormat = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String fromOracle =
                oracleFormat.format(inputFormat.parse(fromDate)).toUpperCase();

        String toOracle =
                oracleFormat.format(inputFormat.parse(toDate)).toUpperCase();

        String asOnDate =
                oracleFormat.format(new java.util.Date()).toUpperCase();


        /* SELECT REPORT */

        String jasperFile;

        if ("WITH_RECEIPT".equals(letterType)) {
            jasperFile = "TDMaturityReminder.jasper";
        } else {
            jasperFile = "TDMaturityReminder(WithoutReceipt).jasper";
        }

        String jasperPath =
                application.getRealPath("/Reports/" + jasperFile);

        File file = new File(jasperPath);

        if (!file.exists()) {
            throw new RuntimeException("Jasper file not found : " + jasperPath);
        }

        JasperReport report =
                (JasperReport) JRLoader.loadObject(file);


        /* PARAMETERS */

        Map<String,Object> param = new HashMap<String,Object>();

        param.put("branch_code", branchCode);
        param.put("product_code", productCode);
        param.put("from_date", fromOracle);
        param.put("To_date", toOracle);
        param.put("as_on_date", asOnDate);
        param.put("report_title","TD MATURITY REMINDER LETTER");

        String userId = (String)session.getAttribute("user_id");
        if(userId == null || userId.trim().equals(""))
            userId = "admin";

        param.put("user_id",userId);

        param.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));


        /* FILL REPORT */

        JasperPrint print =
                JasperFillManager.fillReport(report,param,conn);


        /* PDF */

        if("pdf".equalsIgnoreCase(reportType)){

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"TDMaturityReminder.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(print,outStream);

            outStream.flush();
            outStream.close();
            return;
        }


        /* EXCEL */

        if("xls".equalsIgnoreCase(reportType)){

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"TDMaturityReminder.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                    JRXlsExporterParameter.JASPER_PRINT,print);

            exporter.setParameter(
                    JRXlsExporterParameter.OUTPUT_STREAM,outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
            return;
        }

    }
    catch(Exception e){

        response.setContentType("text/html");

        out.println("<h2 style='color:red'>Report Error</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");

        return;
    }
    finally{

        if(conn!=null){
            try{conn.close();}catch(Exception ex){}
        }
    }
}
%>


<!DOCTYPE html>
<html>
<head>

<title>TD Maturity Reminder Letter</title>

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
TD MATURITY REMINDER LETTER
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/TDMaturityReminder.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>


<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>
<div class="input-box">
            <input type="text"
                   name="branch_code"
                   id="branch_code"
                   class="input-field"
                   required>

            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('branch')">…</button>
        </div>
</div>


<div class="parameter-group">
<div class="parameter-label">Product Code</div>
<div class="input-box">
            <input type="text"
                   name="product_code"
                   id="product_code"
                   class="input-field">

            <button type="button"
                    class="icon-btn"
                    onclick="openLookup('product')">…</button>
        </div>
        
</div>

<div class="parameter-group">
<div class="parameter-label">Product Description</div>

<input type="text"
       name="productName"
       id="productName"
       class="input-field"
       readonly>
</div>


<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date" name="from_date"
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


<div class="format-section">

<div class="parameter-label">Letter Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="letter_type"
value="WITH_RECEIPT" checked>
With Receipt No
</div>

<div class="format-option">
<input type="radio" name="letter_type"
value="WITHOUT_RECEIPT">
Without Receipt No
</div>

</div>

</div>


<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="reporttype"
value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype"
value="xls"> Excel
</div>

</div>

</div>


<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>