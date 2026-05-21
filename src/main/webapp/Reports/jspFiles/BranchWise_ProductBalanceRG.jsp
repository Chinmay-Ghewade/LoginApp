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

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";

String errorMessage = "";

/* =========================================================
   DOWNLOAD / REPORT GENERATION
========================================================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype  = request.getParameter("reporttype");
    String branchCode  = request.getParameter("branch_code");
    String productCode = request.getParameter("product_code");
    String singleAll   = request.getParameter("single_all");
    String asOnDate    = request.getParameter("as_on_date");

    if(branchCode == null || branchCode.trim().equals("")){
        branchCode = sessionBranchCode;
    }

    /* =====================================================
       SECURITY
    ===================================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    if(productCode == null)
        productCode = "";

    productCode = productCode.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if("S".equals(singleAll)
        && productCode.equals("")){

        errorMessage = "Please Enter Product Code";
    }

    if(asOnDate == null
        || asOnDate.trim().equals("")){

        errorMessage = "Please Select As On Date";
    }

    /* ==============================================
    SINGLE / ALL LOGIC
 ============================================== */

 if("A".equals(singleAll)){

     productCode = "";

 }
    /* =====================================================
       DATE CONVERSION
    ===================================================== */

    String oracleDate = "";

    if(errorMessage.equals("")){

        try{

            java.util.Date d =
                new SimpleDateFormat("dd/MM/yyyy")
                .parse(asOnDate);

            oracleDate =
                new SimpleDateFormat(
                    "dd-MMM-yyyy",
                    Locale.ENGLISH
                ).format(d).toUpperCase();

        }catch(Exception e){

            errorMessage = "Invalid Date Format";
        }
    }

    /* =====================================================
       PRODUCT VALIDATION
    ===================================================== */

    Connection conn = null;

    if(errorMessage.equals("")){

        try{

            conn = DBConnection.getConnection();

            if("S".equals(singleAll)){

                PreparedStatement ps =
                    conn.prepareStatement(
                        "SELECT PRODUCT_CODE, DESCRIPTION " +
                        "FROM HEADOFFICE.PRODUCT " +
                        "WHERE PRODUCT_CODE = ?"
                    );

                ps.setString(1, productCode);

                ResultSet rs = ps.executeQuery();

                if(!rs.next()){

                    errorMessage =
                        "Invalid Product Code";
                }

                rs.close();
                ps.close();
            }

        }catch(Exception e){

            errorMessage =
                "Database Error While Validating Product";
        }
    }

    /* =====================================================
       GENERATE REPORT
    ===================================================== */

    if(errorMessage.equals("")){

        try{

            response.reset();
            response.setBufferSize(1024 * 1024);

            if(conn == null){
                conn = DBConnection.getConnection();
            }

            /* ==============================================
               JASPER FILE
            ============================================== */

            String jasperPath =
                application.getRealPath(
                    "/Reports/BranchWise_ProductBalanceRG.jasper"
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

            /* ==============================================
               PARAMETERS
            ============================================== */

            Map<String,Object> parameters =
                new HashMap<String,Object>();

            parameters.put("branch_code",branchCode);
            parameters.put("as_on_date",oracleDate);
            parameters.put("product_code",productCode);
            parameters.put("single_all",singleAll);
            parameters.put("report_title","BRANCH WISE PRODUCT BALANCE");
            parameters.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

            String userId =
                (String)session.getAttribute("userId");

            if(userId == null)
                userId = "admin";

            parameters.put("user_id",userId);
            parameters.put(
                JRParameter.REPORT_CONNECTION,
                conn
            );

            /* ==============================================
               FILL REPORT
            ============================================== */

            JasperPrint jasperPrint =
                JasperFillManager.fillReport(
                    jasperReport,
                    parameters,
                    conn
                );

            if (jasperPrint.getPages().isEmpty()) {

                response.reset();
                response.setContentType("text/html");

                out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
                out.println("No Records Found!");
                out.println("</h2>");
%>

<%
                return;
            }

            /* ==============================================
               EXPORT PDF
            ============================================== */

            if("pdf".equalsIgnoreCase(reporttype)){

                response.setContentType(
                    "application/pdf"
                );

                response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"BranchWise_ProductBalanceRG.pdf\""
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

            /* ==============================================
               EXPORT EXCEL
            ============================================== */

            else if(
                "xls".equalsIgnoreCase(reporttype)
            ){

                response.setContentType(
                    "application/vnd.ms-excel"
                );

                response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"BranchWise_ProductBalanceRG.xls\""
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

            response.setContentType("text/html");

        }finally{

            if(conn != null){

                try{
                    conn.close();
                }catch(Exception ex){}
            }
        }
    }
}
%>

<!DOCTYPE html>

<html>

<head>

<title>
Branch Wise Product Balance Report
</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script src=
"<%=request.getContextPath()%>/js/lookup.js">
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
BRANCH WISE PRODUCT BALANCE
</h1>

<% if(errorMessage != null &&
      !errorMessage.trim().equals("")) { %>

<div class="error-box">
<%= errorMessage %>
</div>

<% } %>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/BranchWise_ProductBalanceRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download">
<!-- =====================================================
     BRANCH CODE
===================================================== -->

<div class="parameter-section">

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

<!-- Radio Buttons moved below -->
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

<!-- =====================================================
     AS ON DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="text"
       name="as_on_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

</div>

<!-- =====================================================
     REPORT FORMAT
===================================================== -->

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

<label style="margin-left:25px;">
<input type="radio"
       name="reporttype"
       value="xls">
Excel
</label>

</div>

<!-- =====================================================
     BUTTON
===================================================== -->

<button type="submit"
        class="download-button">
Generate Report
</button>

</form>

</div>

<!-- =====================================================
     LOOKUP MODAL
===================================================== -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

function toggleProduct() {

    var single =
      document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
      document.querySelector('input[name="product_code"]');

    if (single) {
        productField.disabled = false;
        productField.readOnly = false;
    } else {
        productField.value = "";
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