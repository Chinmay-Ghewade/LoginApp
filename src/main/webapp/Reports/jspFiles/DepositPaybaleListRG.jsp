<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>

<%@ page import="db.DBConnection" %>

<%
/* ===== SESSION DATE ===== */
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

/* ===== SESSION BRANCH ===== */
String branchCodeSession = (String) session.getAttribute("branchCode");

if(branchCodeSession == null || branchCodeSession.trim().equals("")){
    branchCodeSession = "0001";
}
%>

<%
String action = request.getParameter("action");

String branchCode = request.getParameter("branch_code");
String toDateUI = request.getParameter("to_date");
String productCode = request.getParameter("product_code");
String singleAll = request.getParameter("single_all");

if ("download".equals(action)) {

    /* =========================
       VALIDATION (NO DEFAULTS)
    ========================= */

    if(branchCode == null || branchCode.trim().equals("")){
        out.println("<h3 style='color:red'>Please enter Branch Code</h3>");
        return;
    }

    if(toDateUI == null || toDateUI.trim().equals("")){
        out.println("<h3 style='color:red'>Please select Date</h3>");
        return;
    }

    if(singleAll == null){
        singleAll = "S"; // safe default (optional)
    }

    if("S".equals(singleAll) && (productCode == null || productCode.trim().equals(""))){
        out.println("<h3 style='color:red'>Please enter Product Code</h3>");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* =========================
           DATE FORMAT FOR ORACLE
        ========================= */

        SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);

        String oracleDate = outFmt.format(inFmt.parse(toDateUI)).toUpperCase();

        /* =========================
           PRODUCT CONDITION
        ========================= */

        String condition = "";

        if ("S".equals(singleAll) && productCode != null && !productCode.trim().isEmpty()) {

            condition =
                " AND SUBSTR(A.ACCOUNT_CODE,5,3) = ? ";
        }

        /* =========================
           MAIN SQL (FROM OLD SERVLET)
        ========================= */

        String sql =
            " SELECT A.ACCOUNT_CODE ACCOUNT_NO, " +
            " A.NAME AC_NAME, " +
            " P.DESCRIPTION, " +
            " FN_GET_BALANCE_ASON(?,A.ACCOUNT_CODE) BALANCE_AMT, " +
            " (FN_GET_RECPAY_REPORTS(?,A.ACCOUNT_CODE,'N') * (-1)) PAYBALE_AMT " +

            " FROM ACCOUNT.ACCOUNT A, ACCOUNT.ACCOUNTDEPOSIT D, HEADOFFICE.PRODUCT P " +

            " WHERE A.ACCOUNT_CODE = D.ACCOUNT_CODE " +
            " AND SUBSTR(A.ACCOUNT_CODE,5,3) = P.PRODUCT_CODE " +
            " AND SUBSTR(A.ACCOUNT_CODE,1,4) = ? " +

            " AND ((A.DATEACCOUNTOPEN IS NULL OR A.DATEACCOUNTOPEN <= ?)) " +
            " AND ((A.DATEACCOUNTCLOSE IS NULL OR A.DATEACCOUNTCLOSE > ?)) " +

            condition +

            " AND ( FN_GET_BALANCE_ASON(?,A.ACCOUNT_CODE) <> 0 " +
            " OR FN_GET_RECPAY_REPORTS(?,A.ACCOUNT_CODE,'N') <> 0 ) " +

            " ORDER BY P.PRODUCT_CODE, A.ACCOUNT_CODE";

        pstmt = conn.prepareStatement(sql);

        int idx = 1;

        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, branchCode);
        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);

        if ("S".equals(singleAll) && productCode != null && !productCode.trim().isEmpty()) {
            pstmt.setString(idx++, productCode);
        }

        pstmt.setString(idx++, oracleDate);
        pstmt.setString(idx++, oracleDate);

        rs = pstmt.executeQuery();

        /* =========================
           LOAD JASPER REPORT
        ========================= */

        String reportsDir = application.getRealPath("/Reports") + File.separator;
        String reportPath = reportsDir + "DepositPaybaleListRG.jrxml";

        JasperReport jasperReport = JasperCompileManager.compileReport(reportPath);

        Map<String, Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("report_title", "PAYABLE DEPOSIT REPORT");

        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);
        
        params.put("SUBREPORT_DIR", reportsDir);
        params.put("REPORT_CONNECTION", conn);

        JRResultSetDataSource jrDataSource =
                new JRResultSetDataSource(rs);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, jrDataSource);

        ServletOutputStream sos = response.getOutputStream();
        String reportType = request.getParameter("reporttype");

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "inline; filename=\"DepositPayableReport.pdf\"");

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;
        }

        if ("xls".equalsIgnoreCase(reportType)) {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"DepositPayableReport.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);

            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);

            exporter.exportReport();
            sos.flush();
            return;
        }

    } catch (Exception e) {

        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Deposit Payable Report : " + e.getMessage());

        response.sendRedirect("DepositPaybaleListRG.jsp");
        return;

    } finally {

        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<% if (!"download".equals(action)) { %>

<!DOCTYPE html>
<html>
<head>

<title>Deposit Payable Report</title>

<link rel="stylesheet"href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">
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

<h1 class="report-title">PAYABLE DEPOSIT REPORT</h1>

<%
String errorMessage = (String) session.getAttribute("errorMessage");
if (errorMessage != null) {
%>
<div class="error-message"><%= errorMessage %></div>
<%
session.removeAttribute("errorMessage");
}
%>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositPaybaleListRG.jsp"
      target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>
<div class="input-box">
    <input type="text"
           name="branch_code"
           id="branch_code"
           class="input-field"
           value="<%=branchCodeSession%>"
           required>

    <button type="button"
            class="icon-btn"
            onclick="openBranchLookup()">…</button>
</div>
</div>

<!-- Branch Name -->
<div class="parameter-group">
    <div class="parameter-label">Branch Description</div>

    <input type="text"
           id="branchName"
           class="input-field"
           readonly>
</div>

<div class="parameter-group">
<div class="parameter-label">As on Date</div>
<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

<!-- Product Code -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
    <div class="input-box">
    <input type="text"
           name="product_code"
           id="product_code"
           class="input-field"
           placeholder="Enter Product Code">

    <button type="button"
            class="icon-btn"
            onclick="openProductLookup()">…</button>
</div>
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

</div>

<div class="format-section">
<div class="parameter-label">Report Type</div>
<input type="radio" name="reporttype" value="pdf" checked> PDF
<input type="radio" name="reporttype" value="xls"> Excel
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

/* =========================
PRODUCT TOGGLE
========================= */
function toggleProduct(){
 var single =
     document.querySelector('input[name="single_all"][value="S"]').checked;

 var productField =
     document.getElementById("product_code");

 if(single){
     productField.disabled = false;
     productField.readOnly = false;
 }else{
     productField.value = "";
     productField.disabled = true;
     productField.readOnly = true;
 }
}

/* =========================
OPEN BRANCH POPUP
========================= */
function openBranchLookup() {
 fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")
     .then(res => res.text())
     .then(html => {
         document.getElementById("lookupTable").innerHTML = html;
         document.getElementById("lookupModal").style.display = "flex";
     });
}

/* =========================
OPEN PRODUCT POPUP
========================= */
function openProductLookup() {
 fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=product")
     .then(res => res.text())
     .then(html => {
         document.getElementById("lookupTable").innerHTML = html;
         document.getElementById("lookupModal").style.display = "flex";
     });
}

/* =========================
CLOSE POPUP
========================= */
function closeLookup() {
 document.getElementById("lookupModal").style.display = "none";
}

/* =========================
SELECT BRANCH
========================= */
function selectBranch(code, name) {
 document.getElementById("branch_code").value = code;
 document.getElementById("branchName").value = name;
 closeLookup();
}

/* =========================
SELECT PRODUCT
========================= */
function selectProduct(code, name, type) {
 document.getElementById("product_code").value = code;
 closeLookup();
}

/* =========================
FETCH BRANCH NAME
========================= */
function fetchBranchName(code){

 if (!code) return;

 fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + code)
     .then(res => res.text())
     .then(name => {
         document.getElementById("branchName").value = name || "Not Found";
     });
}

/* =========================
PAGE LOAD
========================= */
window.onload = function(){

 toggleProduct();

 let code = document.getElementById("branch_code").value;

 if(code){
     fetchBranchName(code);
 }

 document.getElementById("branch_code").addEventListener("blur", function() {
     fetchBranchName(this.value);
 });
};
</script>

</body>
</html>

<% } %>