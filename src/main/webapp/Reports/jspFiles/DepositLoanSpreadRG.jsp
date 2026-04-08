<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="db.DBConnection" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="java.io.File" %>
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

String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>
<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String branchCode = request.getParameter("branch_code");
    String fromDate   = request.getParameter("from_date");
    String toDate     = request.getParameter("to_date");
    String singleAll  = request.getParameter("single_all");

    if(singleAll == null) singleAll = "S";

    /* ================= VALIDATION ================= */

    if (fromDate == null || fromDate.trim().isEmpty()) {
        out.println("<h3 style='color:red;text-align:center'>Enter From Date</h3>");
        return;
    }

    if (toDate == null || toDate.trim().isEmpty()) {
        out.println("<h3 style='color:red;text-align:center'>Enter To Date</h3>");
        return;
    }

    /* ================= BRANCH LOGIC (IMPORTANT) ================= */

    if ("A".equals(singleAll)) {
        branchCode = "0000";   // SAME AS SERVLET
    }

    /* ================= DATE FORMAT (SERVLET STYLE) ================= */

    String oracleFromDate = "";
    String oracleToDate   = "";
    try {

        java.util.Date d1 = new SimpleDateFormat("yyyy-MM-dd").parse(fromDate);
        oracleFromDate = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(d1).toUpperCase();

        java.util.Date d2 = new SimpleDateFormat("yyyy-MM-dd").parse(toDate);
        oracleToDate = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                .format(d2).toUpperCase();

        sessionDate = oracleToDate; // same as servlet current_date

    } catch (Exception e) {
        out.println("<h3 style='color:red;text-align:center'>Invalid Date</h3>");
        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= CALL PROCEDURE (FIXED WITH SCHEMA) ================= */

        CallableStatement stmt =
    conn.prepareCall("{ call Sp_Fp_Td_Tl_Avg(?,?,?,?,?) }");
        
        stmt.setString(1, branchCode);
        stmt.setString(2, sessionDate);
        stmt.setString(3, oracleFromDate);
        stmt.setString(4, oracleToDate);
        stmt.setString(5, "admin");

        stmt.execute();

        /* ================= MAIN QUERY (MATCH SERVLET getSql()) ================= */

        Statement st = conn.createStatement();

        ResultSet rs = st.executeQuery(
        " select D_BRANCH_CODE ,decode(trim(D_SEQ_NO),'999','','1000','',trim(D_SEQ_NO)) D_SEQ_NO , D_DESCRIPTION ,D_REP_CHAR ,D_BALANCE, " +
        " L_BRANCH_CODE , decode(trim(L_SEQ_NO),'999','','1000','',trim(L_SEQ_NO)) L_SEQ_NO, L_DESCRIPTION ,L_REP_CHAR ,L_BALANCE " +
        " from  " +
        " (SELECT BRANCH_CODE D_BRANCH_CODE,SEQ_NO D_SEQ_NO , DESCRIPTION D_DESCRIPTION, REP_CHAR D_REP_CHAR, BALANCE D_BALANCE " +
        " FROM BANKDATA.FP_TD_TL_AVG WHERE REP_CHAR='D' AND SEQ_NO<>1001 " +
        " group by BRANCH_CODE, SEQ_NO , DESCRIPTION, REP_CHAR, BALANCE), " +
        " (SELECT BRANCH_CODE L_BRANCH_CODE, SEQ_NO L_SEQ_NO, DESCRIPTION L_DESCRIPTION, REP_CHAR L_REP_CHAR, BALANCE L_BALANCE " +
        " FROM BANKDATA.FP_TD_TL_AVG WHERE REP_CHAR='L' AND SEQ_NO<>1001 " +
        " group by BRANCH_CODE, SEQ_NO , DESCRIPTION, REP_CHAR, BALANCE) " +
        " where L_SEQ_NO = D_SEQ_NO " +
        " order by to_number(L_SEQ_NO)"
        );

        if (!rs.isBeforeFirst()) {
            out.println("<h2 style='color:red;text-align:center'>No Records Found</h2>");
            return;
        }

        /* ================= LOAD JASPER ================= */

        String jasperPath =
            application.getRealPath("/Reports/DepositLoanSpreadRG.jasper");

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(new File(jasperPath));

        /* ================= DATASOURCE ================= */

        JRResultSetDataSource jrds = new JRResultSetDataSource(rs);

        Map<String,Object> parameters = new HashMap<>();

        parameters.put("branch_code", branchCode);
        parameters.put("from_date", oracleFromDate);
        parameters.put("to_date", oracleToDate);

        /* ================= FILL ================= */

        /* ✅ IMPORTANT FOR SUBREPORT */
        parameters.put(JRParameter.REPORT_CONNECTION, conn);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, parameters, jrds);
        
