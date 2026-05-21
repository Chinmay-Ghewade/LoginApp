<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
/* =========================================================
   SESSION DATA
========================================================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if(obj != null){

    if(obj instanceof java.sql.Date){

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
            .format((java.sql.Date)obj);

    }else{

        sessionDate = obj.toString();
    }
}

if(sessionDate == null || sessionDate.isEmpty()){

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
        .format(new java.util.Date());
}

String displayDate = "";

try{

    java.util.Date d =
        new SimpleDateFormat("yyyy-MM-dd")
        .parse(sessionDate);

    displayDate =
        new SimpleDateFormat("dd/MM/yyyy")
        .format(d);

}catch(Exception e){

    displayDate = "";
}

String sessionBranchCode =
    (String)session.getAttribute("branchCode");

String isSupportUser =
    (String)session.getAttribute("isSupportUser");

String userId =
    (String)session.getAttribute("userId");

if(sessionBranchCode == null)
    sessionBranchCode = "";

if(isSupportUser == null)
    isSupportUser = "N";

if(userId == null)
    userId = "admin";
%>

<%
/* =========================================================
   DOWNLOAD / REPORT GENERATION
========================================================= */

String action = request.getParameter("action");

if("download".equals(action)){

    String reportType =
        request.getParameter("reporttype");

    String branchCode =
        request.getParameter("branch_code");

    String year =
        request.getParameter("year");

    String monthNo =
        request.getParameter("month_no");

    String monthName =
        request.getParameter("month_nm");

    String deductionType =
        request.getParameter("deduction_type");

    String deductionName =
        request.getParameter("deduction_name");

    if(branchCode == null ||
       branchCode.trim().isEmpty()){

        branchCode = sessionBranchCode;
    }

    /* =====================================================
       SECURITY
    ===================================================== */

    if(!"Y".equalsIgnoreCase(isSupportUser)){

        branchCode = sessionBranchCode;
    }

    if(year == null) year = "";
    if(monthNo == null) monthNo = "";
    if(monthName == null) monthName = "";
    if(deductionType == null) deductionType = "";
    if(deductionName == null) deductionName = "";

    year = year.trim();
    monthNo = monthNo.trim();
    deductionType = deductionType.trim();

    /* =====================================================
       VALIDATION
    ===================================================== */

    if(year.equals("")){

        out.println(
        "<h3 style='color:red'>Please Enter Year</h3>");

        return;
    }

    if(monthNo.equals("")){

        out.println(
        "<h3 style='color:red'>Please Enter Month</h3>");

        return;
    }

    if(deductionType.equals("")){

        out.println(
        "<h3 style='color:red'>Please Enter Deduction Type</h3>");

        return;
    }

    Connection conn = null;

    try{

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* =====================================================
           SQL
        ===================================================== */

        String monthYear =
            monthNo + "/" + year;

        String sql =

        "select " +

        "ROW_NUMBER() OVER(ORDER BY TO_NUMBER(p.emp_no)) serial," +

        "p.emp_no," +

        "'   ' || p.emp_name emp_name," +

        "ed_no," +

        "month_year," +

        "amount," +

        "m.basic_sal " +

        "from payroll.payroll_table p, " +
        "payroll.employee_mst m " +

        "where p.emp_no = m.emp_no " +

        "and ed_no = '" + deductionType + "' " +

        "and month_year = '" + monthYear + "' " +

        "and amount <> 0";

        Statement st =
            conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.CONCUR_READ_ONLY);

        ResultSet rs =
            st.executeQuery(sql);

        if(!rs.next()){

            response.reset();
            response.setContentType("text/html");

            out.println(
            "<h2 style='color:red;"
          + "text-align:center;"
          + "margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        rs.beforeFirst();

        /* =====================================================
           LOAD JASPER
        ===================================================== */

        String jasperPath =
            application.getRealPath(
            "/Reports/DeductionSalary.jasper");

        File file =
            new File(jasperPath);

        if(!file.exists()){

            throw new RuntimeException(
            "Jasper file not found : "
            + jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport)
            JRLoader.loadObject(file);

        /* =====================================================
           PARAMETERS
        ===================================================== */

        Map<String,Object> parameters =
            new HashMap<String,Object>();

        parameters.put("branch_code",branchCode);
        parameters.put("as_on_date",displayDate);
        parameters.put("report_title","SALARY DEDUCTION");
        parameters.put("month_year",monthYear);
        parameters.put("ed_no",deductionType);
        parameters.put("deduction_name",deductionName);
        parameters.put("user_id",userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn);

        /* =====================================================
           FILL REPORT
        ===================================================== */

        JRResultSetDataSource jrDataSource =
            new JRResultSetDataSource(rs);

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                jrDataSource);

        /* =====================================================
           EXPORT PDF
        ===================================================== */

        if("pdf".equalsIgnoreCase(reportType)){

            response.setContentType(
                "application/pdf");

            response.setHeader(
                "Content-Disposition",

                "inline; filename=\"DeductionSalary.pdf\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JasperExportManager
                .exportReportToPdfStream(
                    jasperPrint,
                    outStream);

            outStream.flush();
            outStream.close();

            return;
        }

        /* =====================================================
           EXPORT EXCEL
        ===================================================== */

        else if("xls".equalsIgnoreCase(reportType)){

            response.setContentType(
            "application/vnd.ms-excel");

            response.setHeader(
            "Content-Disposition",

            "attachment; filename=\"DeductionSalary.xls\"");

            ServletOutputStream outStream =
                response.getOutputStream();

            JRXlsExporter exporter =
                new JRXlsExporter();

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

    }catch(Exception e){

        out.println(
        "<h3 style='color:red'>"
      + "Error Generating Report"
      + "</h3>");

        e.printStackTrace(
            new PrintWriter(out));

    }finally{

        if(conn != null){

            try{
                conn.close();
            }catch(Exception ex){}
        }
    }
}
%>

<!DOCTYPE html>
<html>

<head>

<title>Salary Deduction</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath =
    "<%=request.getContextPath()%>";
</script>

<script
src="<%=request.getContextPath()%>/js/lookup.js?v=6">
</script>

<style>
.radio-container {
    margin-top:8px;
    display:flex;
    gap:40px;
}

.input-field:disabled {
    background-color:#e0e0e0;
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
SALARY DEDUCTION
</h1>

<form method="post"
   action="<%=request.getContextPath()%>/Reports/jspFiles/DeductionSalary.jsp"
   target="_blank"
   autocomplete="off"
   onsubmit="return validateForm();">

<input type="hidden"
    name="action"
    value="download"/>

<div class="parameter-section">

<!-- =====================================================
  BRANCH CODE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
    name="branch_code"
    id="branch_code"
    class="input-field"
    value="<%=sessionBranchCode%>"
    <%= !"Y".equalsIgnoreCase(isSupportUser)
        ? "readonly"
        : "" %>
    required>

<% if("Y".equalsIgnoreCase(isSupportUser)){ %>

<button type="button"
     class="icon-btn"
     onclick="openLookup('branch')">
...
</button>

<% } %>

</div>
</div>

<!-- =====================================================
  YEAR
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Year
</div>

<input type="text"
    name="year"
    id="year"
    class="input-field"
    maxlength="4"
    required>

</div>

<!-- =====================================================
  MONTH
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Month
</div>

<div class="input-box">

<input type="text"
    name="month_no"
    id="month_no"
    class="input-field"
    required>

<button type="button"
     class="icon-btn"
     onclick="openLookup('month')">
...
</button>

<input type="text"
    name="month_nm"
    id="month_nm"
    class="input-field"
    placeholder="Month Name"
    readonly>

</div>

</div>

<!-- =====================================================
  DEDUCTION TYPE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
ED Number
</div>

<div class="input-box">

<input type="text"
    name="deduction_type"
    id="ed_no"
    class="input-field"
    placeholder="ED No"
    required>

<button type="button"
     class="icon-btn"
     onclick="openLookup('deductionType')">
...
</button>

<input type="text"
    name="deduction_name"
    id="deductionTypeName"
    class="input-field"
    placeholder="Description"
    readonly>

</div>

</div>

<!-- =====================================================
  REPORT TYPE
===================================================== -->

<div class="parameter-group"
 style="margin-top:20px;">

<div class="parameter-label">
Report Type
</div>

<div class="radio-container">

<label>
<input type="radio"
    name="reporttype"
    value="pdf"
    checked>
PDF
</label>

<label>
<input type="radio"
    name="reporttype"
    value="xls">
Excel
</label>

</div>

</div>

</div>

<!-- =====================================================
  ERROR DIV
===================================================== -->

<div id="errorDiv"
 class="error-msg"
 style="margin-top:15px;color:red;font-weight:bold;">
</div>

<!-- =====================================================
  BUTTONS
===================================================== -->

<div style="margin-top:30px;">

<button type="submit"
     class="download-button">

Generate Report

</button>

</div>

</form>

</div>

<!-- =====================================================
  LOOKUP MODAL
===================================================== -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

</body>
</html>