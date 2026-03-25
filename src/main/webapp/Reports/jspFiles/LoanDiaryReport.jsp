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
/* =========================
   SESSION HANDLING (FIXED)
   ========================= */

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

// fallback date
if (sessionDate == null || sessionDate.isEmpty()) {
    sessionDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
            .format(new java.util.Date());
}

%>

<%
String action = request.getParameter("action");

if ("download".equals(action)) {

    String reporttype  = request.getParameter("reporttype");
    String accountCode = request.getParameter("account_code");
    String branchCode  = request.getParameter("branch_code");
    String asOnDate    = request.getParameter("as_on_date");

    Connection conn = null;

    try {

        /* =========================
           RESPONSE SETUP
           ========================= */
        response.reset();
        response.setBufferSize(1024 * 1024);
        response.setHeader("Cache-Control", "no-cache");
        response.setDateHeader("Expires", 0);

        conn = DBConnection.getConnection();

        /* =========================
           VALIDATION
           ========================= */
        if (accountCode == null || accountCode.trim().equals("")) {
            throw new RuntimeException("Account Code is required");
        }

        /* =========================
           DATE FORMAT (LIKE SERVLET)
           ========================= */
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

        /* =========================
           LOAD JASPER
           ========================= */
        String jasperPath =
            application.getRealPath("/Reports/LoanDiaryReport.jasper");

        File jasperFile = new File(jasperPath);

        if (!jasperFile.exists()) {
            throw new RuntimeException("Jasper file not found: " + jasperPath);
        }

        JasperReport jasperReport =
            (JasperReport) JRLoader.loadObject(jasperFile);

        /* =========================
           PARAMETERS
           ========================= */
        Map<String, Object> parameters = new HashMap<>();

        parameters.put("account_code", accountCode);
        parameters.put("branch_code", branchCode);
        parameters.put("as_on_date", oracleDateStr);

        String userId = (String) session.getAttribute("userId");

        parameters.put("user_id", userId);
        parameters.put("SUBREPORT_DIR",
            application.getRealPath("/Reports/"));
        parameters.put("IMAGE_PATH",
            application.getRealPath("/images/logo.png"));

        /* =========================
           FILL REPORT
           ========================= */
        JasperPrint jasperPrint =
            JasperFillManager.fillReport(jasperReport, parameters, conn);

        /* =========================
           EXPORT
           ========================= */
        if ("pdf".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/pdf");
            response.setHeader(
                "Content-Disposition",
                "inline; filename=LoanDiaryReport.pdf"
            );

            ServletOutputStream outStream = response.getOutputStream();
            JasperExportManager.exportReportToPdfStream(jasperPrint, outStream);

            outStream.flush();
            outStream.close();
            return;
        }

        else if ("xls".equalsIgnoreCase(reporttype)) {

            response.reset();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader(
                "Content-Disposition",
                "attachment; filename=LoanDiaryReport.xls"
            );

            ServletOutputStream outStream = response.getOutputStream();

            JRXlsExporter exporter = new JRXlsExporter();
            exporter.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);
            exporter.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, outStream);

            exporter.exportReport();

            outStream.flush();
            outStream.close();
            return;
        }

    } catch (Exception e) {

        response.reset();
        response.setContentType("text/html");

        out.println("<h2 style='color:red'>Error Generating Loan Diary Report</h2>");
        out.println("<pre>");
        e.printStackTrace(new PrintWriter(out));
        out.println("</pre>");
        return;

    } finally {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignored) {}
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Loan Diary Report</title>

    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/common-report.css">
    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/lookup.css">
    
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

    <h1 class="report-title">
        LOAN DIARY REPORT
    </h1>

    <form method="post"
          action="<%=request.getContextPath()%>/Reports/jspFiles/LoanDiaryReport.jsp"
          target="_blank"
          autocomplete="off">

        <input type="hidden" name="action" value="download"/>

        <!-- PARAMETERS -->
        <div class="parameter-section">

            <div class="parameter-group">
                <div class="parameter-label">Branch Code</div>
                <div class="input-box">
        <input type="text"
               id="branchCode"
               name="branch_code"
               class="input-field"
               required>

        <button type="button"
                class="icon-btn"
                onclick="openBranchLookup()">…</button>
    </div>
            </div>
            
            <div class="parameter-group">
    <div class="parameter-label">Branch Name</div>
    <input type="text" id="branchName"
           class="input-field" readonly>
