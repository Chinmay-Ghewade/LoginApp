<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {

    if (obj instanceof java.sql.Date) {

        sessionDate =
        new java.text.SimpleDateFormat("yyyy-MM-dd")
        .format((java.sql.Date) obj)
        .toUpperCase();

    } else {

        sessionDate = obj.toString();
    }
}
String displayDate = "";

try {
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

if (sessionDate == null || sessionDate.isEmpty()) {

    sessionDate =
    new java.text.SimpleDateFormat("yyyy-MM-dd")
    .format(new java.util.Date());
}
%>

<%
/* =====================================================
   SESSION
===================================================== */

String sessionBranchCode =
(String) session.getAttribute("branchCode");

String userId =
(String) session.getAttribute("userId");

String isSupportUser =
(String) session.getAttribute("isSupportUser");

if(sessionBranchCode==null)
    sessionBranchCode="";

if(userId==null)
    userId="";

if(isSupportUser==null)
    isSupportUser="N";

/* =====================================================
   ACTION
===================================================== */

String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode =
    request.getParameter("branch_code");

    String fromCustomer =
    request.getParameter("from_customer");

    String toCustomer =
    request.getParameter("to_customer");

    String reportType =
    request.getParameter("reporttype");

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    /* =============================================
       VALIDATION
    ============================================= */

    if(fromCustomer==null ||
       fromCustomer.trim().equals("")){

        session.setAttribute(
        "errorMessage",
        "Please Enter From Customer"
        );

        response.sendRedirect(
        "CustomerRG.jsp"
        );

        return;
    }

    if(toCustomer==null ||
       toCustomer.trim().equals("")){

        session.setAttribute(
        "errorMessage",
        "Please Enter To Customer"
        );

        response.sendRedirect(
        "CustomerRG.jsp"
        );

        return;
    }

    if(Long.parseLong(fromCustomer)
        >
       Long.parseLong(toCustomer)){

        session.setAttribute(
        "errorMessage",
        "To Customer must be greater than or equal to From Customer"
        );

        response.sendRedirect(
        "CustomerRG.jsp"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();

        conn =
        DBConnection.getConnection();

        /* =============================================
           LOAD JASPER
        ============================================= */

        String jasperPath =
        application.getRealPath(
        "/Reports/CustomerRG.jasper"
        );

        JasperReport jasperReport =
        (JasperReport)
        JRLoader.loadObject(
        new File(jasperPath)
        );

        /* =============================================
           PARAMETERS
        ============================================= */

        Map<String,Object> params =
        new HashMap<String,Object>();

        params.put("branch_code",branchCode);
        params.put("fromcustomerid",fromCustomer);
        params.put("tocustomerid",toCustomer);
        params.put("report_title","CUSTOMER ID REPORT");
        params.put("as_on_date",sessionDate);
        params.put("user_id",userId);
        params.put("SUBREPORT_DIR",application.getRealPath("/Reports/"));

        params.put(
        JRParameter.REPORT_CONNECTION,
        conn
        );

        /* =============================================
           FILL REPORT
        ============================================= */

        JasperPrint jp =
        JasperFillManager.fillReport(
        jasperReport,
        params,
        conn
        );

        if(jp.getPages().isEmpty()){

            session.setAttribute(
            "errorMessage",
            "No Records Found!"
            );

            response.sendRedirect(
            "CustomerRG.jsp"
            );

            return;
        }

        out.clear();
        out = pageContext.pushBody();

        /* =============================================
           PDF EXPORT
        ============================================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType(
            "application/pdf"
            );

            response.setHeader(
            "Content-Disposition",
            "inline; filename=\"CustomerRG.pdf\""
            );

            ServletOutputStream os =
            response.getOutputStream();

            JasperExportManager
            .exportReportToPdfStream(
            jp,
            os
            );

            os.close();
        }

        /* =============================================
           EXCEL EXPORT
        ============================================= */

        else{

            response.setContentType(
            "application/vnd.ms-excel"
            );

            response.setHeader(
            "Content-Disposition",
            "attachment; filename=\"CustomerRG.xls\""
            );

            ServletOutputStream os =
            response.getOutputStream();

            JRXlsExporter exporter =
            new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT,
            jp
            );

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,
            os
            );

            exporter.exportReport();

            os.close();
        }

    }catch(Exception e){

        Throwable cause = e;

        while(cause.getCause()!=null){

            cause = cause.getCause();
        }

        session.setAttribute(
        "errorMessage",
        "Error = " + cause.getMessage()
        );

        response.sendRedirect(
        "CustomerRG.jsp"
        );
    }
    finally{

        if(conn!=null)
        try{
            conn.close();
        }catch(Exception ex){}
    }

    return;
}
%>

