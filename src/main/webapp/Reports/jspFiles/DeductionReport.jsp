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

    String salaryDate =
        request.getParameter("from_d");

    String deductionType =
        request.getParameter("deduction_type");

    String isEDChecked =
        request.getParameter("isEDChecked");

    String isReportChecked =
        request.getParameter("isReportChecked");

    String empBranch =
        request.getParameter("emp_br_nm");

    if(branchCode == null || branchCode.trim().isEmpty()){
        branchCode = sessionBranchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)){
        branchCode = sessionBranchCode;
    }

    /* VALIDATION */

    if(salaryDate == null || salaryDate.trim().isEmpty()){

        out.println(
        "<h3 style='color:red'>Please Enter Salary Date</h3>");

        return;
    }

    if(deductionType == null || deductionType.trim().isEmpty()){

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
           DATE CONVERSION
        ===================================================== */

        String oracleMonth = "";

        try{

        	oracleMonth = salaryDate;

        }catch(Exception e){

            out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>");

            return;
        }

        /* =====================================================
           SQL CONDITION
        ===================================================== */

        String branchCondition = "";

        if("B".equals(isReportChecked)){

            branchCondition =
                " and em.branch_code = '" +
                empBranch + "' ";
        }

        String sql =
        "select em.emp_no,em.emp_name," +
        "nvl(em.branch_code,' ') branch_code," +
        "payroll.Fn_Get_Emp_Branch('"+branchCode+"') \"PAYROLL.FN_GET_EMP_BRANCH(:1)\"," +
        "ed.description," +
        "pt.amount," +
        "(select amount basic FROM payroll.payroll_table pt1 " +
        "where pt.emp_no=pt1.emp_no and ed_no = 30 " +
        "and month_year = '"+oracleMonth+"') BASIC_SAL," +
        "em.PFNUMBER," +
        "nvl(FN_GET_BR_NAME(em.branch_code),' ') br_name," +
        "ed.ed_no," +
        "nvl(em.desig_code,' ') desig_code," +
        "(em.branch_code ||','|| FN_GET_BR_NAME(em.branch_code)) BRANCH_NM " +
        "from payroll.employee_mst em ," +
        "payroll.payroll_table pt ," +
        "payroll.earning_deduction_master ed " +
        "where em.emp_no=pt.emp_no " +
        "and pt.ed_no= ed.ed_no " +
        "and ed.ed_no = '"+deductionType+"' " +
        "and pt.month_year = '"+oracleMonth+"' " +
        "and em.left_code=1 " +
        "and pt.amount>0 " +
        branchCondition +
        " order by em.branch_code,em.desig_code,em.emp_no";

        Statement st =
            conn.createStatement(
                ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);

        ResultSet rs = st.executeQuery(sql);

        if(!rs.next()){

            response.reset();
            response.setContentType("text/html");

            out.println(
            "<h2 style='color:red;text-align:center;margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        rs.beforeFirst();

    /* =====================================================
        LOAD JASPER
     ===================================================== */

     String jasperName = "";

     /*
        D = Deduction
        R = Earning

        ED NO 85 special handling
     */

     if("D".equals(isEDChecked)){

         if("85".equals(deductionType)){

             jasperName =
                 "DeductionReport (Deduction).jasper";

         }else{

             jasperName =
                 "DeductionReport (Deductionwithout85).jasper";
         }

     }else{

         if("85".equals(deductionType)){

             jasperName =
                 "DeductionReport(Earning).jasper";

         }else{

             jasperName =
                 "DeductionReport(Earningwithout85).jasper";
         }
     }

     String jasperPath =
         application.getRealPath(
         "/Reports/" + jasperName);

     File file = new File(jasperPath);

     if(!file.exists()){

         throw new RuntimeException(
             "Jasper file not found : " + jasperPath);
     }

     JasperReport jasperReport =
         (JasperReport)JRLoader.loadObject(file);
  /* =====================================================
     PARAMETERS
  ===================================================== */

  Map<String,Object> parameters =
      new HashMap<String,Object>();

  parameters.put("branch_code", branchCode);

  parameters.put("as_on_date", displayDate);

  parameters.put(
      "report_title",

      "D".equals(isEDChecked)
      ? "DEDUCTION REPORT"
      : "EARNING REPORT");

  parameters.put("user_id", userId);

  parameters.put("month_year", oracleMonth);

  parameters.put("ed_no", deductionType);

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

         response.setContentType("application/pdf");

         response.setHeader(
             "Content-Disposition",
             "inline; filename=\"DeductionReport.pdf\"");

         ServletOutputStream outStream =
             response.getOutputStream();

         JasperExportManager.exportReportToPdfStream(
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
             "attachment; filename=\"DeductionReport.xls\"");

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
     "<h3 style='color:red'>Error Generating Report</h3>");

     e.printStackTrace(new PrintWriter(out));

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

<title>Deduction Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js?v=5"></script>

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
#branchDiv {
    width: 100%;
    clear: both;
    margin-top: 10px;
}

#branchDiv .parameter-group {
    display: block;
    width: 100%;
}

