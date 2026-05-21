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
/* ================= SESSION DATA ================= */

String sessionDate = "";
Object obj = session.getAttribute("workingDate");

if (obj != null) {

    if (obj instanceof java.sql.Date) {

        sessionDate =
            new SimpleDateFormat("yyyy-MM-dd")
                .format((java.sql.Date) obj);

    } else {

        sessionDate = obj.toString();
    }
}

if (sessionDate == null || sessionDate.isEmpty()) {

    sessionDate =
        new SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

String isSupportUser =
        (String) session.getAttribute("isSupportUser");

String sessionBranchCode =
        (String) session.getAttribute("branchCode");

if(isSupportUser == null)
    isSupportUser = "N";

if(sessionBranchCode == null)
    sessionBranchCode = "";
%>

<%
/* ================= DOWNLOAD LOGIC ================= */

String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype =
            request.getParameter("reporttype");

    String branchCode =
            request.getParameter("branch_code");

    String productCode =
            request.getParameter("product_code");

    String singleAll =
            request.getParameter("single_all");

    String asOnDate =
            request.getParameter("as_on_date");

    String monthFrom =
            request.getParameter("month_from");

    String monthTo =
            request.getParameter("month_to");

    if(branchCode == null ||
       branchCode.trim().isEmpty()) {

        branchCode = sessionBranchCode;
    }

    /* SECURITY */

    if(!"Y".equalsIgnoreCase(isSupportUser)) {

        branchCode = sessionBranchCode;
    }

    if(productCode == null)
        productCode = "";

    productCode = productCode.trim();

    /* ================= VALIDATION ================= */

    if("S".equals(singleAll) &&
       productCode.equals("")) {

        out.println(
            "<h3 style='color:red'>Please Enter Product Code</h3>");

        return;
    }

    if(asOnDate == null ||
       asOnDate.trim().equals("")) {

        out.println(
            "<h3 style='color:red'>Please Select As On Date</h3>");

        return;
    }

    if(monthFrom == null ||
       monthFrom.trim().equals("")) {

        out.println(
            "<h3 style='color:red'>Please Enter Installment Due From</h3>");

        return;
    }

    if(monthTo == null ||
       monthTo.trim().equals("")) {

        out.println(
            "<h3 style='color:red'>Please Enter Installment Due To</h3>");

        return;
    }

    /* DATE FORMAT */

    String oracleDateStr = "";

    try {

        java.util.Date d =
            new SimpleDateFormat("yyyy-MM-dd")
                .parse(asOnDate);

        oracleDateStr =
            new SimpleDateFormat(
                    "dd-MMM-yyyy",
                    Locale.ENGLISH)
                    .format(d)
                    .toUpperCase();

    } catch(Exception e){

        out.println(
            "<h3 style='color:red'>Invalid Date Format</h3>");

        return;
    }

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        /* ================= SQL ================= */

       String sql = "";

if("S".equals(singleAll)) {

    sql =
    " SELECT rownum as sr, " +
    " account_code, name, product, descr, " +
    " address, open_d, due_d, " +
    " disb, inst, prin, intamt, " +
    " prin_ovd_amt, charges, installment, mobile " +

    " FROM ( " +

    " SELECT " +
    " l.account_code account_code, " +
    " a.name name, " +
    " substr(l.account_code,5,3) product, " +
    " p.description descr, " +

    " (trim(c.address1)||' '||trim(c.address2)||' '||trim(c.address3)) address, " +

    " c.phonemobile mobile, " +

    " to_char(a.dateaccountopen,'DD/MM/YY') open_d, " +
    " to_char(l.accountreviewdate,'DD/MM/YY') due_d, " +

    " nvl(l.disburesed_amount,0) disb, " +
    " nvl(l.installmentamount,0) inst, " +

    " b.ledgerbalance prin, " +
    " nvl(l.interest_receivable,0) intamt, " +
    " nvl(h.principal_overdue,0) prin_ovd_amt, " +

    " (h.principal_overdue + l.interest_receivable + l.postage) charges, " +

    " case " +
    " when l.installmentamount = 0 " +
    " or h.principal_overdue = 0 " +
    " then 0 " +
    " else round(h.principal_overdue/l.installmentamount) " +
    " end installment " +

    " FROM history.tlccoverdueadvance h, " +
    " account.account a, " +
    " account.accountloan l, " +
    " balance.account b, " +
    " headoffice.product p, " +
    " customer.customer c " +

    " WHERE substr(l.account_code,1,4)=? " +

    " AND l.account_code=a.account_code " +
    " AND l.account_code=h.account_code " +
    " AND l.account_code=b.account_code " +

    " AND substr(l.account_code,5,3)=p.product_code " +
    " AND a.customer_id=c.customer_id " +

    " AND substr(l.account_code,5,3)=? " +

    " AND h.ovd_adv_date=? " +

    " ) " +

    " WHERE installment BETWEEN ? AND ? ";

}
else {

    sql =
    " SELECT rownum as sr, " +
    " account_code, name, product, descr, " +
    " address, open_d, due_d, " +
    " disb, inst, prin, intamt, " +
    " prin_ovd_amt, charges, installment, mobile " +

    " FROM ( " +

    " SELECT " +
    " l.account_code account_code, " +
    " a.name name, " +
    " substr(l.account_code,5,3) product, " +
    " p.description descr, " +

    " (trim(c.address1)||' '||trim(c.address2)||' '||trim(c.address3)) address, " +

    " c.phonemobile mobile, " +

    " to_char(a.dateaccountopen,'DD/MM/YY') open_d, " +
    " to_char(l.accountreviewdate,'DD/MM/YY') due_d, " +

    " nvl(l.disburesed_amount,0) disb, " +
    " nvl(l.installmentamount,0) inst, " +

    " b.ledgerbalance prin, " +
    " nvl(l.interest_receivable,0) intamt, " +
    " nvl(h.principal_overdue,0) prin_ovd_amt, " +

    " (h.principal_overdue + l.interest_receivable + l.postage) charges, " +

    " case " +
    " when l.installmentamount = 0 " +
    " or h.principal_overdue = 0 " +
    " then 0 " +
    " else round(h.principal_overdue/l.installmentamount) " +
    " end installment " +

    " FROM history.tlccoverdueadvance h, " +
    " account.account a, " +
    " account.accountloan l, " +
    " balance.account b, " +
    " headoffice.product p, " +
    " customer.customer c " +

    " WHERE substr(l.account_code,1,4)=? " +

    " AND l.account_code=a.account_code " +
    " AND l.account_code=h.account_code " +
    " AND l.account_code=b.account_code " +

    " AND substr(l.account_code,5,3)=p.product_code " +
    " AND a.customer_id=c.customer_id " +

    " AND h.ovd_adv_date=? " +

    " ) " +

    " WHERE installment BETWEEN ? AND ? ";
}

        PreparedStatement ps =
                conn.prepareStatement(sql);

        if("S".equals(singleAll)) {

            ps.setString(1, branchCode);
            ps.setString(2, productCode);
            ps.setDate(
                3,
                java.sql.Date.valueOf(
                    new SimpleDateFormat("yyyy-MM-dd")
                    .parse(asOnDate)
                    .toInstant()
                    .toString()
                    .substring(0,10)
                )
            );

            ps.setInt(4, Integer.parseInt(monthFrom));
            ps.setInt(5, Integer.parseInt(monthTo));

        } else {

            ps.setString(1, branchCode);

            ps.setDate(
                2,
                java.sql.Date.valueOf(
                    new SimpleDateFormat("yyyy-MM-dd")
                    .parse(asOnDate)
                    .toInstant()
                    .toString()
                    .substring(0,10)
                )
            );

            ps.setInt(3, Integer.parseInt(monthFrom));
            ps.setInt(4, Integer.parseInt(monthTo));
        }

        ResultSet rs = ps.executeQuery();

        if(!rs.isBeforeFirst()) {

            response.reset();
            response.setContentType("text/html");

            out.println(
                "<h2 style='color:red;text-align:center;margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        JRResultSetDataSource jrds =
                new JRResultSetDataSource(rs);

        /* ================= REPORT ================= */

        String jasperPath =
            application.getRealPath(
                "/Reports/NPAOverdueReport.jasper");

        JasperReport jasperReport =
            (JasperReport)
                JRLoader.loadObject(
                    new File(jasperPath));

        /* PARAMETERS */

        Map<String,Object> parameters =
                new HashMap<String,Object>();

        parameters.put("branch_code", branchCode);

        parameters.put("as_on_date",
                       oracleDateStr);

        parameters.put("month_from",
                       monthFrom);

        parameters.put("month_to",
                       monthTo);
        
        parameters.put("Product_Code", productCode);

        parameters.put(
            "report_title",
            "NPA OVERDUE REPORT");

        String userId =
            (String) session.getAttribute("userId");

        if(userId == null)
            userId = "admin";

        parameters.put("user_id", userId);

        parameters.put(
            "SUBREPORT_DIR",
            application.getRealPath("/Reports/"));

        parameters.put(
            JRParameter.REPORT_CONNECTION,
            conn);

        JasperPrint jasperPrint =
            JasperFillManager.fillReport(
                jasperReport,
                parameters,
                jrds);

        if(jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println(
                "<h2 style='color:red;text-align:center;margin-top:50px;'>");

            out.println("No Records Found!");

            out.println("</h2>");

            return;
        }

        /* PDF */

        if("pdf".equalsIgnoreCase(reporttype)) {

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"NPA_Overdue_Report.pdf\"");

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

        /* EXCEL */

        else if("xls".equalsIgnoreCase(reporttype)) {

            response.setContentType(
                "application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"NPA_Overdue_Report.xls\"");

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

    } catch(Exception e) {

        response.setContentType("text/html");

        out.println(
            "<h2 style='color:red'>Error Generating Report</h2>");

        out.println("<pre>");

        e.printStackTrace(new PrintWriter(out));

        out.println("</pre>");

    } finally {

        if(conn != null) {

            try {
                conn.close();
            } catch(Exception ex){}
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>

<title>NPA Overdue Report</title>

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/common-report.css">

<link rel="stylesheet"
href="<%=request.getContextPath()%>/css/lookup.css">

<script>
var contextPath = "<%=request.getContextPath()%>";
</script>

<script src="<%=request.getContextPath()%>/js/lookup.js"></script>

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
NPA OVERDUE REPORT
</h1>

<form method="post"
      action="<%=request.getContextPath()%>/Reports/jspFiles/NPAOverdueReport.jsp"
      target="_blank"
      autocomplete="off">

<input type="hidden"
       name="action"
       value="download"/>

<div class="parameter-section">

<!-- BRANCH -->

<div class="parameter-group">

<div class="parameter-label">
Branch Code
</div>

<div class="input-box">

<input type="text"
       name="branch_code"
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

<!-- PRODUCT -->

<div class="parameter-group">

<div class="parameter-label">
Product Code
</div>

<div class="input-box">

<input type="text"
       name="product_code"
       class="input-field">

<button type="button"
        class="icon-btn"
        onclick="openLookup('product')">

...

</button>

</div>

<div class="radio-container">

<label>

<input type="radio"
       name="single_all"
       value="S"
       checked
       onclick="toggleProduct()">

Single

</label>

<label>

<input type="radio"
       name="single_all"
       value="A"
       onclick="toggleProduct()">

All

</label>

</div>

</div>

<!-- AS ON DATE -->

<div class="parameter-group">

<div class="parameter-label">
As On Date
</div>

<input type="date"
       name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>

</div>

<!-- INSTALLMENT FROM -->

<div class="parameter-group">

<div class="parameter-label">
Installment Due From
</div>

<input type="number"
       name="month_from"
       class="input-field"
       min="0"
       required>

</div>

<!-- INSTALLMENT TO -->

<div class="parameter-group">

<div class="parameter-label">
Installment Due To
</div>

<input type="number"
       name="month_to"
       class="input-field"
       min="0"
       required>

</div>

</div>

<!-- REPORT FORMAT -->

<div class="format-section">

<div class="parameter-label">
Report Type
</div>

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

<!-- BUTTON -->

<button type="submit"
        class="download-button">

Generate Report

</button>

</form>

<!-- LOOKUP MODAL -->

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>

<!-- ERROR MESSAGE -->

<div class="error-box">

<%
String err = request.getParameter("error");

if(err != null){
    out.print(err);
}
%>

</div>

</div>

<script>
function toggleProduct(){
    var single =
        document.querySelector('input[name="single_all"][value="S"]').checked;

    var field =
        document.querySelector('input[name="product_code"]');

    if(single){
        field.disabled = false;
    } else {
        field.value = "";
        field.disabled = true;
    }
}

window.onload = toggleProduct;
</script>


</body>
</html>