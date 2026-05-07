<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
String sessionBranchCode = (String) session.getAttribute("branchCode");
if (sessionBranchCode == null || sessionBranchCode.isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

String selectedBranch = request.getParameter("branch");
if (selectedBranch == null || selectedBranch.trim().isEmpty()) {
    selectedBranch = sessionBranchCode;
}

java.util.List<String[]> allBranches = new java.util.ArrayList<>();
Connection connB = null; PreparedStatement pstmtB = null; ResultSet rsB = null;
try {
    connB = DBConnection.getConnection();
    if (connB != null) {
        pstmtB = connB.prepareStatement("SELECT BRANCH_CODE, NAME FROM HEADOFFICE.BRANCH ORDER BY BRANCH_CODE");
        rsB = pstmtB.executeQuery();
        while (rsB.next()) allBranches.add(new String[]{ rsB.getString("BRANCH_CODE"), rsB.getString("NAME") });
    }
} catch (Exception e) {
} finally {
    try { if (rsB != null) rsB.close(); } catch (Exception ignored) {}
    try { if (pstmtB != null) pstmtB.close(); } catch (Exception ignored) {}
    try { if (connB != null) connB.close(); } catch (Exception ignored) {}
}

String branchDescription = "";
for (String[] b : allBranches) {
    if (b[0].equals(selectedBranch)) { branchDescription = b[1] != null ? b[1] : ""; break; }
}

java.util.List<Object[]> userList = new java.util.ArrayList<>();
Connection connU = null; PreparedStatement pstmtU = null; ResultSet rsU = null;
try {
    connU = DBConnection.getConnection();
    if (connU != null) {
        String sql = "SELECT USER_ID, NAME, CREATEDDATE_TIME, MOBILE_NUMBER FROM ACL.USERREGISTER WHERE BRANCH_CODE = ? ORDER BY CREATEDDATE_TIME DESC";
        pstmtU = connU.prepareStatement(sql);
        pstmtU.setString(1, selectedBranch);
        rsU = pstmtU.executeQuery();
        while (rsU.next()) {
            userList.add(new Object[]{
                rsU.getString("USER_ID"),
                rsU.getString("NAME"),
                rsU.getString("CREATEDDATE_TIME"),
                rsU.getString("MOBILE_NUMBER")
            });
        }
    }
} catch (Exception e) {
} finally {
    try { if (rsU != null) rsU.close(); } catch (Exception ignored) {}
    try { if (pstmtU != null) pstmtU.close(); } catch (Exception ignored) {}
    try { if (connU != null) connU.close(); } catch (Exception ignored) {}
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Total Users for Branch: <%=selectedBranch%></title>
    <link rel="stylesheet" href="../css/totalCustomers.css">
	<link rel="stylesheet" href="../css/lookup-modal.css">
    <style>

    body {
        font-family: Arial, sans-serif;
        background: #E6E6FA;
        margin: 0;
        padding: 20px;
    }

    html, body { overflow-x: hidden; }

    .container {
        max-width: 1400px;
        margin: auto;
    }

    h2 {
        text-align: center;
        color: #2b0d73;
        font-weight: 700;
        margin-bottom: 18px;
        font-size: 24px;
    }

    .filter-card {
        background: #fff;
        border-radius: 6px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.10);
        border: 1px solid #B8B8E6;
        padding: 16px 20px;
        margin-bottom: 18px;
    }

    .filter-card form {
        display: grid;
        grid-template-columns: 1fr 1fr 130px 130px;
        gap: 16px;
        align-items: end;
        width: 100%;
    }

    .filter-group {
        display: flex;
        flex-direction: column;
        gap: 5px;
    }

    .filter-group label {
        font-size: 13px;
        font-weight: 600;
        color: #2b0d73;
    }

    .filter-group select,
    .filter-group input {
        width: 100%;
        height: 34px;
        padding: 0 10px;
        border: 1px solid #B8B8E6;
        border-radius: 4px;
        font-size: 13px;
        font-family: Arial, sans-serif;
        color: #444;
        background: #FFFFFF;
        box-sizing: border-box;
    }

    .filter-group select { cursor: pointer; }
    .filter-group input[readonly] { background: #f5f5f5; color: #555; }

    .filter-btn, .new-btn {
        height: 34px;
        width: 100%;
        background-color: #2b0d73;
        color: #FFFFFF;
        border: none;
        border-radius: 3px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
    }

    .filter-btn:hover, .new-btn:hover { background: #1E2870; }

    .search-box {
        width: 650px;
        margin: 0 auto 18px auto;
    }

    .search-box input {
        width: 100%;
        padding: 8px 12px;
        border-radius: 4px;
        border: 1px solid #B8B8E6;
        font-size: 13px;
        background: #FFFFFF;
        box-sizing: border-box;
        color: #444;
    }

    .table-card {
        background: #fff;
        border-radius: 6px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.10);
        overflow: auto;
        border: 1px solid #B8B8E6;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
    }

    thead tr { background: #303F9F; }

    th {
        color: #FFFFFF;
        padding: 6px 8px;
        text-align: center;
        font-weight: 600;
        font-size: 12.5px;
        border-right: 1px solid rgba(255,255,255,0.2);
    }

    th:last-child { border-right: none; }

    tbody tr:nth-child(odd)  { background: #F7F7F7; }
    tbody tr:nth-child(even) { background: #FFFFFF; }

    td {
        padding: 5px 8px;
        text-align: left;
        border-right: 1px solid #e3e3e3;
    }

    td:last-child { border-right: none; }

    .view-btn {
        background: #2b0d73;
        color: #FFFFFF;
        border: none;
        padding: 3px 10px;
        border-radius: 3px;
        font-size: 12px;
        cursor: pointer;
        font-weight: 400;
        text-decoration: none;
        display: inline-block;
    }

    .view-btn:hover { background: #1E2870; }

    .no-records {
        text-align: center;
        padding: 30px;
        color: #666;
        font-size: 14px;
    }

    /* ── PAGINATION ── */
    .pagination-bar {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 28px;
        padding: 20px 0 6px;
    }

    .btn-prev,
    .btn-next {
        background: #2b0d73;
        color: #fff;
        border: none;
        border-radius: 8px;
        padding: 11px 26px;
        font-size: 14px;
        font-weight: 700;
        font-family: Arial, sans-serif;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 8px;
        transition: background 0.18s, transform 0.12s, box-shadow 0.12s;
        box-shadow: 0 3px 10px rgba(43,13,115,0.22);
        letter-spacing: 0.01em;
    }

    .btn-prev:hover:not(:disabled),
    .btn-next:hover:not(:disabled) {
        background: #3d1f99;
        transform: translateY(-1px);
        box-shadow: 0 5px 14px rgba(43,13,115,0.30);
    }

    .btn-prev:disabled,
    .btn-next:disabled {
        opacity: 0.38;
        cursor: not-allowed;
        transform: none;
        box-shadow: none;
    }

    .page-info {
        font-size: 15px;
        font-weight: 700;
        color: #2b0d73;
        min-width: 160px;
        text-align: center;
    }

    </style>
</head>
<body>

<div class="container">

    <h2>Total Users for Branch: <%=selectedBranch%></h2>

    <!-- Filter Card -->
    <div class="filter-card">
        <form method="get" action="">

            <div class="filter-group">
                <label>Branch</label>
                <select name="branch" id="branchSelect" onchange="updateDescription()">
                    <% for (String[] b : allBranches) {
                        String sel = b[0].equals(selectedBranch) ? "selected" : ""; %>
                    <option value="<%=b[0]%>" data-desc="<%=b[1] != null ? b[1].replace("\"","&quot;") : ""%>" <%=sel%>><%=b[0]%></option>
                    <% } %>
                </select>
            </div>

            <div class="filter-group">
                <label>Description</label>
                <input type="text" id="branchDesc" value="<%=branchDescription%>" readonly>
            </div>

            <button type="submit" class="filter-btn">Filter</button>
            <button type="button" class="new-btn" onclick="window.location.href='<%=request.getContextPath()%>/Utility/NewUser.jsp'">New +</button>

        </form>
    </div>

    <!-- Search Box -->
    <div class="search-box">
        <input type="text"
               id="searchInput"
               oninput="filterTable()"
               placeholder="🔍 Search by User ID, Name, Mobile...">
    </div>

    <!-- Table -->
    <div class="table-card">
        <table id="usersTable">
            <thead>
                <tr>
                    <th>SR NO</th>
                    <th>USER ID</th>
                    <th>NAME</th>
                    <th>CREATED DATE &amp; TIME</th>
                    <th>MOBILE NUMBER</th>
                    <th>ACTION</th>
                </tr>
            </thead>
            <tbody id="tableBody">
                <% if (userList.isEmpty()) { %>
                <tr><td colspan="6" class="no-records">No users found for this branch.</td></tr>
                <% } else {
                    int sr = 1;
                    for (Object[] u : userList) {
                        String uid       = u[0] != null ? (String)u[0] : "";
                        String uname     = u[1] != null ? (String)u[1] : "";
                        String createdDt = u[2] != null ? (String)u[2] : "";
                        String mobile    = u[3] != null ? (String)u[3] : "";
                %>
                <tr data-search="<%=uid.toLowerCase()%> <%=uname.toLowerCase()%> <%=mobile.toLowerCase()%>">
                    <td class="sr-col"><%=sr++%></td>
                    <td><%=uid%></td>
                    <td><%=uname%></td>
                    <td><%=createdDt%></td>
                    <td><%=mobile%></td>
                    <td>
                        <a href="<%=request.getContextPath()%>/Utility/ViewUserDetails.jsp?userId=<%=uid%>" class="view-btn">View Details</a>
                    </td>
                </tr>
                <% } } %>
            </tbody>
        </table>
    </div>

    <!-- Pagination Bar -->
    <div class="pagination-bar">
        <button class="btn-prev" id="btnPrev" onclick="changePage(-1)" disabled>&#8592; Previous</button>
        <span class="page-info" id="pageInfo">Page 1 of 1</span>
        <button class="btn-next" id="btnNext" onclick="changePage(1)">Next &#8594;</button>
    </div>

</div>

<script>
    /* ── Pagination config ── */
    const ROWS_PER_PAGE = 15;
    let currentPage = 1;
    let filteredRows = [];   // holds the currently visible (search-matched) rows

    /* Collect all data rows once */
    const allRows = Array.from(document.querySelectorAll('#tableBody tr[data-search]'));

    /* ── Initial render ── */
    initPagination();

    /* ── Called on search input ── */
    function filterTable() {
        const query = document.getElementById('searchInput').value.toLowerCase().trim();
        filteredRows = allRows.filter(function(row) {
            return !query || row.getAttribute('data-search').includes(query);
        });
        currentPage = 1;
        renderPage();
    }

    /* ── Set up filteredRows first time ── */
    function initPagination() {
        filteredRows = allRows.slice(); // all rows
        renderPage();
    }

    /* ── Render the current page ── */
    function renderPage() {
        const totalPages = Math.max(1, Math.ceil(filteredRows.length / ROWS_PER_PAGE));
        if (currentPage > totalPages) currentPage = totalPages;

        const start = (currentPage - 1) * ROWS_PER_PAGE;
        const end   = start + ROWS_PER_PAGE;

        /* Hide ALL rows first */
        allRows.forEach(function(r) { r.style.display = 'none'; });

        /* Remove any "no results" dynamic row */
        const dynRow = document.getElementById('dynamicNoRecord');
        if (dynRow) dynRow.remove();

        if (filteredRows.length === 0) {
            /* Show "no match" message */
            const tbody = document.getElementById('tableBody');
            const tr = document.createElement('tr');
            tr.id = 'dynamicNoRecord';
            tr.innerHTML = '<td colspan="6" class="no-records">No matching users found.</td>';
            tbody.appendChild(tr);
        } else {
            /* Show only the slice for this page and renumber SR NO */
            filteredRows.forEach(function(row, idx) {
                if (idx >= start && idx < end) {
                    row.style.display = '';
                    row.querySelector('.sr-col').textContent = idx + 1;
                }
            });
        }

        /* Update pagination controls */
        document.getElementById('pageInfo').textContent = 'Page ' + currentPage + ' of ' + totalPages;
        document.getElementById('btnPrev').disabled = (currentPage <= 1);
        document.getElementById('btnNext').disabled = (currentPage >= totalPages);
    }

    /* ── Previous / Next ── */
    function changePage(direction) {
        const totalPages = Math.max(1, Math.ceil(filteredRows.length / ROWS_PER_PAGE));
        currentPage += direction;
        if (currentPage < 1) currentPage = 1;
        if (currentPage > totalPages) currentPage = totalPages;
        renderPage();
        /* Scroll table into view smoothly */
        document.querySelector('.table-card').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    /* ── Branch description dropdown ── */
    function updateDescription() {
        const select = document.getElementById('branchSelect');
        const opt = select.options[select.selectedIndex];
        document.getElementById('branchDesc').value = opt.getAttribute('data-desc') || '';
    }
</script>

</body>
</html>
