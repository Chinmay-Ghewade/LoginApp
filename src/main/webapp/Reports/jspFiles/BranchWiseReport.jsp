<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.text.*, java.util.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>

<%
String user_id = (String) session.getAttribute("user_id");
if(user_id == null) user_id = "";
String action = request.getParameter("action");

%>

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
%>

<%
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if(isSupportUser == null) isSupportUser = "N";
if(sessionBranchCode == null) sessionBranchCode = "";
%>

<%
/* ================= BACKEND ================= */
if("process".equals(action)){

    response.reset();   // 🔥 IMPORTANT

    String fromBranch   = request.getParameter("from_branch");
    String toBranch     = request.getParameter("to_branch");
    String asOnDate     = request.getParameter("as_on_date");
    String loanAgainst  = request.getParameter("loan_against");
    String reportType   = request.getParameter("reporttype");
    String report       = request.getParameter("report_name");

    // 🔥 GET BRANCH NAMES FROM UI (LIKE JAVA CODE)
    String fromBranchName = request.getParameter("from_branch_name");
    String toBranchName   = request.getParameter("to_branch_name");

    if(fromBranchName == null) fromBranchName = "";
    if(toBranchName == null) toBranchName = "";

    Connection conn = null;

    try{

        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();
        
        /* DATE FORMAT */
        String oracleDate = "";

        if(asOnDate != null && !asOnDate.trim().equals("")){
            java.util.Date d = new SimpleDateFormat("dd/MM/yyyy").parse(asOnDate);
            oracleDate = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(d).toUpperCase();
        }

        /* CALL STORED PROCEDURE */
        if("OVERDUE".equals(report)){

            CallableStatement cs;

            if("Y".equals(loanAgainst)){
                cs = conn.prepareCall("{call sp_rep_overdue_summary_all (?,?,?,?)}");
            } else {
                cs = conn.prepareCall("{call sp_rep_overdue_summary (?,?,?,?)}");
            }

            cs.setString(1, fromBranch);
            cs.setString(2, toBranch);
            cs.setString(3, oracleDate);
            cs.setString(4, user_id);
            cs.execute();
        }

        /* SELECT REPORT */
        String jasperFile="";

        if("OVERDUE".equals(report)){
            jasperFile = "Overdue_Summary.jasper";
        }else{
            jasperFile = "ProductWiseNoOfAccountsAndBalances.jasper";
        }

        String path = application.getRealPath("/Reports/" + jasperFile);

        JasperReport jr =
            (JasperReport) JRLoader.loadObject(new java.io.File(path));

        Map<String,Object> params = new HashMap<>();

        params.put("agent_name", "BANK NAME");
        params.put("branch_code", fromBranch);
        params.put("from_product", fromBranch);
        params.put("to_product", toBranch);
        params.put("as_on_date", oracleDate);

        // 🔥 CORRECT VALUES (FROM UI)
        params.put("account_name", fromBranchName);
        params.put("court_charges", toBranchName);

        // 🔥 SUBREPORT SUPPORT
        params.put("SUBREPORT_DIR", application.getRealPath("/Reports/") + "/");
        params.put("REPORT_CONNECTION", conn);
        params.put(JRParameter.REPORT_CONNECTION, conn);

        JasperPrint jp = JasperFillManager.fillReport(jr, params, conn);

        if (jp.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        ServletOutputStream outStream = response.getOutputStream();

        if("pdf".equalsIgnoreCase(reportType)){
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition","inline; filename=report.pdf");

            JasperExportManager.exportReportToPdfStream(jp, outStream);

        }else{
            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition","attachment; filename=report.xls");

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
            exporter.exportReport();
        }

        outStream.flush();
        outStream.close();

        return;

    }catch(Exception e){
        response.reset();
        out.println("<h3 style='color:red'>Error generating report</h3>");
        e.printStackTrace(new java.io.PrintWriter(out));
    }finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Branch Wise Report</title>

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
</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">BRANCH WISE REPORT</h1>

<form method="post"
      action="BranchWiseReport.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="process"/>
<input type="hidden" name="report_name" id="report_name"/>

<!-- 🔥 BRANCH CODE SECTION (REFERENCE STYLE) -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Branch Code</div>
<div class="input-box">

<input type="text"
name="from_branch"
id="from_branch"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch','from_branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Branch Code</div>
<div class="input-box">

<input type="text"
name="to_branch"
id="to_branch"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch','to_branch')">…</button>
<% } %>

</div>
</div>

</div>

<!-- 🔥 DATE + OPTION -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">As On Date</div>
<input type="text"
       name="as_on_date"
       class="input-field"
       value="<%= displayDate %>"
       placeholder="DD/MM/YYYY"
       required>
</div>

<div class="parameter-group">
<div class="parameter-label">Loan Against Deposit</div>
<div class="radio-container">
<label><input type="radio" name="loan_against" value="Y"> Yes</label>
<label><input type="radio" name="loan_against" value="N" checked> No</label>
</div>
</div>

</div>

<!-- 🔥 REPORT TYPE -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
<label><input type="radio" name="reporttype" value="xls"> Excel</label>

</div>

<!-- 🔥 BUTTONS -->

<div style="margin-top:20px; display:flex; gap:20px;">

<button type="submit"
class="download-button"
onclick="return setReport('OVERDUE')">
Overdue Summary
</button>

<button type="submit"
class="download-button"
onclick="return setReport('PRODUCT')">
Product Wise Report
</button>

</div>

</form>

</div>

<!-- 🔥 LOOKUP MODAL -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<script>
document.querySelector("form").onsubmit=function(){
    let f=document.getElementById("from_branch").value;
    let t=document.getElementById("to_branch").value;

    if(f=="" || t==""){
        alert("Enter Branch Range");
        return false;
    }
};

function setReport(type){
    document.getElementById("report_name").value = type;
    return true;
}
</script>

</body>
</html>