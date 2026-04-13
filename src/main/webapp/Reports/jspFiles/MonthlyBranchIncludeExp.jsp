<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.io.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
/* ================= SESSION ================= */

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

String sessionBranch = (String) session.getAttribute("branch_code");
String userId        = (String) session.getAttribute("user_id");

if (sessionBranch == null) sessionBranch = "";
if (userId == null) userId = "";


String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";

/* ================= ACTION ================= */

String action = request.getParameter("action");

if ("generate".equals(action)) {

    String fromDate  = request.getParameter("from_date");
    String toDate    = request.getParameter("to_date");
    String branchCode= request.getParameter("branch_code");

    String fromBr = request.getParameter("from_br");
    String toBr   = request.getParameter("to_br");

    String reportType = request.getParameter("reporttype"); // pdf/xls
    String mode       = request.getParameter("mode");       // D/S

    /* ===== VALIDATION ===== */

    if(fromDate == null || fromDate.equals("")){
        out.println("<h3 style='color:red'>From Date Required</h3>");
        return;
    }

    if(toDate == null || toDate.equals("")){
        out.println("<h3 style='color:red'>To Date Required</h3>");
        return;
    }

    java.util.Date fd = new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);
    java.util.Date td = new SimpleDateFormat("yyyy-MM-dd").parse(toDate);

    if(fd.after(td)){
        out.println("<h3 style='color:red'>From Date must be less than To Date</h3>");
        return;
    }

    /* ===== DATE FORMAT ===== */

    String fromOracle =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(fd).toUpperCase();

    String toOracle =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(td).toUpperCase();

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* ================= CALL PROCEDURE ================= */

        if("0000".equals(branchCode)){

            Statement st = conn.createStatement();
            ResultSet rs = st.executeQuery(
                "SELECT BRANCH_CODE FROM HEADOFFICE.BRANCH");

            while(rs.next()){

                CallableStatement cs =
                conn.prepareCall("{ call sp_monthly_exp_cbs(?,?,?,?,?) }");

                cs.setString(1, rs.getString(1));
                cs.setString(2, sessionDate);
                cs.setString(3, fromOracle);
                cs.setString(4, toOracle);
                cs.setString(5, userId);

                cs.execute();
                cs.close();
            }

            rs.close();
            st.close();

        }else{

            CallableStatement cs =
            conn.prepareCall("{ call sp_monthly_exp_cbs(?,?,?,?,?) }");

            cs.setString(1, branchCode);
            cs.setString(2, sessionDate);
            cs.setString(3, fromOracle);
            cs.setString(4, toOracle);
            cs.setString(5, userId);

            cs.execute();
            cs.close();
        }

        conn.commit();

        /* ================= REPORT FILE ================= */

        String jasperFile = "";

        if("S".equalsIgnoreCase(mode)){
            jasperFile = "MonthlyBranchExp.jasper";
        }else{
            jasperFile = "MonthlyBranchIncludeExp(Details).jasper";
        }

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */

        Map<String,Object> params = new HashMap<>();

params.put("branch_code", fromBr != null && !fromBr.isEmpty() ? fromBr : branchCode);
params.put("to_branch", toBr != null && !toBr.isEmpty() ? toBr : branchCode);

// VERY IMPORTANT (JRXML needs this)
params.put("as_on_date", toOracle);

// Optional (header)
params.put("report_title", "MONTHLY BRANCH EXPENSES REPORT");
params.put("user_id", userId);

