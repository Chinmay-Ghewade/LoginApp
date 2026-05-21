<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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
    (String)session.getAttribute(
        "isSupportUser"
    );

String sessionBranchCode =
    (String)session.getAttribute(
        "branchCode"
    );

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

    String reportSelect =
        request.getParameter("selreports");

    String asOnDate =
        request.getParameter("CashDeposit_date_from");

    String noOfAcc =
        request.getParameter("cashreceipt_totalacc");

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

    if(reportSelect == null)
        reportSelect = "1";

    if(noOfAcc == null)
        noOfAcc = "";

    noOfAcc = noOfAcc.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(asOnDate == null
        || asOnDate.trim().equals("")){

        errorMessage =
            "Enter As On Date!";
    }

    if(
        (
            "5".equals(reportSelect)
            || "6".equals(reportSelect)
            || "7".equals(reportSelect)
            || "9".equals(reportSelect)
        )
        &&
        noOfAcc.equals("")
    ){

        errorMessage =
            "Enter Number Of Accounts!";
    }

    /* =====================================================
       DATE FORMAT
    ===================================================== */

    String oracleDate = "";

    if(errorMessage.equals("")){

        try{

            java.util.Date d =
                new SimpleDateFormat(
                    "dd/MM/yyyy"
                ).parse(asOnDate);

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
            REPORT FILE
         ============================================== */

         String reportFile = "";

         if("1".equals(reportSelect)){

             reportFile =
                 "CashAndOverdraftRG.jasper";
         }

         else if("2".equals(reportSelect)){

             reportFile =
                 "AdvancesAndDepositsRG.jasper";
         }

         else if("3".equals(reportSelect)){

             reportFile =
                 "CreditBalanceInLoansRG.jasper";
         }

         else if("4".equals(reportSelect)){

             reportFile =
                 "ProfitAndLossRG.jasper";
         }

         else if("5".equals(reportSelect)){

             reportFile =
                 "TopNoNPARG.jasper";
         }

         else if("6".equals(reportSelect)){

             reportFile =
                 "TopNoDepositRG.jasper";
         }

         else if("7".equals(reportSelect)){

             reportFile =
                 "TopLoanHousingRG.jasper";
         }

         else if("8".equals(reportSelect)){

             reportFile =
                 "WeeklyMeetingDetailsRG.jasper";
         }

         else if("9".equals(reportSelect)){

             reportFile =
                 "TopInterestPaidDepositsRG.jasper";
         }
         
            /* ==============================================
               LOAD REPORT
            ============================================== */

            String jasperPath =
                application.getRealPath(
                    "/Reports/" + reportFile
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
            parameters.put("as_on_date",oracleDate);
            
            java.text.SimpleDateFormat sdf =
            	    new java.text.SimpleDateFormat(
            	        "dd-MMM-yyyy",
            	        java.util.Locale.ENGLISH
            	    );

            	java.util.Date toDt =
            	    sdf.parse(oracleDate);

            	Calendar cal =
            	    Calendar.getInstance();

            	cal.setTime(toDt);
            	cal.add(Calendar.YEAR,-1);
            	cal.add(Calendar.DAY_OF_MONTH,1);

            	String fromDate =
            	    sdf.format(cal.getTime()).toUpperCase();

            	parameters.put("from_date",fromDate);
            	parameters.put("to_date",oracleDate);
            parameters.put("CashDeposit_date_from",oracleDate);
            parameters.put("no_of_accounts",noOfAcc);

            String title = "";

            if("1".equals(reportSelect)){

                title =
                    "Cash and Overdraft";
            }

            else if("2".equals(reportSelect)){

                title =
                    "Advances and Deposits";
            }

            else if("3".equals(reportSelect)){

                title =
                    "Credit Balance in Loans";
            }

            else if("4".equals(reportSelect)){

                title =
                    "Profit and Loss";
            }

            else if("5".equals(reportSelect)){

                title =
                    "Top NPA";
            }

            else if("6".equals(reportSelect)){

                title =
                    "Top Deposit";
            }

            else if("7".equals(reportSelect)){

                title =
                    "Top Housing Loan";
            }

            else if("8".equals(reportSelect)){

                title =
                    "Weekly Meeting Details";
            }

            else if("9".equals(reportSelect)){

                title =
                    "Interest Paid Deposits";
            }

            parameters.put("report_title",title);

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
                application.getRealPath(
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
                reporttype == null
                || "pdf".equalsIgnoreCase(
                    reporttype
                )
            ){

                response.setContentType(
                    "application/pdf"
                );

                response.setHeader(
                    "Content-Disposition",

                    "inline; filename=\"CBSMultipleRG.pdf\""
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

                    "attachment; filename=\"CBSMultipleRG.xls\""
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
CBS Multiple Reports
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
BRANCHWISE MULTIPLE REPORTS
</h1>

<% if(errorMessage != null &&
      !errorMessage.trim().equals("")) { %>

<div class="error-box">
<%= errorMessage %>
</div>

<% } %>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/CBSMultipleRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden"
name="action"
value="download"/>

<!-- =====================================================
     BRANCH SECTION
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

…

</button>

<% } %>

</div>

</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

</div>

<!-- =====================================================
     REPORT TYPE SECTION
===================================================== -->

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">
Select Report
</div>

<select name="selreports"
        id="selreports"
        class="input-field"
        onchange="toggleNoOfAcc()">

<option value="1">
Cash and Overdraft
</option>

<option value="2">
Advances and Deposits
</option>

<option value="3">
Credit Balance in Loans
</option>

<option value="4">
Profit and Loss
</option>

<option value="5">
Top No. NPA
</option>

<option value="6">
Top No. Deposit
</option>

<option value="7">
Top Housing Loan
</option>

<option value="8">
Weekly Meeting Details
</option>

<option value="9">
Top Interest Paid Deposits
</option>

</select>

</div>

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="text"
       name="CashDeposit_date_from"
       id="CashDeposit_date_from"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

</div>

<!-- =====================================================
     NO OF ACCOUNTS
===================================================== -->

<div class="parameter-section"
     id="accSection">

<div class="parameter-group">

<div class="parameter-label">
Top No Of Accounts
</div>

<input type="text"
       name="cashreceipt_totalacc"
       id="cashreceipt_totalacc"
       class="input-field">

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

</body>
</html>