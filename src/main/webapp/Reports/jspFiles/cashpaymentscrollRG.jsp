<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="db.DBConnection" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>

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
String branchCode = request.getParameter("branch_code");
String asOnDateUI = request.getParameter("as_on_date");

if (branchCode == null) branchCode = "";

if (asOnDateUI == null || asOnDateUI.trim().isEmpty()) {
    asOnDateUI = sessionDate;
}

/* =====================================================
   DOWNLOAD SECTION
===================================================== */
if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");
    String userId = (String) session.getAttribute("userId");

    Connection conn = null;
    ServletOutputStream sos = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        /* DATE FORMAT */
        SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
        String oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        String reportsDir = application.getRealPath("/Reports") + File.separator;

        String mainReportPath = reportsDir + "cashpaymentscrollRG.jasper";
        String subReportPath  = reportsDir + "subReportHeader.jasper";

        System.out.println("Main Report Path: " + mainReportPath);
        System.out.println("File Exists? " + new File(mainReportPath).exists());

        JasperReport mainReport =
                (JasperReport) JRLoader.loadObject(new File(mainReportPath));

        JasperReport subReport =
                (JasperReport) JRLoader.loadObject(new File(subReportPath));

        Map<String, Object> params = new HashMap<>();
        params.put("branch_code", branchCode);
        params.put("as_on_date", oracleDate);
        params.put("user_id", userId);
        params.put("report_title", "Cash Payment Scroll Report");
        params.put("SUBREPORT_DIR", reportsDir);
        params.put("subReportHeader.jasper", subReport);

        JasperPrint jasperPrint =
                JasperFillManager.fillReport(mainReport, params, conn);
        
     // 🔥 NO DATA CHECK
        // 🔥 CHECK IF NO DATA
if (jasperPrint.getPages().isEmpty()) {

    response.reset();
    response.setContentType("text/html");

    out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
    out.println("No Records Found!");
    out.println("</h2>");

    return;
}
        sos = response.getOutputStream();

        if ("pdf".equalsIgnoreCase(reportType)) {

            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"CashPaymentScroll.pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);

        } else {

            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"CashPaymentScroll.xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.exportReport();
        }

        sos.flush();
        return;

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Cash Payment Scroll: " + e.getMessage());
        response.sendRedirect("cashpaymentscrollRG.jsp?error=true");
        return;

    } finally {
        if (sos != null) try { sos.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<%
/* =====================================================
   UI SECTION (ONLY IF NOT DOWNLOAD)
===================================================== */
if (!"download".equals(action)) {
%>

<!DOCTYPE html>
<html>
<head>
    <title>Cash Payment Scroll Report</title>
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
</style>
</head>

<body>

<div class="report-container">

    <%
        String errorMessage = (String) session.getAttribute("errorMessage");
        if (errorMessage != null) {
    %>
        <div class="error-message">
            <%= errorMessage %>
        </div>
    <%
            session.removeAttribute("errorMessage");
        }
    %>

    <h1 class="report-title">CASH PAYMENT SCROLL REPORT</h1>

    <form method="post"
          action="<%=request.getRequestURI()%>"
          target="_blank"
          id="reportForm">

        <input type="hidden" name="action" value="download"/>

        <div class="parameter-section">
            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <div class="input-box">
    <input type="text"
           id="branch_code"
           name="branch_code"
           class="input-field"
           value="<%= sessionBranchCode %>"
           <%= !"Y".equalsIgnoreCase(isSupportUser.trim()) ? "readonly" : "" %> >

    <% if ("Y".equalsIgnoreCase(isSupportUser.trim())) { %>
        <button type="button"
                class="icon-btn"
                onclick="openLookup('branch')">…</button>
    <% } %>
    
</div>
            </div>
            
            <div class="parameter-group">
    <div class="parameter-label">Description</div>
   <input type="text" id="branchName" class="input-field" readonly>
</div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" name="as_on_date"
                       class="input-field"
                       value="<%= sessionDate %>" required>
            </div>
        </div>

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

<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>


</body>
</html>

<%
}
%>
