<%@ page contentType="text/html; charset=UTF-8" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String branchCode = (String) session.getAttribute("branchCode");

    if (branchCode == null) {
        response.sendRedirect("../../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Charges</title>
    <link rel="stylesheet" href="../../css/cardView.css">
</head>
<body>

<div class="dashboard-container">
    <div class="cards-wrapper">

        <!-- 1. Debit Charges To Account -->
        <div class="card" onclick="openInParentFrame('Transactions/Charges/debitCharges.jsp', 'Transactions > Charges > Debit Charges To Account')">
            <h3>Debit Charges To Account</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 2. Loan Int. Posting -->
        <div class="card" onclick="openInParentFrame('Transactions/Charges/loanIntPosting.jsp', 'Transactions > Charges > Loan Int. Posting')">
            <h3>Loan Int. Posting</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 3. Deposit Int. Posting -->
        <div class="card" onclick="openInParentFrame('Transactions/Charges/depositIntPosting.jsp', 'Transactions > Charges > Deposit Int. Posting')">
            <h3>Deposit Int. Posting</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 4. Saving Int. Posting -->
        <div class="card" onclick="openInParentFrame('Transactions/Charges/savingIntPosting.jsp', 'Transactions > Charges > Saving Int. Posting')">
            <h3>Saving Int. Posting</h3>
            <p class="size-1">→</p>
        </div>

        <!-- 5. Rebit Int. Posting -->
        <div class="card" onclick="openInParentFrame('Transactions/Charges/rebitIntPosting.jsp', 'Transactions > Charges > Rebit Int. Posting')">
            <h3>Rebit Int. Posting</h3>
            <p class="size-1">→</p>
        </div>

    </div>
</div>

<script>
    window.onload = function () {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Transactions > Charges');
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
