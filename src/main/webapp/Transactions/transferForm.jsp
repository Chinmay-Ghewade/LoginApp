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
    String creditAccountCode = request.getParameter("creditAccountCode");
    String creditAccountName = request.getParameter("creditAccountName");
    
    if (operationType == null) operationType = "";
    if (accountCategory == null) accountCategory = "";
    if (accountCode == null) accountCode = "";
    if (accountName == null) accountName = "";
    if (creditAccountCode == null) creditAccountCode = "";
    if (creditAccountName == null) creditAccountName = "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Transfer Form</title>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <link rel="stylesheet" href="css/transactionsForm.css">
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
</head>
<body>

<form action="ProcessTransferServlet" method="post" onsubmit="return validateForm()">
    <input type="hidden" name="operationType" value="<%= operationType %>">
    <input type="hidden" name="accountCategory" value="<%= accountCategory %>">
    <input type="hidden" name="accountCode" value="<%= accountCode %>">
    <input type="hidden" name="creditAccountCode" value="<%= creditAccountCode %>">
    
    <!-- ========================================== -->
    <!-- DEBIT ACCOUNT INFORMATION FIELDSET -->
    <!-- ========================================== -->
    <fieldset class="account-info-section" id="debitAccountInfoSection">
        <legend>Debit Account Information</legend>
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

    <!-- ========================================== -->
    <!-- CREDIT ACCOUNT INFORMATION FIELDSET -->
    <!-- ========================================== -->
    <fieldset class="account-info-section" id="creditAccountInfoSection">
        <legend>Credit Account Information</legend>
        <div class="form-grid">
            
            <div>
                <label>GL Account Code</label>
                <input type="text" id="creditGlAccountCode" name="creditGlAccountCode" readonly>
            </div>
            
            <div>
                <label>GL Account Name</label>
                <input type="text" id="creditGlAccountName" name="creditGlAccountName" readonly>
            </div>
            
            <div>
                <label>Customer ID</label>
                <input type="text" id="creditCustomerId" name="creditCustomerId" readonly>
            </div>
            
            <div>
                <label>Ledger Balance</label>
                <input type="text" id="creditLedgerBalance" name="creditLedgerBalance" readonly>
            </div>
            
            <div>
                <label>Available Balance</label>
                <input type="text" id="creditAvailableBalance" name="creditAvailableBalance" readonly>
            </div>
            
            <div>
                <label>New Ledger Balance</label>
                <input type="text" id="creditNewLedgerBalance" name="creditNewLedgerBalance" readonly>
            </div>
            
            <div>
			    <label>Limit Amount</label>
			    <input type="text" id="creditLimitAmount" name="creditLimitAmount" readonly>
			</div>
			
			<div>
			    <label>Drawing Power</label>
			    <input type="text" id="creditDrawingPower" name="creditDrawingPower" readonly>
			</div>
			
			<div>
			    <label>Unclear Balance</label>
			    <input type="text" id="creditUnclearBalance" name="creditUnclearBalance" readonly>
			</div>
			
			<div>
			    <label>Last Transaction Date</label>
			    <input type="date" id="creditLastTransactionDate" name="creditLastTransactionDate" readonly>
			</div>
			
			<div>
			    <label>Account Review Date</label>
			    <input type="date" id="creditAccountReviewDate" name="creditAccountReviewDate" readonly>
			</div>
			
			<div>
			    <label>Last OD Date</label>
			    <input type="date" id="creditLastOdDate" name="creditLastOdDate" readonly>
			</div>
			
			<div>
			    <label>OD Interest</label>
			    <input type="text" id="creditOdInterest" name="creditOdInterest" readonly>
			</div>
			
			<div>
			    <label>Aadhar Number</label>
			    <input type="text" id="creditAadharnumber" name="creditAadharnumber" readonly>
			</div>
			
			<div>
			    <label>PAN Number</label>
			    <input type="text" id="creditPannumber" name="creditPannumber" readonly>
			</div>
			
			<div>
			    <label>ZIP Code</label>
			    <input type="text" id="creditZipcode" name="creditZipcode" readonly>
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

