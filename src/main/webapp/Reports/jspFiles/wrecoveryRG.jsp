<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*" %>
<%@ page import="java.io.*" %>

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

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}
%>
<%
String action = request.getParameter("action");
if(action == null) action = "";
%>
<%
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";
%>

<%
/* ================= CALCULATE ================= */
if("calculate".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String fromProd   = request.getParameter("from_product");
    String toProd     = request.getParameter("to_product");

    /* 🔒 SECURITY */
    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */
    if(branchCode==null || branchCode.trim().isEmpty() ||
       fromDate==null || fromDate.trim().isEmpty() ||
       toDate==null || toDate.trim().isEmpty() ||
       fromProd==null || fromProd.trim().isEmpty() ||
       toProd==null || toProd.trim().isEmpty()){

        out.println("<script>alert('All fields are required');history.back();</script>");
        return;
    }

    Connection conn = null;
    Statement stmt = null;

    try{
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* ================= DELETE OLD DATA ================= */
        PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM BANKDATA.WRECOVERY WHERE BRANCH_CODE=?");

        ps.setString(1, branchCode);
        ps.executeUpdate();
        ps.close();

        /* ================= DATE FORMAT ================= */
        String fromDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
                .toUpperCase();

        String toDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate))
                .toUpperCase();

        String currentDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(new java.util.Date())
                .toUpperCase();

        /* ================= MAIN LOGIC (PLSQL BLOCK) ================= */
        String plsql =
        "DECLARE " +
        " from_date DATE := TO_DATE('" + fromDateOracle + "','DD-MON-YYYY'); " +
        " to_date DATE := TO_DATE('" + toDateOracle + "','DD-MON-YYYY'); " +
        " asondate DATE := TO_DATE('" + currentDateOracle + "','DD-MON-YYYY'); " +
        " b_cod VARCHAR2(4) := '" + branchCode + "'; " +
        " v_from_product CHAR(3) := '" + fromProd + "'; " +
        " v_to_product CHAR(3) := '" + toProd + "'; " +
        "BEGIN " +

        " INSERT INTO BANKDATA.WRECOVERY " +
        " SELECT " +
        "   FN_GET_BALANCE_ASON(to_date, A.ACCOUNT_CODE), " +
        "   A.ACCOUNT_CODE, " +
        "   A.NAME, " +
        "   'Y', " +
        "   FN_GET_OVERDUE_ASON(to_date, A.ACCOUNT_CODE), " +
        "   SUBSTR(A.ACCOUNT_CODE,1,4), " +
        "   0, " +
        "   SYSDATE, " +
        "   NULL, " +
        "   FN_GET_INT_CR_BY_ACCOUNT(A.ACCOUNT_CODE, from_date, to_date), " +
        "   0 " +
        " FROM ACCOUNT.ACCOUNT A " +
        " WHERE SUBSTR(A.ACCOUNT_CODE,1,4)=b_cod " +
        " AND SUBSTR(A.ACCOUNT_CODE,5,3) BETWEEN v_from_product AND v_to_product; " +

        " COMMIT; " +
        "END;";

        stmt = conn.createStatement();
        stmt.execute(plsql);

        conn.commit();

        out.println("<script>alert('Calculation Completed Successfully');</script>");
    }catch(Exception e){

        try{
            if(conn!=null) conn.rollback();
        }catch(Exception ex){}

        e.printStackTrace(); // log only

        session.setAttribute(
            "errorMessage",
            "Error generating report : " + e.getMessage()
        );

        response.sendRedirect("wrecoveryRG.jsp"); // same page

        return;
        
    }finally{

        if(stmt!=null) try{stmt.close();}catch(Exception ex){}
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }

    return;
}
%>

