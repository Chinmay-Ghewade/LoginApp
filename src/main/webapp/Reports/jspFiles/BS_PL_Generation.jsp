<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.io.*,java.text.SimpleDateFormat" %>
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

String displayDate = "";

try {
    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd").parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy").format(d);

} catch(Exception e) {
    displayDate = "";
}

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>
<%
/* ================= SESSION ================= */

String userId         = (String) session.getAttribute("userId");

/* ================= ACTION ================= */
String action = request.getParameter("action");

if("download".equalsIgnoreCase(action)){

/* ================= PARAMETERS ================= */
String reporttype = request.getParameter("reporttype");   // pdf/xls
String reportSel  = request.getParameter("report_select"); // P/X
String branchCode = request.getParameter("branch_code");
String asOnDate   = request.getParameter("as_on_date");
String regularclosing = request.getParameter("regularclosing_0");
if(regularclosing == null) regularclosing = "R";

/* DEFAULTS (MATCH SERVLET STYLE) */
if(reportSel == null || reportSel.trim().equals("")) reportSel = "P";
if(reporttype == null || reporttype.trim().equals("")) reporttype = "pdf";



/* STORE IN SESSION (LIKE SERVLET) */
session.setAttribute("branchCode", branchCode);
session.setAttribute("as_on_date", asOnDate);
session.setAttribute("regularclosing", regularclosing);

/* ================= DATE FORMAT ================= */
String oracleDate = "";

if(asOnDate != null && !asOnDate.trim().equals("")){
try{
java.util.Date d =
new SimpleDateFormat("dd/MM/yyyy").parse(asOnDate);


    oracleDate =
    new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
    .format(d).toUpperCase();

}catch(Exception e){
    oracleDate = "";
}


}

/* ================= DB ================= */
Connection conn = null;

try{

response.reset();
response.setBufferSize(1024*1024);

conn = DBConnection.getConnection();

/* ================= REPORT SELECTION ================= */
String jasperFile;
String reportTitle;

if("X".equalsIgnoreCase(reportSel)){
jasperFile = "Profit_and_Loss.jasper";
reportTitle = "PROFIT & LOSS";
}else{
jasperFile = "BalanceSheet.jasper";
reportTitle = "BALANCE SHEET";
}

/* ================= LOAD REPORT ================= */
String reportPath =
application.getRealPath("/Reports/" + jasperFile);

JasperReport jr =
(JasperReport) JRLoader.loadObject(new File(reportPath));

/* ================= PARAMETERS ================= */
Map<String,Object> param = new HashMap<>();

param.put("branch_code", branchCode);
param.put("as_on_date", oracleDate);
param.put("report_title", reportTitle);
param.put("user_id", userId);

param.put("SUBREPORT_DIR",
application.getRealPath("/Reports/"));

param.put(JRParameter.REPORT_CONNECTION, conn);

/* ================= FINAL GENERATE LOGIC ================= */

Connection genConn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try{

    genConn = DBConnection.getConnection();
    genConn.setAutoCommit(false);

    /* 🔹 1. CLEAR OLD DATA */
    ps = genConn.prepareStatement(
        "DELETE FROM TEMP.TEMP_BS_STRUCTURE WHERE BRANCH_CODE=?");
    ps.setString(1, branchCode);
    ps.executeUpdate();
    ps.close();

    ps = genConn.prepareStatement(
        "DELETE FROM TEMP.TEMP_PL_STRUCTURE WHERE BRANCH_CODE=?");
    ps.setString(1, branchCode);
    ps.executeUpdate();
    ps.close();

    /* 🔹 2. MODE */
    String is_year_end = "N";
    if("C".equalsIgnoreCase(regularclosing)){
        is_year_end = "Y";
    }

    /* 🔹 3. FETCH GROUPS */
    ps = genConn.prepareStatement(
        "SELECT FINALACCOUNTGROUP_CODE, DESCRIPTION " +
        "FROM HEADOFFICE.FINALACCOUNTGROUP ORDER BY FINALACCOUNTGROUP_CODE");

    rs = ps.executeQuery();

    int srNo = 0;

    while(rs.next()){

        srNo++;

        String groupCode = rs.getString("FINALACCOUNTGROUP_CODE");
        String desc      = rs.getString("DESCRIPTION");

        double closingBalance = 0;

        /* 🔹 4. BASE BALANCE FROM FUNCTION */
        PreparedStatement psBal = genConn.prepareStatement(
            "SELECT FN_GET_BS_PL_GROUP_SUM(?, ?, ?, ?) FROM DUAL");

        psBal.setString(1, branchCode);
        psBal.setString(2, groupCode);
        psBal.setString(3, oracleDate);
        psBal.setString(4, is_year_end);

        ResultSet rsBal = psBal.executeQuery();

        if(rsBal.next()){
            closingBalance = rsBal.getDouble(1);
        }

        rsBal.close();
        psBal.close();

        /* 🔹 5. CLOSING ADJUSTMENT (FIX WITHOUT DB CHANGE) */
        if("C".equalsIgnoreCase(regularclosing)){

            PreparedStatement psTxn = genConn.prepareStatement(
                "SELECT NVL(SUM(CASE WHEN TRANSACTIONINDICATOR_CODE='TRCR' THEN amount ELSE 0 END),0) CR, " +
                "NVL(SUM(CASE WHEN TRANSACTIONINDICATOR_CODE='TRDR' THEN amount ELSE 0 END),0) DR " +
                "FROM transaction.dailytxn " +
                "WHERE BRANCH_CODE=? " +
                "AND GLACCOUNT_CODE IN ( " +
                "   SELECT GLACCOUNT_CODE FROM HEADOFFICE.GLACCOUNT " +
                "   WHERE FINALACCOUNTMASTERWHENPOSITIVE=? " +
                "      OR FINALACCOUNTMASTERWHENNEGATIVE=? ) " +
                "AND TXN_DATE=? " +
                "AND TRANIDENTIFICATION_ID=99 " +
                "AND TRANSACTIONSTATUS='A'"
            );

            psTxn.setString(1, branchCode);
            psTxn.setString(2, groupCode);
            psTxn.setString(3, groupCode);
            psTxn.setString(4, oracleDate);

            ResultSet rsTxn = psTxn.executeQuery();

            if(rsTxn.next()){
                double cr = rsTxn.getDouble("CR");
                double dr = rsTxn.getDouble("DR");

                closingBalance = closingBalance - cr + dr;
            }

            rsTxn.close();
            psTxn.close();
        }

        /* 🔹 6. INSERT BASED ON SIGN (IMPORTANT FIX) */

        if(closingBalance >= 0){

            /* ASSET / INCOME */
            PreparedStatement psInsert = genConn.prepareStatement(
                "INSERT INTO TEMP.TEMP_BS_STRUCTURE " +
                "(BRANCH_CODE, SR_NO, ASSET_DESC, ASSET_AMT) " +
                "VALUES (?,?,?,?)");

            psInsert.setString(1, branchCode);
            psInsert.setInt(2, srNo);
            psInsert.setString(3, desc);
            psInsert.setDouble(4, closingBalance);

            psInsert.executeUpdate();
            psInsert.close();

        }else{

            /* LIABILITY / EXPENSE */
            PreparedStatement psInsertPL = genConn.prepareStatement(
                "INSERT INTO TEMP.TEMP_PL_STRUCTURE " +
                "(BRANCH_CODE, SR_NO, INCOME_DESC, INCOME_OUTER_AMT) " +
                "VALUES (?,?,?,?)");

            psInsertPL.setString(1, branchCode);
            psInsertPL.setInt(2, srNo);
            psInsertPL.setString(3, desc);
            psInsertPL.setDouble(4, Math.abs(closingBalance));

            psInsertPL.executeUpdate();
            psInsertPL.close();
        }
    }

    rs.close();
    ps.close();

    genConn.commit();

}catch(Exception e){

    if(genConn != null){
        try{ genConn.rollback(); }catch(Exception ex){}
    }

    e.printStackTrace();

}finally{

    if(rs != null) try{ rs.close(); }catch(Exception e){}
    if(ps != null) try{ ps.close(); }catch(Exception e){}
    if(genConn != null) try{ genConn.close(); }catch(Exception e){}
}

/* ================= FILL ================= */
JasperPrint jp =
JasperFillManager.fillReport(jr, param, conn);

/* ================= NO DATA ================= */
if(jp.getPages() == null || jp.getPages().size() == 0){


response.reset();
response.setContentType("text/html");

out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>No Records Found!</h2>");
return;


}

/* ================= EXPORT ================= */
if("pdf".equalsIgnoreCase(reporttype)){


response.setContentType("application/pdf");

response.setHeader("Content-Disposition",
"inline; filename=\"" + jasperFile.replace(".jasper",".pdf") + "\"");

ServletOutputStream os = response.getOutputStream();

JasperExportManager.exportReportToPdfStream(jp, os);

os.flush();
os.close();
return;


}
else{


response.setContentType("application/vnd.ms-excel");

response.setHeader("Content-Disposition",
"attachment; filename=\"" + jasperFile.replace(".jasper",".xls") + "\"");

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

}catch(Exception e){

response.reset();
response.setContentType("text/html");

out.println("<h2 style='color:red'>Error Generating Report</h2>");
out.println("<pre>");
e.printStackTrace(new PrintWriter(out));
out.println("</pre>");

return;

}finally{

if(conn != null){
try{ conn.close(); }catch(Exception ex){}
}

}

}
%>


<!DOCTYPE html>

<html>
<head>

<title>Balance Sheet & P/L Generation</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=4">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

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

.error-box {
    color:red;
    font-weight:bold;
    margin-top:10px;
}
</style>

<script>

/* 🔹 SET REPORT TYPE */
function setReportType(val){
    document.getElementById("report_select").value = val;
}

/* 🔹 VALIDATION */
function validateForm(){

    let branch = document.getElementById("branch_code").value;
    let date   = document.getElementById("as_on_date").value;

    if(branch.trim() === ""){
        alert("Please Enter Branch Code");
        return false;
    }

    if(date.trim() === ""){
        alert("Please Enter As On Date");
        return false;
    }

    return true;
}

</script>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
BALANCE SHEET & P/L GENERATION
</h1>

<form method="post"
      action="BS_PL_Generation.jsp"
      target="_blank"
      autocomplete="off"
      onsubmit="return validateForm()">

<input type="hidden" name="action" value="download"/>
<input type="hidden" name="report_select" id="report_select" value="P"/>

<div class="parameter-section">

<!-- 🔹 Branch Code -->

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">

<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%= sessionBranchCode %>"
<%= !"Y".equalsIgnoreCase(isSupportUser) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %> <button type="button"
     class="icon-btn"
     onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<!-- 🔹 Branch Name -->

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- 🔹 Date -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="text"
    name="as_on_date"
    id="as_on_date"
    class="input-field"
    value="<%= displayDate %>"
    placeholder="DD/MM/YYYY"
    required>

</div>

<!-- 🔹 Type -->

<div class="parameter-group">
<div class="parameter-label">Type</div>

<label>
<input type="radio" name="regularclosing_0" value="R" checked> Regular
</label>

<label>
<input type="radio" name="regularclosing_0" value="C"> Closing</label>
</div>

</div>

<!-- 🔹 FORMAT -->

<div class="format-section">

<div class="parameter-label">Report Format</div>

<div class="format-options">

<div class="format-option">
<input type="radio"
       name="reporttype"
       value="pdf"
       onclick="setReportType('P')"
       checked> PDF
</div>

<div class="format-option">
<input type="radio"
       name="reporttype"
       value="xls"
       onclick="setReportType('X')"> Excel
</div>

</div>

</div>

<!-- 🔹 ERROR -->

<div class="error-box">
<%= (session.getAttribute("errorMessage") != null)
      ? session.getAttribute("errorMessage") : "" %>
</div>

<!-- 🔹 BUTTONS -->

<div style="margin-top:20px; display:flex; gap:10px;">

<button type="submit"
     class="download-button"
     onclick="document.getElementById('report_select').value='P'">
Balance Sheet </button>

<button type="submit"
     class="download-button"
     onclick="document.getElementById('report_select').value='X'">
P & L </button>

</div>

</form>

</div>

<!-- 🔹 LOOKUP MODAL -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>
