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

Object obj =
    session.getAttribute("workingDate");

if(obj != null){

    if(obj instanceof java.sql.Date){

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    } else {

        sessionDate = obj.toString();
    }
}

if(sessionDate == null ||
   sessionDate.isEmpty()){

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
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action =
    request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    String amount =
        request.getParameter("amount");

    String creditDebit =
        request.getParameter("credit_debit");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode =
            sessionBranchCode;
    }

    /* ================= SECURITY ================= */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode =
            sessionBranchCode;
    }

    if(amount == null)
        amount = "";

    amount = amount.trim();

    /* ================= VALIDATION ================= */

    if(fromDate == null ||
       fromDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter From Date</h3>"
        );

        return;
    }

    if(toDate == null ||
       toDate.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter To Date</h3>"
        );

        return;
    }

    if(amount.equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter Amount</h3>"
        );

        return;
    }

    if(creditDebit == null ||
       creditDebit.trim().equals("")){

        out.println(
            "<h3 style='color:red'>Please Select Credit/Debit</h3>"
        );

        return;
    }

    /* ================= DATE FORMAT ================= */

    String oracleFromDate = "";
    String oracleToDate   = "";

    try{

        java.util.Date d1 =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(fromDate);

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(d1).toUpperCase();

        java.util.Date d2 =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(toDate);

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(d2).toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();

        response.setBufferSize(
            1024 * 1024
        );

        conn =
            DBConnection.getConnection();

        /* ================= LOAD REPORT ================= */

        /* ================= LOAD REPORT ================= */

        String reportFile = "";

        if("D".equalsIgnoreCase(creditDebit)){

            reportFile =
                "/Reports/NewAccountLargeCashTransaction (Debit).jasper";

        }else{

            reportFile =
                "/Reports/NewAccountLargeCashTransaction(Credit).jasper";
        }

        String jasperPath =
            application.getRealPath(reportFile);

        File file =
            new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : "
                + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)
            JRLoader.loadObject(file);

        /* ================= PARAMETERS ================= */

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
            "amount",
            amount
        );

        parameters.put(
            "report_title",
            "NEW ACCOUNT LARGE CASH TRANSACTION"
        );

        String userId =
            (String)session.getAttribute(
                "userId"
            );

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

            response.setContentType(
                "text/html"
            );

            out.println(
                "<h2 style='color:red;text-align:center;margin-top:50px;'>"
            );

            out.println(
                "No Records Found!"
            );

            out.println("</h2>");

            return;
        }

        out.clear();
        out = pageContext.pushBody();
                /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"NewAccountLargeCashTransaction.pdf\""
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
                "attachment; filename=\"NewAccountLargeCashTransaction.xls\""
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

<title>
New Account Large Cash Transaction
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

.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    cursor:not-allowed;
}

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

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
NEW ACCOUNT LARGE CASH TRANSACTION
</h1>

<form method="post"

action="<%=request.getContextPath()%>/Reports/jspFiles/NewAccountLargeCashTransaction.jsp"

target="_blank"

autocomplete="off">

<input type="hidden"
       name="action"
       value="download"/>

<!-- ================= PARAMETERS ================= -->

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

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">

…

</button>

<% } %>

</div>

</div>

<!-- ================= BRANCH NAME ================= -->

<div class="parameter-group">

<div class="parameter-label">
Branch Name
</div>

<input type="text"
       id="branchName"
       class="input-field"
       readonly>

</div>

<!-- ================= FROM DATE ================= -->

<div class="parameter-group">

<div class="parameter-label">
From Date
</div>

<input type="text"
       name="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<!-- ================= TO DATE ================= -->

<div class="parameter-group">

<div class="parameter-label">
To Date
</div>

<input type="text"
       name="to_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<!-- ================= AMOUNT ================= -->

<div class="parameter-group">

<div class="parameter-label">
Amount Above
</div>

<input type="text"
       name="amount"
       class="input-field"
       value="100000"
       required>

</div>

<!-- ================= CREDIT / DEBIT ================= -->

<div class="parameter-group">

<div class="parameter-label">
Transaction Type
</div>

<div class="radio-container">

<label>

<input type="radio"
       name="credit_debit"
       value="C"
       checked>

Credit

</label>

<label>

<input type="radio"
       name="credit_debit"
       value="D">

Debit

</label>

</div>

</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<div class="format-options">

<div class="format-option">

<input type="radio"
       name="reporttype"
       value="pdf"
       checked>

PDF

</div>

<div class="format-option">

<input type="radio"
       name="reporttype"
       value="xls">

Excel

</div>

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

<button type="button"
        onclick="closeLookup()"
        style="float:right;">

✖

</button>

<div id="lookupTable"></div>

</div>

</div>

</body>

</html>