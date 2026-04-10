<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="db.DBConnection" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="java.io.File" %>

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

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";

String singleAll = request.getParameter("single_all");
if(singleAll == null) singleAll = "S";

%>

<%

/* ================= ACTION ================= */

String action = request.getParameter("action");

if ("print".equals(action)) {

    String branchCode = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");

    /* 🔒 BRANCH LOGIC */
    if (branchCode == null || branchCode.trim().isEmpty()) {
        branchCode = sessionBranchCode;
    }

    if (!"Y".equalsIgnoreCase(isSupportUser)) {
        branchCode = sessionBranchCode;
    }

    /* ================= ERROR ================= */

    if (fromDate == null || fromDate.trim().isEmpty()) {
        out.println("<h3 style='color:red;text-align:center'>Please Select From Date</h3>");
        return;
    }

    if (toDate == null || toDate.trim().isEmpty()) {
        out.println("<h3 style='color:red;text-align:center'>Please Select To Date</h3>");
        return;
    }

    if("S".equals(singleAll) && 
    		   (productCode == null || productCode.trim().isEmpty())){

    		    out.println("<h3 style='color:red;text-align:center'>Please Enter Product Code</h3>");
    		    return;
    		}
    
    /* 🔥 DATE FORMAT */

    String oracleFromDate = "";
    String oracleToDate = "";

    try {

    	java.util.Date d1 = new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);
    	oracleFromDate = new SimpleDateFormat("dd-MMM-yy", Locale.ENGLISH)
    	        .format(d1).toUpperCase();

    	java.util.Date d2 = new SimpleDateFormat("yyyy-MM-dd").parse(toDate);
    	oracleToDate = new SimpleDateFormat("dd-MMM-yy", Locale.ENGLISH)
    	        .format(d2).toUpperCase();
    	
    } catch (Exception e) {
        out.println("<h3 style='color:red;text-align:center'>Invalid Date Format</h3>");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= LOAD JASPER ================= */

        String jasperPath = application.getRealPath("/Reports/GoldLoanReminder.jasper");

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */

        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("product_code",
        	    "S".equals(singleAll) ? productCode : null);

        	parameters.put("single_all", singleAll);
        	
        parameters.put("form_date", oracleFromDate);
        parameters.put("to_date", oracleToDate);
        parameters.put("as_on_date", oracleFromDate);
        parameters.put("report_title", "GOLD LOAN REMINDER");

        String userId = (String) session.getAttribute("userId");
        if (userId == null || userId.trim().isEmpty()) {
            userId = "admin";
        }

        parameters.put("user_id", userId);

        parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));
        
        ////////////////////////////////////////////////////
        
        PreparedStatement ps = null;
        ResultSet rs = null;

        String sql =
        "SELECT L.ACCOUNT_CODE, A.NAME, " +
        "C.ADDRESS1 || ' ' || C.ADDRESS2 || ' ' || C.ADDRESS3 AS ADDRESS, " +
        "L.ACCOUNTREVIEWDATE, B.LEDGERBALANCE " +
        "FROM ACCOUNT.ACCOUNT A, ACCOUNT.ACCOUNTLOAN L, BALANCE.ACCOUNT B, CUSTOMER.CUSTOMER C " +
        "WHERE SUBSTR(L.ACCOUNT_CODE,1,4)=? " +
        "AND L.ACCOUNTREVIEWDATE BETWEEN ? AND ? " +
        "AND L.ACCOUNT_CODE=A.ACCOUNT_CODE " +
        "AND L.ACCOUNT_CODE=B.ACCOUNT_CODE " +
        "AND A.CUSTOMER_ID=C.CUSTOMER_ID " +
        "AND A.DATEACCOUNTCLOSE IS NULL ";

        /* ✅ PRODUCT CONDITION */
        if("S".equals(singleAll)){
            sql += " AND SUBSTR(L.ACCOUNT_CODE,5,3)=? ";
        }

        sql += " ORDER BY L.ACCOUNT_CODE";

        ps = conn.prepareStatement(sql);

        ps.setString(1, branchCode);
        ps.setString(2, oracleFromDate);
        ps.setString(3, oracleToDate);

        if("S".equals(singleAll)){
            ps.setString(4, productCode);
        }

        rs = ps.executeQuery();

        /* ================= FILL REPORT ================= */

       JRResultSetDataSource jrds = new JRResultSetDataSource(rs);

       parameters.put(JRParameter.REPORT_CONNECTION, conn);

        JasperPrint jasperPrint =
    JasperFillManager.fillReport(jasperReport, parameters, jrds);


        /* ================= NO DATA CHECK ================= */

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= EXPORT ================= */

        String reporttype = request.getParameter("reporttype");
        if (reporttype == null) reporttype = "pdf";

        /* ===== PDF ===== */

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");

            response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"GoldLoanReminder.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                    jasperPrint,
                    outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        /* ===== EXCEL ===== */

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"GoldLoanReminder.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

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

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html");

        out.println("<h3 style='color:red;text-align:center'>Error Generating Report</h3>");
        out.println("<div style='text-align:center;color:#555;'>Please contact system administrator</div>");

        e.printStackTrace();

    } finally {

        if (conn != null) try { conn.close(); } catch (Exception ex) {}
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Gold Loan Reminder</title>

<!-- ✅ COMMON CSS -->
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<!-- ✅ CONTEXT -->
<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<!-- ✅ LOOKUP SCRIPT -->
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

<h1 class="report-title">GOLD LOAN REMINDER</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/GoldLoanReminder.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="print"/>

<!-- ================= BRANCH ================= -->

<div class="parameter-section">

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
<input type="text"
id="branchName"
class="input-field"
readonly>
</div>

</div>

<!-- ================= PRODUCT ================= -->

<div class="parameter-section">

<!-- Product Code -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
    <input type="text"
           name="product_code"
           id="product_code"
           class="input-field"
           placeholder="Enter Product Code">

    <button type="button"
            class="icon-btn"
            onclick="openLookup('product')">…</button>
</div>

<div class="radio-container">

<label>
<input type="radio"
       name="single_all"
       value="S"
       onclick="toggleProduct()"
       checked>
Single
</label>

<label>
<input type="radio"
       name="single_all"
       value="A"
       onclick="toggleProduct()">
All
</label>

</div>

</div>

<div class="parameter-group">
<div class="parameter-label">Product Name</div>
<input type="text"
id="productName"
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
value="<%= sessionDate %>"
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

<!-- ================= BUTTON ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

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

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- ================= POPUP ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>
function toggleProduct(){

    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
        document.getElementById("product_code");

    if(single){
        productField.disabled = false;
        productField.readOnly = false;
    }else{
        productField.value="";
        productField.disabled = true;
        productField.readOnly = true;
    }
}

window.onload = function(){
    toggleProduct();
}
</script>

</body>
</html>