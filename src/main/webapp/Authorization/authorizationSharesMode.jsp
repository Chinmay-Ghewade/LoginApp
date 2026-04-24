<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    int recordsPerPage = 15;
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Authorization Shares Transaction - Branch <%= branchCode %></title>
<link rel="stylesheet" href="../css/totalCustomers.css">
<script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>

<style>
.pagination-container {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 10px;
    margin: 20px 0;
    padding: 15px;
}

.pagination-btn {
    background: #2b0d73;
    color: white;
    padding: 8px 16px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    font-weight: bold;
    transition: background 0.3s;
}

.pagination-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
    opacity: 0.6;
}

.page-info {
    font-size: 14px;
    color: #2b0d73;
    font-weight: bold;
    padding: 0 15px;
}

.view-details-btn {
    background: #2b0d73;
    color: white;
    padding: 4px 10px;
    border-radius: 4px;
    text-decoration: none;
    display: inline-block;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
    border: none;
    transition: background 0.3s;
}

.view-details-btn:hover {
    background: #1a0847;
}
</style>

<script>
let allTransactions = [];
let currentPage = 1;
const recordsPerPage = <%= recordsPerPage %>;

function searchTable() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();

    var filtered = filter ? allTransactions.filter(function(t) {
        return t.scrollNumber.toLowerCase().indexOf(filter) > -1 ||
               t.accountCode.toLowerCase().indexOf(filter) > -1 ||
               t.accountName.toLowerCase().indexOf(filter) > -1 ||
               t.glAccountName.toLowerCase().indexOf(filter) > -1 ||
               t.forAccountCode.toLowerCase().indexOf(filter) > -1 ||
               t.particular.toLowerCase().indexOf(filter) > -1;
    }) : allTransactions;

    displayTransactions(filtered, 1);
}

function displayTransactions(transactions, page) {
    currentPage = page;
    var tbody = document.querySelector("#transactionTable tbody");
    tbody.innerHTML = "";

    if (transactions.length === 0) {
        tbody.innerHTML = "<tr><td colspan='9' class='no-data'>No transactions found.</td></tr>";
        updatePaginationControls(0, page);
        return;
    }

    var start = (page - 1) * recordsPerPage;
    var end   = Math.min(start + recordsPerPage, transactions.length);

    for (var i = start; i < end; i++) {
        var t    = transactions[i];
        var srNo = start + (i - start) + 1;
        var row  = tbody.insertRow();
        row.innerHTML =
            "<td>" + srNo + "</td>" +
            "<td>" + t.scrollNumber + "</td>" +
            "<td>" + t.accountCode + "</td>" +
            "<td>" + t.accountName + "</td>" +
            "<td>" + t.glAccountName + "</td>" +
            "<td>" + t.forAccountCode + "</td>" +
            "<td style='text-align:right;'>" + t.amount + "</td>" +
            "<td>" + t.particular + "</td>" +
            "<td><button class='view-details-btn' onclick=\"viewTransaction('" + t.scrollNumber + "'); return false;\">View Details</button></td>";
    }

    updatePaginationControls(transactions.length, page);
}

function updatePaginationControls(totalRecords, page) {
    var totalPages = Math.ceil(totalRecords / recordsPerPage);
    document.getElementById("prevBtn").disabled = (page <= 1);
    document.getElementById("nextBtn").disabled = (page >= totalPages);
    document.getElementById("pageInfo").textContent = "Page " + page + " of " + Math.max(1, totalPages);
    sessionStorage.setItem('authSharesTxnPage', page);
}

function previousPage() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();
    var transactions = filter ? allTransactions.filter(function(t) {
        return t.scrollNumber.toLowerCase().indexOf(filter) > -1 ||
               t.accountCode.toLowerCase().indexOf(filter) > -1 ||
               t.accountName.toLowerCase().indexOf(filter) > -1 ||
               t.glAccountName.toLowerCase().indexOf(filter) > -1 ||
               t.forAccountCode.toLowerCase().indexOf(filter) > -1 ||
               t.particular.toLowerCase().indexOf(filter) > -1;
    }) : allTransactions;

    if (currentPage > 1) displayTransactions(transactions, currentPage - 1);
}

