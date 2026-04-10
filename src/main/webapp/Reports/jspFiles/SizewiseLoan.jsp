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
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId = (String) session.getAttribute("userId");
String isSupportUser = (String) session.getAttribute("isSupportUser");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";

String action = request.getParameter("action");
if(action==null) action="";
%>

<%
/* ================= AUTO CALCULATE + REPORT ================= */
if("download".equals(action)){

    String branchCode = request.getParameter("branch_code");
    String branchFrom = request.getParameter("branch_from");
    String branchTo   = request.getParameter("branch_to");
    String asOnDate   = request.getParameter("ason_date");
    String reportType = request.getParameter("reporttype");
    String reportName = request.getParameter("report_name");

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    Connection conn=null;
    Statement stmt=null;

    try{
        response.reset();
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* DELETE OLD */
        PreparedStatement ps =
        conn.prepareStatement("DELETE FROM BANKDATA.SIZEWISE_LOAN WHERE BRANCH_CODE=?");
        ps.setString(1, branchCode);
        ps.executeUpdate();
        ps.close();

        /* DATE FORMAT */
        String oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate))
        .toUpperCase();

        /* MAIN LOGIC (SIMPLIFIED FROM SERVLET) */
        String plsql =
        "DECLARE " +
        " ason_date DATE := TO_DATE('"+oracleDate+"','DD-MON-YYYY'); " +
        " b_cod VARCHAR2(4) := '"+branchCode+"'; " +
        " b_cod_fm VARCHAR2(4) := '"+branchFrom+"'; " +
        " b_cod_to VARCHAR2(4) := '"+branchTo+"'; " +
        "BEGIN " +

        " INSERT INTO BANKDATA.SIZEWISE_LOAN " +
        " SELECT '"+branchCode+"', ACCOUNT_CODE, " +
        " FN_GET_BALANCE_ASON(ason_date, ACCOUNT_CODE), " +
        " 'A', '000000', 'A' " +
        " FROM ACCOUNT.ACCOUNT " +
        " WHERE SUBSTR(ACCOUNT_CODE,1,4) BETWEEN b_cod_fm AND b_cod_to; " +

        " END;";

        stmt = conn.createStatement();
        stmt.execute(plsql);

        conn.commit();

        /* ================= REPORT ================= */

        String jasperFile = "";

        if("details".equalsIgnoreCase(reportName)){
            jasperFile = "SizewiseLoan(Details).jasper";
        }else{
            jasperFile = "SizewiseLoan.jasper"; // default summary
        }

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */
        String bankName = "";
        String branchName = "";
        String cityCode = "";
        String address1 = "";

        PreparedStatement ps1 = conn.prepareStatement(
        "SELECT NAME, CITY_CODE, ADDRESS1 " +
        "FROM HEADOFFICE.BRANCH " +
        "WHERE BRANCH_CODE = ?");

        ps1.setString(1, branchCode);

        ResultSet rs1 = ps1.executeQuery();

        if(rs1.next()){
            branchName = rs1.getString("NAME");
            cityCode   = rs1.getString("CITY_CODE");
            address1   = rs1.getString("ADDRESS1");
        }

        rs1.close();
        ps1.close();	
        
        PreparedStatement ps2 = conn.prepareStatement(
        		"SELECT NAME FROM GLOBALCONFIG.BANK WHERE BANK_CODE = " +
        		"(SELECT BANK_CODE FROM GLOBALCONFIG.UNIVERSALPARAMETER)");

        		ResultSet rs2 = ps2.executeQuery();

        		if(rs2.next()){
        		    bankName = rs2.getString("NAME");
        		}

        		rs2.close();
        		ps2.close();

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("as_on_date",oracleDate); // 🔥 FIX NULL ISSUE
        params.put("report_title","SIZE WISE LOAN REPORT");
        
        params.put("bank_name", bankName);
        params.put("branch_name", branchName);
        params.put("city_code", cityCode);
        params.put("address1", address1);

        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/") + File.separator);

        params.put("user_id",userId);

        /* ================= FILL ================= */

        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport,params,conn);

        if(jp.getPages().isEmpty()){
            response.setContentType("text/html");
            out.println("<h3 style='color:red;text-align:center;'>No Records Found</h3>");
            return;
        }

        /* ================= EXPORT ================= */

        out.clear();
        out = pageContext.pushBody();

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"SizewiseLoan.pdf\"");

            ServletOutputStream os = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jp,os);
            os.close();
        }
        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"SizewiseLoan.xls\"");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT,jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM,os);
            exporter.exportReport();

            os.close();
        }

    }catch(Exception e){
        if(conn!=null) conn.rollback();
        e.printStackTrace(new PrintWriter(out));
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

<title>SIZEWISE LOAN REPORT</title>

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

<h1 class="report-title">
SIZEWISE LOAN REPORT
</h1>

<form method="post"
action="<%=request.getContextPath()%>/Reports/jspFiles/SizewiseLoan.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= BRANCH ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">From Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_code"
id="branch_code"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if("Y".equalsIgnoreCase(isSupportUser.trim())){ %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">To Branch Code</div>

<div class="input-box">
<input type="text"
name="branch_to"
id="branch_to"
class="input-field"
value="<%=sessionBranchCode%>"
<%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %>
required>

<% if("Y".equalsIgnoreCase(isSupportUser.trim())){ %>
<button type="button"
class="icon-btn"
onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

</div>

<!-- ================= DATE ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="ason_date"
class="input-field"
value="<%=sessionDate%>"
required>
</div>



<!-- ================= VIEW TYPE ================= -->

<div class="parameter-group">

        <div class="parameter-label">Report Mode</div>

        <div class="format-options" style="display:flex; gap:20px;">

            <div class="format-option">
                <input type="radio" name="report_name" value="details" checked>
                Details
            </div>

            <div class="format-option">
                <input type="radio" name="report_name" value="summary">
                Summary
            </div>

        </div>
    </div>
</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

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

<!-- ================= BUTTON ================= -->

<button type="submit"
class="download-button">
Generate Report
</button>

</form>

</div>

<!-- ================= LOOKUP POPUP ================= -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>

</html>