params.put(JRParameter.REPORT_CONNECTION, conn);

        /* ================= QUERY (DETAIL) ================= */

        String condition;

        if("0000".equals(branchCode)){
            condition = " BETWEEN '" + fromBr + "' AND '" + toBr + "' ";
        }else{
            condition = " = '" + branchCode + "' ";
        }

        String sql =
        " SELECT ROWNUM SR_NO, DATE_EXP, ACCOUNT_CODE, BRANCH_CODE, AC_NAME," +
        " NVL(DR,0) DR, NVL(CR,0) CR, CLOSE_BAL, PARTICULAR," +
        " (NVL(DR,0)-NVL(CR,0)) TOTAL_EXPEN " +
        " FROM BANKDATA.MONTHLY_EXP_CBS " +
        " WHERE BRANCH_CODE " + condition;

        JasperPrint jp =
        		JasperFillManager.fillReport(jasperReport, params, conn);

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
                "inline; filename=\"MonthlyBranchExp.pdf\"");

            ServletOutputStream os = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, os);

            os.flush();
            os.close();
            return;
        }

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
                "attachment; filename=\"MonthlyBranchExp.xls\"");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
                JRXlsExporterParameter.JASPER_PRINT, jp);

            exporter.setParameter(
                JRXlsExporterParameter.OUTPUT_STREAM, os);

            exporter.exportReport();

            os.flush();
            os.close();
            return;
        }

    } catch(Exception e){
        e.printStackTrace();  // keep for debugging

        Throwable cause = e;

        while(cause.getCause() != null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg != null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute(
            "errorMessage",
            "Error Message = " + msg
        );

        response.sendRedirect(
            request.getContextPath() + "/Reports/jspFiles/MonthlyBranchIncludeExp.jsp"
        );
        return;
    }
    finally{

        if(conn != null){
            try{ conn.close(); }catch(Exception ignored){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Monthly Branch Expenses Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.radio-container{
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled{
    background-color:#e0e0e0;
    color:#666;
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
MONTHLY BRANCH EXPENSES REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/MonthlyBranchIncludeExp.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="generate"/>

<div class="parameter-section">

<!-- Branch Code -->
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
            onclick="openLookup('branch')">…</button>
<% } %>
</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Description</div>
    <input type="text"
           id="branchName"
           class="input-field"
           readonly>
</div>
<!-- ================= HO BRANCH RANGE ================= -->

<% if("0000".equals((String)session.getAttribute("branch_code"))) { %>

<div class="parameter-group">
<div class="parameter-label">From Branch</div>

<div class="input-box">
<input type="text" name="from_br" id="from_br" class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">…</button>
</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Branch</div>

<div class="input-box">
<input type="text" name="to_br" id="to_br" class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">…</button>
</div>
</div>

<% } %>

<!-- ================= DATES ================= -->

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
       value="<%=session.getAttribute("toDate")%>"
       required>
</div>

<!-- ================= REPORT TYPE + MODE (SIDE BY SIDE) ================= -->

<div style="display:flex; gap:120px; align-items:center; margin-top:30px;">

    <!-- REPORT TYPE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Type</div>

        <div class="format-options" style="display:flex; gap:30px;">

            <div class="format-option">
                <input type="radio" name="reporttype" value="pdf" checked>
                PDF
            </div>

            <div class="format-option">
                <input type="radio" name="reporttype" value="xls">
                Excel
            </div>

        </div>
    </div>

    <!-- REPORT MODE -->
    <div class="parameter-group">

        <div class="parameter-label">Report Mode</div>

        <div class="format-options" style="display:flex; gap:20px;">

            <div class="format-option">
                <input type="radio"
                       name="mode"
                       value="D"
                       <%= "D".equals(session.getAttribute("radioVal")) ? "checked" : "" %>>
                Detail
            </div>

            <div class="format-option">
                <input type="radio"
                       name="mode"
                       value="S"
                       <%= "S".equals(session.getAttribute("radioVal")) ? "checked" : "" %>>
                Summary
            </div>

        </div>
    </div>

</div>

</div>
<!-- ================= SUBMIT ================= -->

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- ================= POPUP ================= -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

<!-- ================= SCRIPT ================= -->

<script>

document.querySelector("form").onsubmit = function(){

    let fromDate = document.querySelector("[name='from_date']").value;
    let toDate   = document.querySelector("[name='to_date']").value;

    if(fromDate === ""){
        alert("From Date Required");
        return false;
    }

    if(toDate === ""){
        alert("To Date Required");
        return false;
    }

    if(fromDate > toDate){
        alert("From Date must be less than To Date");
        return false;
    }

    return true;
};

</script>

</body>
</html>