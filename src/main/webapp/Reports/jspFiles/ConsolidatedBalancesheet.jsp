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
String action = request.getParameter("action");
if(action == null) action = "";

/* ================= SESSION ================= */

String branchCode = request.getParameter("branch_code");
String asOnDate   = request.getParameter("as_on_date");
String regularclosing = request.getParameter("regularclosing");

if(branchCode == null) branchCode = (String)session.getAttribute("branchCode");
if(asOnDate == null) asOnDate = "";

if(regularclosing == null || regularclosing.trim().equals("")){
    regularclosing = (String)session.getAttribute("regularclosing");
    if(regularclosing == null) regularclosing = "R";
}

session.setAttribute("as_on_date", asOnDate);
session.setAttribute("regularclosing", regularclosing);

/* ================= CANCEL ================= */

if("cancel".equalsIgnoreCase(action)){
    session.removeAttribute("as_on_date");
    session.removeAttribute("regularclosing");
    session.removeAttribute("errorMessage");

    response.sendRedirect("ConsolidatedBalancesheet.jsp");
    return;
}

/* ================= DIRECT GENERATE + DOWNLOAD ================= */

if("download".equalsIgnoreCase(action)){

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try{

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* 🔹 DATE FORMAT */
        String oracleDate="";
        if(asOnDate != null && !asOnDate.trim().equals("")){
            java.util.Date d =
            new SimpleDateFormat("dd/MM/yyyy").parse(asOnDate);

            oracleDate =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d).toUpperCase();
        }

        /* 🔹 MODE */
        String is_year_end = "N";
        String condition = "";

        if("C".equalsIgnoreCase(regularclosing)){
            is_year_end = "Y";
            condition = " AND IS_BR_PL='N' ";
        }

        /* ================= GENERATE ================= */

        ps = conn.prepareStatement("DELETE FROM TEMP.CONSOLIDATED_BS");
        ps.executeUpdate();
        ps.close();

        ps = conn.prepareStatement(
        		"INSERT INTO TEMP.CONSOLIDATED_BS " +
        		"(SR_NO,LIAB_DESC,LIAB_BOLD_NORMAL,LIAB_INNER_AMT,LIAB_OUTER_AMT," +
        		"ASSET_DESC,ASSET_BOLD_NORMAL,ASSET_INNER_AMT,ASSET_OUTER_AMT) " +
        		"SELECT LEVEL, ' ', ' ',0,0,' ',' ',0,0 FROM DUAL CONNECT BY LEVEL <= 600");

        		ps.executeUpdate();
        		ps.close();

        int srNo = 0;
        
        Map<String, Double> balanceMap = new HashMap<>();

        PreparedStatement psAll = conn.prepareStatement(
        "SELECT GLACCOUNT_CODE, NVL(SUM(OPENINGBALANCE + CREDITCASH + CREDITTRANSFER + CREDITCLEARING - " +
        "(DEBITCASH + DEBITTRANSFER + DEBITCLEARING)),0) " +
        "FROM BALANCE.BRANCHGLHISTORY WHERE TXN_DATE=? GROUP BY GLACCOUNT_CODE");

        psAll.setString(1, oracleDate);

        ResultSet rsAll = psAll.executeQuery();

        while(rsAll.next()){
            balanceMap.put(rsAll.getString(1), rsAll.getDouble(2));
        }

        rsAll.close();
        psAll.close();

        ps = conn.prepareStatement(
        "SELECT FINALACCOUNTGROUP_CODE,DESCRIPTION " +
        "FROM HEADOFFICE.FINALACCOUNTGROUP " +
        "WHERE FINALACCOUNTGROUP_CODE LIKE 'A%' " +
        "ORDER BY FINALACCOUNTGROUP_CODE");

        rs = ps.executeQuery();

        while(rs.next()){

            String groupCode = rs.getString(1);
            String desc = rs.getString(2);

            PreparedStatement psSum = conn.prepareStatement(
            "SELECT FN_GET_BS_PL_GROUP_SUM('0000',?,?,?) FROM DUAL");

            psSum.setString(1,groupCode);
            psSum.setString(2,oracleDate);
            psSum.setString(3,is_year_end);

            ResultSet rsSum = psSum.executeQuery();

            double groupTotal = 0;
            if(rsSum.next()){
                groupTotal = rsSum.getDouble(1);
            }

            rsSum.close();
            psSum.close();

            if(groupTotal > 0){

                srNo++;

                PreparedStatement psUpd = conn.prepareStatement(
                "UPDATE TEMP.CONSOLIDATED_BS SET ASSET_DESC=?, ASSET_BOLD_NORMAL='B' WHERE SR_NO=?");

                psUpd.setString(1,desc);
                psUpd.setInt(2,srNo);
                psUpd.executeUpdate();
                psUpd.close();

                double innerTotal = 0;

                PreparedStatement psGL = conn.prepareStatement(
                "SELECT GLACCOUNT_CODE,DESCRIPTION " +
                "FROM HEADOFFICE.GLACCOUNT " +
                "WHERE FINALACCOUNTMASTERWHENPOSITIVE=? " + condition);

                psGL.setString(1,groupCode);

                ResultSet rsGL = psGL.executeQuery();

                while(rsGL.next()){

                    String gl = rsGL.getString(1);
                    String gldesc = rsGL.getString(2);

                    double bal = balanceMap.getOrDefault(gl, 0.0);

                    if(bal < 0){

                        srNo++;

                        PreparedStatement psUpd2 = conn.prepareStatement(
                        "UPDATE TEMP.CONSOLIDATED_BS SET ASSET_DESC=?, ASSET_INNER_AMT=? WHERE SR_NO=?");

                        psUpd2.setString(1,gldesc);
                        psUpd2.setDouble(2,Math.abs(bal));
                        psUpd2.setInt(3,srNo);

                        psUpd2.executeUpdate();
                        psUpd2.close();

                        innerTotal += bal;
                    }
                }

                rsGL.close();
                psGL.close();

                PreparedStatement psTotal = conn.prepareStatement(
                "UPDATE TEMP.CONSOLIDATED_BS SET ASSET_OUTER_AMT=? WHERE SR_NO=?");

                psTotal.setDouble(1,Math.abs(innerTotal));
                psTotal.setInt(2,srNo - 1);

                psTotal.executeUpdate();
                psTotal.close();
            }
        }

        rs.close();
        ps.close();

        conn.commit();

        /* ================= REPORT ================= */

        String reporttype = request.getParameter("reporttype");
        String reportSel  = request.getParameter("report_select");

        String jasperFile = "";
        String reportTitle = "";

        if("PL".equalsIgnoreCase(reportSel)){
            jasperFile = "Consolidated_PLGeneration.jasper";
            reportTitle = "CONSOLIDATED PROFIT & LOSS";
        }else{
            jasperFile = "Consolidated_BSGeneration.jasper";
            reportTitle = "CONSOLIDATED BALANCE SHEET";
        }

        String path = application.getRealPath("/Reports/" + jasperFile);

        JasperReport jr =
        (JasperReport) JRLoader.loadObject(new File(path));

        Map<String,Object> param = new HashMap<>();

        param.put("branch_code", branchCode);
        param.put("as_on_date", oracleDate);
        param.put("report_title", reportTitle);
        param.put("user_id", (String)session.getAttribute("userId"));
        param.put("SUBREPORT_DIR", application.getRealPath("/Reports/"));
        param.put(JRParameter.REPORT_CONNECTION, conn);

        JasperPrint jp =
        JasperFillManager.fillReport(jr, param, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        
        response.reset();
        response.setBufferSize(1024*1024);

        ServletOutputStream os = response.getOutputStream();

        if("pdf".equalsIgnoreCase(reporttype)){
            response.setContentType("application/pdf");
            JasperExportManager.exportReportToPdfStream(jp, os);
        }else{
            response.setContentType("application/vnd.ms-excel");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, os);
            exporter.exportReport();
        }

        os.flush();
        os.close();

    }catch(Exception e){
        if(conn!=null) conn.rollback();
        e.printStackTrace();
    }finally{
        if(conn!=null) conn.close();
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>Consolidated Balance Sheet</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
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

.error-box{
    color:red;
    font-weight:bold;
    margin-top:10px;
    text-align:center;
}

</style>

<script>

function validateForm(){
    var date = document.getElementById("as_on_date").value;

    if(date == ""){
        alert("Please enter As On Date");
        return false;
    }
    return true;
}

/* REPORT CALL */
function setReport(val){

    document.getElementById("report_select").value = val;
    document.getElementById("actionType").value = "download";

    document.forms[0].target = "_blank";
    document.forms[0].submit();

    document.forms[0].target = "";
}

</script>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
CONSOLIDATED BALANCE SHEET
</h1>

<form method="post"
      action="ConsolidatedBalancesheet.jsp"
      autocomplete="off"
      onsubmit="return validateForm();">

<input type="hidden" name="action" id="actionType">
<input type="hidden" name="report_select" id="report_select" value="BS">

<!-- PARAMETERS -->

<div class="parameter-section">

<!-- Branch -->

<div class="parameter-group">
<div class="parameter-label">Branch Code</div>

<div class="input-box">

<input type="text"
       name="branch_code"
       id="branch_code"
       class="input-field"
       value="<%= sessionBranchCode %>"
       readonly>

<button type="button"
        class="icon-btn"
        onclick="openLookup('branch')">…</button>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Branch Name</div>

<input type="text"
       id="branchName"
       class="input-field"
       readonly>
</div>

<!-- DATE -->

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="text"
       name="as_on_date"
       id="as_on_date"
       class="input-field"
       value="<%=displayDate%>"
       placeholder="DD/MM/YYYY"
       required>
</div>

<!-- TYPE -->

<div class="parameter-group">
<div class="parameter-label">Type</div>

<%
String rc = (String)session.getAttribute("regularclosing");
if(rc == null) rc = "R";
%>

<label>
<input type="radio" name="regularclosing" value="R"
<%= "R".equals(rc) ? "checked" : "" %>> Regular
</label>

<label>
<input type="radio" name="regularclosing" value="C"
<%= "C".equals(rc) ? "checked" : "" %>> Closing
</label>
</div>

</div>

<!-- FORMAT -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<div class="format-option">
<input type="radio" name="reporttype" value="pdf" checked> PDF
</div>

<div class="format-option">
<input type="radio" name="reporttype" value="xls"> Excel
</div>

</div>

</div>

<!-- ERROR -->

<div class="error-box">
<%= session.getAttribute("errorMessage") != null ? session.getAttribute("errorMessage") : "" %>
</div>

<!-- BUTTONS -->

<div style="margin-top:20px; display:flex; gap:10px;">

<button type="button"
        class="download-button"
        onclick="setReport('BS')">
Balance Sheet
</button>

<button type="button"
        class="download-button"
        onclick="setReport('PL')">
P & L
</button>

</div>

</form>

</div>

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>