</div>

            <div class="parameter-group">
                <div class="parameter-label">Account Code</div>
                <div class="input-box">
        <input type="text"
               name="account_code"
               id="account_code"
               class="input-field"
               required>

        <!-- 🔥 POPUP BUTTON -->
        <button type="button"
                class="icon-btn"
                onclick="openAccountLookup()">…</button>
    </div>

            </div>
            
            <div class="parameter-group">
    <div class="parameter-label">Account Name</div>
    <input type="text"
           id="account_name"
           class="input-field"
           readonly>
</div>

            <div class="parameter-group">
                <div class="parameter-label">As On Date</div>
                <input type="date" name="as_on_date"
       class="input-field"
       value="<%=sessionDate%>"
       required>
            </div>

        </div>

        <!-- FORMAT -->
        <div class="format-section">
            <div class="parameter-label">Report Type</div>

            <div class="format-options">
                <div class="format-option">
                    <input type="radio" name="reporttype"
                           value="pdf" checked> PDF
                </div>

                <div class="format-option">
                    <input type="radio" name="reporttype"
                           value="xls"> Excel
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

<script>

/* =========================
   🔹 OPEN BRANCH LOOKUP
   ========================= */
function openBranchLookup() {

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch")

        .then(res => res.text())

        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        })

        .catch(err => console.error("Branch lookup error:", err));
}


/* =========================
   🔹 OPEN ACCOUNT LOOKUP
   ========================= */
function openAccountLookup() {

    let branch = document.getElementById("branchCode").value;

    // validation
    if (!branch || branch.trim() === "") {
        alert("Please select branch first");
        return;
    }

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=account&branchCode=" + encodeURIComponent(branch))

        .then(res => res.text())

        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        })

        .catch(err => console.error("Account lookup error:", err));
}


/* =========================
   🔹 CLOSE POPUP
   ========================= */
function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}


/* =========================
   🔹 SELECT BRANCH
   ========================= */
function selectBranch(code, name) {

    document.getElementById("branchCode").value = code;
    document.getElementById("branchName").value = name;

    // clear account when branch changes
    document.getElementById("account_code").value = "";
    document.getElementById("account_name").value = "";

    closeLookup();
}


/* =========================
   🔹 SELECT ACCOUNT
   ========================= */
function selectAccount(code, name) {

    document.getElementById("account_code").value = code;

    let accName = document.getElementById("account_name");
    if (accName) accName.value = name;

    closeLookup();
}


/* =========================
   🔹 AUTO FETCH BRANCH NAME
   ========================= */
document.getElementById("branchCode").addEventListener("blur", function() {

    let code = this.value;

    if (!code) return;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=branch&action=getName&code=" + code)

        .then(res => res.text())

        .then(name => {
            document.getElementById("branchName").value = name || "Not Found";
        })

        .catch(err => console.error(err));
});


/* =========================
   🔹 AUTO FETCH ACCOUNT NAME
   ========================= */
document.getElementById("account_code").addEventListener("blur", function() {

    let code = this.value;

    if (!code) return;

    fetch("<%=request.getContextPath()%>/CommonLookupServlet?type=account&action=getName&code=" + code)

        .then(res => res.text())

        .then(name => {
            document.getElementById("account_name").value = name || "Not Found";
        })

        .catch(err => console.error(err));
});

</script>

</body>
</html>