<!DOCTYPE html>

<html>

<head>

<title>
Customer ID Report
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
"<%=request.getContextPath()%>/js/lookup.js?v=5">
</script>

<style>

.error-message{
    background:#ffe6e6;
    color:red;
    padding:10px;
    text-align:center;
    margin-bottom:15px;
    border-radius:5px;
    font-weight:bold;
}

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

<%
String errorMessage =
(String)session.getAttribute(
"errorMessage"
);

if(errorMessage!=null){
%>

<div class="error-message">

<%=errorMessage%>

</div>

<%
session.removeAttribute(
"errorMessage"
);
}
%>

<h1 class="report-title">

CUSTOMER ID REPORT

</h1>

<form method="post"
action="CustomerRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download">

<!-- ============================================
     PARAMETERS
============================================ -->

<div class="parameter-section">

<!-- BRANCH -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
maxlength="4"
value="<%=sessionBranchCode%>"
readonly>

</div>

</div>

<!-- FROM CUSTOMER -->

<div class="parameter-group">

<div class="parameter-label">
From Customer No
</div>

<div class="input-box">

<input type="text"
name="from_customer"
id="from_customer"
class="input-field"
maxlength="14"
required>

<button type="button"
class="icon-btn"
onclick="
activeInput=document.getElementById('from_customer');
openLookup('customer');
">

...

</button>
</div>

</div>

<!-- TO CUSTOMER -->

<div class="parameter-group">

<div class="parameter-label">
To Customer No
</div>

<div class="input-box">

<input type="text"
name="to_customer"
id="to_customer"
class="input-field"
maxlength="14"
required>

<button type="button"
class="icon-btn"
onclick="
activeInput=document.getElementById('to_customer');
openLookup('customer');
">

...

</button>
</div>

</div>

<!-- Date -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="text"
       name="as_on_date"
       class="input-field"
       value="<%= displayDate %>"
       placeholder="DD/MM/YYYY"  required>
</div>

</div>

<!-- ============================================
     REPORT TYPE
============================================ -->

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

&nbsp;&nbsp;&nbsp;

<label>

<input type="radio"
name="reporttype"
value="xls">

Excel

</label>

</div>

<!-- ============================================
     BUTTON
============================================ -->

<button type="submit"
class="download-button">

Generate Report

</button>

</form>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

/* ============================================
   VALIDATION
============================================ */

document.querySelector("form")
.addEventListener(
"submit",
function(e){

    let fromCustomer =
    document.getElementById(
    "from_customer"
    ).value.trim();

    let toCustomer =
    document.getElementById(
    "to_customer"
    ).value.trim();

    if(fromCustomer===""){

        alert(
        "Please Enter From Customer"
        );

        e.preventDefault();
        return false;
    }

    if(toCustomer===""){

        alert(
        "Please Enter To Customer"
        );

        e.preventDefault();
        return false;
    }

    if(
        parseInt(fromCustomer)
        >
        parseInt(toCustomer)
    ){

        alert(
        "To Customer must be greater than or equal to From Customer"
        );

        e.preventDefault();
        return false;
    }
}
);


/* ============================================
   WINDOW CLICK
============================================ */

window.onclick = function(event){

    let modal =
    document.getElementById(
    "lookupModal"
    );

    if(event.target == modal){

        modal.style.display = "none";
    }
}

/* ============================================
   ONLY NUMBER
============================================ */

document.getElementById(
"from_customer"
).addEventListener(
"keypress",
onlyNumber
);

document.getElementById(
"to_customer"
).addEventListener(
"keypress",
onlyNumber
);

function onlyNumber(e){

    let charCode =
    (e.which)
    ? e.which
    : e.keyCode;

    if(
        charCode > 31 &&
        (charCode < 48 || charCode > 57)
    ){

        e.preventDefault();
    }
}

</script>

</body>

</html>