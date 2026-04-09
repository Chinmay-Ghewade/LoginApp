<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*,java.util.*,java.text.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* =========================
   SESSION VALUES
========================= */
String sessionBranchCode = (String) session.getAttribute("branchCode");
if(sessionBranchCode == null) sessionBranchCode = "";

String isSupportUser = (String) session.getAttribute("isSupportUser");
if(isSupportUser == null) isSupportUser = "N";

/* =========================
   SESSION DATE
========================= */
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

/* =========================
   ACTION
========================= */
String action = request.getParameter("action");

if ("download".equals(action)) {

    String branchCode = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String asOnDate = request.getParameter("as_on_date");
    String reporttype = request.getParameter("reporttype");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        if(branchCode == null || branchCode.trim().isEmpty()){
            branchCode = sessionBranchCode;
        }

        if (!"Y".equalsIgnoreCase(isSupportUser)) {
            branchCode = sessionBranchCode;
        }

        if(productCode == null || productCode.trim().isEmpty()){
            throw new Exception("Enter Product Code");
        }

        if(asOnDate == null || asOnDate.trim().isEmpty()){
            throw new Exception("Enter As On Date");
        }

        conn = DBConnection.getConnection();

        /* DATE FORMAT */
        String oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate))
            .toUpperCase();

        /* LOAD JASPER */
        String jasperPath =
            application.getRealPath("/Reports/Loan_Deposit_IR_BWB.jasper");

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new java.io.File(jasperPath));

        /* PARAMETERS */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("product_code", productCode);
        parameters.put("as_on_date", oracleDate);

        parameters.put("report_title", "LOAN / DEPOSIT INTEREST RATE REPORT");

        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        String userId = (String) session.getAttribute("userId");
        parameters.put("user_id", userId);

        /* FILL REPORT */
        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, parameters, conn);

        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>No Records Found!</h2>");
            return;
        }

        /* EXPORT */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                "inline; filename=\"LoanDepositInterestRate.pdf\"");

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.close();
        }
        else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                "attachment; filename=\"LoanDepositInterestRate.xls\"");

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.close();
        }

        return;

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

        response.sendRedirect("Loan_Deposit_Interest_Rate_BWB.jsp");
        return;
    

    } finally {
        if(conn!=null) conn.close();
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Loan Deposit Interest Rate</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
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
LOAN / DEPOSIT INTEREST RATE
</h1>

<form method="post"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- 🔹 BRANCH CODE -->
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

<!-- 🔹 BRANCH NAME -->
<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text"
           id="branchName"
           class="input-field"
           readonly>
</div>

<!-- 🔹 PRODUCT CODE (ONLY SIMPLE FIELD) -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
    <input type="text"
           name="product_code"
           id="product_code"
           class="input-field"
           placeholder="Enter Product Code"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openLookup('product')">…</button>
</div>

</div>

<!-- 🔹 AS ON DATE -->
<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

</div> <!-- ✅ parameter-section END -->

<!-- 🔹 REPORT TYPE -->
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

<!-- 🔹 BUTTON -->
<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- 🔹 LOOKUP MODAL -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>