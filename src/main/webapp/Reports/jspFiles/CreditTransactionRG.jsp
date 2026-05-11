<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.design.JRDesignQuery" %>
<%@ page import="net.sf.jasperreports.engine.design.JasperDesign" %>
<%@ page import="net.sf.jasperreports.engine.xml.JRXmlLoader" %>
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

String sessionBankCode =
    (String)session.getAttribute("bankCode");

String sessionBankName =
    (String)session.getAttribute("bankName");

String userId =
    (String)session.getAttribute("userId");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(sessionBranchName == null)
    sessionBranchName = "";

if(sessionBankCode == null)
    sessionBankCode = "";

if(sessionBankName == null)
    sessionBankName = "";

if(userId == null)
    userId = "admin";
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
        request.getParameter("product_code");

    String fromDate =
        request.getParameter("from_date");

    String toDate =
        request.getParameter("to_date");

    String limitFrom =
        request.getParameter("limit_from");

    String limitTo =
        request.getParameter("limit_to");

    String transactionType =
        request.getParameter("transaction_type");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode =
            sessionBranchCode;
    }

    System.out.println(
        "transactionType = "
        + transactionType
    );

    System.out.println(
        "fromDate = "
        + fromDate
    );

    System.out.println(
        "toDate = "
        + toDate
    );

    System.out.println(
        "limitFrom = "
        + limitFrom
    );

    System.out.println(
        "limitTo = "
        + limitTo
    );

    /* =====================================================
       SECURITY
    ===================================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode =
            sessionBranchCode;
    }

    if(productCode == null)
        productCode = "";

    if(limitFrom == null)
        limitFrom = "0";

    if(limitTo == null)
        limitTo = "0";

    productCode = productCode.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(productCode.equals("")){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Please Enter Product Code"
            + "</h3>"
        );

        return;
    }

    if(fromDate == null ||
       fromDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Please Select From Date"
            + "</h3>"
        );

        return;
    }

    if(toDate == null ||
       toDate.trim().equals("")){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Please Select To Date"
            + "</h3>"
        );

        return;
    }

    if(limitFrom.trim().equals("")){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Please Enter Limit From"
            + "</h3>"
        );

        return;
    }

    if(limitTo.trim().equals("")){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Please Enter Limit To"
            + "</h3>"
        );

        return;
    }

    double limitFromAmt = 0;
    double limitToAmt   = 0;

    try{

        limitFromAmt =
            Double.parseDouble(limitFrom);

        limitToAmt =
            Double.parseDouble(limitTo);

    }catch(Exception e){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Limit Amount Must Be Numeric"
            + "</h3>"
        );

        return;
    }

    try{

        java.util.Date fDate =
            new SimpleDateFormat(
                "dd/MM/yyyy"
            ).parse(fromDate);

        java.util.Date tDate =
            new SimpleDateFormat(
                "dd/MM/yyyy"
            ).parse(toDate);

        if(fDate.after(tDate)){

            out.println(
                "<h3 style='color:red;"
                + "text-align:center'>"
                + "From Date Must Be Less "
                + "Than To Date"
                + "</h3>"
            );

            return;
        }

    }catch(Exception e){

        out.println(
            "<h3 style='color:red;"
            + "text-align:center'>"
            + "Invalid Date Format"
            + "</h3>"
        );

        return;
    }

    Connection conn = null;

    PreparedStatement ps = null;

    ResultSet rs = null;

    try{

        response.reset();

        response.setBufferSize(
            1024 * 1024
        );

        conn =
            DBConnection.getConnection();

        /* =====================================================
           LOAD REPORT
        ===================================================== */

        String reportFile = "";

        if("CASH".equalsIgnoreCase(transactionType)){

            reportFile =
                "/Reports/CreditTransactionRG_cash.jasper";

        }else if(
            "TRANSFER".equalsIgnoreCase(transactionType)
        ){

            reportFile =
                "/Reports/CreditTransactionRG_transfer.jasper";

        }else{

            reportFile =
                "/Reports/CreditTransactionRG_CashTransfer.jasper";
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

        /* =====================================================
           PARAMETERS
        ===================================================== */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code",branchCode);
        parameters.put("product_code",productCode);
        parameters.put("from_date",fromDate);
        parameters.put("to_date",toDate);

        if("CASH".equalsIgnoreCase(transactionType)){

            parameters.put("from_amt",limitFrom);
            parameters.put("to_amt",limitTo);

        }else{

            parameters.put(
                "from_amt",
                new java.math.BigDecimal(
                    limitFromAmt
                )
            );

            parameters.put(
                "to_amt",
                new java.math.BigDecimal(
                    limitToAmt
                )
            );
        }

        parameters.put("as_on_date",displayDate);

        parameters.put(
            "report_title",
            "CREDIT TRANSACTION REPORT"
        );

        parameters.put("user_id",userId);
        parameters.put("bank_name",sessionBankName);
        parameters.put("branch_name",sessionBranchName);

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

        /* =====================================================
           SQL
        ===================================================== */

        String sql = "";

        if("CASH".equalsIgnoreCase(transactionType)){

            sql =
            "SELECT ROWNUM AS SR_NO, " +
            "PRODUCT, DESCRIPTION, " +
            "ACCOUNT_CODE, NAME, " +
            "TOTALCREDIT, PAN_NO, ADDRESS " +
            "FROM ( " +

            " SELECT " +
            " SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " AS PRODUCT, " +
            " P.DESCRIPTION AS DESCRIPTION, " +
            " D.ACCOUNT_CODE AS ACCOUNT_CODE, " +
            " A.NAME AS NAME, " +
            " SUM(D.AMOUNT) AS TOTALCREDIT, " +
            " fn_get_pancard_no(" +
            " D.ACCOUNT_CODE) PAN_NO, " +
            " fn_get_account_address(" +
            " D.ACCOUNT_CODE) ADDRESS " +
            " FROM TRANSACTION.DAILYTXN D, " +
            " ACCOUNT.ACCOUNT A, " +
            " HEADOFFICE.PRODUCT P " +
            " WHERE D.TXN_DATE BETWEEN " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " = P.PRODUCT_CODE " +
            " AND D.ACCOUNT_CODE = A.ACCOUNT_CODE " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3)=? " +
            " AND TRANSACTIONINDICATOR_CODE " +
            " = 'CSCR' " +
            " AND D.BRANCH_CODE = ? " +
            " GROUP BY " +
            " D.ACCOUNT_CODE, " +
            " A.NAME, " +
            " P.DESCRIPTION, " +
            " P.PRODUCT_CODE " +
            " ORDER BY D.ACCOUNT_CODE " +
            " ) " +
            " WHERE TOTALCREDIT BETWEEN ? AND ? " +
            " ORDER BY SR_NO, PRODUCT, " +
            " ACCOUNT_CODE ";

        }else if(
            "TRANSFER".equalsIgnoreCase(
                transactionType
            )
        ){

            sql =
            "SELECT ROWNUM AS SR_NO, " +
            "PRODUCT, DESCRIPTION, " +
            "ACCOUNT_CODE, NAME, " +
            "TOTALCREDIT, PAN_NO, ADDRESS " +
            "FROM ( " +
            " SELECT " +
            " SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " AS PRODUCT, " +
            " P.DESCRIPTION AS DESCRIPTION, " +
            " D.ACCOUNT_CODE AS ACCOUNT_CODE, " +
            " A.NAME AS NAME, " +
            " SUM(D.AMOUNT) AS TOTALCREDIT, " +
            " fn_get_pancard_no(" +
            " D.ACCOUNT_CODE) PAN_NO, " +
            " fn_get_account_address(" +
            " D.ACCOUNT_CODE) ADDRESS " +
            " FROM TRANSACTION.DAILYTXN D, " +
            " ACCOUNT.ACCOUNT A, " +
            " HEADOFFICE.PRODUCT P " +
            " WHERE D.TXN_DATE BETWEEN " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " = P.PRODUCT_CODE " +
            " AND D.ACCOUNT_CODE = A.ACCOUNT_CODE " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3)=? " +
            " AND TRANSACTIONINDICATOR_CODE " +
            " = 'TRCR' " +
            " AND D.BRANCH_CODE = ? " +
            " GROUP BY " +
            " D.ACCOUNT_CODE, " +
            " A.NAME, " +
            " P.DESCRIPTION, " +
            " P.PRODUCT_CODE " +
            " ORDER BY D.ACCOUNT_CODE " +
            " ) " +
            " WHERE TOTALCREDIT BETWEEN ? AND ? " +
            " ORDER BY SR_NO, PRODUCT, " +
            " ACCOUNT_CODE ";

        }else{

            sql =
            "SELECT ROWNUM AS SR_NO, " +
            "PRODUCT, DESCRIPTION, " +
            "ACCOUNT_CODE, NAME, " +
            "TOTALCREDIT, PAN_NO, ADDRESS " +
            "FROM ( " +
            " SELECT " +
            " SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " AS PRODUCT, " +
            " P.DESCRIPTION AS DESCRIPTION, " +
            " D.ACCOUNT_CODE AS ACCOUNT_CODE, " +
            " A.NAME AS NAME, " +
            " SUM(D.AMOUNT) AS TOTALCREDIT, " +
            " fn_get_pancard_no(" +
            " D.ACCOUNT_CODE) PAN_NO, " +
            " fn_get_account_address(" +
            " D.ACCOUNT_CODE) ADDRESS " +
            " FROM TRANSACTION.DAILYTXN D, " +
            " ACCOUNT.ACCOUNT A, " +
            " HEADOFFICE.PRODUCT P " +
            " WHERE D.TXN_DATE BETWEEN " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND " +
            " TO_DATE(?,'DD/MM/YYYY') " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3) " +
            " = P.PRODUCT_CODE " +
            " AND D.ACCOUNT_CODE = A.ACCOUNT_CODE " +
            " AND SUBSTR(D.ACCOUNT_CODE,5,3)=? " +
            " AND ( " +
            " TRANSACTIONINDICATOR_CODE " +
            " = 'CSCR' " +
            " OR " +
            " TRANSACTIONINDICATOR_CODE " +
            " = 'TRCR' " +
            " ) " +
            " AND D.BRANCH_CODE = ? " +
            " GROUP BY " +
            " D.ACCOUNT_CODE, " +
            " A.NAME, " +
            " P.DESCRIPTION, " +
            " P.PRODUCT_CODE " +
            " ORDER BY D.ACCOUNT_CODE " +
            " ) " +
            " WHERE TOTALCREDIT BETWEEN ? AND ? " +
            " ORDER BY SR_NO, PRODUCT, " +
            " ACCOUNT_CODE ";
        }

        /* =====================================================
           PREPARED STATEMENT
        ===================================================== */

        ps =
            conn.prepareStatement(sql);

        ps.setString(1, fromDate);
        ps.setString(2, toDate);
        ps.setString(3, productCode);
        ps.setString(4, branchCode);

        if("CASH".equalsIgnoreCase(transactionType)){

            ps.setString(5, limitFrom);
            ps.setString(6, limitTo);

        }else{

            ps.setBigDecimal(
                5,
                new java.math.BigDecimal(
                    limitFrom
                )
            );

            ps.setBigDecimal(
                6,
                new java.math.BigDecimal(
                    limitTo
                )
            );
        }

        rs = ps.executeQuery();

        /* =====================================================
           NO RECORDS
        ===================================================== */

        if(!rs.isBeforeFirst()){

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

        /* =====================================================
           DATASOURCE
        ===================================================== */

        JRResultSetDataSource jrds =
            new JRResultSetDataSource(rs);

        /* =====================================================
           FILL REPORT
        ===================================================== */

        JasperPrint jasperPrint =

            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                jrds
            );

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

        /* =====================================================
           EXPORT PDF
        ===================================================== */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType(
                "application/pdf"
            );

            response.setHeader(
                "Content-Disposition",

                "inline; filename="
                + "\"CreditTransaction.pdf\""
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

                "attachment; filename="
                + "\"CreditTransaction.xls\""
            );

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter
                .JASPER_PRINT,

                jasperPrint
            );

            exporter.setParameter(
                JRXlsExporterParameter
                .OUTPUT_STREAM,

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

        e.printStackTrace(
            new PrintWriter(out)
        );

    }finally{

        if(rs != null){

            try{
                rs.close();
            }catch(Exception ex){}
        }

        if(ps != null){

            try{
                ps.close();
            }catch(Exception ex){}
        }

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

<title>Credit Transaction Report</title>

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

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

.radio-container{
    display:flex;
    gap:25px;
    margin-top:10px;
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
    background:#ffffff;
    width:80%;
    max-height:85%;
    overflow:auto;
    border-radius:8px;
    padding:20px;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
CREDIT TRANSACTION REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/CreditTransactionRG.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm()">

<input type="hidden"
       name="action"
       value="download">

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

<!-- PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
Product Code
</div>

<div class="input-box">

<input type="text"
       name="product_code"
       id="product_code"
       class="input-field"
       required>

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">

...

</button>

</div>

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
       id="to_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>

</div>

<!-- LIMIT FROM -->

<div class="parameter-group">

<div class="parameter-label">
Limit From
</div>

<input type="text"
       name="limit_from"
       id="limit_from"
       class="input-field"
       onblur="validateNumeric(this)"
       required>

</div>

<!-- LIMIT TO -->

<div class="parameter-group">

<div class="parameter-label">
Limit To
</div>

<input type="text"
       name="limit_to"
       id="limit_to"
       class="input-field"
       onblur="validateNumeric(this)"
       required>

</div>

<!-- TRANSACTION TYPE -->

<div class="parameter-group">

<div class="parameter-label">
Transaction Type
</div>

<div class="radio-container">

<label>
<input type="radio"
       name="transaction_type"
       value="CASH"
       checked>
Cash
</label>

<label>
<input type="radio"
       name="transaction_type"
       value="TRANSFER">
Transfer
</label>

<label>
<input type="radio"
       name="transaction_type"
       value="BOTH">
Cash / Transfer
</label>

</div>

</div>

</div>

<!-- REPORT FORMAT -->

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

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

function validateNumeric(field){

    if(isNaN(field.value)){

        alert(
            "Amount Should Be Numeric"
        );

        field.value = "";

        field.focus();
    }
}

function validateForm(){

    var fromDate =
        document.getElementById(
            "from_date"
        ).value;

    var toDate =
        document.getElementById(
            "to_date"
        ).value;

    var f =
        convertDate(fromDate);

    var t =
        convertDate(toDate);

    if(f > t){

        alert(
            "From Date Must Be "
            + "Less Than To Date"
        );

        return false;
    }

    return true;
}

function convertDate(dateString){

    var parts =
        dateString.split("/");

    return new Date(
        parts[2],
        parts[1]-1,
        parts[0]
    );
}

</script>

</body>
</html>