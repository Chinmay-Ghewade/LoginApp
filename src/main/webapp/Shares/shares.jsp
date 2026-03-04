<%@ page import="java.sql.*, db.DBConnection, java.text.SimpleDateFormat" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String branchCode = (String) sess.getAttribute("branchCode");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>View Shares Card</title>
<link rel="stylesheet" href="../css/cardView.css">
</head>

<body>
<div class="dashboard-container">
    <div class="cards-wrapper">

        <!-- Shares Allotment Card -->
        <div class="card" onclick="navigateTo('Shares/sharesAllotment.jsp', 'Shares > Shares Allotment')">
            <h3>Shares Allotment</h3>
        </div>

        <!-- Shares Refund Card -->
        <div class="card" onclick="navigateTo('Shares/sharesRefund.jsp', 'Shares > Shares Refund')">
            <h3>Shares Refund</h3>
        </div>

        <!-- Dividend Calculation Card -->
        <div class="card" onclick="navigateTo('Shares/dividendCal.jsp', 'Shares > Dividend Calculation')">
            <h3>Dividend Calculation</h3>
        </div>

    </div>
</div>

<script>
    function navigateTo(page, breadcrumb) {
        if (window.parent && window.parent.loadPage) {
            // Update the iframe src directly
            window.parent.document.getElementById('contentFrame').src = page;
            // Update the breadcrumb in the parent
            window.parent.updateParentBreadcrumb(breadcrumb, page);
        } else {
            // Fallback: navigate directly
            window.location.href = page;
        }
    }

    window.onload = function () {
        // Update breadcrumb to show we're on the Shares card view
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Shares', 'Shares/shares.jsp');
        }
    };
</script>
</body>
</html>
