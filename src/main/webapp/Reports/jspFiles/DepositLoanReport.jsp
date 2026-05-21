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
/* =========================================================
   SESSION DATA
========================================================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if (obj != null) {

    if (obj instanceof java.sql.Date) {

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    } else {

        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.trim().equals("")){

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

/* DISPLAY DATE */

String displayDate = "";

try{

    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(d);

}catch(Exception e){

    displayDate = "";
}

/* SESSION VALUES */

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

String userId =
    (String)session.getAttribute("userId");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(userId == null)
    userId = "admin";
%>

<%
/* =========================================================
   REPORT DOWNLOAD LOGIC
========================================================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String productCode =
        request.getParameter("product_code");

    String singleAll =
        request.getParameter("single_all");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    /* ============================================
       DEFAULT BRANCH
    ============================================ */

    if(branchCode == null ||
       branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    /* ============================================
       SECURITY FOR NON SUPPORT USER
    ============================================ */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    if(productCode == null)
        productCode = "";

    productCode = productCode.trim();

    /* ============================================
       VALIDATION
    ============================================ */

    if(singleAll == null ||
       singleAll.trim().equals("")){

        singleAll = "S";
    }

    if("S".equals(singleAll) &&
       productCode.equals("")){

        out.println(
            "<h3 style='color:red;text-align:center;'>Please Enter Product Code</h3>"
        );
        return;
    }

    if(fromDate == null ||
       fromDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center;'>Please Select From Date</h3>"
        );
        return;
    }

    if(toDate == null ||
       toDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center;'>Please Select To Date</h3>"
        );
        return;
    }

    /* ============================================
       DATE FORMAT CONVERSION
    ============================================ */

    String oracleFromDate = "";
    String oracleToDate   = "";

    try{

        java.util.Date fd =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(fromDate);

        java.util.Date td =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(toDate);

        if(fd.after(td)){

            out.println(
                "<h3 style='color:red;text-align:center;'>From Date Must Be Less Than Or Equal To To Date</h3>"
            );
            return;
        }

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(fd).toUpperCase();

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(td).toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red;text-align:center;'>Invalid Date Format</h3>"
        );
        return;
    }

    /* ============================================
       CONNECTION
    ============================================ */

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ============================================
           REPORT NAME
        ============================================ */

        String jasperName = "";

        if("S".equals(singleAll)){

            jasperName =
                "depositloanreport_single.jasper";

        }else{

            jasperName =
                "depositloanreport_all.jasper";
        }

        String jasperPath =
            application.getRealPath(
                "/Reports/" + jasperName
            );

        File file = new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper File Not Found : "
                + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)
            JRLoader.loadObject(file);

        /* ============================================
           PARAMETERS
        ============================================ */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put(
            "branch_code",
            branchCode
        );

        parameters.put(
        	    "as_on_date",
        	    oracleFromDate
        	);
        
        parameters.put(
            "to_date",
            oracleToDate
        );

        parameters.put(
            "product_code",
            productCode
        );

        parameters.put(
            "user_id",
            userId
        );
        
        parameters.put("report_title","Security Deposit Loan Report");


        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* ============================================
           FILL REPORT
        ============================================ */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn
            );

        /* ============================================
           NO RECORDS
        ============================================ */

        if(jasperPrint.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");

            out.println(
                "<h2 style='color:red;text-align:center;margin-top:50px;'>"
            );

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        /* ============================================
           PDF EXPORT
        ============================================ */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"DepositLoanReport.pdf\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager
                .exportReportToPdfStream(
                    jasperPrint,
                    outStream
                );

            outStream.flush();
            outStream.close();

            return;
        }

        /* ============================================
           EXCEL EXPORT
        ============================================ */

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"DepositLoanReport.xls\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream
            );

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>Error Generating Report</h3>"
        );

        e.printStackTrace(
            new PrintWriter(out)
        );

    }finally{

        if(conn != null){

            try{
                conn.close();
            }catch(Exception ex){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Security Deposit Loan Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script
src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.radio-container {
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled {
    background-color:#e0e0e0;
    cursor:not-allowed;
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
Security Deposit Loan Report
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/DepositLoanReport.jsp"
target="_blank"
autocomplete="off"
onsubmit="return validateForm();">

<input type="hidden"
name="action"
value="download"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser)
? "readonly" : "" %>
required>

<% if("Y".equalsIgnoreCase(isSupportUser)){ %>

<button type="button"
class="icon-btn"
onclick="openLookup('branch')">
...
</button>

<% } %>

</div>

</div>

<!-- ================= PRODUCT ================= -->

<div class="parameter-group">

<div class="parameter-label">
Product Code
</div>

<div class="input-box">

<input type="text"
name="product_code"
id="product_code"
class="input-field">

<button type="button"
class="icon-btn"
onclick="openLookup('product')">
...
</button>

</div>

<div class="radio-container">

<label>
<input type="radio"
name="single_all"
value="S"
checked
onclick="toggleProduct();">
Single
</label>

<label>
<input type="radio"
name="single_all"
value="A"
onclick="toggleProduct();">
All
</label>

</div>

</div>

<!-- ================= FROM DATE ================= -->

<div class="parameter-group">

<div class="parameter-label">
From Date
</div>

<input type="text"
name="from_date"
id="from_date"
class="input-field"
placeholder="DD/MM/YYYY"
value="<%=displayDate%>"
required>

</div>

<!-- ================= TO DATE ================= -->

<div class="parameter-group">

<div class="parameter-label">
To Date
</div>

<input type="text"
name="to_date"
id="to_date"
class="input-field"
placeholder="DD/MM/YYYY"
value="<%=displayDate%>"
required>

</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<label>
<input type="radio"
name="reporttype"
value="pdf"
checked>
PDF
</label>

<label>
<input type="radio"
name="reporttype"
value="xls">
Excel
</label>

</div>

<!-- ================= BUTTONS ================= -->

<div style="display:flex; gap:20px;">

<button type="submit"
class="download-button">
Generate Report
</button>

</div>

<div id="errorBox"
class="error-box">
</div>

</form>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<!-- ================= JAVASCRIPT ================= -->

<script>

/* ==========================================
   PRODUCT ENABLE DISABLE
========================================== */

function toggleProduct(){

    var single =
        document.querySelector(
            'input[name="single_all"][value="S"]'
        ).checked;

    var field =
        document.getElementById("product_code");

    if(single){

        field.disabled = false;

    }else{

        field.value = "";
        field.disabled = true;
    }
}

/* ==========================================
   FORM VALIDATION
========================================== */

function validateForm(){

    var single =
        document.querySelector(
            'input[name="single_all"][value="S"]'
        ).checked;

    var product =
        document.getElementById("product_code").value.trim();

    var fromDate =
        document.getElementById("from_date").value.trim();

    var toDate =
        document.getElementById("to_date").value.trim();

    var errorBox =
        document.getElementById("errorBox");

    errorBox.innerHTML = "";

    if(single && product === ""){

        errorBox.innerHTML =
            "Please Enter Product Code";

        return false;
    }

    if(fromDate === ""){

        errorBox.innerHTML =
            "Please Enter From Date";

        return false;
    }

    if(toDate === ""){

        errorBox.innerHTML =
            "Please Enter To Date";

        return false;
    }

    return true;
}

/* ==========================================
   SELECT BRANCH
========================================== */

function selectBranch(branchCode){

    document.getElementById(
        "branch_code"
    ).value = branchCode;

    closeLookup();
}

/* ==========================================
   SELECT PRODUCT
========================================== */

function selectProduct(productCode){

    document.getElementById(
        "product_code"
    ).value = productCode;

    closeLookup();
}

/* ==========================================
   PAGE LOAD
========================================== */

window.onload = function(){

    toggleProduct();
};

</script>

</body>
</html>