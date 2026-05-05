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
String isSupportUser = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");

if (isSupportUser == null) isSupportUser = "N";
if (sessionBranchCode == null) sessionBranchCode = "";
%>
<%
String action = request.getParameter("action");

if ("download".equals(action)) {
String reporttype  = request.getParameter("reporttype");
String branchCode  = request.getParameter("branch_code");
String asOnDate    = request.getParameter("as_on_date");
String type        = request.getParameter("regularclosing"); // R / C


if (branchCode == null || branchCode.trim().isEmpty()) {
    branchCode = sessionBranchCode;
}

if (!"Y".equalsIgnoreCase(isSupportUser)) {
    branchCode = sessionBranchCode;
}

if(asOnDate == null || asOnDate.trim().isEmpty()){
    out.println("<h3 style='color:red'>Please Enter As On Date</h3>");
    return;
}

Connection conn = null;

try {

    response.reset();
    response.setBufferSize(1024*1024);

    conn = DBConnection.getConnection();
    conn.setAutoCommit(false);

    Statement st = conn.createStatement();

    /* ================= TEMP TABLE PREPARATION ================= */

    st.executeUpdate("DELETE FROM TEMP.MTBGOADETAILS");
    st.executeUpdate("DELETE FROM TEMP.MTEMP_TBGOAHEADER");
    st.executeUpdate("DELETE FROM TEMP.MTEMP_TBGOAFOOTER");

    st.executeUpdate(
    "INSERT INTO TEMP.MTBGOADETAILS " +
    "(BRANCH_CODE,AMOUNT,SR_NO,GLACCOUNT_CODE,TEMPBALANCE) " +
    "SELECT '9999',0,TBGOA_SR,GLACCOUNT_CODE,0 FROM HEADOFFICE.GLACCOUNT");

    st.executeUpdate(
    "INSERT INTO TEMP.MTEMP_TBGOAHEADER " +
    "SELECT '9999',SR_NO,GRP,CR_AMT,DR_AMT,C_D,DES,SERIAL_NUMBER FROM TEMP.MTBGOA_HEADER");

    st.executeUpdate(
    "INSERT INTO TEMP.MTEMP_TBGOAFOOTER " +
    "SELECT '9999',SR_NO,LEFTDES,LEFT_AMT,LEFTGRP,RIGHTDES,RIGHT_AMT,RIGHTGRP FROM TEMP.MTBGOA_FOOTER");

    /* ================= DATE ================= */

    java.util.Date d =
    new java.text.SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

    String oracleDate =
    new java.text.SimpleDateFormat("dd-MMM-yyyy",java.util.Locale.ENGLISH)
    .format(d).toUpperCase();

    /* ================= MAIN LOGIC ================= */

    Statement s2 = conn.createStatement();
    s2.execute("BEGIN DELETE FROM TEMP.CONSOL_TB WHERE TXN_DATE = TO_DATE('"+oracleDate+"','DD-MON-YYYY'); END;");
    s2.close();

    ResultSet rsTB = st.executeQuery(
    "SELECT GLACCOUNT_CODE,CLOSING_BALANCE FROM TEMP.CONSOL_TB " +
    "WHERE TXN_DATE = TO_DATE('"+oracleDate+"','DD-MON-YYYY')");

    while(rsTB.next()){
        st.executeUpdate(
        "UPDATE TEMP.MTBGOADETAILS SET AMOUNT="+rsTB.getDouble(2)+
        ", TEMPBALANCE="+rsTB.getDouble(2)+
        " WHERE GLACCOUNT_CODE='"+rsTB.getString(1)+"'");
    }

    rsTB.close();

    conn.commit();

    /* ================= SELECT JASPER ================= */

    String jasperFile = "";

    if("C".equalsIgnoreCase(type)){
        jasperFile = "/Reports/ConsolTBGoa (Closing).jasper";
    }else{
        jasperFile = "/Reports/ConsolTBGoa.jasper";
    }

    String jasperPath = application.getRealPath(jasperFile);

    net.sf.jasperreports.engine.JasperReport jasperReport =
    (net.sf.jasperreports.engine.JasperReport)
    net.sf.jasperreports.engine.util.JRLoader.loadObject(new java.io.File(jasperPath));

    /* ================= PARAMETERS ================= */

    java.util.Map<String,Object> parameters = new java.util.HashMap<>();

    parameters.put("branch_code", branchCode);
    parameters.put("as_on_date", oracleDate);
    parameters.put("report_title", "CONSOLIDATED TB GOA");

    String userId = (String) session.getAttribute("userId");
    parameters.put("user_id", userId);

    parameters.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

    parameters.put(net.sf.jasperreports.engine.JRParameter.REPORT_CONNECTION, conn);

    /* ================= FILL ================= */

    net.sf.jasperreports.engine.JasperPrint jasperPrint =
    net.sf.jasperreports.engine.JasperFillManager.fillReport(
        jasperReport, parameters, conn);


    if (jasperPrint.getPages().isEmpty()) {

        response.reset();
        response.setContentType("text/html");

        out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
        out.println("No Records Found!");
        out.println("</h2>");

        return;
    }
    

    /* ================= DOWNLOAD ================= */

    if("pdf".equalsIgnoreCase(reporttype)){

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition",
        "inline; filename=\"ConsolTBGoa.pdf\"");

        javax.servlet.ServletOutputStream outStream =
        response.getOutputStream();

        net.sf.jasperreports.engine.JasperExportManager
        .exportReportToPdfStream(jasperPrint,outStream);

        outStream.close();
    }

    else if("xls".equalsIgnoreCase(reporttype)){

        response.setContentType("application/vnd.ms-excel");
        response.setHeader("Content-Disposition",
        "attachment; filename=\"ConsolTBGoa.xls\"");

        javax.servlet.ServletOutputStream outStream =
        response.getOutputStream();

        net.sf.jasperreports.engine.export.JRXlsExporter exporter =
        new net.sf.jasperreports.engine.export.JRXlsExporter();

        exporter.setParameter(
        net.sf.jasperreports.engine.export.JRXlsExporterParameter.JASPER_PRINT,
        jasperPrint);

        exporter.setParameter(
        net.sf.jasperreports.engine.export.JRXlsExporterParameter.OUTPUT_STREAM,
        outStream);

        exporter.exportReport();

        outStream.close();
    }

} catch(Exception e){

    if(conn!=null){
        try{conn.rollback();}catch(Exception ex){}
    }

    out.println("<h3 style='color:red'>Error Generating Report</h3>");
    e.printStackTrace(new java.io.PrintWriter(out));

} finally {

    if(conn!=null){
        try{conn.close();}catch(Exception ex){}
    }
}


}
%>


