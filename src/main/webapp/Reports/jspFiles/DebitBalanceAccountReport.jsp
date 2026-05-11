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

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    } else {

        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

String displayDate = "";

try {

    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(d);

} catch(Exception e){

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
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String productCodeFrom =
        request.getParameter("product_code_from");

    String productCodeTo =
        request.getParameter("product_code_to");

    String asOnDate =
        request.getParameter("as_on_date");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode = sessionBranchCode;
    }

    /* 🔒 SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    if(productCodeFrom == null)
        productCodeFrom = "";

    if(productCodeTo == null)
        productCodeTo = "";

    productCodeFrom = productCodeFrom.trim();
    productCodeTo   = productCodeTo.trim();

    /* ================= VALIDATION ================= */

    if(productCodeFrom.equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter Product Code From</h3>"
        );
        return;
    }

    if(productCodeTo.equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter Product Code To</h3>"
        );
        return;
    }

    if(asOnDate == null ||
       asOnDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Please Select As On Date</h3>"
        );
        return;
    }

    /* ================= DATE FORMAT ================= */

    String oracleDateStr = "";

    try{

        java.util.Date d =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(asOnDate);

        oracleDateStr =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(d).toUpperCase();

    } catch(Exception e){

        out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>"
        );
        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= LOAD REPORT ================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/DebitBalanceAccountReport.jasper"
            );

        File file = new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : " + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(file);

        /* ================= PARAMETERS ================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code",branchCode);
        parameters.put("as_on_date",oracleDateStr);
        parameters.put("from_product",productCodeFrom);
        parameters.put("to_product",productCodeTo);
        parameters.put("to_date",oracleDateStr);
        parameters.put("report_title","DEBIT BALANCE ACCOUNT REPORT");

        String userId =
            (String)session.getAttribute("userId");

        if(userId == null)
            userId = "admin";

        parameters.put(
            "user_id",
            userId
        );

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
            + File.separator
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* ================= FILL REPORT ================= */

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
                "<h2 style='color:red;text-align:center;margin-top:50px;'>"
            );

            out.println(
                "No Records Found!"
            );

            out.println("</h2>");

            return;
        }

        /* CLEAR BUFFER (IMPORTANT) */
        out.clear();
        out = pageContext.pushBody();

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"DebitBalanceAccountReport.pdf\""
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

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"DebitBalanceAccountReport.xls\""
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

    } catch(Exception e){

        out.println(
            "<h3 style='color:red'>Error Generating Report</h3>"
        );

        e.printStackTrace(
            new PrintWriter(out)
        );

    } finally {

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

<title>Debit Balance Account Report</title>

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

.input-box{
    display:flex;
    gap:10px;
}

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.modal{
    display:none;
    position:fixed;
    top:0;
    left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#f5f5f5;
    width:80%;
    max-height:85%;
    padding:20px;
    border-radius:8px;
}

.readonly-field{
    background:#f0f0f0;
}
</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
DEBIT BALANCE ACCOUNT REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/DebitBalanceAccountReport.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
       name="action"
       value="download"/>

<!-- ================= BRANCH ================= -->

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
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim())
           ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">

…

</button>

<% } %>

</div>
</div>

<div class="parameter-group">

<div class="parameter-label">
Branch Name
</div>

<input type="text"
       id="branchName"
       class="input-field"
       readonly>

</div>

</div>

<!-- ================= PRODUCT RANGE ================= -->

<div class="parameter-section">

<!-- FROM PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
From Product
</div>

<div class="input-box">

<input type="text"
       name="product_code_from"
       id="product_code"
       class="input-field"
       required>

<input type="text"
       id="productName"
       class="input-field"
       readonly
       placeholder="Product Name">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">

…

</button>

</div>

</div>

<!-- TO PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
To Product
</div>

<div class="input-box">

<input type="text"
       name="product_code_to"
       id="product_code_to"
       class="input-field"
       required>

<input type="text"
       id="productNameTo"
       class="input-field"
       readonly
       placeholder="Product Name">

<button type="button"
        class="icon-btn"
        onclick="openToProductLookup()">

…

</button>

</div>

</div>

</div>

<script>

function openToProductLookup(){

    activeInput =
        document.getElementById(
            "product_code_to"
        );

    let url =
        contextPath +
        "/CommonLookupServlet?type=product";

    fetch(url)
    .then(res => res.text())
    .then(html => {

        document.getElementById(
            "lookupTable"
        ).innerHTML = html;

        document.getElementById(
            "lookupModal"
        ).style.display = "flex";
    });
}

/* OVERRIDE FOR TO PRODUCT */

function selectProduct(code, name, type) {

    if(activeInput &&
       activeInput.id === "product_code_to"){

        document.getElementById(
            "product_code_to"
        ).value = code;

        document.getElementById(
            "productNameTo"
        ).value = name;

        closeLookup();
        return;
    }

    /* DEFAULT FROM PRODUCT */

    let field =
        document.getElementById(
            "product_code"
        );

    if(field) field.value = code;

    let nameField =
        document.getElementById(
            "productName"
        );

    if(nameField) nameField.value = name;

    closeLookup();
}

</script>
<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="text"
       name="as_on_date"
       class="input-field"
       value="<%= displayDate %>"
       placeholder="DD/MM/YYYY"
       required>

</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">

<input type="radio"
       name="reporttype"
       value="pdf"
       checked>PDF</div>

<div class="format-option">

<input type="radio"
       name="reporttype"
       value="xls">Excel</div>

</div>

</div>

<!-- ================= BUTTON ================= -->

<button type="submit"
        class="download-button">

Generate Report

</button>

</form>

</div>

<!-- ================= LOOKUP POPUP ================= -->

<div id="lookupModal"
     class="modal">

<div class="modal-content">

<button onclick="closeLookup()"
        style="float:right;">✖</button>

<div id="lookupTable"></div>

</div>

</div>

</body>

</html>