#emp_br_nm {
    display: block;
    width: 300px;
    margin-top: 8px;
}
</style>

</head>

<body>

<div class="report-container">

<h1 class="report-title">
DEDUCTION REPORT
</h1>

<form method="post"
   action="<%=request.getContextPath()%>/Reports/jspFiles/DeductionReport.jsp"
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
  SALARY DATE
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Salary Date
</div>

<input type="text"
    name="from_d"
    id="from_d"
    class="input-field"
    value=""
    placeholder="MM/YYYY"
    maxlength="7"
    required>

</div>

<!-- =====================================================
  DEDUCTION / EARNING
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Select Type
</div>

<div class="radio-container">

<label>
<input type="radio"
    name="isEDChecked"
    value="D"
    checked>
Deduction
</label>

<label>
<input type="radio"
    name="isEDChecked"
    value="R">
Earning
</label>

</div>

</div>

<!-- =====================================================
  BRANCH / ALL
===================================================== -->

<div class="parameter-group">

<div class="parameter-label">
Select Report
</div>

<div class="radio-container">

<label>
<input type="radio"
    name="isReportChecked"
    value="B"
    onclick="toggleBranchDiv()">
Branch
</label>

<label>
<input type="radio"
    name="isReportChecked"
    value="A"
    checked
    onclick="toggleBranchDiv()">
All
</label>

</div>

</div>

</div>

<!-- =====================================================
  BRANCH DROPDOWN
===================================================== -->

<div id="branchDiv">

<div class="parameter-group"
  style="margin-top:20px;">

<div class="parameter-label">
Employee Branch
</div>

<select name="emp_br_nm"
     id="emp_br_nm"
     class="input-field">

<option value="">--Select Branch--</option>

<%
Connection brConn = null;

try{

 brConn = DBConnection.getConnection();

 Statement brStmt =
     brConn.createStatement();

 ResultSet brRs =
		    brStmt.executeQuery(
		    "SELECT BRANCH_CODE, NAME " +
		    "FROM HEADOFFICE.BRANCH " +
		    "ORDER BY BRANCH_CODE");
 
 while(brRs.next()){
%>

<option value="<%=brRs.getString("BRANCH_CODE")%>">
<%=brRs.getString("NAME")%>
</option>
<%
 }

}catch(Exception e){
 e.printStackTrace();
}finally{

 if(brConn!=null){
     try{
         brConn.close();
     }catch(Exception ex){}
 }
}
%>

</select>

</div>

</div>

<!-- =====================================================
  DEDUCTION TYPE
===================================================== -->

<div class="parameter-group"
  style="margin-top:20px;">

<div class="parameter-label">
Deduction Type
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
    id="deductionTypeName"
    class="input-field"
    placeholder="Description"
    readonly>

<input type="text"
    id="shortDescription"
    class="input-field"
    placeholder="Short Description"
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

<!-- =====================================================
  ERROR
===================================================== -->

<div id="errorDiv"
  class="error-msg"></div>

<!-- =====================================================
  BUTTON
===================================================== -->

<button type="submit"
     class="download-button">
Generate Report
</button>

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

<script>

/* =====================================================
DATE FORMAT
===================================================== */

function formatDate(field){

    let value =
        field.value.replace(/\D/g,'');

    if(value.length > 2){

        value =
            value.substring(0,2) + '/' +
            value.substring(2,6);
    }

    field.value = value;
}
/* =====================================================
TOGGLE BRANCH
===================================================== */

function toggleBranchDiv(){

 let branchRadio =
     document.querySelector(
     'input[name="isReportChecked"][value="B"]');

 let branchDiv =
     document.getElementById("branchDiv");

 if(branchRadio.checked){
     branchDiv.style.display = "block";
 }else{
     branchDiv.style.display = "none";
 }
}

/* =====================================================
VALIDATION
===================================================== */

function validateForm(){

 let salaryDate =
     document.getElementById("from_d").value;

 let deductionType =
	    document.getElementById("ed_no").value;

 let errorDiv =
     document.getElementById("errorDiv");

 errorDiv.innerHTML = "";

 if(salaryDate.trim() === ""){

     errorDiv.innerHTML =
         "Please Enter Salary Date";

     return false;
 }

 if(deductionType.trim() === ""){

     errorDiv.innerHTML =
         "Please Enter Deduction Type";

     return false;
 }

 return true;
}
window.onload = function () {
    toggleBranchDiv();
};
</script>

</body>
</html>
                