<!DOCTYPE html>

<html>
<head>

<title>Consolidated TB Goa</title>

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

.radio-container {
    display:flex;
    gap:40px;
    margin-top:10px;
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
CONSOLIDATED TB GOA REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/consolTBGoa.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

<!-- ================= BRANCH ================= -->

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

<% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %> <button type="button"
     class="icon-btn"
     onclick="openLookup('branch')">…</button>
<% } %>

</div>
</div>

<div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName" class="input-field" readonly>
</div>

<!-- ================= TYPE ================= -->

<div class="parameter-group">

<div class="parameter-label">Select Type</div>

<div class="radio-container">

<label>
<input type="radio"
       name="regularclosing"
       value="R"
       checked> Regular
</label>

<label>
<input type="radio"
       name="regularclosing"
       value="C"> Closing
</label>

</div>

</div>

<!-- ================= DATE ================= -->

<div class="parameter-group">

<div class="parameter-label">As On Date</div>

<input type="date"
    name="as_on_date"
    class="input-field"
    value="<%=sessionDate%>"
    required>

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

<button type="submit" class="download-button">
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

<!-- ================= VALIDATION ================= -->

<script>

document.querySelector("form").onsubmit = function(){

    let date = document.querySelector("[name=as_on_date]").value;

    if(date === ""){
        alert("Please select As On Date");
        return false;
    }

    return true;
};

</script>

</body>
</html>
