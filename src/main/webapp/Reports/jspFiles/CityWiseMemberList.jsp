<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*,java.util.*,java.text.*,java.io.*" %>
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
        sessionDate = new SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);
    } else {
        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String isSupportUser     = (String) session.getAttribute("isSupportUser");
String sessionBranchCode = (String) session.getAttribute("branchCode");
String userId            = (String) session.getAttribute("userId");

if(isSupportUser==null) isSupportUser="N";
if(sessionBranchCode==null) sessionBranchCode="";
if(userId==null) userId="";

/* ================= ACTION ================= */

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String branchCode = request.getParameter("branch_code");

    if(branchCode == null || branchCode.trim().equals("")){
        branchCode = sessionBranchCode;
    }

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    String fromCity = request.getParameter("from_city");
    String toCity   = request.getParameter("to_city");
    String asOnDate = request.getParameter("as_on_date");

    /* VALIDATION */

    if(fromCity==null || fromCity.equals("")){
        session.setAttribute("errorMessage","Please Enter From City");
        response.sendRedirect("CityWiseMemberList.jsp");
        return;
    }

    if(toCity==null || toCity.equals("")){
        session.setAttribute("errorMessage","Please Enter To City");
        response.sendRedirect("CityWiseMemberList.jsp");
        return;
    }

    if(asOnDate==null || asOnDate.equals("")){
        session.setAttribute("errorMessage","Please Insert AS On Date");
        response.sendRedirect("CityWiseMemberList.jsp");
        return;
    }

    Connection conn=null;

    try{

        response.reset();
        response.setBufferSize(1024*1024);

        conn = DBConnection.getConnection();

        /* DATE FORMAT */

        String oracleDate =
        new SimpleDateFormat("dd-MMM-yyyy",Locale.ENGLISH)
        .format(new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate))
        .toUpperCase();

        /* LOAD REPORT */

        String jasperPath =
        application.getRealPath("/Reports/bnkrptCityWiseMemberList.jasper");

        JasperReport jasperReport =
        (JasperReport)JRLoader.loadObject(new File(jasperPath));

        /* PARAMETERS */

        Map<String,Object> params = new HashMap<>();

        params.put("branch_code",branchCode);
        params.put("from_city",fromCity);
        params.put("to_city",toCity);
        params.put("as_on_date",oracleDate);
        params.put("user_id",userId);
        params.put("report_title", "CITY WISE SHARE MEMBER LIST");


        params.put("SUBREPORT_DIR",
        application.getRealPath("/Reports/"));

        params.put(JRParameter.REPORT_CONNECTION,conn);

        /* FILL */

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
        out.clear();
        out = pageContext.pushBody();

        /* EXPORT */

        if("pdf".equalsIgnoreCase(reporttype)){

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
            "inline; filename=CityWiseMemberList.pdf");

            JasperExportManager.exportReportToPdfStream(
            jp,response.getOutputStream());
        }
        else{

            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-Disposition",
            "attachment; filename=CityWiseMemberList.xls");

            JRXlsExporter exporter = new JRXlsExporter();

            exporter.setParameter(
            JRXlsExporterParameter.JASPER_PRINT,jp);

            exporter.setParameter(
            JRXlsExporterParameter.OUTPUT_STREAM,
            response.getOutputStream());

            exporter.exportReport();
        }

        return;

    }catch(Exception e){

        Throwable cause = e;

        while(cause.getCause()!=null){
            cause = cause.getCause();
        }

        String msg = cause.getMessage();

        if(msg!=null && msg.contains("ORA-")){
            msg = msg.substring(msg.indexOf("ORA-"));
        }

        session.setAttribute("errorMessage",
        "Error Message = "+msg);

        response.sendRedirect("CityWiseMemberList.jsp");
        return;

    }finally{
        if(conn!=null) try{conn.close();}catch(Exception ex){}
    }
}
%>

<!DOCTYPE html>
<html>
<head>

<title>City Wise Member List</title>

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

<h1 class="report-title">
CITY WISE SHARE MEMBER LIST
</h1>

<form method="post"
action="CityWiseMemberList.jsp"
target="_blank"
autocomplete="off">

<input type="hidden" name="action" value="download"/>

<!-- ================= CITY + DATE (ONE ROW) ================= -->

<div class="parameter-section">

<!-- FROM CITY -->
<div class="parameter-group">
<div class="parameter-label">From City</div>

<div class="input-box">

<input type="text"
name="from_city"
id="city_code"
class="input-field"
required>

<input type="text"
id="cityName"
class="input-field"
readonly
placeholder="City Name">

<button type="button"
class="icon-btn"
onclick="openLookup('city')">…</button>

</div>
</div>


<!-- TO CITY -->
<div class="parameter-group">
<div class="parameter-label">To City</div>

<div class="input-box">

<input type="text"
name="to_city"
id="city_code"
class="input-field"
required>

<input type="text"
id="cityName"
class="input-field"
readonly
placeholder="City Name">

<button type="button"
class="icon-btn"
onclick="openLookup('city')">…</button>

</div>
</div>

<!-- AS ON DATE -->
<div class="parameter-group">
<div class="parameter-label">As On Date</div>

<input type="date"
name="as_on_date"
value="<%=sessionDate%>"
class="input-field"
required>
</div>

</div>

<!-- ================= REPORT TYPE ================= -->

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

<!-- ================= BUTTON ================= -->

<button type="submit" class="download-button">
Generate Report
</button>

</form>

</div>

<!-- LOOKUP POPUP -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>