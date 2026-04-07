<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Authorization Pending</title>
    <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
	<link rel="stylesheet" href="../css/cardView.css">
</head>
<body>
    <div class="dashboard-container">
        <div class="cards-wrapper">
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingCustomers.jsp', 'Authorization  > Customer List')">
                <h3>Authorization Pending Customers</h3>
                <p class="loading" id="pending-customers-value">Loading...</p>
            </div>
            
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingApplications.jsp', 'Authorization > Application List')">
                <h3>Authorization Pending Application</h3>
                <p class="loading" id="pending-applications-value">Loading...</p>
            </div>
            
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingMasters.jsp', 'Authorization > Pending Masters')">
                <h3>Authorization Pending Masters</h3>
                <p class="loading" id="pending-masters-value">Loading...</p>
            </div>
            
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingUsers.jsp', 'Authorization > Pending Users')">
                <h3>Authorization Pending Users</h3>
                <p class="loading" id="pending-users-value">Loading...</p>
            </div>
            
        <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingTransactionCash.jsp', 'Authorization > Pending Transaction (Cash)')">
                <h3>Authorization Pending Transaction (Cash)</h3>
                <p class="loading" id="pending-txn-cash-value">Loading...</p>
            </div>
            
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingTransactionTransfer.jsp', 'Authorization > Pending Transaction (Transfer)')">
                <h3>Authorization Pending Transaction (Transfer)</h3>
                <p class="loading" id="pending-txn-transfer-value">Loading...</p>
            </div>
            
            <div class="card" onclick="openInParentFrame('Authorization/authorizationPendingShares.jsp', 'Authorization > Pending Shares')">
                <h3>Authorization Pending Shares </h3>
                <p class="loading" id="pending-shares-value">Loading...</p>
            </div>
        </div>  <%-- this closing div was already there --%>
    </div>
    
    <script>
    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb(
                window.buildBreadcrumbPath('authorizationPending.jsp')
            );
        }
        loadCardValues();
    };
    
    async function loadCardValues() {
        await Promise.all([
            loadCard('pending_customers', 'pending-customers-value', 'auth'),
            loadCard('pending_applications', 'pending-applications-value', 'auth'),
            loadCard('pending_masters', 'pending-masters-value', 'auth'),
            loadCard('pending_users', 'pending-users-value', 'auth'),
            loadCard('pending_txn_cash', 'pending-txn-cash-value', 'auth'),
            loadCard('pending_txn_transfer', 'pending-txn-transfer-value', 'auth'),
            loadCard('pending_shares', 'pending-shares-value', 'auth')
            
        ]);
    }

    
    async function loadCard(cardId, elementId, cardType) {
        try {
            const response = await fetch('../getCardValueUnified.jsp?type=' + cardType + '&id=' + cardId);
            const data = await response.json();
            
            const valueElement = document.getElementById(elementId);
            if (valueElement) {
                if (data.error) {
                    valueElement.textContent = 'Error';
                } else {
                    valueElement.textContent = data.value;
                }
                valueElement.classList.remove('loading');
            }
        } catch (error) {
            console.error('Error loading card:', error);
            const valueElement = document.getElementById(elementId);
            if (valueElement) {
                valueElement.textContent = 'Error';
                valueElement.classList.remove('loading');
            }
        }
    }

    function openInParentFrame(page, breadcrumbPath) {
        if (window.parent && window.parent.document) {
            const iframe = window.parent.document.getElementById("contentFrame");
            if (iframe) {
                iframe.src = page;
                if (window.parent.updateParentBreadcrumb) {
                    window.parent.updateParentBreadcrumb(breadcrumbPath);
                }
            }
        }
    }
</script>
</body>
</html>
