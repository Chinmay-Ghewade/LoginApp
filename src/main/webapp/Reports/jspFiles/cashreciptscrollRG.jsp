<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
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
String branchCode = request.getParameter("branch_code");
String asOnDateUI = request.getParameter("as_on_date");

if (branchCode == null) branchCode = "";

if (asOnDateUI == null || asOnDateUI.trim().isEmpty()) {
    asOnDateUI = sessionDate;
}

if ("download".equals(action)) {

    String reportType = request.getParameter("reporttype");
    String userId = (String) session.getAttribute("userId");

    Connection conn = null;

    try {

        /* =========================
           RESPONSE SETUP
           ========================= */
        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        /* =========================
           DATE FORMAT FOR ORACLE
           ========================= */
        String oracleDate;
        try {
            SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat outFmt = new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH);
            oracleDate = outFmt.format(inFmt.parse(asOnDateUI)).toUpperCase();
        } catch (Exception e) {
            oracleDate = asOnDateUI;
        }

        /* =========================
           REPORT PATHS
           ========================= */
        String reportsDir = application.getRealPath("/Reports") + File.separator;

        String mainReportPath = reportsDir + "cashreciptscrollrg.jrxml";
        String subReportPath  = reportsDir + "subReportHeader.jrxml";

        JasperReport jasperReport = JasperCompileManager.compileReport(mainReportPath);
        JasperReport subJasperReport = JasperCompileManager.compileReport(subReportPath);

        /* =========================
           PARAMETERS
           ========================= */
        Map<String, Object> params = new HashMap<>();
        params.put("branch_code", branchCode);
        params.put("user_id", userId);
        params.put("as_on_date", oracleDate);
        params.put("report_title", "Cash Receipt Scroll Report");
        params.put("SUBREPORT_DIR", reportsDir);
        params.put("subReportHeader.jasper", subJasperReport);

        /* =========================
           FILL REPORT
           ========================= */
        JasperPrint jasperPrint =
                JasperFillManager.fillReport(jasperReport, params, conn);

     // 🔥 CHECK IF NO DATA
        if (jasperPrint.getPages().isEmpty()) {

            response.reset();
            response.setContentType("text/html");

            out.println("<h2 style='color:red;text-align:center;margin-top:50px;'>");
            out.println("No Records Found!");
            out.println("</h2>");

            return;
        }
        
        ServletOutputStream sos = response.getOutputStream();

        /* =========================
           EXPORT
           ========================= */
        if ("pdf".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"CashReceiptScroll.pdf\""
            );

            JasperExportManager.exportReportToPdfStream(jasperPrint, sos);
            sos.flush();
            return;

        } else if ("xls".equalsIgnoreCase(reportType)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"CashReceiptScroll.xls\""
            );

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, sos);
            exporter.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
            exporter.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
            exporter.exportReport();

            sos.flush();
            return;
        }

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("errorMessage",
                "Error generating Cash Receipt Scroll: " + e.getMessage());
        response.sendRedirect("cashreciptscrollRG.jsp?error=true");
        return;
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Cash Receipt Scroll Report</title>
    <link rel="stylesheet"href="<%=request.getContextPath()%>/css/common-report.css?v=4">
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

    <h1 class="report-title">CASH RECEIPT SCROLL REPORT</h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/cashreciptscrollRG.jsp"
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
    <div class="parameter-label">Branch Name</div>
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

        <button type="submit"
                class="download-button"
                id="downloadBtn">
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