function checkDebitAccountDetails() {
    const accountCode = '<%= accountCode %>';
    const accountCategory = '<%= accountCategory %>';

    if (!accountCode) {
        showToast('No debit account selected', 'error');
        return;
    }

    if (accountCategory === 'loan' || accountCategory === 'cc') {
        document.getElementById('limitAmount').closest('div').style.display = 'flex';
        document.getElementById('drawingPower').closest('div').style.display = 'flex';
        document.getElementById('accountReviewDate').closest('div').style.display = 'flex';
    } else {
        document.getElementById('limitAmount').closest('div').style.display = 'none';
        document.getElementById('drawingPower').closest('div').style.display = 'none';
        document.getElementById('accountReviewDate').closest('div').style.display = 'none';
    }

    fetch('GetAccountDetails.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showToast('Error: ' + data.error, 'error');
            } else {
                document.getElementById('glAccountCode').value    = data.glAccountCode || '';
                document.getElementById('glAccountName').value    = data.glAccountName || '';
                document.getElementById('customerId').value       = data.customerId || '';
                document.getElementById('aadharnumber').value     = data.aadharNumber || '';
                document.getElementById('pannumber').value        = data.panNumber || '';
                document.getElementById('zipcode').value          = data.zipcode || '';
                document.getElementById('ledgerBalance').value    = data.ledgerBalance || '0.00';
                document.getElementById('availableBalance').value = data.availableBalance || '0.00';

                // ✅ Get txnAmount passed from parent window via URL param
                const urlParams = new URLSearchParams(window.location.search);
                const txnAmount = parseFloat(urlParams.get('txnAmount')) || 0;
                const ledgerBalance = parseFloat(data.ledgerBalance) || 0;

                // ✅ Debit: subtract txnAmount from ledgerBalance
                document.getElementById('newLedgerBalance').value = 
                    (ledgerBalance - txnAmount).toFixed(2);
            }
        })
        .catch(error => {
            console.error('Error fetching debit account details:', error);
            showToast('Failed to fetch debit account details', 'error');
        });
}

function checkCreditAccountDetails() {
    const creditAccountCode = '<%= creditAccountCode %>';

    if (!creditAccountCode) {
        showToast('No credit account selected', 'error');
        return;
    }

    fetch('GetAccountDetails.jsp?accountCode=' + encodeURIComponent(creditAccountCode))
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showToast('Error: ' + data.error, 'error');
            } else {
                document.getElementById('creditGlAccountCode').value    = data.glAccountCode || '';
                document.getElementById('creditGlAccountName').value    = data.glAccountName || '';
                document.getElementById('creditCustomerId').value       = data.customerId || '';
                document.getElementById('creditLedgerBalance').value    = data.ledgerBalance || '0.00';
                document.getElementById('creditAvailableBalance').value = data.availableBalance || '0.00';
                document.getElementById('creditAadharnumber').value     = data.aadharNumber || '';
                document.getElementById('creditPannumber').value        = data.panNumber || '';
                document.getElementById('creditZipcode').value          = data.zipcode || '';

                // ✅ Get txnAmount passed from parent window via URL param
                const urlParams = new URLSearchParams(window.location.search);
                const txnAmount = parseFloat(urlParams.get('txnAmount')) || 0;
                const creditLedgerBalance = parseFloat(data.ledgerBalance) || 0;

                // ✅ Credit: add txnAmount to creditLedgerBalance
                document.getElementById('creditNewLedgerBalance').value = 
                    (creditLedgerBalance + txnAmount).toFixed(2);
            }
        })
        .catch(error => {
            console.error('Error fetching credit account details:', error);
            showToast('Failed to fetch credit account details', 'error');
        });
}

// Show account info sections when page loads if accounts are selected
window.addEventListener('DOMContentLoaded', function() {
    const accountCode = '<%= accountCode %>';
    const creditAccountCode = '<%= creditAccountCode %>';
    
    if (accountCode && accountCode.trim() !== '') {
        document.getElementById('debitAccountInfoSection').classList.add('active');
        checkDebitAccountDetails();
    }
    
    if (creditAccountCode && creditAccountCode.trim() !== '') {
        document.getElementById('creditAccountInfoSection').classList.add('active');
        checkCreditAccountDetails();
    }
});
</script>

</body>
</html>