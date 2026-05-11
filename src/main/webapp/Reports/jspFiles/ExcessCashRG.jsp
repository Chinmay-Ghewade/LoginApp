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
<%@ page import="net.sf.jasperreports.engine.design.JRDesignQuery" %>
<%@ page import="net.sf.jasperreports.engine.design.JasperDesign" %>
<%@ page import="net.sf.jasperreports.engine.xml.JRXmlLoader" %>

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

if(sessionDate == null || sessionDate.isEmpty()){

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

String sessionBranchName =
    (String)session.getAttribute("branchName");

String userId =
    (String)session.getAttribute("userId");

if(isSupportUser == null) isSupportUser = "N";
if(sessionBranchCode == null) sessionBranchCode = "";
if(sessionBranchName == null) sessionBranchName = "";
if(userId == null) userId = "admin";
%>

<%
/* =========================================================
   DOWNLOAD LOGIC
========================================================= */
String defaultLimitAmount = "";

Connection limitConn = null;

try{

    limitConn = DBConnection.getConnection();

    Statement limitStmt =
        limitConn.createStatement();

    ResultSet limitRs =
        limitStmt.executeQuery(

        " SELECT CASH_LIMIT " +
        " FROM HEADOFFICE.BRANCHPARAMETER " +
        " WHERE BRANCH_CODE = '" +
        sessionBranchCode + "' "

        );

    if(limitRs.next()){

        defaultLimitAmount =
            limitRs.getString("CASH_LIMIT");
    }

    limitRs.close();
    limitStmt.close();

}catch(Exception e){

    defaultLimitAmount = "";

}finally{

    if(limitConn != null){

        try{
            limitConn.close();
        }catch(Exception ex){}
    }
}
String action = request.getParameter("action");

if("download".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    String limitAmount =
        request.getParameter("limitamount");

    if(branchCode == null || branchCode.trim().isEmpty()){

        branchCode = sessionBranchCode;
    }

    /* =====================================================
       SECURITY FOR NON SUPPORT USER
    ===================================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    if(limitAmount == null){

        limitAmount = "0";
    }

  

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(fromDate == null || fromDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Select From Date"
            + "</h3>"
        );

        return;
    }

    if(toDate == null || toDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Select To Date"
            + "</h3>"
        );

        return;
    }

    if(limitAmount.trim().equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Enter Limit Amount"
            + "</h3>"
        );

        return;
    }

    double limitAmt = 0;

    try{

        limitAmt = Double.parseDouble(limitAmount);

    }catch(Exception e){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Limit Amount Must Be Numeric"
            + "</h3>"
        );

        return;
    }

    String oracleFromDate = "";
    String oracleToDate   = "";

    try{

        java.util.Date fDate =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(fromDate);

        java.util.Date tDate =
            new SimpleDateFormat("dd/MM/yyyy")
            .parse(toDate);

        if(fDate.after(tDate)){

            out.println(
                "<h3 style='color:red;text-align:center'>"
                + "From Date Must Be Less Than To Date"
                + "</h3>"
            );

            return;
        }

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(fDate).toUpperCase();

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(tDate).toUpperCase();

    }catch(Exception e){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Invalid Date Format"
            + "</h3>"
        );

        return;
    }

    Connection conn = null;

    try{

        response.reset();

        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =====================================================
           LOAD REPORT
        ===================================================== */

        String jasperPath =
            application.getRealPath(
                "/Reports/ExcessCashRG.jasper"
            );

        File file = new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
                "Jasper file not found : "
                + jasperPath
            );
        }

        JasperDesign jasperDesign =
        	    JRXmlLoader.load(
        	        application.getRealPath(
        	            "/Reports/ExcessCashRG.jrxml"
        	        )
        	    );
     
        /* =====================================================
           PARAMETERS
        ===================================================== */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);
        parameters.put("from_date", fromDate);
        parameters.put("to_date", toDate);
        parameters.put("limitamount", String.valueOf(limitAmt));
        parameters.put("as_on_date",displayDate);

        String account_cash_in_hand = "";

        Statement stmt = conn.createStatement();

        ResultSet rsGL = stmt.executeQuery(
            "SELECT ACCOUNT_CODE_CASH_IN_HAND " +
            "FROM ACCOUNTLINK.DEFAULTBANKACCOUNTS"
        );

        if(rsGL.next()){

            account_cash_in_hand =
                rsGL.getString("ACCOUNT_CODE_CASH_IN_HAND");
        }

        rsGL.close();
        stmt.close();

        parameters.put(
            "GLaccount_code",
            account_cash_in_hand
        );
        parameters.put(
            "report_title",
            "EXCESS CASH ON HAND"
        );

        parameters.put("user_id", userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/")
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        /* =====================================================
           FILL REPORT
        ===================================================== */

        		String condition =
        	    " WHERE AMOUNT > " + limitAmt;

        	String sqlQuery =

        	    " SELECT ROWNUM AS SERIALNUMBER, " +
        	    " TXN_DATE, " +
        	    " AMOUNT, " +
        	    " ABS(" + limitAmt + " - AMOUNT) DIFFERENCE " +
        	    " FROM ( " +

        	    " SELECT TXN_DATE, " +

        	    " ABS(OPENINGBALANCE - " +
        	    " (DEBITCASH + DEBITTRANSFER + DEBITCLEARING) + " +
        	    " (CREDITCASH + CREDITTRANSFER + CREDITCLEARING)) AMOUNT " +

        	    " FROM BALANCE.BRANCHGLHISTORY " +

        	    " WHERE BRANCH_CODE = '" + branchCode + "' " +

        	    " AND GLACCOUNT_CODE = '" +
        	    account_cash_in_hand + "' " +

        	    " AND TXN_DATE BETWEEN " +
        	    " TO_DATE('" + fromDate + "','DD/MM/YYYY') " +
        	    " AND TO_DATE('" + toDate + "','DD/MM/YYYY') " +

        	    " ORDER BY TXN_DATE " +

        	    " ) " + condition;
        	
        	JRDesignQuery newQuery =
        	    new JRDesignQuery();

        	newQuery.setText(sqlQuery);

        	jasperDesign.setQuery(newQuery);

        	JasperReport jasperReport =
        	    JasperCompileManager.compileReport(
        	        jasperDesign
        	    );

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
            );

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        /* =====================================================
           EXPORT PDF
        ===================================================== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"ExcessCashReport.pdf\""
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

        /* =====================================================
           EXPORT EXCEL
        ===================================================== */

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"ExcessCashReport.xls\""
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
            "<h3 style='color:red'>"
            + "Error Generating Report"
            + "</h3>"
        );

        e.printStackTrace(new PrintWriter(out));

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

