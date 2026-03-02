<%@ page contentType="text/html; charset=UTF-8" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String branchCode = (String) session.getAttribute("branchCode");

    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Transactions</title>
    <link rel="stylesheet" href="../css/cardView.css">
</head>
<body>

<div class="dashboard-container">
    <div class="cards-wrapper">

        <!-- 1. Entry -->
        <div class="card" onclick="openInParentFrame('Transactions/transactions.jsp', 'Transactions > Entry')">
            <h3>Entry</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 2. Charges -->
        <div class="card" onclick="openInParentFrame('Transactions/charges.jsp', 'Transactions > Charges')">
            <h3>Charges</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 3. RTGS -->
        <div class="card" onclick="openInParentFrame('Transactions/rtgs.jsp', 'Transactions > RTGS')">
            <h3>RTGS</h3>
            <p class="size-1">→</p>
        </div>

    </div>
</div>

<script>
    window.onload = function () {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Transactions');
        }
    };

    function openInParentFrame(page, breadcrumbPath) {
        if (window.parent && window.parent.document) {
            const iframe = window.parent.document.getElementById("contentFrame");
            if (iframe) {
                var adjustedPage = page.includes('/') ? page : '../' + page;
                iframe.src = adjustedPage;

                if (window.parent.updateParentBreadcrumb) {
                    window.parent.updateParentBreadcrumb(breadcrumbPath, adjustedPage);
                }
            }
        }
    }
</script>

</body>
</html>
