<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String schemaParam = request.getParameter("schema");
    if (schemaParam == null) schemaParam = "";

    String searchParam = request.getParameter("search");
    if (searchParam == null) searchParam = "";

    String pageParam = request.getParameter("page");

    int currentPage = 1;
    int recordsPerPage = 16;

    if (pageParam != null) {
        try {
            currentPage = Integer.parseInt(pageParam);
        } catch (Exception e) {
            currentPage = 1;
        }
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int totalRecords = 0;
    int totalPages = 0;
%>

<!DOCTYPE html>
<html>
<head>
<title>Report List</title>

<link rel="stylesheet"
      href="<%=request.getContextPath()%>/css/common-table.css?v=4">

</head>

<body>

<div class="container">

    <!-- ================= AUTO SEARCH ================= -->
    <div class="search-box">
        <form id="searchForm" method="get">
            <input type="hidden" name="schema" value="<%=schemaParam%>">
            <input type="hidden" name="page" value="1">

            <input type="text"
                   id="searchInput"
                   name="search"
                   placeholder="🔍 Search by Program Name..."
                   value="<%=searchParam%>"
                   onkeyup="autoSearch()">
        </form>
    </div>

    <div class="card-wrapper">

<%
    try {

        conn = DBConnection.getConnection();

        String countSql =
        	    "SELECT COUNT(*) FROM ACL.PROGRAM " +
        	    "WHERE UPPER(\"SCHEMA\") LIKE ? " +
        	    "AND UPPER(PROGRAM_NAME) LIKE ? " +
        	    "AND PROGRAM_ID = 999999";

        ps = conn.prepareStatement(countSql);
        ps.setString(1, "%" + schemaParam.toUpperCase() + "%");
        ps.setString(2, "%" + searchParam.toUpperCase() + "%");

        rs = ps.executeQuery();

        if (rs.next()) {
            totalRecords = rs.getInt(1);
        }

        rs.close();
        ps.close();

        totalPages = (int) Math.ceil((double) totalRecords / recordsPerPage);
        int start = (currentPage - 1) * recordsPerPage;

        String dataSql =
        	    "SELECT PROGRAM_NAME, PAGE_LINK FROM (" +
        	    " SELECT PROGRAM_NAME, PAGE_LINK, ROW_NUMBER() OVER (ORDER BY PROGRAM_NAME) rn " +
        	    " FROM ACL.PROGRAM " +
        	    " WHERE UPPER(\"SCHEMA\") LIKE ? " +
        	    " AND UPPER(PROGRAM_NAME) LIKE ? " +
        	    " AND PROGRAM_ID = 999999 " +
        	    ") WHERE rn BETWEEN ? AND ?";
        
        ps = conn.prepareStatement(dataSql);
        ps.setString(1, "%" + schemaParam.toUpperCase() + "%");
        ps.setString(2, "%" + searchParam.toUpperCase() + "%");
        ps.setInt(3, start + 1);
        ps.setInt(4, start + recordsPerPage);

        rs = ps.executeQuery();
%>

        <table class="program-table">
            <thead>
                <tr>
                    <th>PROGRAM</th>
                    <th>PROGRAM</th>
                    <th>PROGRAM</th>
                    <th>PROGRAM</th>
                </tr>
            </thead>
            <tbody>
                <tr>

<%
        int columnCount = 0;

        while (rs.next()) {

            if (columnCount == 4) {
%>
                </tr>
                <tr>
<%
                columnCount = 0;
            }
%>

            <!-- 🔥 SAFE FIX USING data-url -->
            <td class="program-cell"
                data-url="<%= rs.getString("PAGE_LINK") %>">
                <%= rs.getString("PROGRAM_NAME") %>
            </td>

<%
            columnCount++;
        }

        while (columnCount < 4 && columnCount != 0) {
%>
            <td></td>
<%
            columnCount++;
        }
%>

                </tr>
            </tbody>
        </table>

<%
    } catch (Exception e) {
%>
        <div style="color:red; text-align:center;">Error loading data</div>
<%
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (conn != null) conn.close(); } catch (Exception e) {}
    }
%>

    </div>

    <!-- ================= PAGINATION ================= -->
    <div class="pagination-container">

        <% if (currentPage > 1) { %>
            <a href="?schema=<%=schemaParam%>&search=<%=searchParam%>&page=<%=currentPage-1%>"
               class="nav-btn">← Previous</a>
        <% } else { %>
            <button class="disabled-btn">← Previous</button>
        <% } %>

        <span class="page-info">
            Page <%=currentPage%> of <%= totalPages == 0 ? 1 : totalPages %>
        </span>

        <% if (currentPage < totalPages) { %>
            <a href="?schema=<%=schemaParam%>&search=<%=searchParam%>&page=<%=currentPage+1%>"
               class="nav-btn">Next →</a>
        <% } else { %>
            <button class="disabled-btn">Next →</button>
        <% } %>

    </div>

</div>

<!-- ================= FORM CONTAINER ================= -->
<div id="formContainer" style="display:none; margin-top:30px;">
    <div style="text-align:right; margin-bottom:10px;">
        <button onclick="closeForm()" class="nav-btn">Close</button>
    </div>

    <iframe id="formFrame"
            style="width:100%; border:1px solid #ccc; border-radius:8px;"
            scrolling="no"
            onload="resizeIframe(this)">
    </iframe>
</div>

<!-- ================= SCRIPT ================= -->
<script>

// Auto search delay
let typingTimer;
let doneTypingInterval = 500;

function autoSearch() {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(function() {
        document.getElementById("searchForm").submit();
    }, doneTypingInterval);
}

// 🔥 SAFE CLICK HANDLER (Logic Same)
document.addEventListener("DOMContentLoaded", function () {

    const cells = document.querySelectorAll(".program-cell");

    cells.forEach(function(cell) {

        cell.addEventListener("click", function() {

            const url = this.getAttribute("data-url");

            const iframe = document.getElementById("formFrame");
            const container = document.getElementById("formContainer");

            /* remove highlight from all */
            cells.forEach(c => c.classList.remove("active"));

            /* highlight clicked */
            this.classList.add("active");

            container.style.display = "block";
            iframe.src = url;

            window.scrollTo({
                top: container.offsetTop - 20,
                behavior: "smooth"
            });

        });
    });

});

function closeForm() {

    const iframe = document.getElementById("formFrame");
    const container = document.getElementById("formContainer");

    container.style.display = "none";
    iframe.src = "";

    document.querySelectorAll(".program-cell")
        .forEach(c => c.classList.remove("active"));
}

function resizeIframe(iframe) {
    try {
        iframe.style.height =
            iframe.contentWindow.document.documentElement.scrollHeight + "px";
    } catch (e) {
        iframe.style.height = "700px";
    }
}

</script>

</body>
</html>