function nextPage() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();
    var transactions = filter ? allTransactions.filter(function(t) {
        return t.scrollNumber.toLowerCase().indexOf(filter) > -1 ||
               t.accountCode.toLowerCase().indexOf(filter) > -1 ||
               t.accountName.toLowerCase().indexOf(filter) > -1 ||
               t.glAccountName.toLowerCase().indexOf(filter) > -1 ||
               t.forAccountCode.toLowerCase().indexOf(filter) > -1 ||
               t.particular.toLowerCase().indexOf(filter) > -1;
    }) : allTransactions;

    var totalPages = Math.ceil(transactions.length / recordsPerPage);
    if (currentPage < totalPages) displayTransactions(transactions, currentPage + 1);
}

// ✅ FIXED: now points to viewSharesModeDetails.jsp
function viewTransaction(scrollNumber) {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('authorizationSharesMode.jsp')
        );
    }
    window.location.replace('viewSharesModeDetails.jsp?scrollNumber=' + encodeURIComponent(scrollNumber));
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('authorizationSharesMode.jsp')
        );
    }
    var savedPage = parseInt(sessionStorage.getItem('authSharesTxnPage')) || 1;
    currentPage = savedPage;
    displayTransactions(allTransactions, currentPage);
};
</script>
</head>
<body>

<h2>Authorization Shares Transaction — Branch: <%= branchCode %></h2>

<div class="search-container">
    <input type="text" id="searchInput" onkeyup="searchTable()"
           placeholder="🔍 Search by Scroll No, Account Code, Name, GL Name, Particular">
</div>

<div class="table-container">
<table id="transactionTable">
<thead>
    <tr>
        <th>SR NO</th>
        <th>SCROLL NO</th>
        <th>ACCOUNT CODE</th>
        <th>ACCOUNT NAME</th>
        <th>GL ACCOUNT NAME</th>
        <th>FOR ACCOUNT CODE</th>
        <th>AMOUNT</th>
        <th>PARTICULAR</th>
        <th>ACTION</th>
    </tr>