<title>Excess Cash On Hand</title>

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

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
EXCESS CASH ON HAND
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/ExcessCashRG.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm()">

<input type="hidden"
       name="action"
       value="download">

<div class="parameter-section">

<!-- =====================================================
     BRANCH CODE
===================================================== -->

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

<!-- =====================================================
     FROM DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
From Date
</div>

<input type="text"
       name="from_date"
       id="from_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<!-- =====================================================
     TO DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
To Date
</div>

<input type="text"
       name="to_date"
       id="to_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<!-- =====================================================
     LIMIT AMOUNT
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Limit Amount
</div>

<input type="text"
       name="limitamount"
       id="limitamount"
       class="input-field"
       value="<%=defaultLimitAmount%>"
       readonly
       style="background:#e0e0e0;cursor:not-allowed;"
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

<label>
<input type="radio"
       name="reporttype"
       value="xls">
Excel
</label>

</div>

<button type="submit"
        class="download-button">

Generate Report

</button>

</form>

</div>

<!-- =====================================================
     LOOKUP MODAL
===================================================== -->

<div id="lookupModal"
     class="modal">

<div class="modal-content">

<button class="close-btn"
        onclick="closeLookup()">

X

</button>

<div id="lookupTable"></div>

</div>
</div>

<script>

/* =====================================================
   FORM VALIDATION
===================================================== */

function validateForm(){

    var branchCode =
        document.getElementById(
            "branch_code"
        ).value.trim();

    var fromDate =
        document.getElementById(
            "from_date"
        ).value.trim();

    var toDate =
        document.getElementById(
            "to_date"
        ).value.trim();

    var limitAmount =
        document.getElementById(
            "limitamount"
        ).value.trim();

    if(branchCode === ""){

        alert("Please Enter Branch Code");

        return false;
    }

    if(fromDate === ""){

        alert("Please Select From Date");

        return false;
    }

    if(toDate === ""){

        alert("Please Select To Date");

        return false;
    }

    if(limitAmount === ""){

        alert("Please Enter Limit Amount");

        return false;
    }

    if(isNaN(limitAmount)){

        alert("Limit Amount Must Be Numeric");

        return false;
    }

    if(!isValidDate(fromDate)){

        alert("Invalid From Date Format");

        return false;
    }

    if(!isValidDate(toDate)){

        alert("Invalid To Date Format");

        return false;
    }

    var f = convertDate(fromDate);
    var t = convertDate(toDate);

    if(f > t){

        alert(
            "From Date Must Be Less Than To Date"
        );

        return false;
    }

    return true;
}

/* =====================================================
   DATE VALIDATION
===================================================== */

function isValidDate(dateString){

    var regex =
        /^\\d{2}\\/\\d{2}\\/\\d{4}$/;

    if(!regex.test(dateString)){

        return false;
    }

    var parts = dateString.split("/");

    var day   = parseInt(parts[0],10);
    var month = parseInt(parts[1],10)-1;
    var year  = parseInt(parts[2],10);

    var date = new Date(year, month, day);

    return date.getFullYear() === year &&
           date.getMonth() === month &&
           date.getDate() === day;
}

function convertDate(dateString){

    var parts = dateString.split("/");

    return new Date(
        parts[2],
        parts[1]-1,
        parts[0]
    );
}

/* =====================================================
   NUMERIC VALIDATION
===================================================== */

function validateNumeric(field){

    if(isNaN(field.value)){

        alert(
            "Amount Should Be Numeric Value"
        );

        field.value = "";

        field.focus();
    }
}

/* =====================================================
   LOOKUP FUNCTIONS
===================================================== */

function openLookup(type){

    document.getElementById(
        "lookupModal"
    ).style.display = "flex";

    var html = "";

    if(type === 'branch'){

        html += "<h3>Select Branch</h3>";

        html += "<table border='1' width='100%' cellpadding='8'>";

        html += "<tr style='background:#2D2B80;color:white'>";

        html += "<th>Branch Code</th>";
        html += "<th>Branch Name</th>";

        html += "</tr>";

        html += "<tr onclick=\"selectBranch('001')\">";

        html += "<td>001</td>";
        html += "<td>Main Branch</td>";

        html += "</tr>";

        html += "</table>";
    }

    document.getElementById(
        "lookupTable"
    ).innerHTML = html;
}

function closeLookup(){

    document.getElementById(
        "lookupModal"
    ).style.display = "none";
}

function selectBranch(code){

    document.getElementById(
        "branch_code"
    ).value = code;

    closeLookup();
}

window.onclick = function(event){

    var modal =
        document.getElementById(
            "lookupModal"
        );

    if(event.target == modal){

        closeLookup();
    }
}

</script>

</body>
</html>