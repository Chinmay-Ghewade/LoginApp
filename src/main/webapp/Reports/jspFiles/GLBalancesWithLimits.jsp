<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* =========================================================
   SESSION VALUES
========================================================= */

String sessionBranchCode =
        (String)session.getAttribute("branchCode");

String sessionBranchName =
        (String)session.getAttribute("branchName");

String userId =
        (String)session.getAttribute("userId");

String bankName =
        (String)session.getAttribute("bankName");

Object workingDateObj =
        session.getAttribute("workingDate");

String displayDate = "";

try{

    if(workingDateObj != null){

        java.util.Date dt;

        if(workingDateObj instanceof java.sql.Date){

            dt =
                (java.sql.Date)workingDateObj;

        }else{

            dt =
                new SimpleDateFormat(
                    "yyyy-MM-dd"
                ).parse(
                    workingDateObj.toString()
                );
        }

        displayDate =
            new SimpleDateFormat(
                "dd/MM/yyyy"
            ).format(dt);
    }

}catch(Exception e){

    displayDate = "";
}

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(sessionBranchName == null)
    sessionBranchName = "";

if(userId == null)
    userId = "";

if(bankName == null)
    bankName = "";

/* =========================================================
   CASH GL FETCH
========================================================= */

String glCode = "";
String glDescription = "";

Connection conn = null;

try{

    conn =
        DBConnection.getConnection();

    String sql =

        " SELECT G.GLACCOUNT_CODE, " +
        "        G.DESCRIPTION " +

        " FROM ACCOUNTLINK.DEFAULTBANKACCOUNTS D, " +
        "      HEADOFFICE.GLACCOUNT G " +

        " WHERE D.ACCOUNT_CODE_CASH_IN_HAND = " +
        "       G.GLACCOUNT_CODE ";

    PreparedStatement ps =
            conn.prepareStatement(sql);

    ResultSet rs =
            ps.executeQuery();

    if(rs.next()){

        glCode =
            rs.getString("GLACCOUNT_CODE");

        glDescription =
            rs.getString("DESCRIPTION");
    }

    rs.close();
    ps.close();

}catch(Exception e){

    e.printStackTrace();

}finally{

    if(conn != null){

        try{
            conn.close();
        }catch(Exception ex){}
    }
}

/* =========================================================
   REQUEST PARAMETERS
========================================================= */

String action =
        request.getParameter("action");

String fromDate =
        request.getParameter("from_date");

String toDate =
        request.getParameter("to_date");

String reportType =
        request.getParameter("reporttype");

String withAllBalance =
        request.getParameter("with_all_balance");

if(fromDate == null)
    fromDate = "";

if(toDate == null)
    toDate = "";

if(reportType == null)
    reportType = "pdf";

if(withAllBalance == null)
    withAllBalance = "N";

String errorMessage = "";

/* =========================================================
   REPORT GENERATION
========================================================= */

