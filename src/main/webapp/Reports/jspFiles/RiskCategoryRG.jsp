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
   SESSION VALUES
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

String branchCode =
    (String)session.getAttribute("branchCode");

String userId =
    (String)session.getAttribute("userId");

String bankCode =
    (String)session.getAttribute("bankCode");

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

if(branchCode == null) branchCode = "";
if(userId == null) userId = "";
if(bankCode == null) bankCode = "";
if(isSupportUser == null) isSupportUser = "N";

/* =========================================================
   DOWNLOAD / REPORT GENERATION
========================================================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reportType =
        request.getParameter("reporttype");

    String selectedBranch =
        request.getParameter("branch_code");

    String productCode =
        request.getParameter("product_code");

    String singleAll =
        request.getParameter("single_all");

    String riskCategory =
        request.getParameter("risk_category");

    if(selectedBranch == null ||
       selectedBranch.trim().equals("")){

        selectedBranch = branchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        selectedBranch = branchCode;
    }

    if(productCode == null)
        productCode = "";

    if(singleAll == null)
        singleAll = "S";

    if(riskCategory == null)
        riskCategory = "";

    productCode = productCode.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if("S".equals(singleAll)
            && productCode.equals("")){

        out.println(
            "<h3 style='color:red;text-align:center;'>"
          + "Please Enter Product Code"
          + "</h3>"
        );

        return;
    }

    if(riskCategory.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center;'>"
          + "Please Select Risk Category"
          + "</h3>"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =================================================
           LOAD JASPER
        ================================================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/RiskCategoryRG.jasper"
            );

        File reportFile = new File(jasperPath);

        if(!reportFile.exists()){

            throw new RuntimeException(
                "Jasper File Not Found : "
                + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(reportFile);

        /* =================================================
           PARAMETERS
        ================================================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code",selectedBranch);
        parameters.put("report_title","RISK CATEGORY REPORT");
        parameters.put("product_code",productCode);     
        parameters.put("single_all",singleAll);
        parameters.put("risk_category",riskCategory);
        parameters.put("as_on_date",displayDate);
        parameters.put("user_id",userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* =================================================
           FILL REPORT
        ================================================= */

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                conn
            );

        if(jasperPrint.getPages().isEmpty()){

            response.reset();
            response.setContentType("text/html");

            out.println(
                "<h2 style='color:red;"
              + "text-align:center;"
              + "margin-top:50px;'>"
              + "No Records Found!"
              + "</h2>"
            );

            return;
        }

        /* =================================================
           EXPORT PDF / EXCEL
        ================================================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"RiskCategoryReport.pdf\""
            );

            ServletOutputStream outputStream =
                response.getOutputStream();

            JasperExportManager
                .exportReportToPdfStream(
                    jasperPrint,
                    outputStream
                );

            outputStream.flush();
            outputStream.close();

            return;
        }

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"RiskCategoryReport.xls\""
            );

            ServletOutputStream outputStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outputStream
            );

            exporter.exportReport();

            outputStream.flush();
            outputStream.close();

            return;
        }

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>"
          + "Error Generating Report"
          + "</h3>"
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

<title>Risk Category Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script
src="<%=request.getContextPath()%>/js/lookup.js">
</script>

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
    RISK CATEGORY REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/RiskCategoryRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden"
       name="action"
       value="download"/>

<div class="parameter-section">

    <!-- =========================================
         BRANCH CODE
    ========================================== -->

    <div class="parameter-group">

        <div class="parameter-label">
            Branch Code
        </div>

        <div class="input-box">

            <input type="text"
                   name="branch_code"
                   id="branch_code"
                   class="input-field"
                   value="<%=branchCode%>"
                   <%= !"Y".equalsIgnoreCase(isSupportUser)
                       ? "readonly"
                       : "" %>
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

    <!-- =========================================
         PRODUCT CODE
    ========================================== -->

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
                       onclick="toggleProduct()">
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

    <!-- =========================================
         RISK CATEGORY
    ========================================== -->

    <div class="parameter-group">

        <div class="parameter-label">
            Risk Category
        </div>

        <select name="risk_category"
                id="risk_category"
                class="input-field"
                required>

            <option value="">
                -- Select --
            </option>

            <option value="LOW">
                LOW
            </option>

            <option value="MEDIUM">
                MEDIUM
            </option>

            <option value="HIGH">
                HIGH
            </option>

        </select>

    </div>

</div>

<!-- =============================================
     REPORT TYPE
============================================== -->

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

<!-- =============================================
     BUTTONS
============================================== -->

<div style="margin-top:30px;">

    <button type="submit"
            class="download-button"
            onclick="return validateForm();">

        Generate Report

    </button>

</div>

</form>

</div>

<!-- =============================================
     LOOKUP MODAL
============================================== -->

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

    var field =
        document.querySelector('input[name="product_code"]');

    if(single){
        field.disabled = false;
    } else {
        field.value = "";
        field.disabled = true;
    }
}

window.onload = toggleProduct;
</script>

</body>
</html>