/* =====================================
   NO DATA CHECK
===================================== */

if (jasperPrint.getPages().isEmpty()) {

    response.reset();
    response.setContentType("text/html");

    out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
    out.println("No Records Found!");
    out.println("</h2>");

    return;
}

/* =====================================
   EXPORT
===================================== */

String reporttype = request.getParameter("reporttype");
if (reporttype == null) reporttype = "pdf";

/* ===== PDF ===== */

if ("pdf".equalsIgnoreCase(reporttype)) {

    response.reset();
    response.setContentType("application/pdf");

    response.setHeader(
        "Content-Disposition",
        "inline; filename=\"DepositLoanSpreadRG.pdf\"");

    ServletOutputStream outStream = response.getOutputStream();

    JasperExportManager.exportReportToPdfStream(
            jasperPrint,
            outStream);

    outStream.flush();
    outStream.close();

    return;
}

/* ===== EXCEL ===== */

else if ("xls".equalsIgnoreCase(reporttype)) {

    response.reset();
    response.setContentType("application/vnd.ms-excel");

    response.setHeader(
        "Content-Disposition",
        "attachment; filename=\"DepositLoanSpreadRG.xls\"");

    ServletOutputStream outStream = response.getOutputStream();

    JRXlsExporter exporter = new JRXlsExporter();

    exporter.setParameter(
        JRXlsExporterParameter.JASPER_PRINT,
        jasperPrint);

    exporter.setParameter(
        JRXlsExporterParameter.OUTPUT_STREAM,
        outStream);

    exporter.exportReport();

    outStream.flush();
    outStream.close();

    return;
}

    } catch (Exception e) {

        response.setContentType("text/html");

        out.println("<h3 style='color:red;text-align:center'>Error Generating Report</h3>");
        out.println("<pre>");
        e.printStackTrace(new java.io.PrintWriter(out));
        out.println("</pre>");

    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ex) {}
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Deposit Loan Spread Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>

.radio-container {
    margin-top: 10px;
    display: flex;
    gap: 30px;
}

.input-box {
    display: flex;
    gap: 10px;
}

.icon-btn {
    background: #2D2B80;
    color: white;
    border: none;
    width: 40px;
    border-radius: 8px;
    cursor: pointer;
}

.modal {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.5);
    justify-content: center;
    align-items: center;
}

.modal-content {
    background: #fff;
    width: 80%;
    max-height: 85%;
    padding: 20px;
    border-radius: 10px;
    overflow: auto;
}

</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">DEPOSIT LOAN SPREAD REPORT</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/DepositLoanSpreadRG.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

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


<!-- From Date -->
<div class="parameter-group">
<div class="parameter-label">From Date</div>

<input type="date"
       name="from_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>
</div>

<!-- To Date -->
<div class="parameter-group">
<div class="parameter-label">To Date</div>

<input type="date"
       name="to_date"
       class="input-field"
       required>
</div>

</div>

<!-- Report Type -->
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

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- 🔍 LOOKUP MODAL -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>


</body>
</html>
