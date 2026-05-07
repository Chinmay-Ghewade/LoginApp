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

    String fromAccountCode =
        request.getParameter("from_accountcode");

    String toAccountCode =
        request.getParameter("to_accountcode");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode =
            sessionBranchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode =
            sessionBranchCode;
    }

    if(fromAccountCode == null)
        fromAccountCode = "";

    if(toAccountCode == null)
        toAccountCode = "";

    fromAccountCode =
        fromAccountCode.trim();

    toAccountCode =
        toAccountCode.trim();

    /* ================= VALIDATION ================= */

    if(fromAccountCode.equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter From Account Code</h3>"
        );

        return;
    }

    if(toAccountCode.equals("")){

        out.println(
            "<h3 style='color:red'>Please Enter To Account Code</h3>"
        );

        return;
    }

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

    if(Long.parseLong(fromAccountCode)
        >
       Long.parseLong(toAccountCode)){

        out.println(
            "<h3 style='color:red'>To Account Code must be greater than From Account Code</h3>"
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

        /* ================= STORE PROCEDURE ================= */

        CallableStatement stmt =
            conn.prepareCall(
                "{ call sp_get_ho_int_1(?, ?, ?, ?) }"
            );

        stmt.setString(
            1,
            branchCode
        );

        stmt.setString(
            2,
            oracleFromDate
        );

        stmt.setString(
            3,
            oracleToDate
        );

        String userId =
            (String)session.getAttribute(
                "userId"
            );

        if(userId == null)
            userId = "admin";

        stmt.setString(
            4,
            userId
        );

        stmt.execute();

        /* ================= LOAD REPORT ================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/HoAccountStatement.jasper"
            );

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

        /* JRXML PARAMETER NAME */
        parameters.put(
            "from_account",
            fromAccountCode
        );

        /* JRXML PARAMETER NAME */
        parameters.put(
            "to_account",
            toAccountCode
        );

        /* JRXML PARAMETER NAME */
        parameters.put(
            "as_on_date",
            oracleFromDate
        );

        parameters.put(
            "to_date",
            oracleToDate
        );

        parameters.put(
            "report_title",
            "HO ACCOUNT STATEMENT"
        );

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
                "inline; filename=\"HoAccountStatement.pdf\""
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
                "attachment; filename=\"HoAccountStatement.xls\""
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

<title>HO Account Statement</title>

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

.input-field:disabled{
    background:#e0e0e0;
    cursor:not-allowed;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
HO ACCOUNT STATEMENT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/HoAccountStatement.jsp"
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

<!-- BRANCH NAME -->

<div class="parameter-group">

<div class="parameter-label">
Branch Name
</div>

<input type="text"
       id="branchName"
       class="input-field"
       readonly>

</div>

<!-- ================= FROM ACCOUNT ================= -->

<div class="parameter-group">

<div class="parameter-label">
From Account Code
</div>

<div class="input-box">

<input type="text"
       name="from_accountcode"
       id="account_code"
       class="input-field"
       required>

<button type="button"
        class="icon-btn"
        onclick="openLookup('account')">

…

</button>

</div>

</div>


<!-- ================= TO ACCOUNT ================= -->

<div class="parameter-group">

<div class="parameter-label">
To Account Code
</div>

<div class="input-box">

<input type="text"
       name="to_accountcode"
       id="to_account_code"
       class="input-field"
       required>

<button type="button"
        class="icon-btn"
        onclick="openLookupForToAccount()">

…

</button>

</div>

</div>

</div>

<!-- ================= DATE RANGE ================= -->

<div class="parameter-section">

<!-- FROM DATE -->

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

<!-- TO DATE -->

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

<!-- ================= CUSTOM SCRIPT ================= -->

<script>

/* ===============================
   TO ACCOUNT LOOKUP
=============================== */

function openLookupForToAccount(){

    activeInput =
        document.getElementById(
            "to_account_code"
        );

    let branchField =
        document.getElementById(
            "branch_code"
        );

    let branch =
        branchField
        ? branchField.value
        : "";

    let url =
        contextPath +
        "/CommonLookupServlet?type=account";

    if(branch){

        url +=
            "&branchCode=" +
            encodeURIComponent(branch);
    }

    fetch(url)

    .then(res => res.text())

    .then(html => {

        document.getElementById(
            "lookupTable"
        ).innerHTML = html;

        document.getElementById(
            "lookupModal"
        ).style.display = "flex";
    })

    .catch(err =>
        console.error(
            "Lookup Error:",
            err
        )
    );
}


/* ===============================
   OVERRIDE ACCOUNT SELECT
=============================== */

function selectAccount(code, name){

    /* TO ACCOUNT */

    if(activeInput &&
       activeInput.id === "to_account_code"){

        document.getElementById(
            "to_account_code"
        ).value = code;

        closeLookup();

        return;
    }

    /* FROM ACCOUNT */

    let field =
        document.getElementById(
            "account_code"
        );

    if(field){

        field.value = code;
    }

    let nameField =
        document.getElementById(
            "account_name"
        );

    if(nameField){

        nameField.value = name;
    }

    closeLookup();
}

</script>

</body>

</html>