if("download".equalsIgnoreCase(action)){

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(fromDate.trim().equals("")){

        errorMessage =
            "Please Enter From Date";
    }

    else if(toDate.trim().equals("")){

        errorMessage =
            "Please Enter To Date";
    }

    else{

        try{

            SimpleDateFormat sdf =
                new SimpleDateFormat(
                    "dd/MM/yyyy"
                );

            sdf.setLenient(false);

            java.util.Date fd =
                sdf.parse(fromDate);

            java.util.Date td =
                sdf.parse(toDate);

            if(fd.after(td)){

                errorMessage =
                    "From Date Must Be Less Than To Date";
            }

        }catch(Exception ex){

            errorMessage =
                "Invalid Date Format";
        }
    }

    /* =====================================================
       REPORT EXPORT
    ===================================================== */

    if(errorMessage.equals("")){

        Connection reportConn = null;

        try{

            response.reset();

            response.setBufferSize(
                1024 * 1024
            );

            reportConn =
                DBConnection.getConnection();

            /* =============================================
               LOAD JASPER FILE
            ============================================= */

            String jasperPath =
                application.getRealPath(
                    "/Reports/CashBalanceWithLimit.jasper"
                );

            File jasperFile =
                new File(jasperPath);

            if(!jasperFile.exists()){

                throw new Exception(
                    "Jasper File Not Found : " +
                    jasperPath
                );
            }

            JasperReport jasperReport =

                (JasperReport)
                JRLoader.loadObject(
                    jasperFile
                );

            /* =============================================
               PARAMETERS
            ============================================= */

            Map<String,Object> parameters =
                new HashMap<String,Object>();

            parameters.put("branch_code",sessionBranchCode );
            parameters.put("as_on_date",fromDate);
            parameters.put("from_date",fromDate);
            parameters.put("to_date",toDate);
            parameters.put("report_title","CASH BALANCE WITH CASH LIMIT");
            parameters.put("account_code",glCode);
            parameters.put("with_all_balance",withAllBalance);
            parameters.put("user_id",userId);
            parameters.put("SUBREPORT_DIR",application.getRealPath( "/Reports/") + File.separator);

            /* =============================================
               FILL REPORT
            ============================================= */

            JasperPrint jasperPrint =

                JasperFillManager.fillReport(jasperReport,parameters,reportConn);

            /* =============================================
               NO RECORD FOUND
            ============================================= */

            if(jasperPrint.getPages().isEmpty()){

                response.setContentType("text/html");

                out.println("<h2 style='color:red;" +"text-align:center;" +"margin-top:50px;'>");
                out.println("No Records Found!");
                out.println("</h2>");
                return;
             }

            /* =============================================
               PDF EXPORT
            ============================================= */

            if("pdf".equalsIgnoreCase(reportType)){

                response.setContentType(
                    "application/pdf"
                );

                response.setHeader(
                    "Content-Disposition",
                    "inline; filename=CashBalanceWithLimit.pdf"
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
            }

            /* =============================================
               EXCEL EXPORT
            ============================================= */

            else if(
                "xls".equalsIgnoreCase(reportType)
            ){

                response.setContentType(
                    "application/vnd.ms-excel"
                );

                response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=CashBalanceWithLimit.xls"
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

                exporter.setParameter(
                    JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET,
                    Boolean.FALSE
                );

                exporter.setParameter(
                    JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS,
                    Boolean.TRUE
                );

                exporter.setParameter(
                    JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND,
                    Boolean.FALSE
                );

                exporter.exportReport();

                outputStream.flush();
                outputStream.close();
            }

            return;

        }catch(Exception e){

            response.setContentType("text/html");

            out.println("<h3 style='color:red;" +"margin-top:40px;" +"text-align:center;'>");
            out.println("Error Generating Report");
            out.println("</h3>");

            e.printStackTrace(
                new PrintWriter(out)
            );

        }finally{

            if(reportConn != null){

                try{
                    reportConn.close();
                }catch(Exception ex){}
            }
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Cash Balance With Cash Limit</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath ="<%=request.getContextPath()%>";
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

<script>

function validateForm(){

    var fromDate =
        document.getElementById("from_date").value;

    var toDate =
        document.getElementById("to_date").value;

    if(fromDate == ""){

        alert("Please Enter From Date");
        return false;
    }

    if(toDate == ""){

        alert("Please Enter To Date");
        return false;
    }

    return true;
}

</script>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
CASH BALANCE WITH CASH LIMIT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/GLBalancesWithLimits.jsp"
      id="mainForm"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm();">

<input type="hidden"
       name="action"
       value="download">

<div class="parameter-section">

    <!-- WORKING DATE -->

    <div class="parameter-group">

        <div class="parameter-label">
            Working Date
        </div>

        <input type="text"
               class="input-field"
               value="<%= displayDate %>"
               readonly>

    </div>

    <!-- USER ID -->

    <div class="parameter-group">

        <div class="parameter-label">
            User Id
        </div>

        <input type="text"
               class="input-field"
               value="<%= userId %>"
               readonly>

    </div>

    <!-- GL CODE -->

    <div class="parameter-group">

        <div class="parameter-label">
            Cash In Hand Code
        </div>

        <input type="text"
               class="input-field"
               value="<%= glCode %>"
               readonly>

    </div>

    <!-- DESCRIPTION -->

    <div class="parameter-group">

        <div class="parameter-label">
            Description
        </div>

        <input type="text"
               class="input-field"
               value="<%= glDescription %>"
               readonly>

    </div>

    <!-- FROM DATE -->

    <div class="parameter-group">

        <div class="parameter-label">
            From Date
        </div>

        <input type="text"
               name="from_date"
               id="from_date"
               class="input-field"
               value="<%= fromDate == null ? "" : fromDate %>"
               placeholder="DD/MM/YYYY">

    </div>

    <!-- TO DATE -->

    <div class="parameter-group">

        <div class="parameter-label">
            To Date
        </div>

        <input type="text"
               name="to_date"
               id="to_date"
               class="input-field"
               value="<%= toDate == null ? "" : toDate %>"
               placeholder="DD/MM/YYYY">

    </div>

</div>

<!-- RADIO BUTTONS -->

<div class="radio-container">

    <label>

        <input type="radio"
               name="with_all_balance"
               value="Y"
               <%= "Y".equalsIgnoreCase(
                       withAllBalance == null
                       ? "N"
                       : withAllBalance)
                       ? "checked"
                       : "" %> >

        All Balances

    </label>

    <label>

        <input type="radio"
               name="with_all_balance"
               value="N"
               <%= !"Y".equalsIgnoreCase(
                       withAllBalance == null
                       ? "N"
                       : withAllBalance)
                       ? "checked"
                       : "" %> >

        Exceeded Only

    </label>

</div>


<!-- REPORT TYPE -->

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

<!-- BUTTON -->

<div class="button-section">

    <button type="submit"
            class="download-button">

        Generate Report

    </button>

</div>

</form>

</div>

</body>
</html>