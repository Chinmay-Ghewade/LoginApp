<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page buffer="none" %>

<%@ page import="java.sql.*, java.util.*, java.io.*, java.text.SimpleDateFormat" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.util.JRLoader" %>
<%@ page import="db.DBConnection" %>

<%
/* =========================
   SESSION DATE
   ========================= */
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

/* =========================
   USER ID
   ========================= */
String userId = (String) session.getAttribute("userId");
if (userId == null) userId = "SYSTEM";
%>

<%
String action = request.getParameter("action");

/* =========================
   DOWNLOAD REPORT
   ========================= */
if ("download".equals(action)) {

    String reporttype = request.getParameter("reporttype");
    String bankCode   = request.getParameter("bank_code");
    String branchCode = request.getParameter("branch_code");
    String asOnDate   = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        response.reset();
        response.setBufferSize(1024 * 1024);

        conn = DBConnection.getConnection();

        String oracleDateStr;

        if (asOnDate != null && !asOnDate.trim().isEmpty()) {
            java.util.Date utilDate =
                    new SimpleDateFormat("yyyy-MM-dd").parse(asOnDate);

            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(utilDate)
                            .toUpperCase();
        } else {
            oracleDateStr =
                    new SimpleDateFormat("dd-MMM-yyyy", Locale.ENGLISH)
                            .format(new java.util.Date())
                            .toUpperCase();
        }

        if (bankCode == null || bankCode.isEmpty()) bankCode = "0100";
        if (branchCode == null || branchCode.isEmpty()) branchCode = "0002";

        /* =========================
        TALLY MESSAGE (STRING ONLY)
        ========================= */
     String tallyMessage =
             checkTransferClearingTally(conn, oracleDateStr, bankCode, branchCode);

     request.setAttribute("tallyMessage", tallyMessage);

        
        String reportDir = application.getRealPath("/Reports/");
        String jasperPath = reportDir + "daybookRG.jasper";

        JasperReport jasperReport =
                (JasperReport) JRLoader.loadObject(new File(jasperPath));

        Map<String, Object> parameters = new HashMap<>();
        parameters.put("bank_code", bankCode);
        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDateStr);
        parameters.put("session_date", oracleDateStr);
        parameters.put("report_title", "DAY BOOK REPORT");
        parameters.put("user_id", userId);
        parameters.put("SUBREPORT_DIR", reportDir);
        parameters.put("TALLY_MESSAGE", tallyMessage);
        parameters.put("IMAGE_PATH", application.getRealPath("/images/UPSB MONO.png"));

        JasperPrint jp =
                JasperFillManager.fillReport(jasperReport, parameters, conn);

        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();   // VERY IMPORTANT

            response.setContentType("application/pdf");

            response.setHeader(
                "Content-Disposition",
                "inline; filename=\"Daybook_Report.pdf\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JasperExportManager.exportReportToPdfStream(jp, outStream);

            outStream.flush();
            outStream.close();

            return;
        }
        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();

            response.setContentType("application/vnd.ms-excel");

            response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"Daybook_Report.xls\""
            );

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jp);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);
            exporter.exportReport();

            outStream.flush();
            outStream.close();

            return;
        }
    } catch (Exception e) {
        e.printStackTrace(new PrintWriter(out));
        return;
    } finally {
        if (conn != null) conn.close();
    }
}
%>
<%!
    /* =========================================================
       CHECK TRANSFER / CLEARING TALLY
       ========================================================= */
    private String checkTransferClearingTally(Connection conn,
                                              String oracleDate,  // Already in DD-MMM-YYYY format
                                              String bankCode,
                                              String branchCode)
            throws SQLException {

        StringBuilder query = new StringBuilder();
        query.append("SELECT SUM(RECEIPT_TRANSFER) AS TRANSFER_RECEIPT, ")
             .append("SUM(PAYMENT_TRANSFER) AS TRANSFER_PAYMENT, ")
             .append("SUM(RECEIPT_CLEARING) AS CLEARING_RECEIPT, ")
             .append("SUM(PAYMENT_CLEARING) AS CLEARING_PAYMENT ")
             .append("FROM ( ")
             .append(" SELECT ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'TRCR' THEN AMOUNT ELSE 0 END) RECEIPT_TRANSFER, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'TRDR' THEN AMOUNT ELSE 0 END) PAYMENT_TRANSFER, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CLCR' THEN AMOUNT ELSE 0 END) RECEIPT_CLEARING, ")
             .append(" SUM(CASE WHEN TRANSACTIONINDICATOR_CODE = 'CLDR' THEN AMOUNT ELSE 0 END) PAYMENT_CLEARING ")
             .append(" FROM TRANSACTION.TRANSACTION_HT_VIEW ")
             .append(" WHERE TXN_DATE = TO_DATE('").append(oracleDate).append("','DD-MON-YYYY') ")
             .append(" AND BRANCH_CODE = '").append(branchCode).append("' ")
             .append(" AND TRANSACTIONSTATUS = 'A' ")
             .append(" AND TXN_NUMBER > 0 ")
             .append(")");

        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query.toString());

        String tallyMessage = " Day Book Tallied.";

        if (rs.next()) {
            double trR = rs.getDouble("TRANSFER_RECEIPT");
            double trP = rs.getDouble("TRANSFER_PAYMENT");
            double clR = rs.getDouble("CLEARING_RECEIPT");
            double clP = rs.getDouble("CLEARING_PAYMENT");

            if (trR != trP && clR != clP) {
                tallyMessage = "** Transfer And Clearing Not Tallied.";
            } else if (trR != trP) {
                tallyMessage = "** Transfer Not Tallied.";
            } else if (clR != clP) {
                tallyMessage = "** Clearing Not Tallied.";
            }
        }

        rs.close();
        stmt.close();

        return tallyMessage;
    }

%>

<!DOCTYPE html>
<html>
<head>
<title>DAYBOOK REPORT</title>

<!-- CSS -->
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css?v=5">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css?v=5">

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

<h1 class="report-title">DAYBOOK REPORT</h1>

<form method="post" target="_blank">

<input type="hidden" name="action" value="download"/>

<div class="parameter-section">

    <!-- BRANCH -->
    <div class="parameter-group">
        <div class="parameter-label">Branch Code</div>

        <div class="input-box">
            <input type="text" id="branch_code" name="branch_code" class="input-field">
            <button type="button" class="icon-btn" onclick="openLookup('branch')">…</button>
        </div>
    </div>

    <div class="parameter-group">
        <div class="parameter-label">Branch Name</div>
        <input type="text" id="branchName" class="input-field" readonly>
    </div>

    <!-- DATE -->
    <div class="parameter-group">
        <div class="parameter-label">As On Date</div>
        <input type="date" name="as_on_date"
               class="input-field"
               value="<%=sessionDate%>" required>
    </div>

</div>

<div class="format-section">
    <label><input type="radio" name="reporttype" value="pdf" checked> PDF</label>
    <label><input type="radio" name="reporttype" value="xls"> Excel</label>
</div>

<button type="submit" class="download-button">
    Generate Report
</button>

</form>

</div>


<!-- BRANCH POPUP -->
<div id="lookupModal" class="modal">
    <div class="modal-content">
        <button onclick="closeLookup()" style="float:right;">✖</button>
        <div id="lookupTable"></div>
    </div>
</div>


</body>
</html>