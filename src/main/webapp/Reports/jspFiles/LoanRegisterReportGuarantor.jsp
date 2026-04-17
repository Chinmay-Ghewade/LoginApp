<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*, java.util.*, java.io.*, java.text.SimpleDateFormat" %>
<%@ page import="db.DBConnection" %>

<%
/* =========================
   SESSION DATA
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

String userId = (String) session.getAttribute("userId");
if (userId == null) userId = "SYSTEM";

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>

<!DOCTYPE html>
<html>
<head>

<title>Loan Register Guarantor</title>

<!-- CSS -->
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=5">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css?v=5">

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

.radio-container{
    margin-top:8px;
    display:flex;
    gap:30px;
}

.error-box{
    color:red;
    text-align:center;
    margin-top:10px;
}
</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
LOAN REGISTER GUARANTOR
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/LoanRegisterReportGuarantor.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm()">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- Branch -->

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

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
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
<input type="radio" name="single_all" value="S" checked onclick="toggleProduct()"> Single
</label>

<label>
<input type="radio" name="single_all" value="A" onclick="toggleProduct()"> All
</label>
</div>

</div>

<!-- DATE RANGE -->

<div class="parameter-group">
<div class="parameter-label">From Date</div>
<input type="date"
       name="from_date"
       id="from_date"
       class="input-field"
       required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>
<input type="date"
       name="to_date"
       id="to_date"
       class="input-field"
       required>
</div>

</div>

<!-- FORMAT -->

<div class="format-section">

<label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
<label><input type="radio" name="reporttype" value="xls"> Excel</label>

</div>

<div class="error-box" id="errorBox"></div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

/* =========================
   ENABLE / DISABLE PRODUCT
   ========================= */
function toggleProduct(){

    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
        document.getElementById("product_code");

    if(single){
        productField.disabled = false;
    }else{
        productField.value = "";
        productField.disabled = true;
    }
}

/* =========================
   VALIDATION (SERVLET SAME LOGIC)
   ========================= */
function validateForm(){

    var singleAll = document.querySelector('input[name="single_all"]:checked').value;
    var product   = document.getElementById("product_code").value.trim();
    var fromDate  = document.getElementById("from_date").value;
    var toDate    = document.getElementById("to_date").value;

    var errorBox = document.getElementById("errorBox");
    errorBox.innerHTML = "";

    if(singleAll === "S" && product === ""){
        errorBox.innerHTML = "Enter Product Code!!!";
        return false;
    }

    if(fromDate === ""){
        errorBox.innerHTML = "Enter From Date!!!";
        return false;
    }

    if(toDate === ""){
        errorBox.innerHTML = "Enter To Date!!!";
        return false;
    }

    if(new Date(fromDate) > new Date(toDate)){
        errorBox.innerHTML = "From date must be less than or equal to To Date!!!";
        return false;
    }

    return true;
}

window.onload = function(){
    toggleProduct();
}

</script>

</body>
</html>