<%@ page import="java.sql.*, java.util.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");

    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    PreparedStatement countPs = null;
    ResultSet rs = null;

    List<Map<String, String>> cards = new ArrayList<>();

    try {
        conn = DBConnection.getConnection();

        /* ==============================
           1️⃣ MAIN QUERY – Load Reports
           ============================== */
        ps = conn.prepareStatement(
            "SELECT r.SR_NUMBER, r.DESCRIPTION, r.PAGE_LINK " +
            "FROM GLOBALCONFIG.REPORTS r " +
            "WHERE r.DESCRIPTION IS NOT NULL " +
            "ORDER BY r.SR_NUMBER"
        );

        rs = ps.executeQuery();

        /* =====================================
           2️⃣ COUNT QUERY – DYNAMIC REPORT COUNT
           ===================================== */
        		   countPs = conn.prepareStatement(
        				    "SELECT COUNT(*) AS total_count " +
        				    "FROM ACL.PROGRAM " +
        				    "WHERE UPPER(\"SCHEMA\") LIKE ? " +
        				    "AND PROGRAM_ID = 999999"
        				);

        while (rs.next()) {

            Map<String, String> card = new HashMap<>();

            String srNumber = rs.getString("SR_NUMBER");
            String description = rs.getString("DESCRIPTION");
            String pageLink = rs.getString("PAGE_LINK");

            if (pageLink == null || pageLink.trim().isEmpty()) {
                pageLink = "reports.jsp";
            }

            /* 🔢 Bind dynamic value (DAILY / MONTHLY / etc.) */
            countPs.setString(1, "%" + description.toUpperCase() + "%");

            ResultSet countRs = countPs.executeQuery();
            String count = "0";
            if (countRs.next()) {
                count = countRs.getString("total_count");
            }
            countRs.close();

            card.put("srNumber", srNumber);
            card.put("description", description);
            card.put("pageLink", pageLink);
            card.put("count", count);

            cards.add(card);
        }

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (countPs != null) countPs.close(); } catch (Exception ex) {}
        try { if (conn != null) conn.close(); } catch (Exception ex) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reports</title>
<link rel="stylesheet" href="../../css/cardView.css">
</head>

<body>

<div class="dashboard-container">
    <div class="cards-wrapper">

<%
    if (cards != null && !cards.isEmpty()) {
        for (Map<String, String> card : cards) {

            String description = card.get("description");
            String count = card.get("count");

            int len = count.length();
            String sizeClass = "size-1";
            if (len <= 12) sizeClass = "size-1";
            else if (len <= 16) sizeClass = "size-2";
            else if (len <= 20) sizeClass = "size-3";
            else if (len <= 25) sizeClass = "size-4";
            else if (len <= 32) sizeClass = "size-5";
            else if (len <= 40) sizeClass = "size-6";
            else sizeClass = "size-7";
%>

        <div class="card"
             onclick="openInParentFrame(
                 'Reports/jspFiles/programList.jsp?schema=<%= description %>',
                 'Reports > <%= description %>')">

            <h3><%= description %></h3>
            <p class="<%= sizeClass %>"><%= count %></p>
        </div>

<%
        }
    } else {
%>

        <div class="error-message">
            <h3>No reports configured</h3>
            <p>Please configure reports in GLOBALCONFIG.REPORTS table</p>
        </div>

<%
    }
%>

    </div>
</div>

<script>
function openInParentFrame(page, breadcrumbPath) {
    if (window.parent && window.parent.document) {
        const iframe = window.parent.document.getElementById("contentFrame");
        if (iframe) {
            iframe.src = page;
            if (window.parent.updateParentBreadcrumb) {
                window.parent.updateParentBreadcrumb(breadcrumbPath);
            }
        }
    } else {
        window.location.href = page;
    }
}

window.onload = function () {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb('Reports');
    }
};
</script>

</body>
</html>
