<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

// fallback
if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
%>

<%
String action = request.getParameter("action");

String branchCode = request.getParameter("branch_code");
String toDateUI = request.getParameter("to_date");

if(branchCode==null) branchCode="";

if(toDateUI==null || toDateUI.trim().isEmpty()){
    toDateUI = sessionDate;
}

if("download".equals(action)){

    String reportType = request.getParameter("reporttype");
    String productCode = request.getParameter("product_code");
    String singleAll = request.getParameter("single_all");

    if(productCode==null) productCode="";
    productCode = productCode.trim();

    /* VALIDATION */

    if("S".equals(singleAll) && productCode.equals("")){
        session.setAttribute("errorMessage","Please enter Product Code");
        response.sendRedirect("TLCCintrestRecivable.jsp");
        return;
    }

    Connection conn=null;
    PreparedStatement ps=null;
    ResultSet rs=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* DATE FORMAT */

        SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH);

        String oracleDate =
        outFmt.format(inFmt.parse(toDateUI)).toUpperCase();

        /* SQL */

        String sql =
        "SELECT SRNO,ACCOUNT_NO,AC_NAME,DESCRIPTION,PRODUCT_CODE,BALANCE_AMT,(PAYBALE_AMT*(-1)) PAYBALE_AMT " +
        "FROM ( " +
        "SELECT ROW_NUMBER() OVER(PARTITION BY P.PRODUCT_CODE ORDER BY A.ACCOUNT_CODE) SRNO, " +
        "A.ACCOUNT_CODE ACCOUNT_NO, " +
        "A.NAME AC_NAME, " +
        "P.DESCRIPTION, " +
        "P.PRODUCT_CODE, " +
        "FN_GET_BALANCE_ASON(TO_DATE(?,'DD-MON-YYYY'),A.ACCOUNT_CODE) BALANCE_AMT, " +
        "FN_GET_RECPAY_REPORTS(TO_DATE(?,'DD-MON-YYYY'),A.ACCOUNT_CODE,'N') PAYBALE_AMT " +
        "FROM ACCOUNT.ACCOUNT A,ACCOUNT.ACCOUNTLOAN D,HEADOFFICE.PRODUCT P " +
        "WHERE A.ACCOUNT_CODE=D.ACCOUNT_CODE " +
        "AND SUBSTR(A.ACCOUNT_CODE,5,3)=P.PRODUCT_CODE " +
        "AND SUBSTR(A.ACCOUNT_CODE,1,4)=? ";

        if("S".equals(singleAll)){
            sql += " AND SUBSTR(A.ACCOUNT_CODE,5,3)=? ";
        }

        sql +=
        "AND (A.DATEACCOUNTOPEN IS NULL OR A.DATEACCOUNTOPEN<=TO_DATE(?,'DD-MON-YYYY')) " +
        "AND (A.DATEACCOUNTCLOSE IS NULL OR A.DATEACCOUNTCLOSE>TO_DATE(?,'DD-MON-YYYY')) " +
        ") WHERE (BALANCE_AMT<>0 OR PAYBALE_AMT<>0)";

        ps = conn.prepareStatement(sql);

        int i=1;

        ps.setString(i++,oracleDate);
        ps.setString(i++,oracleDate);
        ps.setString(i++,branchCode);

        if("S".equals(singleAll)){
            ps.setString(i++,productCode);
        }

        ps.setString(i++,oracleDate);
        ps.setString(i++,oracleDate);

        rs = ps.executeQuery();

        JRResultSetDataSource jrds =
        new JRResultSetDataSource(rs);

        /* LOAD REPORT */

        String jasperPath =
        application.getRealPath("/Reports/TLCCintrestRecivable.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("to_date",oracleDate);
        params.put("report_title","RECEIVABLE LOAN REPORT");
        params.put("IMAGE_PATH",application.getRealPath("/images/UPSB MONO.png"));
        
        /* ✅ USER ID (FIXED) */
        String userId = (String) session.getAttribute("userId");
        params.put("user_id", userId);


        JasperPrint jasperPrint =
        JasperFillManager.fillReport(jasperReport,params,jrds);

        ServletOutputStream sos = response.getOutputStream();

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");

            response.setHeader(
            "Content-Disposition",
            "inline; filename=\"ReceivableLoanReport.pdf\"");

            JasperExportManager.exportReportToPdfStream(
            jasperPrint,sos);

            sos.flush();
            return;

        }else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
            "Content-Disposition",
            "attachment; filename=\"ReceivableLoanReport.xls\"");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT,
            jasperPrint);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,
            sos);

            exporter.exportReport();

            sos.flush();
            return;
        }

    }catch(Exception e){

        e.printStackTrace();

        session.setAttribute(
        "errorMessage",
        "Error generating report : "+e.getMessage());

        response.sendRedirect("TLCCintrestRecivable.jsp");
        return;

    }finally{

        if(rs!=null){try{rs.close();}catch(Exception e){}}
        if(ps!=null){try{ps.close();}catch(Exception e){}}
        if(conn!=null){try{conn.close();}catch(Exception e){}}

    }
}
%>

<%
if(!"download".equals(action)){
%>

<!DOCTYPE html>
<html>
<head>

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>
<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<title>Receivable Loan Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<style>

.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
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
(String)session.getAttribute("errorMessage");

if(errorMessage!=null){
%>

<div class="error-message">
<%=errorMessage%>
</div>

<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">
RECEIVABLE LOAN REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/TLCCintrestRecivable.jsp"
target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<div class="parameter-group">

<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=branchCode%>"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
</div>

</div>

<div class="parameter-group">
<div class="parameter-label">Branch Description</div>

<input type="text"
id="branchName"
class="input-field"
readonly>
</div>


<!-- Product Code -->
<div class="parameter-group">

<div class="parameter-label">Product Code</div>

<div class="input-box">
<input type="text"
name="product_code"
id="product_code"
class="input-field"
placeholder="Enter Product Code">

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>

<div class="radio-container">

<label>
<input type="radio"
       name="single_all"
       value="S"
       onclick="toggleProduct()"
       checked>
Single
</label>

<label>
<input type="radio"
       name="single_all"
       value="A"
       onclick="toggleProduct()">
All
</label>

</div>

</div>

<div class="parameter-group">

<div class="parameter-label">To Date</div>

<input type="date"
name="to_date"
class="input-field"
value="<%=toDateUI%>"
required>

</div>

</div>


<div class="format-section">

<div class="parameter-label">Report Type</div>

<label>
<input type="radio"
name="reporttype"
value="pdf"
checked> PDF
</label>

<label>
<input type="radio"
name="reporttype"
value="xls"> Excel
</label>

</div>

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>

function toggleProduct(){

    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var productField =
        document.querySelector('input[name="product_code"]');

    if(single){

        productField.disabled = false;
        productField.readOnly = false;

    }else{

        productField.value="";
        productField.disabled = true;
        productField.readOnly = true;

    }
}

window.onload=function(){
    toggleProduct();
}

</script>

</body>
</html>

<%
}
%>