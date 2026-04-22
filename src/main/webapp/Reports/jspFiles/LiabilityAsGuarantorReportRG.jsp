<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

<%@ page import="db.DBConnection" %>

<%
Object obj = session.getAttribute("workingDate");

String sessionDate = "";

if (obj != null) {
    if (obj instanceof java.sql.Date) {
        sessionDate = new java.text.SimpleDateFormat("dd-MMM-yyyy")
                .format((java.sql.Date) obj).toUpperCase();
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("dd-MMM-yyyy")
            .format(new java.util.Date()).toUpperCase();
}
%>

<%
/* ================= SESSION ================= */

String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId            = (String) session.getAttribute("userId");
String isSupportUser     = (String) session.getAttribute("isSupportUser");

if(sessionBranchCode==null) sessionBranchCode="";
if(userId==null) userId="";
if(isSupportUser==null) isSupportUser="N";

/* ================= ACTION ================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String branchCode   = request.getParameter("branch_code");
    String customerId = request.getParameter("customer_id");
    if(customerId != null) customerId = customerId.trim();
    String singleAll = request.getParameter("select_type");
    if(singleAll == null) singleAll = "A";
    String liveOnly     = request.getParameter("live_only");
    String reportType   = request.getParameter("reporttype");

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */

    if("S".equals(singleAll) && (customerId==null || customerId.trim().equals(""))){
        session.setAttribute("errorMessage","Enter Customer Id!");
        response.sendRedirect("LiabilityAsGuarantorReportRG.jsp");
        return;
    }

    Connection conn = null;

    try{

        response.reset();
        conn = DBConnection.getConnection();

        /* ================= LOAD JASPER ================= */

        String jasperFile = "LiabilityAsGuarantorReportRG.jasper";

        if("Y".equalsIgnoreCase(liveOnly)){
            jasperFile = "LiabilityAsGuarantorReportRG(Only_live).jasper";
        }

        String jasperPath =
        application.getRealPath("/Reports/" + jasperFile);
        
        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* ================= PARAMETERS ================= */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code", branchCode);
        params.put("branch_code%", branchCode + "%");
        params.put("customer_id", customerId);
        params.put("select_type", singleAll);
        params.put("live_only", liveOnly);

        params.put("report_title","LIABILITY AS GUARANTOR REPORT");
        params.put("user_id", userId);
        params.put("as_on_date", sessionDate);   // 🔥 ADD THIS

        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION, conn);

        /* ================= FILL ================= */

        JasperPrint jp =
        JasperFillManager.fillReport(jasperReport, params, conn);

        if(jp.getPages().isEmpty()){
            session.setAttribute("errorMessage","No Records Found!");
            response.sendRedirect("LiabilityAsGuarantorReportRG.jsp");
            return;
        }

        out.clear();
        out = pageContext.pushBody();

        /* ================= EXPORT ================= */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=\"LiabilityGuarantor.pdf\"");

            ServletOutputStream os = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jp,os);
            os.close();
        }
        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=\"LiabilityGuarantor.xls\"");

            ServletOutputStream os = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT,jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM,os);
            exporter.exportReport();

            os.close();
        }

    }catch(Exception e){

        Throwable cause = e;
        while(cause.getCause()!=null){
            cause = cause.getCause();
        }

        session.setAttribute("errorMessage","Error = "+cause.getMessage());
        response.sendRedirect("LiabilityAsGuarantorReportRG.jsp");
    }
    finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }

    return;
}
%>
<!DOCTYPE html>
<html>
<head>

<title>Liability As Guarantor Report</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

<style>
.error-message{
    background:#ffe6e6;
    color:red;
    padding:10px;
    text-align:center;
    margin-bottom:10px;
    border-radius:5px;
    font-weight:bold;
}

.parameter-section{
    display:flex;
    gap:30px;
    flex-wrap:wrap;
}

.input-box{ display:flex; gap:10px; }

.icon-btn{
    background:#2D2B80;
    color:white;
    border:none;
    width:40px;
    border-radius:8px;
    cursor:pointer;
}

.modal{
    display:none;
    position:fixed;
    top:0; left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
}

.modal-content{
    background:#fff;
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
if(errorMessage!=null){
%>
<div class="error-message"><%=errorMessage%></div>
<%
session.removeAttribute("errorMessage");
}
%>

<h1 class="report-title">LIABILITY AS GUARANTOR REPORT</h1>

<form method="post"
action="LiabilityAsGuarantorReportRG.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download">
<input type="hidden" name="branch_code" value="<%=sessionBranchCode%>">

<!-- ================= CUSTOMER ================= -->

<div class="parameter-section">

<div class="parameter-group">
<div class="parameter-label">Customer Id</div>

<div class="input-box">

<input type="text"
name="customer_id"
id="customer_id"
class="input-field"
readonly>

<button type="button"
id="customerLookupBtn"
class="icon-btn"
onclick="openLookup('customer')">…</button>

</div>
</div>

<div class="parameter-group">
<div class="parameter-label">Customer Name</div>

<input type="text"
name="customer_name"
id="customerName"
class="input-field"
readonly>

 <!-- 🔹 ONLY LIVE BELOW CUSTOMER NAME -->
    <div style="margin-top:10px;">
        <label>
            <input type="checkbox"
            name="live_only"
            value="Y"> Only Live
        </label>
    </div>

</div>

</div>

<!-- ================= SELECT TYPE ================= -->

<div class="parameter-section">

    <div class="parameter-group">
        <div class="parameter-label ">Select</div>

        <div style="display:flex; align-items:center; gap:15px; ">

            <label>
                <input type="radio"
                name="select_type"
                value="S"
                checked
                onclick="toggleCustomer()"> Single
            </label>
            
            <label>
                <input type="radio"
                name="select_type"
                value="A"
                onclick="toggleCustomer()"> All
            </label>

        </div>

    </div>

</div>

<!-- ================= REPORT TYPE ================= -->

<div class="format-section">

<div class="parameter-label">Report Type</div>

<div class="format-options">

<label>
<input type="radio"
name="reporttype"
value="pdf"
checked> PDF
</label>

<label>
<input type="radio"
name="reporttype"
value="xls"> Excel
</label>

</div>

</div>

<!-- ================= BUTTON ================= -->

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

<!-- ================= SCRIPT ================= -->

<script>

/* 🔹 TOGGLE CUSTOMER FIELD + BUTTON */
function toggleCustomer(){

    let single =
    document.querySelector('input[name="select_type"][value="S"]').checked;

    let custField = document.getElementById("customer_id");
    let custName  = document.getElementById("customerName");
    let btn       = document.getElementById("customerLookupBtn");

    if(single){
        custField.readOnly = false;
        btn.disabled = false;
        btn.style.opacity = "1";
        btn.style.cursor = "pointer";
    }else{
        custField.value = "";
        custName.value  = "";
        custField.readOnly = true;

        btn.disabled = true;
        btn.style.opacity = "0.5";
        btn.style.cursor = "not-allowed";
    }
}

/* 🔹 INIT */
window.onload = function(){
    toggleCustomer();
};

</script>

</body>
</html>