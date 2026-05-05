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
/* ================= DOWNLOAD ================= */
String action = request.getParameter("action");

if("download".equalsIgnoreCase(action)){

    String reporttype      = request.getParameter("reporttype");   // pdf/xls
    String reportSel       = request.getParameter("report_select"); // P / X
    String branchCode      = request.getParameter("branch_code");
    String as_on_date      = request.getParameter("as_on_date");
    String last_year_date  = request.getParameter("last_year_date");
    String regularclosing  = request.getParameter("regularclosing_0");

    if(reportSel == null) reportSel = "P";
    if(reporttype == null) reporttype = "pdf";
    if(regularclosing == null) regularclosing = "R";

    /* ================= STORE IN SESSION ================= */

    session.setAttribute("branchCode", branchCode);
    session.setAttribute("as_on_date", as_on_date);
    session.setAttribute("last_year_date", last_year_date);
    session.setAttribute("regularclosing", regularclosing);

    /* ================= DATE FORMAT ================= */

    String oracle_as_on = "";
    String oracle_to    = "";

    try{

        if(as_on_date != null && !as_on_date.trim().equals("")){
            java.util.Date d =
            new SimpleDateFormat("dd/MM/yyyy").parse(as_on_date);

            oracle_as_on =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d).toUpperCase();
        }

        if(last_year_date != null && !last_year_date.trim().equals("")){
            java.util.Date d2 =
            new SimpleDateFormat("dd/MM/yyyy").parse(last_year_date);

            oracle_to =
            new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
            .format(d2).toUpperCase();
        }

    }catch(Exception e){
        out.println("<h3 style='color:red'>Date Conversion Error</h3>");
        return;
    }

    /* ================= REGULAR / CLOSING ================= */

    String is_year_end = "N";

    if("C".equalsIgnoreCase(regularclosing)){
        is_year_end = "Y";   // Closing
    }else{
        is_year_end = "N";   // Regular
    }

    /* ================= DB ================= */

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = db.DBConnection.getConnection();

        /* ================= REPORT SELECT ================= */

        String jasperFile;
        String reportTitle;

        if("X".equalsIgnoreCase(reportSel)){

            jasperFile  = "Cons_N_PL_Generation.jasper";
            reportTitle = "CONSOLIDATED N FORM PROFIT & LOSS";

        }else{

            jasperFile  = "Cons_N_BalanaceSheet.jasper";
            reportTitle = "CONSOLIDATED N FORM BALANCE SHEET";
        }

        String reportPath =
        application.getRealPath("/Reports/" + jasperFile);

        net.sf.jasperreports.engine.JasperReport jr =
        (net.sf.jasperreports.engine.JasperReport)
        net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(reportPath));

        /* ================= PARAMETERS ================= */

        Map<String,Object> param = new HashMap<>();

        param.put("branch_code", branchCode);

        /* 🔥 IMPORTANT FIX */
        param.put("as_on_date", oracle_as_on);   // current
        param.put("to_date", oracle_to);         // last year
        param.put("from_date", oracle_as_on);

        param.put("report_title", reportTitle);
        param.put("title", reportTitle);
        param.put("user_id", (String)session.getAttribute("userId"));

        param.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        param.put(net.sf.jasperreports.engine.JRParameter.REPORT_CONNECTION, conn);

        /* ================= GENERATE DATA ================= */

        PreparedStatement ps = null;

        /* CLEAR OLD DATA */
        ps = conn.prepareStatement(
        "DELETE FROM TEMP.TEMP_BS_STRUCTURE WHERE BRANCH_CODE=?");
        ps.setString(1, branchCode);
        ps.executeUpdate();
        ps.close();

        ps = conn.prepareStatement(
        "DELETE FROM TEMP.TEMP_PL_STRUCTURE WHERE BRANCH_CODE=?");
        ps.setString(1, branchCode);
        ps.executeUpdate();
        ps.close();

        /* ================= CALL FUNCTION ================= */

        ps = conn.prepareStatement(
        "SELECT FN_GET_BS_PL_GROUP_SUM(?, ?, ?, ?) FROM DUAL");

        ps.setString(1, branchCode);
        ps.setString(2, "ALL");          // group placeholder
        ps.setString(3, oracle_as_on);   // date
        ps.setString(4, is_year_end);    // 🔥 regular/closing

        ps.executeQuery();
        ps.close();

        /* ================= FILL REPORT ================= */

        net.sf.jasperreports.engine.JasperPrint jp =
        net.sf.jasperreports.engine.JasperFillManager.fillReport(jr, param, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"" + jasperFile.replace(".jasper",".pdf") + "\"");

            javax.servlet.ServletOutputStream os = response.getOutputStream();

            net.sf.jasperreports.engine.JasperExportManager
            .exportReportToPdfStream(jp, os);

            os.close();
            return;
        }
        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"" + jasperFile.replace(".jasper",".xls") + "\"");

            javax.servlet.ServletOutputStream os = response.getOutputStream();

            net.sf.jasperreports.engine.export.JRXlsExporter exporter =
            new net.sf.jasperreports.engine.export.JRXlsExporter();

            exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.JASPER_PRINT, jp);

            exporter.setParameter(
            net.sf.jasperreports.engine.export.JRXlsExporterParameter.OUTPUT_STREAM, os);

            exporter.exportReport();

            os.close();
            return;
        }

    }catch(Exception e){

        out.println("<h3 style='color:red'>Error Generating Report</h3>");
        e.printStackTrace(new java.io.PrintWriter(out));

    }finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Consolidated N Form Balance Sheet</title>

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

