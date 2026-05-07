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
/* ================= SESSION DATA ================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

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
    String letterType  = request.getParameter("letter_type");

    String branchCode  = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String allProducts = request.getParameter("all_products");
    
    if(allProducts == null){
        allProducts = "SINGLE";
    }

    /* 🔥 SAME AS JAVA LOGIC */
    if ("ALL".equalsIgnoreCase(allProducts)) {
        productCode = null;   // ignore product filter
    }
    String fromDate    = request.getParameter("from_date");
    String toDate      = request.getParameter("to_date");

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {

        /* ================= VALIDATION ================= */

        if(branchCode == null || branchCode.trim().equals("")){
            out.println("<h3 style='color:red'>Branch Code is required</h3>");
            return;
        }

        if(fromDate == null || fromDate.trim().equals("")){
            out.println("<h3 style='color:red'>From Date is required</h3>");
            return;
        }

        if(toDate == null || toDate.trim().equals("")){
            out.println("<h3 style='color:red'>To Date is required</h3>");
            return;
        }

        /* ================= DATE FORMAT ================= */

        SimpleDateFormat inputFormat  = new SimpleDateFormat("dd/MM/yyyy");
        SimpleDateFormat oracleFormat = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String fromOracle = oracleFormat.format(inputFormat.parse(fromDate)).toUpperCase();
        String toOracle   = oracleFormat.format(inputFormat.parse(toDate)).toUpperCase();

        String asOnDate   = oracleFormat.format(new java.util.Date()).toUpperCase();

        /* ================= DB CONNECTION ================= */

        conn = DBConnection.getConnection();
        

        if (!"ALL".equalsIgnoreCase(allProducts)) {

            if(productCode == null || productCode.trim().equals("")){
                out.println("<h3 style='color:red'>Product Code is required</h3>");
                return;
            }

            ps = conn.prepareStatement(
                "SELECT 1 FROM HEADOFFICE.TDPRODUCTS WHERE PRODUCT_CODE = ?"
            );

            ps.setString(1, productCode);
            rs = ps.executeQuery();

            if(!rs.next()){
                out.println("<h3 style='color:red;text-align:center;margin-top:50px;'>No data available for this product!</h3>");
                return;
            }
        }

        /* ================= LOAD / CACHE REPORT ================= */

        String jasperFile;

        if ("WITH_RECEIPT".equals(letterType)) {
            jasperFile = "TDMaturityReminder.jasper";
        } else {
            jasperFile = "TDMaturityReminder(WithoutReceipt).jasper";
        }

        String jasperPath = application.getRealPath("/Reports/" + jasperFile);

        File file = new File(jasperPath);

        if (!file.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        // 🔥 CACHE REPORT
        JasperReport report = (JasperReport)application.getAttribute(jasperFile);

        if(report == null){
            report = (JasperReport) JRLoader.loadObject(file);
            application.setAttribute(jasperFile, report);
        }

        /* ================= PARAMETERS ================= */

        Map<String,Object> param = new HashMap<>();

        param.put("branch_code", branchCode);
        if(productCode != null && !productCode.trim().equals("")){
            param.put("product_code", productCode);
        } else {
            param.put("product_code", null);
        }        param.put("from_date", fromOracle);
        param.put("To_date", toOracle);
        param.put("as_on_date", asOnDate);
        param.put("report_title","TD MATURITY REMINDER LETTER");

        String userId = (String) session.getAttribute("userId");

        if(userId == null || userId.trim().equals("")){
            userId = "admin";
        }

        param.put("user_id", userId);

        param.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        /* ================= FILL REPORT ================= */

        JasperPrint print = JasperFillManager.fillReport(report, param, conn);

        if (print.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        /* ================= EXPORT ================= */

        response.reset();
        response.setBufferSize(1024 * 1024);

        ServletOutputStream outStream = response.getOutputStream();

        /* ===== PDF ===== */
        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"TDMaturityReminder.pdf\"");

            JasperExportManager.exportReportToPdfStream(print, outStream);
        }

        /* ===== EXCEL ===== */
        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"TDMaturityReminder.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT, print);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            // 🔥 PERFORMANCE OPTIONS
            exporter.setParameter(
                JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);

            exporter.setParameter(
                JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);

            exporter.exportReport();
        }

        outStream.flush();
        outStream.close();
        return;

    } catch(Exception e){

        response.setContentType("text/html");

        out.println("<h2 style='color:red'>Report Error</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");

        return;

    } finally {

        if(rs != null){
            try{ rs.close(); } catch(Exception e){}
        }

        if(ps != null){
            try{ ps.close(); } catch(Exception e){}
        }

        if(conn != null){
            try{ conn.close(); } catch(Exception ex){}
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

<!-- 🔹 Branch Code -->

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

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %> <button type="button"
     class="icon-btn"
     onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<!-- 🔹 Branch Name -->

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
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
        
    <div class="parameter-label">

    <label>
        <input type="radio" name="all_products" value="ALL"
               onclick="toggleProduct(this)">
        All Products
    </label>

    <label>
        <input type="radio" name="all_products" value="SINGLE" checked
               onclick="toggleProduct(this)">
        Product Wise
    </label>
    
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
<input type="text" name="from_date"
class="input-field" 
value="<%= displayDate %>"
placeholder="DD/MM/YYYY" required>
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

<script>
function toggleProduct(radio){
    if(radio.value === "ALL"){
        document.getElementById("product_code").readOnly = true;
        document.getElementById("product_code").value = "";
    } else {
        document.getElementById("product_code").readOnly = false;
    }
}
</script>

</body>
</html>