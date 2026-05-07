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
/* ================= SESSION VALUES ================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if(obj != null){

    if(obj instanceof java.sql.Date){

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    }else{

        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.equals("")){

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

String bankName =
    (String)session.getAttribute("bankName");

String branchName =
    (String)session.getAttribute("branchName");

String userId =
    (String)session.getAttribute("userId");

if(isSupportUser == null) isSupportUser = "N";
if(sessionBranchCode == null) sessionBranchCode = "";
if(bankName == null) bankName = "";
if(branchName == null) branchName = "";
if(userId == null) userId = "admin";
%>

<%
/* ================= REPORT GENERATION ================= */

String action = request.getParameter("action");

if("download".equals(action)
    || "consolidated".equals(action)){

    String reporttype =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    String glaccountCode =
        request.getParameter("glaccount_code");

    String accountSelect =
        request.getParameter("account_select");

    String reportSelect =
        request.getParameter("report_select");

    /* ================= DEFAULT VALUES ================= */

    if(branchCode == null
        || branchCode.trim().equals("")){

        branchCode = sessionBranchCode;
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    if(fromDate == null) fromDate = "";
    if(toDate == null) toDate = "";
    if(glaccountCode == null) glaccountCode = "";
    if(accountSelect == null) accountSelect = "S";
    if(reportSelect == null) reportSelect = "A";
    if(reporttype == null) reporttype = "pdf";

    fromDate = fromDate.trim();
    toDate = toDate.trim();
    glaccountCode = glaccountCode.trim();

    /* ================= VALIDATION ================= */

    if("S".equalsIgnoreCase(accountSelect)
        && glaccountCode.equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Enter GL Account Code"
            + "</h3>"
        );
        return;
    }

    if(fromDate.equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Select From Date"
            + "</h3>"
        );
        return;
    }

    if(toDate.equals("")){

        out.println(
            "<h3 style='color:red;text-align:center'>"
            + "Please Select To Date"
            + "</h3>"
        );
        return;
    }

    /* ================= DATE VALIDATION ================= */

    java.util.Date fd = null;
    java.util.Date td = null;

    try{

        /* HTML DATE INPUT FORMAT */
        SimpleDateFormat htmlFormat = new SimpleDateFormat("dd/MM/yyyy");

        htmlFormat.setLenient(false);

        fd = htmlFormat.parse(fromDate);

        td = htmlFormat.parse(toDate);

        if(fd.after(td)){

            out.println(
                "<h3 style='color:red;text-align:center'>"
                + "From Date Must Be Less Than To Date"
                + "</h3>"
            );

            return;
        }

    }catch(Exception ex){

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

        /* ================= DATE FORMAT ================= */

        String oracleFromDate = "";
        String oracleToDate = "";

        oracleFromDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(fd).toUpperCase();

        oracleToDate =
            new SimpleDateFormat(
                "dd-MMM-yyyy",
                Locale.ENGLISH
            ).format(td).toUpperCase();
        
        /* ================= REPORT FILE ================= */

        String jasperName = "";

        if("consolidated".equals(action)){

            jasperName =
                "GLClosingReportFrom_ToDate (Consolidated Report).jasper";

            branchCode = "0000";

        }else{

            jasperName =
                "GLClosingReportFrom_ToDate.jasper";
        }

        String jasperPath =
            application.getRealPath(
                "/Reports/" + jasperName
            );

        File jasperFile =
            new File(jasperPath);

        if(!jasperFile.exists()){

            throw new RuntimeException(
                "Jasper File Not Found : "
                + jasperPath
            );
        }

        JasperReport jasperReport =
            (JasperReport)JRLoader.loadObject(
                jasperFile
            );

        /* ================= PARAMETERS ================= */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put(
            "branch_code",
            branchCode
        );

        parameters.put(
            "from_date",
            fromDate
        );

        parameters.put(
            "to_date",
            toDate
        );

        parameters.put(
            "as_on_date",
            oracleFromDate
        );

        parameters.put(
            "account_code",
            glaccountCode
        );

        parameters.put(
            "account_select",
            accountSelect
        );

        parameters.put(
            "report_select",
            reportSelect
        );

        parameters.put(
            "report_title",
            "GL CLOSING BALANCE REPORT"
        );

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
            "IMAGE_PATH",
            application.getRealPath(
                "/images/UPSB MONO.png"
            )
        );

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn
        );

        JasperPrint jasperPrint = null;

        /* ================= NORMAL REPORT ================= */

        if("download".equals(action)){

            String condition = "";
            String condition1 = "";

            if("S".equals(accountSelect)
                && !glaccountCode.equals("")){

                condition =
                    " and glaccount_code='"
                    + glaccountCode + "' ";
            }

            if("B".equals(reportSelect)){

                condition1 =
                    " and gl.alie in ('A','L')";

            }else if("P".equals(reportSelect)){

                condition1 =
                    " and gl.alie in ('I','E')";
            }

            String sql =
            " SELECT ROWNUM SERIALNUMBER,"
            + " ACCOUNTCODE,"
            + " ACCOUNTNAME,"
            + " OPENBALANCE,"
            + " TOTALDEBIT,"
            + " TOTALCREDIT,"
            + " CLOSINGBALANCE "
            + " FROM ( "
            + " SELECT "
            + " op.glaccount_code ACCOUNTCODE,"
            + " gl.description ACCOUNTNAME,"
            + " op.openingbalance OPENBALANCE,"
            + " bet.total_debit TOTALDEBIT,"
            + " bet.total_credit TOTALCREDIT,"
            + " (op.openingbalance"
            + " - bet.total_debit"
            + " + bet.total_credit)"
            + " CLOSINGBALANCE "
            + " FROM "
            + " (SELECT openingbalance,"
            + " glaccount_code "
            + " FROM balance.branchglhistory "
            + " WHERE txn_date='"
            + oracleFromDate + "' "
            + " and branch_code='"
            + branchCode + "' "
            + condition + ") op,"
            + " (SELECT "
            + " (sum(debitcash)"
            + " + sum(debitclearing)"
            + " + sum(debittransfer))"
            + " total_debit,"
            + " (sum(creditcash)"
            + " + sum(creditclearing)"
            + " + sum(credittransfer))"
            + " total_credit,"
            + " glaccount_code "
            + " FROM balance.branchglhistory "
            + " WHERE txn_date BETWEEN '"
            + oracleFromDate + "' "
            + " AND '" + oracleToDate + "' "
            + " and branch_code='"
            + branchCode + "' "
            + condition
            + " group by glaccount_code) bet,"
            + " headoffice.glaccount gl "
            + " WHERE op.glaccount_code"
            + " = bet.glaccount_code "
            + " AND op.glaccount_code"
            + " = gl.glaccount_code "
            + condition1
            + " ORDER BY op.glaccount_code )";

            Statement st =
                conn.createStatement(
                    ResultSet.TYPE_SCROLL_INSENSITIVE,
                    ResultSet.CONCUR_READ_ONLY
                );

            ResultSet rs =
                st.executeQuery(sql);

            JRResultSetDataSource jrRS =
                new JRResultSetDataSource(rs);

            jasperPrint =
                JasperFillManager.fillReport(
                    jasperReport,
                    parameters,
                    jrRS
                );
        }

        /* ================= CONSOLIDATED ================= */

        else{
        	
        	String condition2 = "";

        	if("B".equals(reportSelect)){

        	    condition2 =
        	        " and gl.alie in ('A','L') ";

        	}else if("P".equals(reportSelect)){

        	    condition2 =
        	        " and gl.alie in ('I','E') ";

        	}else if("C".equals(reportSelect)){

        	    condition2 = "";
        	}

        	String condition3 = "";

        	if("S".equals(accountSelect)
        	    && !glaccountCode.equals("")){

        	    condition3 =
        	        " and op.glaccount_code='"
        	        + glaccountCode + "' ";
        	}
    String sqlConsolidated =
    " SELECT "
    + " ROWNUM SERIALNUMBER,"
    + " A.* "
    + " FROM ( "
    + " SELECT "
    + " accountcode ACCOUNTCODE,"
    + " accountname ACCOUNTNAME,"
    + " SUM(openbalance) OPENBALANCE,"
    + " SUM(totaldebit) TOTALDEBIT,"
    + " SUM(totalcredit) TOTALCREDIT,"
    + " SUM(openbalance-totaldebit"
    + " + totalcredit)"
    + " CLOSINGBALANCE "
    + " FROM ( "
    + " SELECT "
    + " op.glaccount_code accountcode,"
    + " gl.description accountname,"
    + " op.openingbalance openbalance,"
    + " bet.total_debit totaldebit,"
    + " bet.total_credit totalcredit "
    + " FROM "
    + " (SELECT openingbalance,"
    + " glaccount_code "
    + " FROM balance.branchglhistory "
    + " WHERE txn_date='"
    + oracleFromDate + "') op,"
    + " (SELECT "
    + " SUM(debitcash"
    + " + debitclearing"
    + " + debittransfer)"
    + " total_debit,"
    + " SUM(creditcash"
    + " + creditclearing"
    + " + credittransfer)"
    + " total_credit,"
    + " glaccount_code "
    + " FROM balance.branchglhistory "
    + " WHERE txn_date BETWEEN '"
    + oracleFromDate + "' "
    + " AND '" + oracleToDate + "' "
    + " GROUP BY glaccount_code ) bet,"
    + " headoffice.glaccount gl "
    + " WHERE op.glaccount_code"
    + " = bet.glaccount_code "
    		+ " AND op.glaccount_code"
    		+ " = gl.glaccount_code "
    		+ condition2
    		+ condition3
    + " ) "
    + " GROUP BY "
    + " accountcode,"
    + " accountname "
    + " ORDER BY accountcode "
    + " ) A ";

    System.out.println(
        "Consolidated SQL : "
        + sqlConsolidated
    );

    Statement st2 =
        conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.CONCUR_READ_ONLY
        );

    ResultSet rs2 =
        st2.executeQuery(
            sqlConsolidated
        );

    JRResultSetDataSource jrRS2 =
        new JRResultSetDataSource(
            rs2
        );

    jasperPrint =
        JasperFillManager.fillReport(
            jasperReport,
            parameters,
            jrRS2
        );
}
        /* ================= NO RECORD ================= */

        if(jasperPrint.getPages().isEmpty()){

            response.reset();

            response.setContentType(
                "text/html"
            );

            out.println(
                "<h2 style='color:red;"
                + "text-align:center;"
                + "margin-top:50px;'>"
                + "No Records Found!"
                + "</h2>"
            );

            return;
        }

        /* ================= PDF ================= */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"GLClosingReport.pdf\""
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

        /* ================= EXCEL ================= */

        else if("xls".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/vnd.ms-excel"
            );

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"GLClosingReport.xls\""
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

            exporter.setParameter(
                JRXlsExporterParameter
                .IS_ONE_PAGE_PER_SHEET,
                Boolean.FALSE
            );

            exporter.setParameter(
                JRXlsExporterParameter
                .IS_DETECT_CELL_TYPE,
                Boolean.TRUE
            );

            exporter.setParameter(
                JRXlsExporterParameter
                .IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS,
                Boolean.TRUE
            );

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }catch(Exception e){

        response.reset();

        response.setContentType(
            "text/html"
        );

        out.println(
            "<h2 style='color:red;"
            + "text-align:center'>"
            + "Error Generating Report"
            + "</h2>"
        );

        out.println("<pre>");

        e.printStackTrace(
            new PrintWriter(out)
        );

        out.println("</pre>");

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

<title>GL Closing Balance Report</title>

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
        GL CLOSING BALANCE REPORT
    </h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/GLClosingReportFrom_ToDate.jsp"
          target="_blank"
          autocomplete="off"
          onsubmit="return validateForm();">

        <!-- ACTION -->

        <input type="hidden"
               name="action"
               value="download"
               id="actionType">

        <!-- ACCOUNT TYPE -->

        <input type="hidden"
               id="account_type"
               name="account_type">

        <div class="parameter-section">

            <!-- ================= BRANCH CODE ================= -->

            <div class="parameter-group">

                <div class="parameter-label">
                    Branch Code
                </div>

                <div class="input-box">

                    <input type="text"
                           id="branch_code"
                           name="branch_code"
                           class="input-field"
                           value="<%=sessionBranchCode%>"
                           <%= !"Y".equalsIgnoreCase(
                               isSupportUser.trim())
                               ? "readonly"
                               : "" %> >

                    <% if("Y".equalsIgnoreCase(
                        isSupportUser.trim())){ %>

                    <button type="button"
                            class="icon-btn"
                            onclick="openLookup('branch')">...</button>

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
                       value="<%=branchName%>"
                       readonly>

            </div>

            <!-- ================= GL ACCOUNT ================= -->

            <div class="parameter-group">

                <div class="parameter-label">
                    GL Account Code
                </div>

                <div class="input-box">

                    <input type="text"
                           id="product_code"
                           name="glaccount_code"
                           class="input-field"
                           placeholder="Select GL Account">

                    <!-- IMPORTANT -->

                    <button type="button"
                            class="icon-btn"
                            onclick="openLookup('glByAccountType')"> ...</button>

                </div>

            </div>

            <!-- ================= ACCOUNT NAME ================= -->

            <div class="parameter-group">

                <div class="parameter-label">
                    Account Name
                </div>

                <input type="text"
                       id="productName"
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
                       id="from_date"
                       class="input-field"
                       value="<%= displayDate %>"
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
                       id="to_date"
                       class="input-field"
                      placeholder="DD/MM/YYYY" 
                       required>

            </div>

        </div>

        <!-- ================= ACCOUNT SELECT ================= -->

        <div class="parameter-section"
             style="margin-top:20px;">

            <div class="parameter-group">

                <div class="parameter-label">
                    Account Select
                </div>

                <div class="radio-container">

                    <label>

                        <input type="radio"
                               name="account_select"
                               value="S"
                               checked
                               onclick="toggleAccount()">

                        Single

                    </label>

                    <label>

                        <input type="radio"
                               name="account_select"
                               value="L"
                               onclick="toggleAccount()">All</label>

                </div>

            </div>

            <!-- ================= REPORT SELECT ================= -->

            <div class="parameter-group">

                <div class="parameter-label">
                    Report Select
                </div>

                <div class="radio-container">

                    <label>

                        <input type="radio"
                               name="report_select"
                               value="A"
                               checked>

                       
                        All

                    </label>

                    <label>

                        <input type="radio"
                               name="report_select"
                               value="B">

                        BS

                    </label>

                    <label>

                        <input type="radio"
                               name="report_select"
                               value="P">

                        PL

                    </label>

                    <label>

                        <input type="radio"
                               name="report_select"
                               value="C">

                        Closing

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

        </div>

       <!-- ================= BUTTONS ================= -->

<div style="display:flex;
            gap:15px;
            margin-top:20px;">

    <!-- NORMAL REPORT -->

    <button type="submit"
            class="download-button"
            onclick="
            document.getElementById('actionType').value='download';
            ">

        Generate Report

    </button>

    <!-- CONSOLIDATED REPORT -->

    <button type="submit"
            class="download-button"
            onclick="
            document.getElementById('actionType').value='consolidated';
            ">

        Consolidated Report

    </button>

</div>

<!-- ================= LOOKUP MODAL ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>
</form>

</div>

</body>

</html>