/* VALIDATION */
function validateForm(){

    let branch = document.getElementById("branch_code").value;
    let ason   = document.getElementById("as_on_date").value;
    let last   = document.getElementById("last_year_date").value;

    if(branch.trim() === ""){
        alert("Enter Branch Code");
        return false;
    }

    if(ason.trim() === ""){
        alert("Enter As On Date");
        return false;
    }

    if(last.trim() === ""){
        alert("Enter Last Year Date");
        return false;
    }

    return true;
}

/* OPEN REPORTS */
function openBS(){

    if(!validateForm()) return;

    let form = document.forms[0];

    document.getElementById("report_select").value = "P";
    form.target = "_blank";
    form.submit();
}

function openPL(){

    if(!validateForm()) return;

    let form = document.forms[0];

    document.getElementById("report_select").value = "X";
    form.target = "_blank";
    form.submit();
}

</script>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
CONSOLIDATED N-FORM BALANCE SHEET
</h1>

<form method="post"
      action="ConsolidatedNFormBalanceSheet.jsp"
      autocomplete="off">

<!-- 🔥 IMPORTANT HIDDEN FIELDS -->
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

<% if ("Y".equalsIgnoreCase(isSupportUser)) { %>
<button type="button"
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

<!-- 🔹 Last Year Date -->
<div class="parameter-group">
<div class="parameter-label">Last Year Date</div>
<input type="text"
name="last_year_date"
id="last_year_date"
class="input-field"
value="<%=displayDate%>"
placeholder="DD/MM/YYYY">
</div>

<!-- 🔹 As On Date -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="text"
name="as_on_date"
id="as_on_date"
class="input-field"
value="<%=displayDate%>"
placeholder="DD/MM/YYYY">
</div>

<!-- 🔹 Type -->
<div class="parameter-group">
<div class="parameter-label">Type</div>

<label>
<input type="radio" name="regularclosing_0" value="R" checked> Regular
</label>

<label>
<input type="radio" name="regularclosing_0" value="C"> Closing
</label>

</div>

<!-- 🔹 FORMAT -->
<div class="format-section">
<div class="parameter-label">Report Format</div>

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

</div>

<!-- 🔹 BUTTONS -->
<div style="margin-top:20px; display:flex; gap:10px;">

<button type="button"
        onclick="openBS()"
        class="download-button">
Balance Sheet
</button>

<button type="button"
        onclick="openPL()"
        class="download-button">
P & L
</button>

</div>

</form>

</div>

<!-- 🔹 LOOKUP -->
<div id="lookupModal" class="modal">
<div class="modal-content">
<button onclick="closeLookup()" style="float:right;">✖</button>
<div id="lookupTable"></div>
</div>
</div>

</body>
</html>