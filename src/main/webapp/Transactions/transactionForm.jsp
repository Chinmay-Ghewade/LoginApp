<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    String operationType = request.getParameter("operationType");
    String accountCategory = request.getParameter("accountCategory");
    String accountCode = request.getParameter("accountCode");
    String accountName = request.getParameter("accountName");
    
    if (operationType == null) operationType = "";
    if (accountCategory == null) accountCategory = "";
    if (accountCode == null) accountCode = "";
    if (accountName == null) accountName = "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Transaction Form</title>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <link rel="stylesheet" href="css/transactionsForm.css">
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
</head>
<body>

<form action="ProcessTransactionServlet" method="post" onsubmit="return validateForm()">
    <input type="hidden" name="operationType" value="<%= operationType %>">
    <input type="hidden" name="accountCategory" value="<%= accountCategory %>">
    <input type="hidden" name="accountCode" value="<%= accountCode %>">
    
    <!-- ========================================== -->
    <!-- ACCOUNT INFORMATION FIELDSET -->
    <!-- ========================================== -->
    <fieldset class="account-info-section" id="accountInfoSection">
        <legend>Account Information</legend>
        <div class="form-grid">
            
            <div>
                <label>GL Account Code</label>
                <input type="text" id="glAccountCode" name="glAccountCode" readonly>
            </div>
            
            <div>
                <label>GL Account Name</label>
                <input type="text" id="glAccountName" name="glAccountName" readonly>
            </div>
            
            <div>
			    <label>Customer ID</label>
			    <input type="text" id="customerId" name="customerId" readonly>
			</div>
			
            <div>
                <label>Ledger Balance</label>
                <input type="text" id="ledgerBalance" name="ledgerBalance" readonly>
            </div>
            
            <div>
                <label>Available Balance</label>
                <input type="text" id="availableBalance" name="availableBalance" readonly>
            </div>
            
            <div>
                <label>New Ledger Balance</label>
                <input type="text" id="newLedgerBalance" name="newLedgerBalance" readonly>
            </div>
            
            <div>
                <label>Limit Amount</label>
                <input type="text" id="limitAmount" name="limitAmount" readonly>
            </div>
            
            <div>
                <label>Drawing Power</label>
                <input type="text" id="drawingPower" name="drawingPower" readonly>
            </div>
            
            <div>
                <label>Unclear Balance</label>
                <input type="text" id="unclearBalance" name="unclearBalance" readonly>
            </div>
            
            <div>
                <label>Last Transaction Date</label>
                <input type="date" id="lastTransactionDate" name="lastTransactionDate" readonly>
            </div>
            
            <div>
                <label>Account Review Date</label>
                <input type="date" id="accountReviewDate" name="accountReviewDate" readonly>
            </div>
            
            <div>
                <label>Last OD Date</label>
                <input type="date" id="lastOdDate" name="lastOdDate" readonly>
            </div>
            
            <div>
                <label>OD Interest</label>
                <input type="text" id="odInterest" name="odInterest" readonly>
            </div>
                        
            <div>
                <label>Aadhar Number</label>
                <input type="text" id="aadharnumber" name="aadharnumber" readonly>
            </div>
            
            <div>
                <label>PAN Number</label>
                <input type="text" id="pannumber" name="pannumber" readonly>
            </div>
            
            <div>
                <label>ZIP Code</label>
                <input type="text" id="zipcode" name="zipcode" readonly>
            </div>
            
        </div>
    </fieldset>

</form>

<script>
function showToast(message, type = 'info') {
    const styles = {
        success: { borderColor: '#4caf50', icon: '✅' },
        error: { borderColor: '#f44336', icon: '❌' },
        warning: { borderColor: '#ff9800', icon: '⚠️' },
        info: { borderColor: '#2196F3', icon: 'ℹ️' }
    };
    const style = styles[type] || styles.info;
    
    Toastify({
        text: style.icon + ' ' + message,
        duration: 5000,
        close: true,
        gravity: "top",
        position: "center",
        style: {
            background: "#fff",
            color: "#333",
            borderRadius: "8px",
            fontSize: "14px",
            padding: "16px 24px",
            boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
            borderLeft: "5px solid " + style.borderColor,
            marginTop: "20px"
        }
    }).showToast();
}

function validateForm() {
    return true;
}

function checkAccountDetails() {
    const accountCode = '<%= accountCode %>';
    const accountCategory = '<%= accountCategory %>';
    
    console.log('Account Code:', accountCode); // DEBUG
    console.log('Account Category:', accountCategory); // DEBUG
    
    if (!accountCode) {
        showToast('No account selected', 'error');
        return;
    }
    
    // Show/hide fields based on account category (before fetching data)
    if (accountCategory === 'loan' || accountCategory === 'cc') {
        // Show loan/CC specific fields
        document.getElementById('limitAmount').closest('div').style.display = 'flex';
        document.getElementById('drawingPower').closest('div').style.display = 'flex';
        document.getElementById('accountReviewDate').closest('div').style.display = 'flex';
    } else {
        // Hide loan/CC specific fields for other categories
        document.getElementById('limitAmount').closest('div').style.display = 'none';
        document.getElementById('drawingPower').closest('div').style.display = 'none';
        document.getElementById('accountReviewDate').closest('div').style.display = 'none';
    }
    
    // Make AJAX call to fetch account details
    fetch('GetAccountDetails.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => {
            console.log('Response status:', response.status); // DEBUG
            return response.json();
        })
        .then(data => {
            console.log('Data received:', data); // DEBUG
            
            if (data.error) {
                showToast('Error: ' + data.error, 'error');
            } else {
                // Populate GL Account Code and Name
                document.getElementById('glAccountCode').value = data.glAccountCode || '';
                document.getElementById('glAccountName').value = data.glAccountName || '';
               	document.getElementById('customerId').value = data.customerId || '';
               	document.getElementById('aadharnumber').value = data.aadharNumber || '';
               	document.getElementById('pannumber').value = data.panNumber || '';
               	document.getElementById('zipcode').value = data.zipcode || '';
                
                // Populate product name and balance fields
                document.getElementById('ledgerBalance').value = data.ledgerBalance || '0.00';
                document.getElementById('availableBalance').value = data.availableBalance || '0.00';
                
            }
        })
        .catch(error => {
            console.error('Error fetching account details:', error);
            showToast('Failed to fetch account details', 'error');
        });
}

//Show account info section when page loads if account is selected
window.addEventListener('DOMContentLoaded', function() {
    const accountCode = '<%= accountCode %>';
    const operationType = '<%= operationType %>';
    
    if (accountCode && accountCode.trim() !== '') {
        document.getElementById('accountInfoSection').classList.add('active');
        checkAccountDetails();
    }
});
</script>

</body>
</html>