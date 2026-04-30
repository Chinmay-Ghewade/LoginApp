<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String userId    = (String) session.getAttribute("userId");
    String branchCode = (String) session.getAttribute("branchCode");

    if (userId == null || branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Casher</title>
    <link rel="stylesheet" href="../css/cardView.css">
    <script src="../js/breadcrumb-auto.js"></script>
</head>
<body>

<div class="dashboard-container">
    <div class="cards-wrapper">

        <div class="card" onclick="goTo('cashInOut.jsp', 'Casher > Cash In / Out')">
            <h3>Cash In / Out</h3>
            <p class="size-1">→</p>
        </div>

        <div class="card" onclick="goTo('userDenominationMaster.jsp', 'Casher > User Denomination Master')">
            <h3>User Denomination Master</h3>
            <p class="size-1">→</p>
        </div>

        <div class="card" onclick="goTo('combineDenomination.jsp', 'Casher > Combine Denomination')">
            <h3>Combine Denomination</h3>
            <p class="size-1">→</p>
        </div>

        <div class="card" onclick="goTo('denominationView.jsp', 'Casher > Denomination View')">
            <h3>Denomination View</h3>
            <p class="size-1">→</p>
        </div>

        <div class="card" onclick="goTo('denominationReport.jsp', 'Casher > Denomination Report')">
            <h3>Denomination Report</h3>
            <p class="size-1">→</p>
        </div>

    </div>
</div>

<script>
    function goTo(page, breadcrumb) {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(breadcrumb, 'Cashers/' + page);
        }
        window.location.href = page;
    }

    window.onload = function () {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Cashers');
        }

        if (window.parent && window.parent.pushNavigationHistory) {
            window.parent.pushNavigationHistory('Cashers', 'Cashers/casher.jsp');
        }
    };
</script>
</body>
</html>