</thead>
<tbody>
<%
try (Connection conn = DBConnection.getConnection()) {

    java.sql.Date workingDate = (java.sql.Date) session.getAttribute("workingDate");

    PreparedStatement ps = conn.prepareStatement(
        "SELECT " +
        "  d.SCROLL_NUMBER, " +
        "  CASE " +
        "      WHEN d.TRANSACTIONINDICATOR_CODE = 'TRDR' " +
        "      THEN d.FORACCOUNT_CODE " +
        "      ELSE d.ACCOUNT_CODE " +
        "  END AS ACCOUNT_CODE, " +
        "  CASE " +
        "      WHEN d.TRANSACTIONINDICATOR_CODE = 'TRDR' " +
        "      THEN Fn_Get_Account_name(d.FORACCOUNT_CODE) " +
        "      ELSE Fn_Get_Account_name(d.ACCOUNT_CODE) " +
        "  END AS ACCOUNT_NAME, " +
        "  CASE " +
        "      WHEN d.TRANSACTIONINDICATOR_CODE = 'TRDR' " +
        "      THEN Fn_Get_Account_name(FN_GET_AC_GL(d.FORACCOUNT_CODE)) " +
        "      ELSE Fn_Get_Account_name(FN_GET_AC_GL(d.ACCOUNT_CODE)) " +
        "  END AS GL_ACCOUNT_NAME, " +
        "  CASE " +
        "      WHEN d.TRANSACTIONINDICATOR_CODE = 'TRDR' " +
        "      THEN NVL(d.ACCOUNT_CODE, '') " +
        "      ELSE NVL(d.FORACCOUNT_CODE, '') " +
        "  END AS FORACCOUNT_CODE, " +
        "  d.AMOUNT, " +
        "  NVL(d.PARTICULAR, '') AS PARTICULAR " +
        "FROM TRANSACTION.DAILYSCROLL d " +
        "WHERE d.BRANCH_CODE = ? " +
        "  AND ( " +
        "      (d.TRANSACTIONINDICATOR_CODE IN ('CSCR','CSDR') " +
        "          AND SUBSTR(d.ACCOUNT_CODE, 5, 3) = '901') " +
        "      OR " +
        "      (d.TRANSACTIONINDICATOR_CODE = 'TRCR' " +
        "          AND SUBSTR(d.ACCOUNT_CODE, 5, 3) = '901') " +
        "      OR " +
        "      (d.TRANSACTIONINDICATOR_CODE = 'TRDR' " +
        "          AND SUBSTR(d.FORACCOUNT_CODE, 5, 3) = '901') " +
        "  ) " +
        (workingDate != null ? "  AND TRUNC(d.SCROLL_DATE) = TRUNC(?) " : "") +
        "ORDER BY d.SCROLL_NUMBER DESC"
    );

    ps.setString(1, branchCode);
    if (workingDate != null) {
        ps.setDate(2, workingDate);
    }

    ResultSet rs = ps.executeQuery();

    boolean hasData  = false;
    int displayCount = 0;
    int srNo         = 1;

    while (rs.next()) {
        hasData = true;

        String scrollNumber   = rs.getString("SCROLL_NUMBER")   != null ? rs.getString("SCROLL_NUMBER")   : "";
        String accountCode    = rs.getString("ACCOUNT_CODE")    != null ? rs.getString("ACCOUNT_CODE")    : "";
        String accountName    = rs.getString("ACCOUNT_NAME")    != null ? rs.getString("ACCOUNT_NAME")    : "";
        String glAccountName  = rs.getString("GL_ACCOUNT_NAME") != null ? rs.getString("GL_ACCOUNT_NAME") : "";
        String forAccountCode = rs.getString("FORACCOUNT_CODE") != null ? rs.getString("FORACCOUNT_CODE") : "";
        String amount         = rs.getString("AMOUNT")          != null ? rs.getString("AMOUNT")          : "0.00";
        String particular     = rs.getString("PARTICULAR")      != null ? rs.getString("PARTICULAR")      : "";

        // Sanitize for JS
        String safeAccountName   = accountName.replace("'", "\\'").replace(".", "");
        String safeGlAccountName = glAccountName.replace("'", "\\'").replace(".", "");
        String safeParticular    = particular.replace("'", "\\'");

        out.println("<script>");
        out.println("allTransactions.push({");
        out.println("  scrollNumber: '"   + scrollNumber      + "',");
        out.println("  accountCode: '"    + accountCode       + "',");
        out.println("  accountName: '"    + safeAccountName   + "',");
        out.println("  glAccountName: '"  + safeGlAccountName + "',");
        out.println("  forAccountCode: '" + forAccountCode    + "',");
        out.println("  amount: '"         + amount            + "',");
        out.println("  particular: '"     + safeParticular    + "'");
        out.println("});");
        out.println("</script>");

        if (displayCount < recordsPerPage) {
            out.println("<tr>");
            out.println("<td>" + srNo + "</td>");
            out.println("<td>" + scrollNumber + "</td>");
            out.println("<td>" + accountCode + "</td>");
            out.println("<td>" + (accountName.equals(".") ? "" : accountName) + "</td>");
            out.println("<td>" + (glAccountName.equals(".") ? "" : glAccountName) + "</td>");
            out.println("<td>" + forAccountCode + "</td>");
            out.println("<td style='text-align:right;'>" + amount + "</td>");
            out.println("<td>" + particular + "</td>");
            out.println("<td><button class='view-details-btn' onclick=\"viewTransaction('" + scrollNumber + "'); return false;\">View Details</button></td>");
            out.println("</tr>");
            displayCount++;
            srNo++;
        }
    }

    if (!hasData) {
        out.println("<tr><td colspan='9' class='no-data'>No pending shares transactions found.</td></tr>");
    }

} catch (Exception e) {
    out.println("<tr><td colspan='9' class='no-data'>Error: " + e.getMessage() + "</td></tr>");
}
%>
</tbody>
</table>
</div>

<div class="pagination-container">
    <button id="prevBtn" class="pagination-btn" onclick="previousPage()">← Previous</button>
    <span id="pageInfo" class="page-info">Page 1</span>
    <button id="nextBtn" class="pagination-btn" onclick="nextPage()">Next →</button>
</div>

<script>
(function() {
    var totalPages = Math.ceil(allTransactions.length / recordsPerPage);
    document.getElementById("prevBtn").disabled = true;
    document.getElementById("nextBtn").disabled = (totalPages <= 1);
    document.getElementById("pageInfo").textContent = "Page 1 of " + Math.max(1, totalPages);
    sessionStorage.setItem('authSharesTxnPage', '1');
})();
</script>

</body>
</html>
