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

Object obj =
    session.getAttribute("workingDate");

if(obj != null){

    if(obj instanceof java.sql.Date){

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    }else{

        sessionDate = obj.toString();
    }
}

if(sessionDate == null
    || sessionDate.trim().equals("")){

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
%>

<%
/* =========================================================
   DOWNLOAD LOGIC
========================================================= */

String action =
    request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
    	    request.getParameter("branch_code");

    	String productCode =
    	    request.getParameter("pr_code_fr");

    	String productCodeTo =
    	    request.getParameter("pr_code_to");
    	
    String asOnDate =
        request.getParameter("as_on_date");

    if(branchCode == null
        || branchCode.trim().equals("")){

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

    if(productCodeTo == null)
        productCodeTo = "";

    productCode =
        productCode.trim();

    productCodeTo =
        productCodeTo.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(productCode.equals("")){

        errorMessage =
            "Please Enter Product Code";
    }

    else if(productCodeTo.equals("")){

        errorMessage =
            "Please Enter Product Code To";
    }

    else if(asOnDate == null
        || asOnDate.trim().equals("")){

        errorMessage =
            "Please Enter As On Date";
    }

    /* =====================================================
       DATE FORMAT
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

            errorMessage =
                "Invalid Date Format";
        }
    }

    Connection conn = null;

    /* =====================================================
       GENERATE REPORT
    ===================================================== */

    if(errorMessage.equals("")){

        try{

            response.reset();

            response.setBufferSize(
                1024 * 1024
            );

            conn =
                DBConnection.getConnection();

            /* ==============================================
               LOAD REPORT
            ============================================== */

            String jasperPath =
                application.getRealPath(
                    "/Reports/WithrawlBeyoundAuthodrwlimit.jasper"
                );

            File file =
                new File(jasperPath);

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
            parameters.put("from_product",productCode);
            parameters.put("to_product", productCodeTo);
            parameters.put("as_on_date",oracleDate);
            parameters.put("report_title", "WITHDRAWL BEYOUND AUTHORIZED/DRAWING LIMIT");

            String userId =(String)session.getAttribute("userId");

            if(userId == null)
                userId = "admin";

            parameters.put("user_id",userId);
            parameters.put(
                "SUBREPORT_DIR",application.getRealPath(
                    "/Reports/"
                )
            );

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

                return;
            }

            /* ==============================================
               EXPORT PDF
            ============================================== */

            if(
                "pdf".equalsIgnoreCase(
                    reporttype
                )
            ){

                response.setContentType(
                    "application/pdf"
                );

                response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"WithrawlBeyoundAuthodrwlimit.pdf\""
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
                "xls".equalsIgnoreCase(
                    reporttype
                )
            ){

                response.setContentType(
                    "application/vnd.ms-excel"
                );

                response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"WithrawlBeyoundAuthodrwlimit.xls\""
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

            response.setContentType(
                "text/html"
            );

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
Withdrawl Beyound Authorized Drawing Limit
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
WITHDRAWL BEYOUND AUTHORIZED/DRAWING LIMIT
</h1>

<% if(errorMessage != null &&
      !errorMessage.trim().equals("")) { %>

<div class="error-box">
<%= errorMessage %>
</div>

<% } %>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/WithrawlBeyoundAuthodrwlimit.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download"/>

<!-- Product Code Section -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Product Code</div>
<div class="input-box">
<input type="text"
name="pr_code_fr"
id="product_code"
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
name="pr_code_to"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>
</div>

</div>

<!-- =====================================================
     PRODUCT NAME SECTION
===================================================== -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">
From Product Name
</div>

<input type="text"
       id="productName"
       class="input-field name-field"
       readonly>
</div>

<div class="parameter-group">

<div class="parameter-label">
To Product Name
</div>

<input type="text"
       id="product_name_to"
       class="input-field name-field"
       readonly>

</div>

</div>

<!-- =====================================================
     DATE SECTION
===================================================== -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="text"
       name="as_on_date"
       id="as_on_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

</div>

<!-- =====================================================
     REPORT TYPE
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

document.addEventListener(
"DOMContentLoaded",
function(){

    let toField =
        document.querySelector(
            'input[name="pr_code_to"]'
        );

    if(!toField) return;

    toField.addEventListener(
    "blur",
    function(){

        let code = this.value;

        if(!code ||
           code.trim()===""){

            return;
        }

        fetch(
            contextPath +
            "/CommonLookupServlet?type=product&action=getName&code=" +
            encodeURIComponent(code)
        )
        .then(res => res.text())
        .then(name => {

            let desc =
                document.getElementById(
                    "product_name_to"
                );

            if(desc){

                desc.value =
                    name || "Not Found";
            }
        });
    });

});

</script>
</body>
</html>