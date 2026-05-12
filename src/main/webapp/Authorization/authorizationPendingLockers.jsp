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
<title>Authorization Pending Lockers - Branch <%= branchCode %></title>
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
let allLockers = [];
let currentPage = 1;
const recordsPerPage = <%= recordsPerPage %>;

function searchTable() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();

    var filtered = filter ? allLockers.filter(function(l) {
        return l.customerId.toLowerCase().indexOf(filter) > -1 ||
               l.nameOfHire.toLowerCase().indexOf(filter) > -1 ||
               l.lockerType.toLowerCase().indexOf(filter) > -1;
    }) : allLockers;

    displayLockers(filtered, 1);
}

function displayLockers(lockers, page) {
    currentPage = page;
    var tbody = document.querySelector("#lockerTable tbody");
    tbody.innerHTML = "";

    if (lockers.length === 0) {
        tbody.innerHTML = "<tr><td colspan='5' class='no-data'>No pending lockers found.</td></tr>";
        updatePaginationControls(0, page);
        return;
    }

    var start = (page - 1) * recordsPerPage;
    var end   = Math.min(start + recordsPerPage, lockers.length);

    for (var i = start; i < end; i++) {
        var l    = lockers[i];
        var srNo = start + (i - start) + 1;
        var row  = tbody.insertRow();
        row.innerHTML =
            "<td>" + srNo + "</td>" +
            "<td>" + l.customerId + "</td>" +
            "<td>" + l.nameOfHire + "</td>" +
            "<td>" + l.lockerType + "</td>" +
            "<td><button class='view-details-btn' onclick=\"viewLocker('" + l.customerId + "'); return false;\">View Details</button></td>";
    }

    updatePaginationControls(lockers.length, page);
}

function updatePaginationControls(totalRecords, page) {
    var totalPages = Math.ceil(totalRecords / recordsPerPage);
    document.getElementById("prevBtn").disabled = (page <= 1);
    document.getElementById("nextBtn").disabled = (page >= totalPages);
    document.getElementById("pageInfo").textContent = "Page " + page + " of " + Math.max(1, totalPages);
    sessionStorage.setItem('authPendingLockersPage', page);
}

function previousPage() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();
    var lockers = filter ? allLockers.filter(function(l) {
        return l.customerId.toLowerCase().indexOf(filter) > -1 ||
               l.nameOfHire.toLowerCase().indexOf(filter) > -1 ||
               l.lockerType.toLowerCase().indexOf(filter) > -1;
    }) : allLockers;

    if (currentPage > 1) displayLockers(lockers, currentPage - 1);
}

function nextPage() {
    var filter = document.getElementById("searchInput").value.toLowerCase().trim();
    var lockers = filter ? allLockers.filter(function(l) {
        return l.customerId.toLowerCase().indexOf(filter) > -1 ||
               l.nameOfHire.toLowerCase().indexOf(filter) > -1 ||
               l.lockerType.toLowerCase().indexOf(filter) > -1;
    }) : allLockers;

    var totalPages = Math.ceil(lockers.length / recordsPerPage);
    if (currentPage < totalPages) displayLockers(lockers, currentPage + 1);
}

function viewLocker(customerId) {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('authorizationPendingLockers.jsp')
        );
    }
    window.location.replace('viewLockerDetails.jsp?customerId=' + encodeURIComponent(customerId));
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('authorizationPendingLockers.jsp')
        );
    }
    var savedPage = parseInt(sessionStorage.getItem('authPendingLockersPage')) || 1;
    currentPage = savedPage;
    displayLockers(allLockers, currentPage);
};
</script>
</head>
<body>

<h2>Authorization Pending Lockers — Branch: <%= branchCode %></h2>

<div class="search-container">
    <input type="text" id="searchInput" onkeyup="searchTable()"
           placeholder="🔍 Search by Customer ID, Name of Hire, Locker Type">
</div>

<div class="table-container">
<table id="lockerTable">
<thead>
    <tr>
        <th>SR NO</th>
        <th>CUSTOMER ID</th>
        <th>NAME OF HIRE</th>
        <th>LOCKER TYPE</th>
        <th>ACTION</th>
    </tr>
</thead>
<tbody>
<%-- Data is loaded into allLockers[] via JS below. Table body is rendered by displayLockers(). --%>
</tbody>
</table>
</div>

<div class="pagination-container">
    <button id="prevBtn" class="pagination-btn" onclick="previousPage()">← Previous</button>
    <span id="pageInfo" class="page-info">Page 1</span>
    <button id="nextBtn" class="pagination-btn" onclick="nextPage()">Next →</button>
</div>

<%-- Load all data into JS array only — no HTML rows rendered here --%>
<script>
<%
try (Connection conn = DBConnection.getConnection()) {

    PreparedStatement ps = conn.prepareStatement(
        "SELECT " +
        "  l.CUSTOMER_ID, " +
        "  NVL(l.NAME_OF_HIRE, '') AS NAME_OF_HIRE, " +
        "  NVL(l.LOCKER_TYPE, '') AS LOCKER_TYPE " +
        "FROM ACCOUNT.LOCKERACCOUNT l " +
        "WHERE l.BRANCH_CODE = ? " +
        "  AND l.ACCOUNT_STATUS = 'E' " +
        "ORDER BY l.CUSTOMER_ID"
    );

    ps.setString(1, branchCode);

    ResultSet rs = ps.executeQuery();
    boolean hasData = false;

    while (rs.next()) {
        hasData = true;

        String customerId = rs.getString("CUSTOMER_ID")  != null ? rs.getString("CUSTOMER_ID")  : "";
        String nameOfHire = rs.getString("NAME_OF_HIRE") != null ? rs.getString("NAME_OF_HIRE") : "";
        String lockerType = rs.getString("LOCKER_TYPE")  != null ? rs.getString("LOCKER_TYPE")  : "";

        // Sanitize for JS string literals
        String safeNameOfHire = nameOfHire.replace("\\", "\\\\").replace("'", "\\'");
        String safeLockerType = lockerType.replace("\\", "\\\\").replace("'", "\\'");

        out.println("allLockers.push({");
        out.println("  customerId: '" + customerId    + "',");
        out.println("  nameOfHire: '" + safeNameOfHire + "',");
        out.println("  lockerType: '" + safeLockerType + "'");
        out.println("});");
    }

    if (!hasData) {
        out.println("// No data found");
    }

} catch (Exception e) {
    out.println("console.error('DB Error: " + e.getMessage().replace("'", "\\'") + "');");
}
%>
</script>

</body>
</html>