<%
if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String fromProd   = request.getParameter("from_product");
    String toProd     = request.getParameter("to_product");

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    Connection conn=null;
    Statement stmt=null;

    try{

        response.reset();
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* ================= DELETE OLD ================= */
        PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM BANKDATA.WRECOVERY WHERE BRANCH_CODE=?");

        ps.setString(1, branchCode);
        ps.executeUpdate();
        ps.close();

        /* ================= DATE FORMAT ================= */
        String fromDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
            .toUpperCase();

        String toDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate))
            .toUpperCase();

        String currentDateOracle = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
            .format(new java.util.Date())
            .toUpperCase();

        /* ================= CALCULATION ================= */
        String plsql =
        "DECLARE " +
        " from_date DATE := TO_DATE('" + fromDateOracle + "','DD-MON-YYYY'); " +
        " to_date DATE := TO_DATE('" + toDateOracle + "','DD-MON-YYYY'); " +
        " asondate DATE := TO_DATE('" + currentDateOracle + "','DD-MON-YYYY'); " +
        " b_cod VARCHAR2(4) := '" + branchCode + "'; " +
        " v_from_product CHAR(3) := '" + fromProd + "'; " +
        " v_to_product CHAR(3) := '" + toProd + "'; " +
        "BEGIN " +

        " INSERT INTO BANKDATA.WRECOVERY " +
        " SELECT " +
        " FN_GET_BALANCE_ASON(to_date, A.ACCOUNT_CODE), " +
        " A.ACCOUNT_CODE, A.NAME, 'Y', " +
        " FN_GET_OVERDUE_ASON(to_date, A.ACCOUNT_CODE), " +
        " SUBSTR(A.ACCOUNT_CODE,1,4), 0, SYSDATE, NULL, " +
        " FN_GET_INT_CR_BY_ACCOUNT(A.ACCOUNT_CODE, from_date, to_date), 0 " +
        " FROM ACCOUNT.ACCOUNT A " +
        " WHERE SUBSTR(A.ACCOUNT_CODE,1,4)=b_cod " +
        " AND SUBSTR(A.ACCOUNT_CODE,5,3) BETWEEN v_from_product AND v_to_product; " +

        " END;";

        stmt = conn.createStatement();
        stmt.execute(plsql);

        conn.commit();

        /* ================= REPORT ================= */
        String jasperPath =
        application.getRealPath("/Reports/wrecoveryRG.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("report_title","WEEKLY RECOVERY STATEMENT");

        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport,params,conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        String reportType = request.getParameter("reporttype");

        /* PDF */
        if("pdf".equalsIgnoreCase(reportType)){
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"WeeklyRecovery.pdf\"");

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream os = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jp,os);
            os.close();
        }
        /* EXCEL */
        else{
            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"WeeklyRecovery.xls\"");

            out.clear();
            out = pageContext.pushBody();

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT,jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM,os);
            exporter.exportReport();

            os.close();
        }
    }catch(Exception e){

        try{
            if(conn!=null) conn.rollback();
        }catch(Exception ex){}

        e.printStackTrace(); // log only

        session.setAttribute(
            "errorMessage",
            "Error generating report : " + e.getMessage()
        );

        response.sendRedirect("wrecoveryRG.jsp");

        return;
    
    }finally{
        if(stmt!=null) try{stmt.close();}catch(Exception ex){}
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }

    return;
}
%>

<!DOCTYPE html>
<html>

<head>

<title>Weekly Recovery Statement</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
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
WEEKLY RECOVERY STATEMENT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/wrecoveryRG.jsp"
target="_blank"
autocomplete="off">

<!-- ================= BRANCH ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

</div>

<!-- ================= PRODUCT ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Product Code</div>

<div class="input-box">
<input type="text"
name="from_product"
id="from_product"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>

</div>

<div class="parameter-group">
<div class="parameter-label">To Product Code</div>

<div class="input-box">
<input type="text"
name="to_product"
id="to_product"
class="input-field"
required>

<button type="button"
class="icon-btn"
onclick="openLookup('product')">…</button>
</div>

</div>

</div>

<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
name="from_date"
class="input-field"
value="<%=sessionDate%>"
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

<!-- ================= BUTTONS ================= -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
name="reporttype"
value="pdf"
checked> PDF
</div>

<div class="format-option">
<input type="radio"
name="reporttype"
value="xls"> Excel
</div>

</div>

</div>

<button type="submit" name="action" value="download"
class="download-button" >
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

</body>
</html>