<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="db.DBConnection" %>
<%@ page import="java.io.File" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

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

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String action = request.getParameter("action");

String sessionBranchCode = (String) session.getAttribute("branchCode");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(sessionBranchCode == null) sessionBranchCode="";
if(isSupportUser == null) isSupportUser="N";


/* ================= GENERATE ================= */

if("generate".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String accountType = request.getParameter("account_type");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    String fromProduct = request.getParameter("from_product");
    String toProduct = request.getParameter("to_product");
    String nominee = request.getParameter("nominee");
    String reportAction = request.getParameter("report_action");
    String reportType = request.getParameter("reporttype");

    /* SECURITY */

    if(branchCode == null || branchCode.equals("")){
        branchCode = sessionBranchCode;
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */

    if(fromDate == null || fromDate.equals("")){
        session.setAttribute("errorMessage","Enter From Date !!!");
        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;
    }

    if(toDate == null || toDate.equals("")){
        session.setAttribute("errorMessage","Enter To Date !!!");
        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;
    }

    if(fromProduct == null || fromProduct.equals("")){
        session.setAttribute("errorMessage","Enter From Product Code !!!");
        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;
    }

    if(toProduct == null || toProduct.equals("")){
        session.setAttribute("errorMessage","Enter To Product Code !!!");
        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;
    }

    if(Integer.parseInt(toProduct) < Integer.parseInt(fromProduct)){
        session.setAttribute("errorMessage","To Product must be >= From Product");
        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;
    }

    Connection conn=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* DATE FORMAT */

        String fromDateDB =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
        .toUpperCase();

        String toDateDB =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate))
        .toUpperCase();

        /* ================= SQL ================= */

        String condition = "";

        if(accountType != null && !accountType.equals("")){
            condition += " AND B.ACCOUNT_TYPE='"+accountType+"' ";
        }

       
        String dateField =
        "OPEN".equalsIgnoreCase(reportAction) ?
        "A.DATEACCOUNTOPEN" :
        "A.DATEACCOUNTCLOSE";

        String sql =
        		"SELECT A.ACCOUNT_CODE, INITCAP(A.NAME) NAME, " +
        		"TO_CHAR(A.DATEACCOUNTOPEN,'DD-MON-YY') OPEN_D, " +
        		"TO_CHAR(A.DATEACCOUNTCLOSE,'DD-MON-YY') CLOSE_D, " +
        		"C.LEDGERBALANCE BAL, B.DESCRIPTION, " +
        		"SUBSTR(A.ACCOUNT_CODE,5,3) AS PRODUCT, " +
        		"'1' AS P, " +
        		"NVL(INITCAP(AN.NAME),'') AS NOMINEE_NAME " +   // ✅ ALWAYS PRESENT
        		"FROM ACCOUNT.ACCOUNT A " +
        		"LEFT JOIN ACCOUNT.ACCOUNTNOMINEE AN ON A.ACCOUNT_CODE = AN.ACCOUNT_CODE " +
        		", HEADOFFICE.PRODUCT B, BALANCE.ACCOUNT C " +
        		"WHERE SUBSTR(A.ACCOUNT_CODE,5,3)=B.PRODUCT_CODE " +
        		"AND A.ACCOUNT_CODE=C.ACCOUNT_CODE " +
        "AND SUBSTR(A.ACCOUNT_CODE,1,4)='"+branchCode+"' " +
        "AND "+dateField+" BETWEEN '"+fromDateDB+"' AND '"+toDateDB+"' " +
        "AND B.PRODUCT_CODE BETWEEN '"+fromProduct+"' AND '"+toProduct+"' " +
        condition +
        " ORDER BY A.ACCOUNT_CODE";

        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(sql);

        if(!rs.isBeforeFirst()){
            session.setAttribute("errorMessage","No Records Found!");
            response.sendRedirect("AccountOpenClose2dateRG.jsp");
            return;
        }

        /* ================= JASPER ================= */

        String jasperFile;

        if("OPEN".equalsIgnoreCase(reportAction)){
            jasperFile="AccountOpenSBCA.jasper";
        }else{
            jasperFile="AccountCloseSBCA.jasper";
        }

        String jasperPath =
        application.getRealPath("/Reports/"+jasperFile);

        JasperReport jr =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("from_date",fromDateDB);
        params.put("to_date",toDateDB);
        params.put("branch_code",branchCode);
        params.put("report_title","ACCOUNT OPEN CLOSE BETWEEN DATES");

        String asOnDate = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
                .toUpperCase();

        params.put("as_on_date", asOnDate);   // ✅ FIX

        params.put("SUBREPORT_DIR",
                application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION,conn);

        JRResultSetDataSource jrds =
        new JRResultSetDataSource(rs);

        JasperPrint jp =
        JasperFillManager.fillReport(jr,params,jrds);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");

            response.setHeader("Content-Disposition",
                "inline; filename=\"AccountOpenClose.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(
                jp,outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType("application/vnd.ms-excel");

            response.setHeader("Content-Disposition",
                "attachment; filename=\"AccountOpenClose.xls\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT,
                jp);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM,
                outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }

    }catch(Exception e){

        e.printStackTrace();

        Throwable cause=e;

        while(cause.getCause()!=null){
            cause=cause.getCause();
        }

        String msg=cause.getMessage();

        if(msg!=null && msg.contains("ORA-")){
            msg=msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute("errorMessage","Error Message = "+msg);

        response.sendRedirect("AccountOpenClose2dateRG.jsp");
        return;

    }finally{

        if(conn!=null){
            try{conn.close();}catch(Exception ex){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Account Open Close Between Dates</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.input-box { display:flex; gap:10px; }

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
    gap:40px;
    margin-top:10px;
}

.modal{
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%; height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#fff;
    width:80%;
    padding:20px;
    border-radius:10px;
}

</style>

</head>

<body>

<div class="report-container">

<!-- ================= ERROR ================= -->

<%
String errorMessage = (String)session.getAttribute("errorMessage");
if(errorMessage != null){
%>
<div class="error-message">
    <%= errorMessage %>
</div>
<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">
ACCOUNT OPEN AND CLOSE BETWEEN DATES
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/AccountOpenClose2dateRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="generate"/>
<input type="hidden" name="report_action" id="report_action"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->

<div style="display:flex; gap:40px;">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
       required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">...</button>
<% } %>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>
<input type="text" id="branchName" class="input-field" readonly>
</div>

</div>

<!-- ================= ACCOUNT TYPE ================= -->

<div class="parameter-group">
<div class="parameter-label">Account Type</div>

<div class="input-box">
<input type="text"
       name="account_type"
       id="account_type"
       class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('accountType')">...</button>
</div>
</div>

<!-- ================= PRODUCT RANGE ================= -->

<div style="display:flex; gap:40px;">

<div class="parameter-group">
<div class="parameter-label">From Product</div>

<div class="input-box">
<input type="text"
       name="from_product"
       class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">...</button>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Product</div>

<div class="input-box">
<input type="text"
       name="to_product"
       class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">...</button>
</div>
</div>

</div>

<!-- ================= DATE ================= -->

<div style="display:flex; gap:40px;">

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
       name="from_date"
       class="input-field"
       value="<%= sessionDate %>"
       required>
</div>

<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
       name="to_date"
       class="input-field"
       required>
</div>

</div>

<!-- ================= NOMINEE ================= -->

<div class="parameter-group">
<div class="parameter-label">Nominee</div>

<div class="radio-container">

<label>
<input type="radio" name="nominee" value="Y" checked>
Yes
</label>

<label>
<input type="radio" name="nominee" value="N">
No
</label>

</div>
</div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div style="display:flex; gap:120px; margin-top:30px;">

<div class="parameter-group">

<div class="parameter-label">Report Type</div>

<div style="display:flex; gap:30px;">

<label>
<input type="radio" name="reporttype" value="pdf" checked> PDF
</label>

<label>
<input type="radio" name="reporttype" value="xls"> Excel
</label>

</div>

</div>

</div>

<!-- ================= BUTTONS ================= -->

<div style="margin-top:30px; display:flex; gap:20px;">

<button type="submit"
        class="download-button"
        onclick="setAction('OPEN')">
A/C Open In Date
</button>

<button type="submit"
        class="download-button"
        onclick="setAction('CLOSE')">
A/C Close In Date
</button>

</div>

</form>

</div>

<!-- ================= POPUP ================= -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">X</button>
<div id="lookupTable"></div>
</div>
</div>

<!-- ================= SCRIPT ================= -->

<script>

function setAction(val){
    document.getElementById("report_action").value = val;
}

document.querySelector("form").onsubmit = function(){

    let fromDate = document.querySelector("[name='from_date']").value;
    let toDate   = document.querySelector("[name='to_date']").value;
    let fromProd = document.querySelector("[name='from_product']").value;
    let toProd   = document.querySelector("[name='to_product']").value;

    if(fromDate === ""){
        alert("Enter From Date");
        return false;
    }

    if(toDate === ""){
        alert("Enter To Date");
        return false;
    }

    if(fromProd === ""){
        alert("Enter From Product Code");
        return false;
    }

    if(toProd === ""){
        alert("Enter To Product Code");
        return false;
    }

    if(parseInt(toProd) < parseInt(fromProd)){
        alert("To Product must be greater than or equal to From Product");
        return false;
    }

    return true;
};

</script>

</body>
</html>